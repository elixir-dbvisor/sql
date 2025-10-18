import SQL
import Ecto.Query
SQL.Pool.start_link(%{name: :mypool, protocol: :tcp, size: 10})
defmodule SQL.Repo do
  use Ecto.Repo, otp_app: :sql, adapter: Ecto.Adapters.Postgres
  use SQL, adapter: SQL.Adapters.Postgres, repo: __MODULE__

  def sql() do
    {idx, _} = SQL.Pool.checkout(SQL.parse("with recursive temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)"), :mypool)
    SQL.Pool.checkin(idx, :mypool)
  end

  def ecto() do
    checkout(fn -> SQL.parse("with recursive temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)") end)
  end
end
Application.put_env(:sql, :ecto_repos, [SQL.Repo])
Application.put_env(:sql, SQL.Repo, log: false, username: "postgres", password: "postgres", hostname: "localhost", database: "sql_test#{System.get_env("MIX_TEST_PARTITION")}", pool_size: 10)
SQL.Repo.__adapter__().storage_up(SQL.Repo.config())
SQL.Repo.start_link()
Benchee.run(
  %{
  "sql" => fn _ -> SQL.Repo.sql() end,
  "ecto" => fn _ -> SQL.Repo.ecto() end,
  },
  parallel: 50, time: 1,
  inputs: %{"1..100_000" => Enum.to_list(1..100_000)},
  memory_time: 2,
  reduction_time: 2,
  unit_scaling: :smallest,
  measure_function_call_overhead: true,
  profile_after: :eprof
)
