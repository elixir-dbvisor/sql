% SPDX-License-Identifier: Apache-2.0
% SPDX-FileCopyrightText: 2026 DBVisor

-module(atomic_queue).

-export([new/2, register_connection/3, checkout/3, checkin/2, dequeue/3, reclaim/1]).

-on_load(init/0).

init() ->
    erlang:load_nif(code:priv_dir(sql) ++ "/atomic_queue", 0).

new(_QueueSize, _PoolSize) ->
    erlang:nif_error(nif_not_loaded).

checkout(_Queue, _Pid, _SchedulerID) ->
    erlang:nif_error(nif_not_loaded).

register_connection(_Queue, _Slot, _Pid) ->
    erlang:nif_error(nif_not_loaded).

checkin(_Queue, _Slot) ->
    erlang:nif_error(nif_not_loaded).

dequeue(_Queue, _Pid, _Slot) ->
    erlang:nif_error(nif_not_loaded).

reclaim(_Queue) ->
    erlang:nif_error(nif_not_loaded).
