import SQL
import Ecto.Query
defmodule SQL.Repo do
  use Ecto.Repo, otp_app: :sql, adapter: Ecto.Adapters.Postgres
  use SQL, adapter: SQL.Adapters.Postgres, repo: __MODULE__

  def test() do
    ~SQL[select 1]
    |> SQL.map(fn row -> row end)
    |> Enum.to_list
  end
end
Application.put_env(:sql, :ecto_repos, [SQL.Repo])
Application.put_env(:sql, SQL.Repo, username: "postgres", password: "postgres", hostname: "localhost", database: "sql_test#{System.get_env("MIX_TEST_PARTITION")}", pool: Ecto.Adapters.SQL.Sandbox, pool_size: 10)
SQL.Repo.__adapter__().storage_up(SQL.Repo.config())
SQL.Repo.start_link()
sql = ~SQL[with recursive temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)]
query = "temp" |> recursive_ctes(true) |> with_cte("temp", as: ^union_all(select("temp", [t], %{n: 0, fact: 1}), ^where(select("temp", [t], [t.n+1, t.n+1*t.fact]), [t], t.n < 9))) |> select([t], [t.n])
result = Tuple.to_list(SQL.Lexer.lex("with recursive temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)"))
tokens = Enum.at(result, -1)
context = Map.merge(Enum.at(result, 1), %{sql_lock: nil, module: SQL.Adapters.ANSI})
{:ok, pcontext, ptokens} = SQL.Parser.parse(tokens, context)
Benchee.run(
  %{
  # "lists.duplicate" => fn _ -> :lists.duplicate(10, ?\s) end,
  # "binary.copy" => fn _ -> :binary.copy(" ", 10) end,
  # "comptime to_string" => fn _ -> to_string(sql) end,
  # "comptime to_sql" => fn _ -> SQL.to_sql(sql) end,
  # "comptime inspect" => fn _ -> inspect(sql) end,
  # "comptime ecto" => fn _ -> SQL.Repo.to_sql(:all, query) end,
  "lex" => fn _ -> SQL.Lexer.lex("with recursive temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)") end,
  "parse" => fn _ -> SQL.Parser.parse(tokens, context) end,
  "iodata" => fn _ -> pcontext.module.to_iodata(ptokens, pcontext, 0, [])  end,
  "lex+parse+iodata" => fn _ ->
    {:ok, _, tokens} = SQL.Lexer.lex("with recursive temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)")
    {:ok, pcontext, tokens} = SQL.Parser.parse(tokens, context)
    pcontext.module.to_iodata(tokens, pcontext, 0, [])
  end,
  # "runtime dynamic" => fn _ -> ~SQL[from users] |> ~SQL[select *] |> ~SQL[where id = {{1+2*3}}] end,
  # "runtime to_string" => fn _ -> to_string(~SQL[with recursive temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)]) end,
  # "runtime to_sql" => fn _ -> SQL.to_sql(~SQL[with recursive temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)]) end,
  # "runtime inspect" => fn _ -> inspect(~SQL[with recursive temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)]) end,
  # "runtime ecto" => fn _ -> SQL.Repo.to_sql(:all, "temp" |> recursive_ctes(true) |> with_cte("temp", as: ^union_all(select("temp", [t], %{n: 0, fact: 1}), ^where(select("temp", [t], [t.n+1, t.n+1*t.fact]), [t], t.n < 9))) |> select([t], [t.n])) end
  },
  inputs: %{"1..100_000" => Enum.to_list(1..100_000)},
  memory_time: 2,
  reduction_time: 2,
  unit_scaling: :smallest,
  measure_function_call_overhead: true,
  profile_after: :eprof
)
