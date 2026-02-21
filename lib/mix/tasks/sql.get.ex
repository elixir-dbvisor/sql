# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule Mix.Tasks.Sql.Get do
  use Mix.Task
  import SQL
  import Mix.Generator
  @moduledoc since: "0.3.0"

  @shortdoc "Generates a sql.lock"
  def run(args) do
    app = Mix.Project.config()[:app]
    Application.load(app)
    Mix.Task.run("app.config", args)
    Application.ensure_all_started(:sql, :permanent)
    create_file("sql.lock", gen_template(app), force: true)
  end

  def gen_template(app \\ :sql) do
    lock_template(lock: Enum.reduce(Application.get_env(app, :pools), [], &(get(&1)++&2)))
  end

  def get({name, %{adapter: SQL.Adapters.Postgres}}) do
    ~SQL"""
    select
        table_schema::text,
        table_name::text,
        column_name::text,
        data_type::text,
        is_nullable = 'YES',
        COALESCE(character_maximum_length, 0)::int4,
        COALESCE(numeric_precision, 0)::int4,
        COALESCE(numeric_scale, 0)::int4,
        COALESCE(datetime_precision, 0)::int4,
        udt_name::text,
        is_identity = 'YES',
        ordinal_position::int4
    from information_schema.columns
    order by table_schema, table_name, ordinal_position
    """
    |> SQL.map(fn row -> Map.new(row) end)
    |> Map.put(:pool, name)
    |> Enum.to_list()
  end

  def columns({name, %{adapter: SQL.Adapters.Postgres}}) do
    ~SQL"""
    SELECT
        table_catalog::text,
        table_schema::text,
        table_name::text,
        ARRAY_AGG(column_name::text ORDER BY ordinal_position) AS columns,
        HSTORE(ARRAY_AGG(column_name::text ORDER BY ordinal_position), ARRAY_AGG(data_type::text ORDER BY ordinal_position)) AS table_info
    FROM
        information_schema.columns
    GROUP BY
        table_catalog,
        table_schema,
        table_name
    """
    |> SQL.map(fn row -> Map.new(row) end)
    |> Map.put(:pool, name)
    |> Enum.to_list()
  end

  def enums({name, %{adapter: SQL.Adapters.Postgres}}) do
    ~SQL"""
    SELECT
        n.nspname::text,
        t.typname::text,
        ARRAY_AGG(e.enumlabel::text ORDER BY e.enumsortorder) AS values
    FROM
        pg_type t
    JOIN
        pg_enum e ON t.oid = e.enumtypid
    JOIN
        pg_namespace n ON n.oid = t.typnamespace
    WHERE
        t.typtype = 'e'
    GROUP BY
        n.nspname,
        t.typname
    ORDER BY
        n.nspname,
        t.typname
    """
    |> SQL.map(fn row -> Map.new(row) end)
    |> Map.put(:pool, name)
    |> Enum.to_list()
  end

  def oids({name, %{adapter: SQL.Adapters.Postgres}}) do
    ~SQL"""
    SELECT
        base_type.typname::text AS type,
        ARRAY_AGG(derived.oid::int4) AS oids
    FROM
        pg_type base_type
    JOIN
        pg_type derived ON derived.typname = base_type.typname and base_type.typtype != 'e'
    WHERE
        base_type.typtype = 'b'
    GROUP BY
        base_type.typname
    ORDER BY
        base_type.typname
    """
    |> SQL.map(fn
      [{:type, "_" <> type}, {:oids, oids}] -> {{:array, :"#{type}"}, oids}
      [{:type, type}, {:oids, oids}] -> {:"#{type}", oids}
    end)
    |> Map.put(:pool, name)
    |> Enum.to_list()
    |> Map.new()
  end

  def functions({name, %{adapter: SQL.Adapters.Postgres}}) do
    ~SQL"""
    SELECT
        n.nspname::text AS schema,
        p.proname::text AS name,
        pg_get_function_arguments(p.oid)::text AS arguments,
        pg_get_function_result(p.oid)::text AS return_type,
        l.lanname::text AS language
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    JOIN pg_language l ON l.oid = p.prolang
    ORDER BY schema, name
    """
    |> Map.put(:pool, name)
    |> Enum.to_list()
  end


  # ~SQL"select * from information_schema.columns where table_schema not in ('information_schema', 'pg_catalog')"
  # ~SQL"select * from information_schema.columns where table_schema not in ('mysql', 'performance_schema', 'sys')"
  # ~SQL"select * from sqlite_master join pragma_table_info (sqlite_master.name)"

  embed_template(:lock, """
    %{
      columns: <%= inspect @lock, pretty: true, limit: :infinity %>,
      validate: fn
      <%= for %{table_name: table, column_name: column} <- @lock do %>
        <%= inspect String.to_charlist(table) %>, nil -> true
        <%= inspect String.to_charlist(table) %>, <%= inspect String.to_charlist(column) %> -> true
      <% end %>
      _, _ -> false
      end
    }
  """)
end
