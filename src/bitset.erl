% SPDX-License-Identifier: Apache-2.0
% SPDX-FileCopyrightText: 2026 DBVisor

-module(bitset).

-export([new/1, mark_prepared/2, is_prepared/2]).

-on_load(init/0).

init() ->
    erlang:load_nif(code:priv_dir(sql) ++ "/bitset", 0).

new(_Size) ->
    erlang:nif_error(nif_not_loaded).

mark_prepared(_Ref, _Integer) ->
    erlang:nif_error(nif_not_loaded).

is_prepared(_Ref, _Integer) ->
    erlang:nif_error(nif_not_loaded).
