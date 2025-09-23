# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule Mix.Tasks.Sql.Get do
  use Mix.Task
  import SQL
  import Mix.Generator
  @moduledoc since: "0.3.0"

  defguard is_postgres(value) when value in [Ecto.Adapters.Postgres, Postgrex]
  defguard is_mysql(value) when value in [Ecto.Adapters.MyXQL, MyXQL]
  defguard is_tds(value) when value in [Ecto.Adapters.Tds, Tds]
  defguard is_sqlite(value) when value in [Ecto.Adapters.SQLite3, Exqlite]

  @shortdoc "Generates a sql.lock"
  def run(args) do
    app = Mix.Project.config()[:app]
    Application.load(app)
    repos = Application.get_env(app, :ecto_repos)
    Mix.Task.run("app.config", args)
    Application.ensure_all_started(:ecto_sql, :permanent)
    lock = Enum.reduce(repos, %{}, fn repo, acc ->
      repo.__adapter__().ensure_all_started(repo.config(), [])
      repo.start_link(repo.config())
      Map.merge(acc, to_lock(repo, repo.__adapter__()), fn _, l, r -> Enum.uniq(:lists.flatten(l, r)) end)
    end)
    create_file("sql.lock", lock_template(lock: lock), force: true)
  end

  def get(repo, sql) do
    {:ok, %{columns: columns, rows: rows}} = repo.query(to_string(sql), [])
    columns = Enum.map(columns, &String.to_atom(String.downcase(&1)))
    Enum.map(rows, &Map.new(Enum.zip(columns, &1)))
  end

  embed_template(:lock, """
  <%= inspect @lock, pretty: true, limit: :infinity %>
  """)

  def to_lock(repo, value) when not is_sqlite(value) do
    %{columns: get(repo, to_query(value, :columns)), tables: get(repo, to_query(value, :tables))}
  end
  def to_lock(repo, value) when is_sqlite(value) do
    tables = get(repo, to_query(value, :tables))
    %{columns: tables, tables: tables}
  end

  def to_query(value, :tables) when is_postgres(value), do: ~SQL"select * from information_schema.tables where table_schema not in ('information_schema', 'pg_catalog')"
  def to_query(value, :columns) when is_postgres(value), do: ~SQL"select * from information_schema.columns where table_schema not in ('information_schema', 'pg_catalog')"
  def to_query(value, :tables) when is_tds(value), do: ~SQL"select * from information_schema.tables where table_schema not in ('information_schema', 'pg_catalog')"
  def to_query(value, :columns) when is_tds(value), do: ~SQL"select * from information_schema.columns where table_schema not in ('information_schema', 'pg_catalog')"
  def to_query(value, :tables) when is_mysql(value), do: ~SQL"select * from information_schema.tables where table_schema not in ('mysql', 'performance_schema', 'sys')"
  def to_query(value, :columns) when is_mysql(value), do: ~SQL"select * from information_schema.columns where table_schema not in ('mysql', 'performance_schema', 'sys')"
  def to_query(value, :tables) when is_sqlite(value), do: ~SQL"select * from sqlite_master join pragma_table_info (sqlite_master.name)"
end
