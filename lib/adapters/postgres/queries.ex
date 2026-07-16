# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Adapters.Postgres.Queries do
  @moduledoc false
  use SQL, adapter: SQL.Adapters.Postgres

  @doc false
  def load(pool) do
    SQL.begin(:transaction, pool, SQL.Adapters.Postgres)
    :persistent_term.put({pool, :oids}, oids(pool))
    :persistent_term.put({pool, :columns}, columns(pool))
    SQL.commit(:transaction, pool, SQL.Adapters.Postgres)
  end

  defp columns(pool) do
    # ~SQL"select * from information_schema.columns where table_schema not in ('information_schema', 'pg_catalog')"
    # ~SQL"select * from information_schema.columns where table_schema not in ('mysql', 'performance_schema', 'sys')"
    # ~SQL"select * from sqlite_master join pragma_table_info (sqlite_master.name)"
    ~SQL"""
    SELECT
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
    FROM information_schema.columns
    ORDER BY table_schema, table_name, ordinal_position
    """
    |> SQL.map(&Map.new(&1))
    |> struct(pool: pool)
    |> Enum.to_list()
  end

  defp oids(pool) do
    ~SQL"""
    SELECT base_type.typname::text AS type, ARRAY_AGG(derived.oid::int4) AS oids
    FROM pg_type base_type
    JOIN pg_type derived ON derived.typname = base_type.typname and base_type.typtype != 'e'
    WHERE base_type.typtype = 'b'
    GROUP BY base_type.typname
    ORDER BY base_type.typname
    """
    |> SQL.map(fn
      [type: "_" <> type, oids: oids] -> {{:array, :"#{type}"}, oids}
      [type: type, oids: oids] -> {:"#{type}", oids}
    end)
    |> struct(pool: pool)
    |> Map.new()
  end

  # def columns({name, %{adapter: SQL.Adapters.Postgres = adapter}}) do
  #   sql = SQL.parse("""
  #   SELECT
  #       table_catalog::text,
  #       table_schema::text,
  #       table_name::text,
  #       ARRAY_AGG(column_name::text ORDER BY ordinal_position) AS columns,
  #       HSTORE(ARRAY_AGG(column_name::text ORDER BY ordinal_position), ARRAY_AGG(data_type::text ORDER BY ordinal_position)) AS table_info
  #   FROM
  #       information_schema.columns
  #   GROUP BY
  #       table_catalog,
  #       table_schema,
  #       table_name
  #   """, [], adapter, 0, name, fn row -> Map.new(row) end)

  #   SQL.transaction do
  #     Enum.to_list(sql)
  #   end
  # end


  # def enums({name, %{adapter: SQL.Adapters.Postgres = adapter}}) do
  #   sql = SQL.parse("""
  #   SELECT
  #       n.nspname::text,
  #       t.typname::text,
  #       ARRAY_AGG(e.enumlabel::text ORDER BY e.enumsortorder) AS values
  #   FROM
  #       pg_type t
  #   JOIN
  #       pg_enum e ON t.oid = e.enumtypid
  #   JOIN
  #       pg_namespace n ON n.oid = t.typnamespace
  #   WHERE
  #       t.typtype = 'e'
  #   GROUP BY
  #       n.nspname,
  #       t.typname
  #   ORDER BY
  #       n.nspname,
  #       t.typname
  #   """, [], adapter, 0, name, fn row -> Map.new(row) end)

  #   SQL.transaction do
  #     Enum.to_list(sql)
  #   end
  # end


  # def functions({name, %{adapter: SQL.Adapters.Postgres = adapter}}) do
  #   SQL.transaction do
  #     """
  #     SELECT
  #         n.nspname::text AS schema,
  #         p.proname::text AS name,
  #         pg_get_function_arguments(p.oid)::text AS arguments,
  #         pg_get_function_result(p.oid)::text AS return_type,
  #         l.lanname::text AS language
  #     FROM pg_proc p
  #     JOIN pg_namespace n ON n.oid = p.pronamespace
  #     JOIN pg_language l ON l.oid = p.prolang
  #     ORDER BY schema, name
  #     """
  #     |> SQL.parse([], adapter, 0, name)
  #     |> Enum.to_list()
  #   end
  # end

  @doc false
  def count_database(%{name: pool, database: database}) do
    SQL.transaction do
      ~SQL"""
      SELECT count(*)::int4
      FROM pg_database
      WHERE datname::text = {{database}}
      """
      |> struct(pool: pool)
      |> Enum.at(0)
    end
  end

  @doc false
  def drop_database(%{name: pool, database: database}) do
    "drop database #{database}"
    |> SQL.parse([], SQL.Adapters.Postgres, 0, pool)
    |> Enum.to_list()
  end

  @doc false
  def create_database(%{name: pool, database: database}=state) do
    ~w[encoding template lc_ctype lc_collate lc_time timezone]a
    |> Enum.reduce("create database #{database}", fn key, acc ->
      right = Map.get(state, key)
      left = String.upcase("#{key}")
      case is_binary(right) do
        false -> acc
        true when key == :template -> <<acc::binary, ?\s, left::binary, ?=, right::binary>>
        true when key == :timezone -> <<acc::binary, ?\s, left::binary, right::binary>>
        true -> <<acc::binary, ?\s, left::binary, ?=, ?', right::binary, ?'>>
      end
    end)
    |> SQL.parse([], SQL.Adapters.Postgres, 0, pool)
    |> Enum.to_list()
  end

  def maintiance(:drop, name, config), do: maintiance(name, config)
  def maintiance(:create, name, config), do: Map.put_new(maintiance(name, config), :encoding, "UTF8")

  defp maintiance(name, config) do
    opts = [signed: true]
    state = :atomics.new(1, opts)
    metrics = :atomics.new(3, opts)
    for n <- 1..1, do: :atomics.put(state,n,1)
    for n <- 1..3, do: :atomics.put(metrics,n,0)
    opts = [:set, :public,  {:write_concurrency, :auto}, {:read_concurrency, true}, {:decentralized_counters, true}]
    sockets = :ets.new(:sockets, opts)
    queue = :ets.new(:queue, opts)
    prepared = :ets.new(:queue, opts)
    :persistent_term.put(name, {metrics, sockets, state, queue, prepared})
    Map.merge(struct(SQL.Pool, [{:name, name}|config]), %{size: 1, state: state, queue: queue, metrics: metrics, handle: make_ref(), sockets: sockets, scheduler_id: 1, database: "postgres"})
  end
end
