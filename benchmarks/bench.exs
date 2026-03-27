# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

import SQL
# import Ecto.Query
defmodule SQL.Repo do
  use Ecto.Repo, otp_app: :sql, adapter: Ecto.Adapters.Postgres
  use SQL, adapter: SQL.Adapters.Postgres
  import Ecto.Query
  def sql(type \\ :transaction)
  def sql(:sum) do
    Enum.to_list(~SQL"SELECT sum(x)::int8 FROM generate_series(1, 1000000) AS x")
  end
  # def sql(:mix) do
  #   Enum.to_list(~SQL[SELECT {{1337}}::int as int, {{"wat"}}::varchar as string, {{DateTime.utc_now()}}::timestamp as timestamp, {{nil}}::int as null, {{false}}::boolean as boolean, {{<<"awesome">>}}::bytea as bytea, {{%{"some" => "json"}}}::json as json])
  # end
  def sql(:statement) do
    Enum.to_list(~SQL"SELECT 1")
  end
  def sql(:empty) do
    SQL.transaction do
      :ok
    end
  end
  def sql(:transaction) do
    SQL.transaction do
      Enum.to_list(~SQL"SELECT 1")
    end
  end
  def sql(:savepoint) do
    SQL.transaction do
      SQL.transaction do
        Enum.to_list(~SQL"SELECT 1")
      end
    end
  end
  def sql(:cursor) do
    SQL.transaction do
      ~SQL"SELECT g, repeat(md5(g::text), 4) FROM generate_series(1, 5000000) AS g"
      |> SQL.stream(max_rows: 500)
      |> Stream.run()
    end
  end

  def ecto(type \\ :transaction)
  def ecto(:sum) do
      SQL.Repo.query("SELECT sum(x)::int8 FROM generate_series(1, 1000000) AS x", [])
  end

  def ecto(:mix) do
    SQL.Repo.query("select $1::int as int, $2::varchar as string, $3:timestamp as timestamp, $4::int as null, $5::boolean as boolean, $6::bytea as bytea, $7::json as json", [1337, "wat", DateTime.utc_now(), nil, false, "awesome", %{"some" => "json"}])
  end

  def ecto(:statement) do
    SQL.Repo.all(select(from("users"), [1]))
  end
  def ecto(:empty) do
    SQL.Repo.transaction(fn ->
      :ok
    end)
  end
  def ecto(:transaction) do
    SQL.Repo.transaction(fn ->
      SQL.Repo.all(select(from("users"), [1]))
    end)
  end
  def ecto(:savepoint) do
    SQL.Repo.transaction(fn ->
      SQL.Repo.transaction(fn ->
        SQL.Repo.all(select(from("users"), [1]))
      end)
    end)
  end
  def ecto(:cursor) do
    SQL.Repo.transaction(fn ->
      from(row in fragment("SELECT g, repeat(md5(g::text), 4) FROM generate_series(1, ?) AS g", 5000000), select: [fragment("?::int", row.g), fragment("?::text", row.repeat)])
      |> SQL.Repo.stream()
      |> Stream.run()
    end)
  end
end
Application.put_env(:sql, :ecto_repos, [SQL.Repo])
Application.put_env(:sql, SQL.Repo, log: false, username: "postgres", password: "postgres", hostname: "localhost", database: "sql_test#{System.get_env("MIX_TEST_PARTITION")}", pool_size: :erlang.system_info(:schedulers_online), ssl: false)
SQL.Repo.__adapter__().storage_up(SQL.Repo.config())
SQL.Repo.start_link()
# query = "temp" |> recursive_ctes(true) |> with_cte("temp", as: ^union_all(select("temp", [t], %{n: 0, fact: 1}), ^where(select("temp", [t], [t.n+1, t.n+1*t.fact]), [t], t.n < 9))) |> select([t], [t.n])
# sql = ~SQL[with recursive temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)]
# result = Tuple.to_list(SQL.Lexer.lex("with recursive temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)"))
# tokens = Enum.at(result, -1)
# context = Map.merge(Enum.at(result, 1), %{sql_lock: nil, module: SQL.Adapters.ANSI})
# {:ok, pcontext, ptokens} = SQL.Parser.parse(tokens, context)

Benchee.run(
  %{
  # "comptime to_string" => fn -> to_string(sql) end,
  # "comptime to_sql" => fn -> SQL.to_sql(sql) end,
  # "comptime inspect" => fn -> inspect(sql) end,
  # "lex" => fn -> SQL.Lexer.lex("with recursive temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)") end,
  # "parse" => fn -> SQL.Parser.parse(tokens, context) end,
  # "iodata" => fn -> pcontext.module.to_iodata(ptokens, pcontext)  end,
  # "format" => fn -> SQL.Format.to_iodata(ptokens, pcontext, 0, false)  end,
  # "lex+parse+iodata" => fn ->
  #   {:ok, _, tokens} = SQL.Lexer.lex("with recursive temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)")
  #   {:ok, pcontext, tokens} = SQL.Parser.parse(tokens, context)
  #   pcontext.module.to_iodata(tokens, pcontext)
  # end,
  # "parse/3" => fn -> SQL.parse("with recursive temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)") end,
  # "sql" => fn -> SQL.Repo.sql(Enum.random([:statement, :transaction])) end,
  # "ecto" => fn -> SQL.Repo.ecto(Enum.random([:statement, :transaction])) end,
  # "sql" => fn -> SQL.Repo.sql(:statement) end,
  # "ecto" => fn -> SQL.Repo.ecto(:statement) end,
  "sql" => fn -> SQL.Repo.sql(:transaction) end,
  "ecto" => fn -> SQL.Repo.ecto(:transaction) end,
  # "sql" => fn -> SQL.Repo.sql(:savepoint) end,
  # "ecto" => fn -> SQL.Repo.ecto(:savepoint) end,
  # "sql" => fn -> SQL.Repo.sql(:cursor) end,
  # "ecto" => fn -> SQL.Repo.ecto(:cursor) end,
  # "sql" => fn -> SQL.Repo.sql(:empty) end,
  # "ecto" => fn -> SQL.Repo.ecto(:empty) end,
  # "sql" => fn -> SQL.Repo.sql(:sum) end,
  # "ecto" => fn -> SQL.Repo.ecto(:sum) end,
  # "sql" => fn -> SQL.Repo.sql(:mix) end,
  # "ecto" => fn -> SQL.Repo.ecto(:mix) end,
  # "runtime to_string" => fn -> to_string(~SQL[with recursive temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)]) end,
  # "runtime to_sql" => fn -> SQL.to_sql(~SQL[with recursive temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)]) end,
  # "runtime inspect" => fn -> inspect(~SQL[with recursive temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)]) end,
  # "runtime ecto" => fn -> SQL.Repo.to_sql(:all, "temp" |> recursive_ctes(true) |> with_cte("temp", as: ^union_all(select("temp", [t], %{n: 0, fact: 1}), ^where(select("temp", [t], [t.n+1, t.n+1*t.fact]), [t], t.n < 9))) |> select([t], [t.n])) end,
  # "comptime ecto" => fn -> SQL.Repo.to_sql(:all, query) end
  },
  parallel: 500,
  warmup: 10,
  memory_time: 2,
  reduction_time: 2,
  unit_scaling: :smallest,
  measure_function_call_overhead: true
  # profile_after: :tprof
  # profile_after: :eprof
  # profile_after: :cprof
  # profile_after: :fprof
)
