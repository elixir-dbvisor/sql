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
    pid: nil,
    secret: nil,
    size: 10,
    sock: nil,
    sockets: nil,
    queue: nil
  ]

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: config[:name])
  end

  @impl true
  def init(config) do
    size = config[:size] || :erlang.system_info(:schedulers)
    pool = struct(init(config[:name], size), config)
    children =
      for n <- 1..size do
        %{
          id: make_ref(),
          start: {pool.adapter, :start, [%{pool | scheduler_id: n}]},
          restart: :permanent,
          shutdown: 5000,
          type: :worker,
        }
      end
    Supervisor.init(children, strategy: :one_for_one)
  end

  def init(name, size) do
    size = size || :erlang.system_info(:schedulers)
    queue = :atomic_queue.new(1024*4, size)
    sockets = :atomic_term.new(size)
    prepared = :atomic_term.new(size)
    pool = :atomic_term.new(3)
    :atomic_term.put(pool, 1, queue)
    :atomic_term.put(pool, 2, sockets)
    :atomic_term.put(pool, 3, prepared)
    :persistent_term.put(name, pool)
    struct(__MODULE__, name: name, size: size, sockets: sockets, queue: queue, prepared: prepared)
  end

  def register_connection(queue, slot, pid) do
    :ok = :atomic_queue.register_connection(queue, slot, pid)
  end

  def checkin(pool, slot) do
    checkin(pool, :atomic_term.get(:persistent_term.get(pool), 1), slot)
  end

  defp checkin(pool, queue, slot) do
    case :atomic_queue.checkin(queue, slot) do
      :ok ->
        Process.delete(SQL.Transaction)
        :ok
      :busy ->
        checkin(pool, queue, slot)
    end
  end

  def checkout(pool, timeout, caller \\ self()) do
    pool = :persistent_term.get(pool)
    checkout(:atomic_term.get(pool, 1), :atomic_term.get(pool, 2), :atomic_term.get(pool, 3), timeout, caller)
  end

  defp checkout(queue, sockets, prepared, timeout, caller) do
    case :atomic_queue.checkout(queue, caller, :erlang.system_info(:scheduler_id)) do
      {:ok, conn, slot} -> {:ok, conn, socket(sockets, slot), :atomic_term.get(prepared, slot), slot}
      :full -> checkout(queue, sockets, prepared, timeout, caller)
      idx ->
        receive do
          {:ok, conn, slot} -> {:ok, conn, socket(sockets, slot), :atomic_term.get(prepared, slot), slot}
        after
          timeout ->
            :atomic_queue.dequeue(queue, caller, idx)
            receive do
              {:ok, _conn, slot} ->
                :atomic_queue.checkin(queue, slot)
                {:error, :timeout}
            after
              0 ->
                {:error, :timeout}
            end
        end
    end
  end

  defp socket(sockets, slot) do
    ref = :atomic_term.get(sockets, slot)
    :persistent_term.get(ref, {:"$socket", ref})
  end
end
