// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 DBVisor

#include <erl_nif.h>
#include <stdatomic.h>
#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>


typedef struct {
    size_t size;
    ErlNifEnv* env;
    _Atomic(uintptr_t) slots[];
} AtomicTermArray;

static ERL_NIF_TERM OK;
static ErlNifResourceType* ATOMIC_TERM_RESOURCE = NULL;

static void atomic_term_dtor(ErlNifEnv* env, void* obj) {
    (void)env;
    AtomicTermArray* array = (AtomicTermArray*)obj;
    if (array->env != NULL) {
        enif_free_env(array->env);
    }
}

static int load(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info) {
    (void)priv_data;
    (void)load_info;
    ErlNifResourceFlags flags = (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER);
    ATOMIC_TERM_RESOURCE = enif_open_resource_type(
        env,
        NULL,
        "atomic_term_resource",
        atomic_term_dtor,
        flags,
        NULL
    );
    OK = enif_make_atom(env, "ok");
    return (ATOMIC_TERM_RESOURCE == NULL) ? -1 : 0;
}

static ERL_NIF_TERM new(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    unsigned int size;
    enif_get_uint(env, argv[0], &size);
    size_t total_bytes = sizeof(AtomicTermArray) + (sizeof(_Atomic(uintptr_t)) * size);
    AtomicTermArray* array = enif_alloc_resource(ATOMIC_TERM_RESOURCE, total_bytes);
    array->size = (size_t)size;
    array->env = enif_alloc_env();
    ERL_NIF_TERM term = enif_make_resource(env, array);
    enif_release_resource(array);
    return term;
}

static ERL_NIF_TERM put(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    (void)argc;
    AtomicTermArray* array;
    unsigned int raw_idx;
    enif_get_resource(env, argv[0], ATOMIC_TERM_RESOURCE, (void**)&array);
    enif_get_uint(env, argv[1], &raw_idx);
    size_t idx = raw_idx-1;
    uintptr_t stored = (ERL_NIF_TERM)enif_make_copy(array->env, argv[2]);
    atomic_store_explicit(&array->slots[idx], stored, memory_order_release);
    return OK;
}

static ERL_NIF_TERM get(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    (void)argc;
    AtomicTermArray* array;
    unsigned int raw_idx;
    enif_get_resource(env, argv[0], ATOMIC_TERM_RESOURCE, (void**)&array);
    enif_get_uint(env, argv[1], &raw_idx);
    size_t idx = raw_idx-1;
    ERL_NIF_TERM stored = (ERL_NIF_TERM)atomic_load_explicit(&array->slots[idx], memory_order_acquire);
    return enif_make_copy(env, stored);
}

static ErlNifFunc funcs[] = {
    {"new", 1, new},
    {"put", 3, put},
    {"get", 2, get},
};

ERL_NIF_INIT(atomic_term, funcs, load, NULL, NULL, NULL)
