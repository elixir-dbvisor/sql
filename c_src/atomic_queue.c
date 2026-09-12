// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 DBVisor

#include <erl_nif.h>
#include <stdatomic.h>
#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <stdalign.h>

// Cross-platform CPU pause intrinsic
#if defined(__x86_64__) || defined(_M_X64) || defined(__i386__) || defined(_M_IX86)
#include <emmintrin.h>
#include <immintrin.h>
#define CPU_PAUSE() _mm_pause()
#elif defined(__aarch64__) || defined(_M_ARM64)
#define CPU_PAUSE() __asm__ __volatile__("yield" ::: "memory")
#else
#define CPU_PAUSE() ((void)0)
#endif

// --- Cross-Platform Aligned Allocation Helpers ---

static inline void* alloc_aligned(size_t alignment, size_t size) {
    size_t rounded_size = (size + alignment - 1) & ~(alignment - 1);
#if defined(_MSC_VER)
    return _aligned_malloc(rounded_size, alignment);
#elif defined(_POSIX_C_SOURCE) && (_POSIX_C_SOURCE >= 200112L)
    void* ptr = NULL;
    if (posix_memalign(&ptr, alignment, rounded_size) != 0) return NULL;
    return ptr;
#else
    return aligned_alloc(alignment, rounded_size);
#endif
}

static inline void free_aligned(void* ptr) {
    if (!ptr) return;
#if defined(_MSC_VER)
    _aligned_free(ptr);
#else
    free(ptr);
#endif
}

// --- BMI1 / Bit Manipulation Intrinsics ---

#if defined(__x86_64__) && (defined(__BMI__) || defined(__BMI1__))
#define count_trailing_zeros(mask) (int)_tzcnt_u64(mask)
#elif defined(_MSC_VER) && (defined(_M_X64) || defined(_M_ARM64))
#include <intrin.h>
static inline int count_trailing_zeros(uint64_t mask) {
    unsigned long index;
    _BitScanForward64(&index, mask);
    return (int)index;
}
#else
#define count_trailing_zeros(mask) __builtin_ctzll(mask)
#endif

#define LIKELY(x)   __builtin_expect(!!(x), 1)
#define UNLIKELY(x) __builtin_expect(!!(x), 0)

#if defined(__GNUC__) || defined(__clang__)
#define ALWAYS_INLINE __attribute__((always_inline)) static inline
#elif defined(_MSC_VER)
#define ALWAYS_INLINE __forceinline static inline
#else
#define ALWAYS_INLINE static inline
#endif

#define NUM_SHARDS 16
#define NUM_SHARDS_MASK 15 // (NUM_SHARDS - 1)
#define SHARD_SHIFT 4      // log2(16) = 4
#define MAX_POOL_SIZE (NUM_SHARDS * 64) // 1024

static ERL_NIF_TERM ATOM_OK;
static ERL_NIF_TERM ATOM_FULL;

// Slot State Definitions
typedef enum {
    SLOT_UNREGISTERED = 0,
    SLOT_IDLE         = 1,
    SLOT_CHECKED_OUT  = 2,
} SlotState;

typedef struct {
    alignas(64) _Atomic(uint32_t) state;
    ErlNifPid conn_pid;
} FastSlot;

_Static_assert(sizeof(FastSlot) == 64, "FastSlot must be exactly 64 bytes");
_Static_assert(alignof(FastSlot) == 64, "FastSlot must be 64-byte aligned");

typedef struct {
    ErlNifPid caller_pid;
    uint64_t checkout_time_ms;
} SlowSlot;

typedef struct {
    alignas(64) _Atomic(size_t) sequence;
    ErlNifPid client_pid;
    uint64_t enqueue_time_ms;
} QueueCell;

_Static_assert(sizeof(QueueCell) == 64, "QueueCell must be exactly 64 bytes");
_Static_assert(alignof(QueueCell) == 64, "QueueCell must be 64-byte aligned");

typedef struct {
    alignas(64) _Atomic(uint64_t) mask;
    char _pad[64 - sizeof(_Atomic(uint64_t))];
} Shard;

_Static_assert(sizeof(Shard) == 64, "Shard must be exactly 64 bytes");

typedef struct {
    size_t capacity;
    size_t mask;
    size_t pool_size;
    uint64_t shard_masks[NUM_SHARDS];

    FastSlot *fast_pool;
    SlowSlot *slow_pool;
    QueueCell *cells;

    alignas(64) _Atomic(size_t) enqueue_pos;
    alignas(64) _Atomic(size_t) dequeue_pos;

    Shard idle_shards[NUM_SHARDS];
} Queue;

static ErlNifResourceType* QUEUE_RESOURCE = NULL;

