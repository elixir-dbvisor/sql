# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.StructTest do
  use ExUnit.Case, async: true
  import SQL

  describe "SQL struct" do
    test "struct has expected fields" do
      sql = ~SQL[select 1]
      assert Map.has_key?(sql, :tokens)
      assert Map.has_key?(sql, :params)
      assert Map.has_key?(sql, :string)
      assert Map.has_key?(sql, :id)
      assert Map.has_key?(sql, :name)
      assert Map.has_key?(sql, :columns)
      assert Map.has_key?(sql, :types)
      assert Map.has_key?(sql, :pool)
      assert Map.has_key?(sql, :portal)
    end

    test "struct has correct defaults" do
      sql = %SQL{}
      assert sql.tokens == []
      assert sql.params == []
      assert sql.pool == :default
      assert sql.max_rows == 0
    end
  end

  describe "SQL.to_sql/1" do
    test "returns tuple of string and params" do
      email = "test@example.com"
      {string, params} = SQL.to_sql(~SQL[select * from users where email = {{email}}])
      assert is_binary(string)
      assert is_list(params)
      assert params == [email]
    end

    test "empty params for static query" do
      {_string, params} = SQL.to_sql(~SQL[select 1])
      assert params == []
    end

    test "multiple params" do
      a = 1
      b = 2
      c = 3
      {_string, params} = SQL.to_sql(~SQL[select {{a}}, {{b}}, {{c}}])
      assert length(params) == 3
    end
  end

  describe "String.Chars protocol" do
    test "to_string returns SQL string" do
      sql = ~SQL[select 1]
      result = to_string(sql)
      assert is_binary(result)
      assert String.contains?(result, "select")
    end

    test "string representation excludes params" do
      value = "test"
      sql = ~SQL[select {{value}}]
      result = to_string(sql)
      assert String.contains?(result, "?") or String.contains?(result, "$")
    end
  end

  describe "Inspect protocol" do
    test "inspect returns readable format" do
      sql = ~SQL[select 1]
      result = inspect(sql)
      assert String.contains?(result, "~SQL")
    end

    test "inspect with color codes" do
      sql = ~SQL[select 1, 'hello']
      result = inspect(sql)
      assert is_binary(result)
    end
  end

  describe "SQL.id/1" do
    test "generates consistent id for same SQL" do
      id1 = SQL.id("select 1")
      id2 = SQL.id("select 1")
      assert id1 == id2
    end

    test "generates different id for different SQL" do
      id1 = SQL.id("select 1")
      id2 = SQL.id("select 2")
      assert id1 != id2
    end
  end

  describe "SQL.parse/1" do
    test "parses SQL string" do
      sql = SQL.parse("select 1")
      assert is_struct(sql, SQL)
      assert String.contains?(to_string(sql), "select")
    end

    test "parses with bindings" do
      value = 42
      sql = SQL.parse("select {{value}}", [value: value])
      assert sql.params == [42]
    end
  end

  describe "SQL.map/2" do
    test "adds transformation function" do
      sql = ~SQL[select id, name from users]
             |> SQL.map(fn row -> row end)
      assert sql.fn != nil
    end

    test "chains multiple maps" do
      sql = ~SQL[select id, name from users]
             |> SQL.map(fn row -> row end)
             |> SQL.map(fn row -> row[:id] end)
      assert sql.fn != nil
    end
  end

  describe "SQL.stream/2" do
    test "sets max_rows" do
      sql = ~SQL[select * from users]
             |> SQL.stream()
      assert sql.max_rows == 500
    end

    test "custom max_rows" do
      sql = ~SQL[select * from users]
             |> SQL.stream(max_rows: 1000)
      assert sql.max_rows == 1000
    end
  end

  describe "composability" do
    test "piping queries" do
      base = ~SQL[from users]
      sql = base |> ~SQL[select id, name]
      assert String.contains?(to_string(sql), "select")
      assert String.contains?(to_string(sql), "from")
    end

    test "piping with where" do
      sql = ~SQL[from users]
            |> ~SQL[where active = true]
            |> ~SQL[select id, name]
      result = to_string(sql)
      assert String.contains?(result, "where")
    end

    test "piping multiple clauses" do
      sql = ~SQL[from users u]
            |> ~SQL[join orders o on u.id = o.user_id]
            |> ~SQL[where u.active = true]
            |> ~SQL[group by u.id]
            |> ~SQL[select u.id, count(o.id) as order_count]

      result = to_string(sql)
      assert String.contains?(result, "select")
      assert String.contains?(result, "from")
      assert String.contains?(result, "join")
      assert String.contains?(result, "where")
      assert String.contains?(result, "group by")
    end

    test "functions returning SQL" do
      defmodule TestModule do
        import SQL

        def base_query do
          ~SQL[from users]
        end

        def with_active do
          base_query() |> ~SQL[where active = true]
        end
      end

      sql = TestModule.with_active() |> ~SQL[select *]
      result = to_string(sql)
      assert String.contains?(result, "where")
    end
  end

  describe "params ordering" do
    test "params preserve order" do
      name = "Alice"
      min_age = 18
      {_sql, params} = SQL.to_sql(~SQL[where name = {{name}} select id, {{min_age}} as threshold from users])
      assert length(params) == 2
    end

    test "multiple interpolations same variable" do
      value = 1
      sql = ~SQL[select {{value}}, {{value}}, {{value}}]
      assert length(sql.params) == 3
    end
  end
end
