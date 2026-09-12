% SPDX-License-Identifier: Apache-2.0
% SPDX-FileCopyrightText: 2026 DBVisor

-module(atomic_term).

-export([new/1, put/3, get/2]).

-on_load(init/0).

init() ->
    erlang:load_nif(code:priv_dir(sql) ++ "/atomic_term", 0).

new(_Size) ->
    erlang:nif_error(nif_not_loaded).

put(_Resource, _Index, _Term) ->
    erlang:nif_error(nif_not_loaded).

get(_Resource, _Index) ->
    erlang:nif_error(nif_not_loaded).