static void queue_dtor(ErlNifEnv* env, void* obj) {
    (void)env;
    Queue* q = (Queue*)obj;
    if (q->cells) free_aligned(q->cells);
    if (q->fast_pool) free_aligned(q->fast_pool);
    if (q->slow_pool) enif_free(q->slow_pool);
}

static int load(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info) {
    (void)priv_data; (void)load_info;
    ErlNifResourceTypeInit rt_init;
    memset(&rt_init, 0, sizeof(rt_init));

    rt_init.members = 3;
    rt_init.dtor = queue_dtor;
    rt_init.stop = NULL;

    QUEUE_RESOURCE = enif_open_resource_type_x(env, "vyukov_queue_resource", &rt_init,
        (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER), NULL);
    if (UNLIKELY(QUEUE_RESOURCE == NULL)) return -1;

    ATOM_OK = enif_make_atom(env, "ok");
    ATOM_FULL = enif_make_atom(env, "full");
    return 0;
}

static inline size_t next_power_of_two(size_t n) {
    if (UNLIKELY(n <= 1)) return 1;
#if defined(__x86_64__) || defined(__aarch64__)
    return 1ULL << (64 - __builtin_clzll(n - 1));
#else
    n--; n |= n >> 1; n |= n >> 2; n |= n >> 4; n |= n >> 8; n |= n >> 16; n |= n >> 32;
    return n + 1;
#endif
}

static ERL_NIF_TERM nif_new(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    (void)argc;
    unsigned int raw_cap, pool_size;
    enif_get_uint(env, argv[0], &raw_cap);
    enif_get_uint(env, argv[1], &pool_size);

    if (pool_size == 0) pool_size = 1;
    if (pool_size > MAX_POOL_SIZE) pool_size = MAX_POOL_SIZE;

    size_t capacity = next_power_of_two((size_t)raw_cap);

    Queue* q = enif_alloc_resource(QUEUE_RESOURCE, sizeof(Queue));

    q->capacity = capacity;
    q->mask = capacity - 1;
    q->pool_size = pool_size;

    q->cells = (QueueCell*)alloc_aligned(64, sizeof(QueueCell) * capacity);
    q->fast_pool = (FastSlot*)alloc_aligned(64, sizeof(FastSlot) * pool_size);
    q->slow_pool = (SlowSlot*)enif_alloc(sizeof(SlowSlot) * pool_size);

    memset(q->cells, 0, sizeof(QueueCell) * capacity);
    memset(q->fast_pool, 0, sizeof(FastSlot) * pool_size);
    memset(q->slow_pool, 0, sizeof(SlowSlot) * pool_size);

    atomic_init(&q->enqueue_pos, 0);
    atomic_init(&q->dequeue_pos, 0);

    for (int i = 0; i < NUM_SHARDS; i++) {
        atomic_init(&q->idle_shards[i].mask, 0);
        q->shard_masks[i] = 0;
    }

    for (size_t i = 0; i < pool_size; i++) {
        atomic_init(&q->fast_pool[i].state, SLOT_UNREGISTERED);
    }

    for (size_t i = 0; i < capacity; i++) {
        atomic_init(&q->cells[i].sequence, i);
    }

    ERL_NIF_TERM resource_term = enif_make_resource(env, q);
    enif_release_resource(q);
    return resource_term;
}

