# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Repo do
  use Ecto.Repo, otp_app: :sql, adapter: Ecto.Adapters.Postgres

  def sql() do
    {idx, _} = SQL.Pool.checkout(%{}, :mypool)
    Process.sleep(5)
    SQL.Pool.checkin(idx, :mypool)
  end

  def ecto() do
    checkout(fn -> Process.sleep(5) end)
  end
end

Application.put_env(:sql, :ecto_repos, [SQL.Repo])
Application.put_env(:sql, SQL.Repo,
  log: false,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "sql_test#{System.get_env("MIX_TEST_PARTITION")}"
)

SQL.Repo.__adapter__().storage_up(SQL.Repo.config())

defmodule Pool.Benchmark do
  @moduledoc false

  @duration_ms 30_000
  @scale_interval 5_000
  @report_interval 2_000

  @deterministic_delays Enum.map(1..1_000, fn i ->
    trunc(50 + :math.sin(i) * 100 + 100)
  end)

  :ets.new(:latency, [:named_table, :public, {:read_concurrency, true}])

  def run_all(pool_size \\ 10, initial_clients \\ 10, max_clients \\ 50, flat \\ false, mode \\ :deterministic) do
    if mode == :benchee do
      SQL.Repo.start_link(pool_size: pool_size)
      SQL.Pool.start_link(%{name: :mypool, protocol: :tcp, size: pool_size})
      Benchee.run(
        %{
        "sql" => fn -> SQL.Repo.sql() end,
        "ecto" => fn -> SQL.Repo.ecto() end,
        },
        parallel: 100,
        time: 5,
        memory_time: 2,
        reduction_time: 2,
        unit_scaling: :smallest,
        measure_function_call_overhead: true,
        profile_after: :eprof
      )
    else
      IO.puts("Starting side-by-side benchmark: SQL vs Ecto")
      IO.puts("Mode: #{mode}, Pool size: #{pool_size}, Initial clients: #{initial_clients}, Max clients: #{max_clients}, Flat: #{flat}\n")

      results =
        [:sql, :ecto]
        |> Enum.map(fn adapter ->
          {adapter, run_single(adapter, mode, pool_size, initial_clients, max_clients, flat)}
        end)

      print_comparison(results)
    end
  end

  defp run_single(adapter, mode, pool_size, initial_clients, max_clients, flat) do
    if mode == :deterministic, do: :rand.seed(:exsplus, {1234, 5678, 9012})
    :ets.delete_all_objects(:latency)
    {:ok, pid} =
      case adapter do
        :sql ->
          IO.puts("Starting benchmark with SQL pool (mode: #{mode})")
          SQL.Pool.start_link(%{size: pool_size, protocol: :tcp, name: :default})

        :ecto ->
          IO.puts("Starting benchmark with Ecto pool (mode: #{mode})")
          SQL.Repo.start_link(pool_size: pool_size)
      end

    stop_time = System.monotonic_time(:millisecond) + @duration_ms
    counter = :counters.new(1, [:write_concurrency])

    state = %{
      adapter: adapter,
      pool: pid,
      pool_size: pool_size,
      counter: counter,
      stop_time: stop_time,
      flat: flat,
      initial_clients: initial_clients,
      max_clients: max_clients
    }

    start_clients(state, initial_clients, mode, 0)
    spawn(fn -> dynamic_load_loop(state, initial_clients, mode, 0) end)
    spawn(fn -> report_loop(state) end)

    Process.sleep(@duration_ms + 100)

    total = :counters.get(counter, 1)
    avg_qps = total / (@duration_ms / 1000)

    IO.puts("\n=== #{String.upcase(to_string(adapter))} Final Report ===")
    IO.puts("Total requests: #{total}")
    IO.puts("Average QPS: #{Float.round(avg_qps, 1)}\n")

    {total, avg_qps}
  end

  defp start_clients(state, n, mode, start_idx) do
    Enum.each(0..(n - 1), fn i ->
      spawn(fn -> client_loop(state, mode, start_idx + i) end)
    end)
  end

  defp client_loop(%{adapter: adapter, counter: counter, stop_time: stop_time}=state, mode, idx) do
    if System.monotonic_time(:millisecond) < stop_time do
      case adapter do
        :sql ->
          {pool_idx, _socket} = measured_checkout_sql(:default)
          :counters.add(counter, 1, 1)
          sleep_for(mode, idx)
          SQL.Pool.checkin(pool_idx, :default)

        :ecto ->
          measured_checkout_ecto(fn ->
            :counters.add(counter, 1, 1)
            sleep_for(mode, idx)
          end)
      end

      client_loop(state, mode, idx + 1)
    end
  end

  defp sleep_for(:deterministic, _idx), do: Process.sleep(5)
  defp sleep_for(:realistic, idx) do
    delay = Enum.at(@deterministic_delays, rem(idx, length(@deterministic_delays)))
    Process.sleep(delay)
  end

  defp measured_checkout_sql(pool) do
    start = System.monotonic_time(:nanosecond)
    result = SQL.Pool.checkout(%{id: 1}, pool)
    elapsed = System.monotonic_time(:nanosecond) - start
    :ets.insert(:latency, {:latency, elapsed})
    result
  end

  defp measured_checkout_ecto(fun) when is_function(fun, 0) do
    start = System.monotonic_time(:nanosecond)
    result = SQL.Repo.checkout(fun)
    elapsed = System.monotonic_time(:nanosecond) - start
    :ets.insert(:latency, {:latency, elapsed})
    result
  end

  defp dynamic_load_loop(%{flat: true, initial_clients: clients, adapter: adapter} = state, clients, _mode, _iteration) do
    if System.monotonic_time(:millisecond) < state.stop_time do
      IO.puts("[#{String.upcase(to_string(adapter))} Load] Active clients: #{clients} Metrics: #{inspect SQL.Pool.metrics(:default), limit: :infinity}")
      Process.sleep(@scale_interval)
      dynamic_load_loop(state, clients, :deterministic, 0)
    end
  end

  defp dynamic_load_loop(%{initial_clients: initial_clients, max_clients: max_clients, adapter: adapter} = state, clients, mode, iteration) do
    if System.monotonic_time(:millisecond) < state.stop_time do
      next_clients = min(initial_clients + iteration * 10, max_clients)
      actual_pool_size = current_pool_size(state)

      string = "[#{String.upcase(to_string(adapter))} Load] Active clients: #{next_clients}, Pool size: #{actual_pool_size}"
      string = if adapter == :sql, do: string <> " Metrics: #{inspect SQL.Pool.metrics(:default), limit: :infinity}", else: string
      IO.puts(string)

      if trunc(next_clients) > trunc(clients), do: start_clients(state, next_clients - clients, :deterministic, clients)

      Process.sleep(@scale_interval)
      dynamic_load_loop(state, next_clients, mode, iteration + 1)
    end
  end

  defp current_pool_size(%{adapter: :sql}) do
    {_, _, _, _, _, _, _, size, _, _} = :persistent_term.get({SQL.Pool, :default})
    size
  end
  defp current_pool_size(%{pool_size: pool_size}), do: pool_size
  defp current_pool_size(_), do: nil

  defp report_loop(%{adapter: :sql, counter: counter, stop_time: stop_time}=state) do
    prev_count = :counters.get(counter, 1)
    prev_time = System.monotonic_time(:millisecond)
    Process.sleep(@report_interval)

    now_count = :counters.get(counter, 1)
    now_time = System.monotonic_time(:millisecond)
    qps = (now_count - prev_count) / ((now_time - prev_time) / 1000)

    metrics = SQL.Pool.metrics(:default)
    percentiles = compute_percentiles()

    IO.puts("""
    [SQL Stats] QPS: #{Float.round(qps,1)}, Pool: #{metrics.pool_size}, In-use: #{metrics.current_in_use}, Idle: #{metrics.idle_connections}
    Cache H/M: #{metrics.cache_hits}/#{metrics.cache_misses}, Rotation retries: #{metrics.rotation_retries}, Free list top: #{metrics.free_list_top}
    Checkout latency (ns) P50/P90/P95/P99: #{percentiles.p50}/#{percentiles.p90}/#{percentiles.p95}/#{percentiles.p99}
    """)

    if now_time < stop_time, do: report_loop(state)
  end

  defp report_loop(%{counter: counter, stop_time: stop_time}=state) do
    prev = :counters.get(counter, 1)
    prev_time = System.monotonic_time(:millisecond)
    Process.sleep(@report_interval)

    now = :counters.get(counter, 1)
    now_time = System.monotonic_time(:millisecond)
    qps = (now - prev) / ((now_time - prev_time) / 1000)

    IO.puts("[#{String.upcase(to_string(state.adapter))} Stats] Current QPS: #{Float.round(qps, 1)}, Pool size: #{current_pool_size(state)}")

    if now_time < stop_time do
      report_loop(state)
    end
  end

  defp compute_percentiles() do
    latencies = :ets.tab2list(:latency) |> Enum.map(fn {:latency, ns} -> ns end)
    sorted = Enum.sort(latencies)
    count = length(sorted)

    if count == 0 do
      %{p50: 0, p90: 0, p95: 0, p99: 0}
    else
      %{
        p50: Enum.at(sorted, trunc(count * 0.5)),
        p90: Enum.at(sorted, trunc(count * 0.9)),
        p95: Enum.at(sorted, trunc(count * 0.95)),
        p99: Enum.at(sorted, trunc(count * 0.99))
      }
    end
  end

  defp print_comparison(results) do
    [{:sql, {sql_total, sql_qps}}, {:ecto, {ecto_total, ecto_qps}}] = results

    IO.puts("=== Side-by-side Comparison ===")
    IO.puts("SQL  -> Total: #{sql_total}, Avg QPS: #{Float.round(sql_qps, 1)}")
    IO.puts("Ecto -> Total: #{ecto_total}, Avg QPS: #{Float.round(ecto_qps, 1)}\n")
    IO.puts("Speedup: #{Float.round(sql_qps / ecto_qps, 2)}x")
  end
end

[mode_arg, pool_size_arg, flat_arg] =
  case System.argv() do
    [m, size, flat] -> [String.to_atom(m), String.to_integer(size), flat == "true"]
    [m, size] -> [String.to_atom(m), String.to_integer(size), false]
    [m] -> [String.to_atom(m), 10, false]
    _ -> [:deterministic, 10, false]
  end

Pool.Benchmark.run_all(pool_size_arg, 10, 50, flat_arg, mode_arg)
