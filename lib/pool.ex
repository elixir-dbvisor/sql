# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Pool do
  @moduledoc false
  use GenServer

  @conn_idle 0
  @conn_in_use 1
  # @conn_closed 2
  @conn_dead 3
  @pool_size 1
  @min_size 10
  @scale_buffer 1.2
  @max_size 2
  @current_in_use 3
  @total_requests 4
  @total_lease_time 5
  @active_connections 6 #(idle + in_use)
  @dead_connections 7
  @idle_connections 8
  # @scheduler_yield_count 9
  # @slots_per_sched 11
  @lambda_alpha 0.5
  @w_alpha 0.5
  @hysteresis 2
  @max_step_fraction 0.5
  @min_idle_buffer 2
  @idle_timeout System.convert_time_unit(5_000, :millisecond, :native)
  @free_list_pop_attempts 14
  @free_list_pop_retries 15
  @free_list_push_attempts 16
  @free_list_push_retries 17
  @rotation_claim_attempts 18
  @rotation_claim_retries 19
  @scale_up_ops 20
  @scale_down_ops 21
  @cache_hits 22
  @cache_misses 23
  @rotation_retries 24
  @checkout_latency_ns 25


  def start_link(opts) do
    GenServer.start_link(__MODULE__, Map.merge(%{size: 10, max_size: 64}, opts), name: __MODULE__)
  end

  defp schedule_calculation() do
    Process.send_after(self(), :calculate, 1000)
  end

  @impl true
  def init(state) do
    state = initialize(state)
    schedule_calculation()
    {:ok, state}
  end

  @impl true
  def handle_info({:DOWN, ref, :socket, _socket, _reason}, %{protocol: protocol, pool: {pool_metrics, scheduler_cache, connections, sockets, free_list, free_top, rotation, size, sched_count, slots_per_sched}}=state) do
    idx = Process.get(ref)
    :atomics.add(connections, idx, @conn_dead)
    :counters.sub(pool_metrics, @active_connections, 1)
    :counters.add(pool_metrics, @dead_connections, 1)
    sockets = :erlang.setelement(idx, sockets, init_socket(idx, connections, protocol))
    pool = {pool_metrics, scheduler_cache, connections, sockets, free_list, free_top, rotation, size, sched_count, slots_per_sched}
    :persistent_term.put({__MODULE__, state.name}, pool)
    Process.delete(ref)
    {:noreply, %{state | pool: pool}}
  end
  def handle_info(:calculate, %{protocol: protocol, pool: pool, last_lambda: last_lambda, last_w: last_w, last_resize_ts: last_resize_ts} = state) do
    {pool_metrics, _scheduler_cache, _connections, _sockets, _free_list, _free_top, _rotation, size, _sched_count, _slots_per_sched} = pool

    total_requests = :counters.get(pool_metrics, @total_requests)
    total_lease_time = :counters.get(pool_metrics, @total_lease_time)
    active_connections = :counters.get(pool_metrics, @active_connections)

    now = System.monotonic_time()
    elapsed_s = System.convert_time_unit(now - last_resize_ts, :native, :second)
    elapsed_s = if elapsed_s > 0, do: elapsed_s, else: 1.0

    raw_lambda = total_requests / elapsed_s
    raw_w = if active_connections > 0, do: System.convert_time_unit(total_lease_time, :native, :second) / active_connections, else: 0.0

    lambda_smoothed = @lambda_alpha * raw_lambda + (1 - @lambda_alpha) * (last_lambda || 0.0)
    w_smoothed = @w_alpha * raw_w + (1 - @w_alpha) * (last_w || 0.0)

    :counters.put(pool_metrics, @total_requests, 0)
    :counters.put(pool_metrics, @total_lease_time, 0)

    raw_desired = lambda_smoothed * w_smoothed * @scale_buffer
    max_size = :counters.get(pool_metrics, @max_size)
    desired = raw_desired |> Float.ceil() |> trunc() |> max(@min_size) |> min(max_size)

    diff = desired - size
    max_step = max(1, trunc(size * @max_step_fraction))

    desired_clamped =
      cond do
        diff > 0 -> size + min(diff, max_step)
        diff < 0 -> size - min(-diff, max_step)
        true -> size
      end

    final_desired = if abs(desired_clamped - size) < @hysteresis, do: size, else: desired_clamped

    pool =
      cond do
        final_desired > size ->
          :counters.add(pool_metrics, @scale_up_ops, 1)
          scale_up(pool, final_desired - size, final_desired, protocol)
        final_desired < size ->
          :counters.add(pool_metrics, @scale_down_ops, 1)
          scale_down(pool, size - final_desired, final_desired)
        true -> pool
      end

    :persistent_term.put({__MODULE__, state.name}, pool)

    schedule_calculation()

    {:noreply, %{state | pool: pool, last_lambda: lambda_smoothed, last_w: w_smoothed, last_resize_ts: now}}
  end

  defp scale_up({pool_metrics, scheduler_cache, connections, sockets, free_list, free_top, rotation, _size, sched_count, slots_per_sched}, count, new_size, protocol) do
    sockets =
      1..:counters.get(pool_metrics, @max_size)
      |> Enum.filter(fn idx -> :atomics.get(connections, 5*idx-4) == @conn_dead end)
      |> Enum.take(count)
      |> Enum.reduce(sockets, fn idx, sockets ->
          {:ok, socket} = :socket.open(:inet, :stream, protocol)
          Process.put(:socket.monitor(socket), idx)
          :erlang.setelement(idx, sockets, socket)
          :atomics.put(connections, 5*idx-4, @conn_idle)
          :atomics.put(connections, 5*idx-2, System.monotonic_time())
          push_free_list(pool_metrics, free_list, free_top, new_size, idx)
          sockets
      end)
    :counters.put(pool_metrics, @pool_size, new_size)
    :counters.add(pool_metrics, @idle_connections, count)
    {pool_metrics, scheduler_cache, connections, sockets, free_list, free_top, rotation, new_size, sched_count, slots_per_sched}
  end

  defp scale_down({pool_metrics, scheduler_cache, connections, sockets, free_list, free_top, rotation, size, sched_count, slots_per_sched}, count, new_size) do
    idle_connections = :counters.get(pool_metrics, @idle_connections)-1
    {sockets, closed} =
      1..min(size, tuple_size(sockets))
      |> Enum.filter(fn idx ->
        status = :atomics.get(connections, 5*idx-4)
        idle_for = System.monotonic_time()-:atomics.get(connections, 5*idx-2)
        status == @conn_idle and idle_for > @idle_timeout and idle_connections >= @min_idle_buffer
      end)
      |> Enum.take(count)
      |> Enum.reduce({sockets, 0}, fn idx, {sockets, closed} ->
        :atomics.put(connections, 5*idx-4, @conn_dead)
        :socket.close(elem(sockets, idx-1))
        remove_from_free_list(free_list, free_top, idx)
        {:erlang.setelement(idx, sockets, nil), closed+1}
      end)
    :counters.put(pool_metrics, @pool_size, new_size)
    :counters.sub(pool_metrics, @idle_connections, closed)
    {pool_metrics, scheduler_cache, connections, sockets, free_list, free_top, rotation, new_size, sched_count, slots_per_sched}
  end

  def checkout(_sql, pool) do
    key = {__MODULE__, pool}
    scheduler_id = :erlang.system_info(:scheduler_id)
    case Process.get(key) do
      nil ->
        state = :persistent_term.get(key)
        Process.put(key, state)
        do_checkout(state, scheduler_id)
      state -> do_checkout(state, scheduler_id)
    end
  end

  def checkin(idx, pool) do
    key = {__MODULE__, pool}
    {pool_metrics, _scheduler_cache, connections, sockets, free_list, free_top, _rotation, size, _sched_count, _slots_per_sched} = Process.get(key) || :persistent_term.get(key)
    socket = elem(sockets, idx - 1)
    :socket.setopt(socket, :otp, :owner, GenServer.whereis(__MODULE__))
    mark_idle(pool_metrics, connections, idx)
    push_free_list(pool_metrics, free_list, free_top, size, idx)
  end

  defp do_checkout({pool_metrics, scheduler_cache, connections, sockets, free_list, free_top, rotation, size, _sched_count, slots_per_sched}=pool, scheduler_id) do
    start = System.monotonic_time()
    cache = elem(scheduler_cache, scheduler_id - 1)
    idx = do_checkout(pool_metrics, connections, cache, size, free_list, free_top, rotation, scheduler_id, slots_per_sched)
    case elem(sockets, idx - 1) do
      nil ->
        :erlang.yield()
        do_checkout(pool, scheduler_id)
      socket ->
        mark_in_use(pool_metrics, connections, idx)
        :socket.setopt(socket, :otp, :owner, self())
        elapsed = System.monotonic_time() - start
        :counters.add(pool_metrics, @checkout_latency_ns, elapsed)
        {idx, socket}
    end
  end

  defp do_checkout(pool_metrics, connections, cache, pool_size, free_list, free_top, rotation, sched_id, slots_per_sched) do
    case try_local_cache(pool_metrics, 1, slots_per_sched, cache, connections) do
      :ok ->
        rot = elem(rotation, sched_id - 1)
        start_idx = (sched_id - 1) * slots_per_sched + 1
        end_idx = min(start_idx + slots_per_sched - 1, pool_size)
        range_size = max(end_idx - start_idx + 1, 1)
        max_attempts = max(8, range_size)
        try_rotation_claim(rot, pool_metrics, connections, start_idx, range_size, max_attempts, pool_size, free_list, free_top)
      idx -> idx
    end
  end

  defp try_rotation_claim(rot, pool_metrics, connections, start_idx, range_size, 0, pool_size, free_list, free_top) do
    case pop_free_list(pool_metrics, free_list, free_top) do
      0 ->
        :counters.add(pool_metrics, @rotation_retries, 1)
        :erlang.yield()
        try_rotation_claim(rot, pool_metrics, connections, start_idx, range_size, max(8, range_size), pool_size, free_list, free_top)
      idx -> idx
    end
  end
  defp try_rotation_claim(rotation_atom, pool_metrics, connections, start_idx, range_size, attempts_left, pool_size, free_list, free_top) do
    new = :atomics.add_get(rotation_atom, 1, 1)
    offset = rem(new-1, range_size)
    idx = start_idx + offset
    status_pos = 5*idx-4
    :counters.add(pool_metrics, @rotation_claim_attempts, 1)
    case :atomics.compare_exchange(connections, status_pos, @conn_idle, @conn_in_use) do
      :ok -> idx
      _ ->
        :counters.add(pool_metrics, @rotation_claim_retries, 1)
        try_rotation_claim(rotation_atom, pool_metrics, connections, start_idx, range_size, attempts_left - 1, pool_size, free_list, free_top)
    end
  end

  defp try_local_cache(pool_metrics, slot, slot, cache, connections) do
    idx = :atomics.get(cache, slot)
    case :atomics.compare_exchange(connections, idx, @conn_idle, @conn_in_use) do
      :ok ->
        :counters.add(pool_metrics, @cache_hits, 1)
        idx
      _ ->
        :counters.add(pool_metrics, @cache_misses, 1)
    end
  end
  defp try_local_cache(pool_metrics, slot, size, cache, connections) do
    idx = :atomics.get(cache, slot)
    case :atomics.compare_exchange(connections, idx, @conn_idle, @conn_in_use) do
      :ok ->
        :counters.add(pool_metrics, @cache_hits, 1)
        idx
      _ ->
        try_local_cache(pool_metrics, slot+1, size, cache, connections)
    end
  end

  defp pop_free_list(pool_metrics, free_list, free_top) do
    case :atomics.get(free_top, 1) do
      0=top -> top
      top ->
      :counters.add(pool_metrics, @free_list_pop_attempts, 1)
      case :atomics.compare_exchange(free_top, 1, top, top - 1) do
        :ok -> :atomics.get(free_list, top)
        _ ->
          :counters.add(pool_metrics, @free_list_pop_retries, 1)
          :erlang.yield()
          pop_free_list(pool_metrics, free_list, free_top)
      end
    end
  end

  defp push_free_list(pool_metrics, free_list, free_top, capacity, idx) do
    top = :atomics.get(free_top, 1)
    case top < capacity do
      true ->
        :counters.add(pool_metrics, @free_list_push_attempts, 1)
        case :atomics.compare_exchange(free_top, 1, top, top + 1) do
          :ok -> :atomics.put(free_list, top + 1, idx)
          _ ->
            :counters.add(pool_metrics, @free_list_push_retries, 1)
            push_free_list(pool_metrics, free_list, free_top, capacity, idx)
        end
      false -> :ok
    end
  end

  defp remove_from_free_list(free_list, free_top, idx) do
    top = :atomics.get(free_top, 1)
    for i <- 1..top, do: :atomics.compare_exchange(free_list, i, idx, 0)
  end

  defp mark_in_use(pool_metrics, connections, idx) do
    :atomics.put(connections, 5 * idx - 4, @conn_in_use)
    now = System.monotonic_time()
    :atomics.put(connections, 5 * idx - 3, now)
    :counters.add(pool_metrics, @current_in_use, 1)
    :counters.add(pool_metrics, @active_connections, 1)
    :counters.sub(pool_metrics, @idle_connections, 1)
    :counters.add(pool_metrics, @total_requests, 1)
  end

  defp mark_idle(pool_metrics, connections, idx) do
    :atomics.put(connections, 5 * idx - 4, @conn_idle)
    now = System.monotonic_time()
    elapsed = now - :atomics.get(connections, 5 * idx - 3)
    :atomics.put(connections, 5 * idx - 2, now)
    :counters.sub(pool_metrics, @current_in_use, 1)
    :counters.sub(pool_metrics, @active_connections, 1)
    :counters.add(pool_metrics, @idle_connections, 1)
    :counters.add(pool_metrics, @total_lease_time, elapsed)
  end

  defp initialize(state) do
    pool = build_pool(state)
    :persistent_term.put({__MODULE__, state.name}, pool)
    Map.merge(state, %{last_lambda: 0.0, last_w: 0.0, last_resize_ts: System.monotonic_time(), pool: pool})
  end

  defp build_pool(state) do
    sched_count = :erlang.system_info(:schedulers_online)
    size = state.size
    max_size = max(size * 5, state.max_size)
    slots_per_sched = div(size + sched_count - 1, sched_count)
    slots_per_sched = max(8, slots_per_sched)
    total_slots = max(size, sched_count * slots_per_sched)
    pool_metrics = :counters.new(25, [:write_concurrency])
    :counters.put(pool_metrics, @pool_size, size)
    :counters.put(pool_metrics, @max_size, max_size)
    :counters.put(pool_metrics, @current_in_use, 0)
    :counters.put(pool_metrics, @total_requests, 0)
    :counters.put(pool_metrics, @total_lease_time, 0)
    :counters.put(pool_metrics, @active_connections, 0)
    :counters.put(pool_metrics, @dead_connections, 0)
    :counters.put(pool_metrics, @idle_connections, size)
    :counters.put(pool_metrics, @scale_up_ops, 0)
    :counters.put(pool_metrics, @scale_down_ops, 0)
    :counters.put(pool_metrics, @free_list_pop_attempts, 0)
    :counters.put(pool_metrics, @free_list_pop_retries, 0)
    :counters.put(pool_metrics, @free_list_push_attempts, 0)
    :counters.put(pool_metrics, @free_list_push_retries, 0)
    :counters.put(pool_metrics, @rotation_claim_attempts, 0)
    :counters.put(pool_metrics, @rotation_claim_retries, 0)
    :counters.put(pool_metrics, @rotation_retries, 0)
    :counters.put(pool_metrics, @checkout_latency_ns, 0)

    connections = :atomics.new(total_slots * 5, signed: true)
    scheduler_cache = scheduler_cache(max_size, sched_count, slots_per_sched)
    sockets = init_sockets(total_slots, size, connections, state.protocol)
    free_list = :atomics.new(max_size, signed: true)
    free_top = :atomics.new(1, signed: true)
    for i <- 1..size, do: :atomics.put(free_list, i, i)
    :atomics.put(free_top, 1, size)
    rotation = List.to_tuple(for _ <- 1..sched_count, do: :atomics.new(1, signed: true))
    {pool_metrics, scheduler_cache, connections, sockets, free_list, free_top, rotation, size, sched_count, slots_per_sched}
  end

  defp scheduler_cache(pool_size, sched_count, slots_per_sched) do
    for _ <- 1..sched_count do
      cache = :atomics.new(slots_per_sched, signed: true)
      indices = Enum.shuffle(1..pool_size) |> Enum.take(slots_per_sched)
      for {idx, slot} <- Enum.with_index(indices), do: :atomics.put(cache, slot + 1, idx)
      cache
    end
    |> List.to_tuple()
  end

  defp init_sockets(max_size, size, connections, protocol) do
    sockets = for idx <- 1..size, do: init_socket(idx, connections, protocol)
    padded = sockets ++ List.duplicate(nil, max_size-size)
    List.to_tuple(padded)
  end

  defp init_socket(idx, connections, protocol) do
    :atomics.put(connections, 5*idx - 4, @conn_idle)
    :atomics.put(connections, 5*idx - 2, System.monotonic_time())
    {:ok, socket} = :socket.open(:inet, :stream, protocol)
    ref = :socket.monitor(socket)
    Process.put(ref, idx)
    socket
  end

  def metrics(pool) do
    key = {__MODULE__, pool}
    {pool_metrics, _scheduler_cache, connections, _sockets, _free_list, free_top, _rotation, size, sched_count, slots_per_sched} =
      :persistent_term.get(key)

    %{
      total_requests: :counters.get(pool_metrics, @total_requests),
      active_connections: :counters.get(pool_metrics, @active_connections),
      current_in_use: :counters.get(pool_metrics, @current_in_use),
      idle_connections: :counters.get(pool_metrics, @idle_connections),
      dead_connections: :counters.get(pool_metrics, @dead_connections),
      scale_up_ops: :counters.get(pool_metrics, @scale_up_ops),
      scale_down_ops: :counters.get(pool_metrics, @scale_down_ops),
      rotation_claim_attempts: :counters.get(pool_metrics, @rotation_claim_attempts),
      rotation_claim_retries: :counters.get(pool_metrics, @rotation_claim_retries),
      rotation_retries: :counters.get(pool_metrics, @rotation_retries),
      checkout_latency_ns: :counters.get(pool_metrics, @checkout_latency_ns),
      free_list_pop_attempts: :counters.get(pool_metrics, @free_list_pop_attempts),
      free_list_pop_retries: :counters.get(pool_metrics, @free_list_pop_retries),
      free_list_push_attempts: :counters.get(pool_metrics, @free_list_push_attempts),
      free_list_push_retries: :counters.get(pool_metrics, @free_list_push_retries),
      cache_hits: :counters.get(pool_metrics, @cache_hits),
      cache_misses: :counters.get(pool_metrics, @cache_misses),
      scheduler_slots: sched_count * slots_per_sched,
      pool_size: size,
      free_list_top: :atomics.get(free_top, 1),
      connections_snapshot: snapshot_connections(connections, size)
    }
  end

  defp snapshot_connections(connections, size) do
    for idx <- 1..size do
      status = :atomics.get(connections, 5*idx - 4)
      last_used = :atomics.get(connections, 5*idx - 2)
      {idx, status, last_used}
    end
  end
end
