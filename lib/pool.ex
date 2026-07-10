# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Pool do
  @moduledoc false
  use Supervisor

  @derive {Inspect, only: []}
  defstruct [
    ssl: false,
    timeout: 250,
    parameter: [],
    prepared: nil,
    name: :default,
    domain: :inet,
    type: :stream,
    protocol: :tcp,
    use_registry: false,
    debug: false,
    otp: %{rcvbuf: {4,  64 * 1024}, select_read: false},
    socket: %{rcvbuf:  64 * 1024, sndbuf:  64 * 1024, keepalive: true, reuseaddr: true},
    tcp: %{nodelay: true, quickack: true, nopush: false, cork: false, keepidle: 60, keepintvl: 5, keepcnt: 3},
    family: :inet,
    port: 5432,
    addr: {127, 0, 0, 1},
    scheduler_id: nil,
    adapter: nil,
    username: nil,
    password: nil,
    hostname: nil,
    database: nil,
    timezone: nil,
    pid: nil,
    secret: nil,
    state: nil,
    size: 10,
    queue: nil,
    sock: nil,
    handle: nil,
    metrics: nil,
    sockets: nil,
  ]

  def start_link(state) do
    Supervisor.start_link(__MODULE__, state, name: state.name)
  end

  @impl true
  def init(state) do
    {_metrics, sockets, _state, _queue, _prepared} = :persistent_term.get(state.name)
    children =
      for n <- 1..state.size do
        handle = make_ref()
        %{
          id: handle,
          start: {state.adapter, :start, [%{state | scheduler_id: n, sockets: sockets, handle: handle, state: state.state}]},
          restart: :permanent,
          shutdown: 5000,
          type: :worker,
        }
      end
    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc false
  def checkout(stats, queue, state, timeout) do
    caller = self()
    a = :erlang.system_info(:scheduler_id)
    {a, b} = case :atomics.info(state)[:size] do
              1 -> {1, 1}
              ^a -> {a, a-1}
              _ -> {a, a+1}
            end
    case :atomics.compare_exchange(state, a, 0, 1) do
      :ok -> monitor(stats, queue, state, a, caller)
      1 ->
        case :atomics.compare_exchange(state, b, 0, 1) do
          :ok -> monitor(stats, queue, state, b, caller)
          1 ->
            idx = :atomics.add_get(stats, 2, 1)
            :ets.insert(queue, {idx, caller})
            receive do
              {^idx, msg} -> msg
            after
              timeout ->
                case :ets.lookup(queue, idx) do
                  [{^idx, ^caller}] ->
                    :ets.delete(queue, idx)
                    {:error, :timeout}
                  [{^idx, _pid}] -> {:error, :timeout}
                  [] ->
                    receive do
                      {^idx, msg} -> msg
                    end
                end
            end
        end
    end
  end

  @doc false
  def dequeue(stats, queue, state, slot) do
    if 0 < :atomics.get(stats, 2) do
      idx = :atomics.add_get(stats, 2, -1)+1
      case :ets.take(queue, idx) do
        [{^idx, caller}] ->
          spawn(fn ->
            ref = Process.monitor(caller)
            send caller, {idx, {slot, self()}}
            receive do
              :release ->
                Process.demonitor(ref, [:flush])
              {:DOWN, ^ref, :process, ^caller, reason} when reason not in ~w[normal shutdown]a ->
                dequeue(stats, queue, state, slot)
            end
            exit(:normal)
          end)
        [] -> dequeue(stats, queue, state, slot)
      end
    else
      :ok = :atomics.compare_exchange(state, slot, 1, 0)
    end
  end

  defp monitor(stats, queue, state, slot, caller) do
    {slot, spawn(fn ->
      ref = Process.monitor(caller)
      receive do
        :release ->
          Process.demonitor(ref, [:flush])
        {:DOWN, ^ref, :process, ^caller, reason} when reason not in ~w[normal shutdown]a ->
          dequeue(stats, queue, state, slot)
      end
      exit(:normal)
    end)}
  end
end
