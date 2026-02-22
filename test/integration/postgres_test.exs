# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Integration.Postgres.Types do
  use SQL, adapter: SQL.Adapters.Postgres

  def list do
    # ~SQL"""
    # SELECT oid::int4, typname::text
    # FROM pg_type
    # WHERE typname NOT LIKE '\_%' ESCAPE '\' AND typname NOT LIKE 'pg_%' AND typname NOT LIKE 'txid_%' AND typname NOT IN ('int2vector', 'oidvector', 'jsonpath', 'tsquery', 'ltxtquery') AND typtype='b' AND (typinput <> 0 AND typreceive <> 0)
    # ORDER BY typname
    # """
    # |> Enum.to_list()
    #

    ~SQL"""
    SELECT t.oid::int4,
           t.typname::text AS name,
           n.nspname::text AS schema_name,
           t.typtype::text,
           t.typbasetype::int4,
           t.typelem::int4,
           CASE
             WHEN t.typtype = 'd' THEN bt.typname
             WHEN t.typtype = 'b' AND t.typname LIKE '\_%' ESCAPE '\' THEN et.typname ELSE t.typname
           END::text AS base_type
    FROM pg_type t
    JOIN pg_namespace n ON t.typnamespace = n.oid
    LEFT JOIN pg_type bt ON t.typbasetype = bt.oid
    LEFT JOIN pg_type et ON t.typelem = et.oid
    WHERE t.typtype IN ('b','d','e','c','r')
      AND t.typinput <> 0
      AND t.typreceive <> 0
      AND t.typname NOT LIKE 'pg_%'
      AND t.typname NOT LIKE '\_pg%' ESCAPE '\'
      AND t.typtype != 'e'
      AND t.typowner = 10
    ORDER BY t.typname
    """
    |> Enum.map(&Map.new/1)
    |> Enum.filter(&(&1.typtype not in ~w[d r c] and &1.name not in ~w[_foreign_data_wrappers int2vector _domain_constraints _view_column_usage _enabled_roles _cstring _user_mappings _table_constraints _int8multirange _attributes _check_constraints _aclitem _domain_udt_usage  _numrange _usage_privileges _ltree_gist _users _role_usage_grants _role_udt_grants _character_data _routine_sequence_usage _time_stamp _yes_or_no _constraint_column_usage __pg_user_mappings _foreign_tables _information_schema_catalog_name _int8range _txid_snapshot _routine_privileges _user_mapping_options _schemata _parameters __pg_foreign_tables _tsquery _collations _column_options _routine_column_usage __pg_foreign_servers _routine_table_usage _int4multirange _sql_features _tsmultirange _applicable_roles _user_defined_types _tables _tstzmultirange _foreign_data_wrapper_options __pg_foreign_data_wrappers oidvector _character_sets _tsrange _key_column_usage _domains jsonpath _column_udt_usage _column_privileges txid_snapshot _ltxtquery _oidvector _triggers _role_column_grants _foreign_servers _jsonpath tsquery _role_routine_grants _routines _foreign_server_options _cardinal_number _foreign_table_options __pg_foreign_table_columns _transforms _referential_constraints _table_privileges _data_type_privileges _datemultirange _daterange _udt_privileges _administrable_role_authorizations _view_routine_usage _sql_sizing ltxtquery _sql_implementation_info _column_column_usage _tstzrange _collation_character_set_applicability _view_table_usage _element_types _column_domain_usage _triggered_update_columns _role_table_grants _sequences _constraint_table_usage _int2vector _columns _nummultirange _sql_identifier _sql_parts _int4range _gtsvector _ghstore _routine_routine_usage _check_constraint_routine_usage _views _int2vector]))
  end

  def value("_bool"), do: [false, true]
  def value("_" <> type), do: [value(type), value(type)]
  def value(name) when name in ~w[int2 int4 int8 oid cid xid xid8 regclass regtype regproc regprocedure regoper regoperator regnamespace regrole regconfig regdictionary regcollation], do: 42
  def value("tid"), do: {123, 4}
  def value("float4"), do: 3.0
  def value("float8"), do: 3.141592653589793
  def value("numeric"), do: ~c"1234.5678"
  def value("money"), do: 12345678
  def value("bool"), do: Enum.random([false, true])
  def value("char"), do: "a"
  def value(name) when name in ~w[varchar text citext bpchar name], do: "hello"
  def value("bytea"), do: <<0, 1, 2, 3>>
  def value("bit"), do: <<1::1>>
  def value("varbit"), do: <<1::1,0::1,1::1,1::1,0::1>>
  def value("date"), do: ~D[2025-01-01]
  def value("time"), do: ~T[12:00:00.000000]
  def value("timetz"), do: ~T[12:00:00.000000]
  def value(name) when name in ~w[timestamp time_stamp], do: ~N[2025-01-01 12:00:00.000000]
  def value("timestamptz"), do: ~U[2025-01-01 12:00:00.000000Z]
  def value("interval"), do: Duration.new!(day: 1, hour: 2, microsecond: {0, 6})
  def value("uuid"), do: "550e8400-e29b-41d4-a716-446655440000"
  def value("json"), do: %{"key" => "value"}
  def value("jsonb"), do: %{"key" => "value"}
  def value("jsonpath"), do: "$.store.book[*].author"
  def value("xml"), do: "<root><x>1</x></root>"
  def value("inet"), do: {127, 0, 0, 1}
  def value("cidr"), do: {192, 168, 0, 0, 16}
  def value("macaddr"), do: <<0,1,2,3,4,5>>
  def value("macaddr8"), do: <<0,1,2,3,4,5,6,7>>
  def value("point"), do: {1.0, 2.0}
  def value("line"), do: {1.0, -1.0, 0.0}
  def value("lseg"), do: {{0.0, 0.0}, {1.0, 1.0}}
  def value("box"), do: {{0.0, 0.0}, {1.0, 1.0}}
  def value("path"), do: [{0.0, 0.0}, {1.0, 1.0}]
  def value("polygon"), do: [{0.0, 0.0}, {1.0, 0.0}, {1.0, 1.0}]
  def value("circle"), do: {{0.0, 0.0}, 1.0}
  def value("tsvector"), do: [{"dog", [{1, :A}, {5, :B}]},{"cat", []},{"bird", [{2, :C}, {10, nil}, {15, :A}]}]
  def value("refcursor"), do: "test_cursor"
  def value("record"), do: {1,2,3}
  def value("lquery"), do: "Top.Science.*"
  def value("ltree"), do: "Top.Science.Astronomy"
  def value("hstore"), do: %{"a" => "1", "b" => "2"}
  def value("daterange"), do: Date.range(~D[2001-01-01], ~D[2002-01-01], 1)
  def value("int8range"), do: -9223372036854775808..9223372036854775807
  def value("int4range"), do: -2_147_483_648..2_147_483_647
  def value("txid_snapshot"), do: {100, 200, [120, 150, 180]}
  def value("tsquery"), do: "foo & bar"

  def type("_" <> type), do: type <> "[]"
  def type(type), do: type