static ERL_NIF_TERM nif_checkout(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    (void)argc;
    Queue* q;
    ErlNifPid client_pid;
    unsigned int sched_arg;
    enif_get_resource(env, argv[0], QUEUE_RESOURCE, (void**)&q);
    enif_get_local_pid(env, argv[1], &client_pid);
    enif_get_uint(env, argv[2], &sched_arg);

    uint32_t sched_id = (sched_arg - 1) % q->pool_size;
    uint32_t pref_shard = sched_id & NUM_SHARDS_MASK;
    uint32_t pref_bit   = sched_id >> SHARD_SHIFT;

    for (int s = 0; s < NUM_SHARDS; s++) {
        uint32_t shard_idx = (pref_shard + s) & NUM_SHARDS_MASK;

        for (;;) {
            uint64_t mask = atomic_load_explicit(&q->idle_shards[shard_idx].mask, memory_order_acquire) & q->shard_masks[shard_idx];
            if (mask == 0) break;

            uint32_t offset = 0;
            if (s == 0) {
                uint64_t upper_mask = mask & ~((1ULL << pref_bit) - 1);
                if (upper_mask != 0) {
                    offset = (uint32_t)count_trailing_zeros(upper_mask);
                } else {
                    offset = (uint32_t)count_trailing_zeros(mask);
                }
            } else {
                offset = (uint32_t)count_trailing_zeros(mask);
            }

            uint64_t bit = 1ULL << offset;

            if (atomic_compare_exchange_strong_explicit(&q->idle_shards[shard_idx].mask, &mask, mask & ~bit,
                                                        memory_order_acq_rel, memory_order_acquire)) {
                uint32_t idx = (offset << SHARD_SHIFT) + shard_idx;
                FastSlot* fast = &q->fast_pool[idx];
                SlowSlot* slow = &q->slow_pool[idx];

                uint32_t expected = SLOT_IDLE;
                if (LIKELY(atomic_compare_exchange_strong_explicit(&fast->state, &expected, SLOT_CHECKED_OUT,
                                                                memory_order_acq_rel, memory_order_acquire))) {
                    slow->caller_pid = client_pid;
                    slow->checkout_time_ms = (uint64_t)enif_monotonic_time(ERL_NIF_MSEC);
                    return enif_make_tuple3(env, ATOM_OK,
                                            enif_make_pid(env, &fast->conn_pid),
                                            enif_make_uint(env, idx + 1));
                }

                atomic_fetch_or_explicit(&q->idle_shards[shard_idx].mask, bit, memory_order_release);
            } else {
                CPU_PAUSE();
            }
        }
    }

    uint64_t now_ms = (uint64_t)enif_monotonic_time(ERL_NIF_MSEC);
    for (;;) {
        size_t pos = atomic_load_explicit(&q->enqueue_pos, memory_order_relaxed);
        QueueCell* cell = &q->cells[pos & q->mask];
        size_t seq = atomic_load_explicit(&cell->sequence, memory_order_acquire);
        intptr_t diff = (intptr_t)seq - (intptr_t)pos;

        if (LIKELY(diff == 0)) {
            if (atomic_compare_exchange_strong_explicit(&q->enqueue_pos, &pos, pos + 1,
                                                        memory_order_acq_rel, memory_order_relaxed)) {
                cell->client_pid = client_pid;
                cell->enqueue_time_ms = now_ms;
                atomic_store_explicit(&cell->sequence, pos + 1, memory_order_release);
                return enif_make_ulong(env, pos);
            }
        } else if (UNLIKELY(diff < 0)) {
            return ATOM_FULL;
        } else {
            CPU_PAUSE();
        }
    }
}

static ERL_NIF_TERM nif_dequeue(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    (void)argc;
    Queue* q;
    ErlNifPid client_pid;
    size_t pos;
    enif_get_resource(env, argv[0], QUEUE_RESOURCE, (void**)&q);
    enif_get_local_pid(env, argv[1], &client_pid);
    enif_get_ulong(env, argv[2], &pos);
    QueueCell* cell = &q->cells[pos & q->mask];
    if (!enif_compare_pids(&cell->client_pid, &client_pid)) {
        cell->enqueue_time_ms = 0;
    }
    return ATOM_OK;
}

ALWAYS_INLINE ERL_NIF_TERM drain_queue_or_idle(ErlNifEnv* env, Queue* q, size_t pool_idx) {
    FastSlot* fast = &q->fast_pool[pool_idx];
    SlowSlot* slow = &q->slow_pool[pool_idx];
    uint32_t shard_idx = pool_idx & NUM_SHARDS_MASK;
    uint64_t my_bit = 1ULL << (pool_idx >> SHARD_SHIFT);

    for (;;) {
        size_t head = atomic_load_explicit(&q->dequeue_pos, memory_order_relaxed);
        size_t tail = atomic_load_explicit(&q->enqueue_pos, memory_order_acquire);

        // 1. Try to process a waiter
        if (head != tail) {
            QueueCell* cell = &q->cells[head & q->mask];
            size_t seq = atomic_load_explicit(&cell->sequence, memory_order_acquire);
            intptr_t diff = (intptr_t)seq - (intptr_t)(head + 1);

            if (LIKELY(diff == 0)) {
                if (atomic_compare_exchange_strong_explicit(&q->dequeue_pos, &head, head + 1,
                                                            memory_order_acq_rel, memory_order_acquire)) {

                    uint64_t now_ms = (uint64_t)enif_monotonic_time(ERL_NIF_MSEC);
                    ErlNifPid waiter_pid = cell->client_pid;

                    // Release the cell for future enqueues
                    atomic_store_explicit(&cell->sequence, head + q->capacity, memory_order_release);

                    // Timeout check
                    if (cell->enqueue_time_ms == 0) {
                        continue;
                    }


                    // Optimistically prepare the slow slot
                    slow->caller_pid = waiter_pid;
                    slow->checkout_time_ms = now_ms;

                    ERL_NIF_TERM msg = enif_make_tuple3(env, ATOM_OK,
                                                        enif_make_pid(env, &fast->conn_pid),
                                                        enif_make_uint(env, (unsigned int)(pool_idx + 1)));

                    // enif_send returns 0 if the process is dead.
                    // If dead, we just loop back and process the next queued item.
                    if (enif_send(env, &waiter_pid, NULL, msg)) {
                        return ATOM_OK; // State remains CHECKED_OUT
                    }
                }
            } else if (diff < 0) {
                CPU_PAUSE();
            } else {
                CPU_PAUSE();
            }
            continue;
        }

        // 2. Queue appears empty, publish idle state
        atomic_store_explicit(&fast->state, SLOT_IDLE, memory_order_release);
        atomic_fetch_or_explicit(&q->idle_shards[shard_idx].mask, my_bit, memory_order_release);

        // // 3. Global synchronization point to prevent StoreLoad reordering
        atomic_thread_fence(memory_order_seq_cst);

        // 4. Final check to prevent the lost-wakeup race
        head = atomic_load_explicit(&q->dequeue_pos, memory_order_relaxed);
        tail = atomic_load_explicit(&q->enqueue_pos, memory_order_acquire);

        if (head == tail) {
            return ATOM_OK; // Successfully idled
        }

        // Work arrived exactly as we published idle. Re-claim ourselves.
        uint32_t expected = SLOT_IDLE;
        if (atomic_compare_exchange_strong_explicit(&fast->state, &expected, SLOT_CHECKED_OUT,
                                                    memory_order_acq_rel, memory_order_acquire)) {
            atomic_fetch_and_explicit(&q->idle_shards[shard_idx].mask, ~my_bit, memory_order_acq_rel);
            // Let the loop naturally handle the dequeue on the next iteration
        }
    }
}

