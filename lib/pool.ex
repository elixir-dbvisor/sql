# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Pool do
  @moduledoc false
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, initialize(state)}
  end

  def checkout(%{id: _id}=sql, pool \\ :default) do
    # start_time = System.monotonic_time()
    scheduler_id = :erlang.system_info(:scheduler_id)
    state = :persistent_term.get({__MODULE__, pool})
    {_size, connections, activations, recent_activations, sockets, schedulers, _indexes, _health} = state
    {n, workers} = Map.get(schedulers, scheduler_id)
    case checkout(state, n, workers) do
      :none=error ->
        # :telemetry.execute([:sql, :checkout], %{pool: pool, duration: System.monotonic_time()-start_time}, %{id: id})
        error
      {idx, _load} ->
        case :atomics.compare_exchange(connections, idx, 0, 1) do
          :ok ->
            :counters.add(activations, idx, 1)
            :counters.add(recent_activations, idx, 1)
            result = {idx, elem(sockets, idx-1)}
            # :telemetry.execute([:sql, :checkout], %{pool: pool, duration: System.monotonic_time()-start_time}, %{id: id})
            result
          _ ->
            checkout(sql, pool)
        end
    end
  end

  defp checkout(_state, _n, []), do: :none
  defp checkout({size, _connections, activations, recent_activations, _sockets, _schedulers, indexes, health}=state, n, workers) do
    # Power-of-three-choices with load weighting
    workers
    |> Enum.take_random(min(3, n))
    |> Enum.map(fn id ->
      active = :counters.get(activations, id)
      recent = :counters.get(recent_activations, id)
      health = :atomics.get(health, id)
      {id, active + recent / 1000, health} # Weight recent activations
    end)
    |> Enum.filter(fn {_, _, health} -> health == 1 end)
    |> Enum.min_by(fn {_, load, _} -> load end, fn -> nil end)
    |> case do
      {id, load, _} -> {id, trunc(load)}
      _ -> checkout(state, size-n, indexes--workers)
    end
  end

  def checkin(idx, pool) do
    {_size, connections, activations, recent_activations, _sockets, _schedulers, _indexes, _health} = :persistent_term.get({__MODULE__, pool})
    :ok = :atomics.put(connections, idx, 0)
    :ok = :counters.sub(activations, idx, 1)
    :ok = :counters.sub(recent_activations, idx, 1)
  end

  defp initialize(state) do
    pool = build_pool(state)
    :persistent_term.put({__MODULE__, state.name}, pool)
    Map.put(state, :pool, pool)
  end

  defp build_pool(state) do
    schedulers = :erlang.system_info(:schedulers_online)
    size = state.size
    connections = :atomics.new(size, signed: false)
    health = :atomics.new(size, signed: false)
    indexes = Enum.to_list(1..size)
    schedulers = indexes
    |> Enum.reduce(%{}, fn id, acc ->
      Map.update(acc, rem(id, schedulers)+1, [id], &([id | &1]))
    end)
    |> Map.new(fn {k, v} -> {k, {length(v), v}} end)
    {size, connections, :counters.new(size, [:write_concurrency]), :counters.new(size, [:write_concurrency]), init_sockets(size, connections, health, state.protocol), schedulers, indexes, health}
  end

  defp init_sockets(size, connections, health, _protocol) do
    # queries = :persistent_term.get({__MODULE__, :queries})
    for idx <- 1..size do
      :atomics.put(connections, idx, 0)
      :atomics.put(health, idx, 1)
      # :socket.open(:inet, :stream, protocol)
      self()
    end
    |> List.to_tuple()
  end
end
