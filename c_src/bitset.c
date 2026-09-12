// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 DBVisor

#include <erl_nif.h>
#include <stdatomic.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>

typedef struct {
    size_t bit_capacity;
    size_t num_slots;
    _Atomic(uint64_t) slots[];
} QueryBitSet;

static ErlNifResourceType* BITSET_RESOURCE = NULL;
static ERL_NIF_TERM ATOM_OK;
static ERL_NIF_TERM ATOM_ERROR;
static ERL_NIF_TERM ATOM_TRUE;
static ERL_NIF_TERM ATOM_FALSE;

static void bitset_dtor(ErlNifEnv* env, void* obj) {
    (void)env; (void)obj;
}

static int load(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info) {
    (void)priv_data; (void)load_info;
    ErlNifResourceFlags flags = (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER);
    BITSET_RESOURCE = enif_open_resource_type(env, NULL, "query_bitset", bitset_dtor, flags, NULL);
    if (!BITSET_RESOURCE) return -1;
    ATOM_OK = enif_make_atom(env, "ok");
    ATOM_ERROR = enif_make_atom(env, "error");
    ATOM_TRUE = enif_make_atom(env, "true");
    ATOM_FALSE = enif_make_atom(env, "false");
    return 0;
}

static ERL_NIF_TERM new(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    unsigned int max_query_id;
    enif_get_uint(env, argv[0], &max_query_id);
    size_t bit_capacity = max_query_id + 1;
    size_t num_slots = (bit_capacity + 63) / 64;
    size_t size = sizeof(QueryBitSet) + (num_slots * sizeof(_Atomic(uint64_t)));
    QueryBitSet* set = enif_alloc_resource(BITSET_RESOURCE, size);
    set->bit_capacity = bit_capacity;
    set->num_slots = num_slots;
    memset((void*)set->slots, 0, num_slots * sizeof(_Atomic(uint64_t)));
    ERL_NIF_TERM resource_term = enif_make_resource(env, set);
    enif_release_resource(set);
    return resource_term;
}

static ERL_NIF_TERM mark_prepared(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    QueryBitSet* set;
    ErlNifUInt64 query_id;
    enif_get_resource(env, argv[0], BITSET_RESOURCE, (void**)&set);
    enif_get_uint64(env, argv[1], &query_id);
    size_t idx = query_id / 64;
    uint64_t bit = 1ULL << (query_id % 64);
    atomic_fetch_or_explicit(&set->slots[idx], bit, memory_order_acq_rel);
    return ATOM_OK;
}

static ERL_NIF_TERM is_prepared(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    QueryBitSet* set;
    ErlNifUInt64 query_id;
    enif_get_resource(env, argv[0], BITSET_RESOURCE, (void**)&set);
    enif_get_uint64(env, argv[1], &query_id);
    size_t idx = query_id / 64;
    uint64_t bit = 1ULL << (query_id % 64);
    uint64_t val = atomic_load_explicit(&set->slots[idx], memory_order_acquire);
    if (val & bit) {
        return ATOM_TRUE;
    } else {
        return ATOM_FALSE;
    }
}

static ErlNifFunc funcs[] = {
    {"new", 1, new},
    {"mark_prepared", 2, mark_prepared},
    {"is_prepared", 2, is_prepared}
};

ERL_NIF_INIT(bitset, funcs, load, NULL, NULL, NULL)