end

defmodule SQL.Integration.PostgresTest do
  use SQL.Case, async: true
  use SQL, adapter: SQL.Adapters.Postgres
  alias SQL.Integration.Postgres.Types
  @moduletag :integration
  describe "data types" do
    for type <- Types.list() do
      @tag type: type.name
      test "round-trip #{type.name}" do
        value = Types.value(unquote(Macro.escape(type.name)))
        sql = SQL.parse(unquote("select {{value}}::#{Types.type(type.name)}"), [value], SQL.Adapters.Postgres)
        assert [[value]] == Enum.to_list(sql)
      end
    end
  end

  describe "composite types" do
    @tag type: :composite
    test "round-trip named" do
      sql = ~SQL"select (SELECT c FROM information_schema.columns c ORDER BY table_name, ordinal_position LIMIT 1)::information_schema.columns"
      assert [row] = Enum.to_list(sql)
      assert length(row) == sql.c_len
    end

    test "round-trip anonymous" do
      sql = ~SQL"SELECT ROW(1,1.5,'a','',NULL,true,false,1::int2,2::int4,3::int8,1.0::float4,2.0::float8,'2025-01-01'::date,'12:34:56'::time,'2025-01-01 12:34:56'::timestamp,'2025-01-01 12:34:56+00'::timestamptz,'{}'::int4[],ARRAY[1,2,3],ROW(1, 'x'),ROW(1, 'x')::record)"
      assert [row] = Enum.to_list(sql)
      assert length(row) == sql.c_len
    end

    test "round-trip *" do
      sql = ~SQL"SELECT * FROM information_schema.columns"
      assert [row|_] = Enum.to_list(sql)
      assert length(row) == sql.c_len
    end
  end

  describe "errors" do
    test "timeout" do
      assert_raise RuntimeError, ~s{canceling statement due to user request}, fn ->
        Enum.to_list(Map.put(~SQL"SELECT pg_sleep(10)", :timeout, 100))
      end
    end

    test "non existing table" do
      assert_raise RuntimeError, ~s{relation "blackhole" does not exist}, fn ->
        Enum.to_list(~SQL"SELECT id FROM blackhole")
      end
    end
  end

  test "transaction state are propagated" do
    state = Process.get(SQL.Transaction)
    parent = self()
    fun = fn -> send(parent, SQL.conn(:default)) end
    spawn_link(fun)
    assert_receive ^state

    spawn(fun)
    assert_receive ^state

    Task.async(fun)
    assert_receive ^state

    Task.Supervisor.start_link(name: SQL.TaskSupervisor)
    Task.Supervisor.async_nolink(SQL.TaskSupervisor, fun)
    assert_receive ^state
  end
end