static ERL_NIF_TERM nif_register_connection(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    (void)argc;
    Queue* q;
    unsigned int conn_id;
    ErlNifPid conn_pid;
    enif_get_resource(env, argv[0], QUEUE_RESOURCE, (void**)&q);
    enif_get_uint(env, argv[1], &conn_id);
    enif_get_local_pid(env, argv[2], &conn_pid);
    size_t pool_idx = conn_id - 1;
    FastSlot* fast = &q->fast_pool[pool_idx];
    fast->conn_pid = conn_pid;

    uint32_t shard_idx = pool_idx & NUM_SHARDS_MASK;
    uint64_t my_bit = 1ULL << (pool_idx >> SHARD_SHIFT);

    q->shard_masks[shard_idx] |= my_bit;

    uint32_t expected = SLOT_UNREGISTERED;
    if (atomic_compare_exchange_strong_explicit(&fast->state, &expected, SLOT_IDLE,
                                                memory_order_acq_rel, memory_order_acquire)) {
        atomic_fetch_or_explicit(&q->idle_shards[shard_idx].mask, my_bit, memory_order_release);
    }

    drain_queue_or_idle(env, q, pool_idx);
    return ATOM_OK;
}

static ERL_NIF_TERM nif_checkin(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    (void)argc;
    Queue* q;
    unsigned int conn_id;
    enif_get_resource(env, argv[0], QUEUE_RESOURCE, (void**)&q);
    enif_get_uint(env, argv[1], &conn_id);
    size_t pool_idx = conn_id - 1;
    drain_queue_or_idle(env, q, pool_idx);
    return ATOM_OK;
}

ERL_NIF_TERM nif_reclaim_stale_slots(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    Queue* q;
    enif_get_resource(env, argv[0], QUEUE_RESOURCE, (void**)&q);

    uint64_t now_ms = (uint64_t)enif_monotonic_time(ERL_NIF_MSEC);

    for (size_t i = 0; i < q->pool_size; i++) {
        FastSlot* fast = &q->fast_pool[i];
        SlowSlot* slow = &q->slow_pool[i];

        uint32_t state = atomic_load_explicit(&fast->state, memory_order_acquire);
        if (state == SLOT_CHECKED_OUT) {
            bool timed_out = (now_ms - slow->checkout_time_ms) > 1000;
            bool dead = !enif_is_process_alive(env, &slow->caller_pid);

            if (timed_out || dead) {
                drain_queue_or_idle(env, q, i);
            }
        }
    }
    return ATOM_OK;
}

static ErlNifFunc funcs[] = {
    {"new", 2, nif_new},
    {"checkout", 3, nif_checkout},
    {"register_connection", 3, nif_register_connection},
    {"checkin", 2, nif_checkin},
    {"reclaim", 1, nif_reclaim_stale_slots},
    {"dequeue", 3, nif_dequeue},
};

ERL_NIF_INIT(atomic_queue, funcs, load, NULL, NULL, NULL)
