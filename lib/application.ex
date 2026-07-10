# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Application do
  @moduledoc false

  def start(_type, _args) do
    {:ok, _} = :dets.open_file(:sql, [type: :set, ram_file: true])
    pools = Application.get_env(:sql, :pools, [])
    children = for {name, opts} <- pools do
      pool = struct(SQL.Pool, Keyword.put(opts, :size, :erlang.system_info(:schedulers)))
      metrics = :atomics.new(3, [signed: true])
      state = :atomics.new(pool.size, [signed: true])
      sockets = :ets.new(:sockets, [:set, :public,  {:write_concurrency, :auto}, {:read_concurrency, true}, {:decentralized_counters, true}])
      prepared = :ets.new(:sql, [:set, :public,  {:write_concurrency, :auto}, {:read_concurrency, true}, {:decentralized_counters, true}])
      queue = :ets.new(:queue, [:set, :public, {:write_concurrency, :auto}, {:read_concurrency, true}, {:decentralized_counters, true}])
      for n <- 1..pool.size, do: :atomics.put(state,n,1)
      for n <- 1..3, do: :atomics.put(metrics,n,0)
      pool = %{pool| name: name, state: state, metrics: metrics, queue: queue, sockets: sockets, prepared: prepared}
      :persistent_term.put(name, {metrics, sockets, state, queue, prepared})
      {SQL.Pool, pool}
    end
    result = {:ok, _sup} = Supervisor.start_link(children, strategy: :one_for_one)
    for {name, opts} <- pools do
      mod = Module.concat(opts[:adapter], Queries)
      mod.load(name)
    end
    result
  end

  def stop(_state) do
    :dets.sync(:sql)
    :dets.close(:sql)
  end
end
