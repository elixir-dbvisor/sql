# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.FormatTest do
  use ExUnit.Case, async: true
  import SQL

  describe "formatting output" do
    test "formats simple select" do
      sql = ~SQL[select id, name from users]
      result = to_string(sql)
      assert String.contains?(result, "select")
      assert String.contains?(result, "id")
      assert String.contains?(result, "name")
    end

    test "formats with lowercase keywords" do
      # Default is lowercase
      sql = ~SQL[SELECT ID FROM USERS]
      result = to_string(sql)
      assert String.contains?(result, "select")
      assert String.contains?(result, "from")
    end

    test "preserves string literals" do
      sql = ~SQL[select 'Hello World' as greeting]
      result = to_string(sql)
      assert String.contains?(result, "'Hello World'")
    end

    test "preserves quoted identifiers" do
      sql = ~SQL[select "Column Name" from "Table Name"]
      result = to_string(sql)
      assert String.contains?(result, "\"Column Name\"")
      assert String.contains?(result, "\"Table Name\"")
    end

    test "preserves numeric literals" do
      sql = ~SQL[select 123, 45.67, -89]
      result = to_string(sql)
      assert String.contains?(result, "123")
      assert String.contains?(result, "45.67")
      assert String.contains?(result, "-89")
    end
  end

  describe "operators formatting" do
    test "comparison operators with spaces" do
      assert "where id = 1" == to_string(~SQL[where id = 1])
      assert "where id <> 1" == to_string(~SQL[where id <> 1])
      assert "where id > 1" == to_string(~SQL[where id > 1])
      assert "where id < 1" == to_string(~SQL[where id < 1])
      assert "where id >= 1" == to_string(~SQL[where id >= 1])
      assert "where id <= 1" == to_string(~SQL[where id <= 1])
    end

    test "arithmetic operators" do
      assert "where id + 1" == to_string(~SQL[where id + 1])
      assert "where id - 1" == to_string(~SQL[where id - 1])
      assert "where id * 1" == to_string(~SQL[where id * 1])
      assert "where id / 1" == to_string(~SQL[where id / 1])
    end

    test "operators without spaces" do
      assert "where id=1" == to_string(~SQL[where id=1])
      assert "where id+1" == to_string(~SQL[where id+1])
    end

    test "logical operators" do
      sql = ~SQL[where a = 1 and b = 2 or c = 3]
      result = to_string(sql)
      assert String.contains?(result, "and")
      assert String.contains?(result, "or")
    end
  end

  describe "join formatting" do
    test "inner join" do
      assert "inner join users" == to_string(~SQL[inner join users])
    end

    test "left join" do
      assert "left join users" == to_string(~SQL[left join users])
    end

    test "left outer join" do
      assert "left outer join users" == to_string(~SQL[left outer join users])
    end

    test "right join" do
      assert "right join users" == to_string(~SQL[right join users])
    end

    test "full join" do
      assert "full join users" == to_string(~SQL[full join users])
    end

    test "cross join" do
      assert "cross join users" == to_string(~SQL[cross join users])
    end

    test "natural join" do
      assert "natural join users" == to_string(~SQL[natural join users])
    end

    test "join with alias" do
      assert "join users u" == to_string(~SQL[join users u])
    end

    test "join with on condition" do
      assert "join users on id = id" == to_string(~SQL[join users on id = id])
    end
  end

  describe "clause ordering" do
    test "reorders clauses correctly" do
      sql = ~SQL[from users select id, name]
      result = to_string(sql)
      # In output, select should come before from
      select_pos = :binary.match(result, "select") |> elem(0)
      from_pos = :binary.match(result, "from") |> elem(0)
      assert select_pos < from_pos
    end

    test "preserves clause order when already correct" do
      sql = ~SQL[select id from users where id = 1]
      result = to_string(sql)
      assert String.contains?(result, "select")
      assert String.contains?(result, "from")
      assert String.contains?(result, "where")
    end
  end

  describe "complex expression formatting" do
    test "nested parentheses" do
      sql = ~SQL[select (a + (b * c))]
      result = to_string(sql)
      assert String.contains?(result, "(")
      assert String.contains?(result, ")")
    end

    test "function calls" do
      sql = ~SQL[select count(*), sum(amount), avg(price)]
      result = to_string(sql)
      assert String.contains?(result, "count(*)")
      assert String.contains?(result, "sum(amount)")
      assert String.contains?(result, "avg(price)")
    end

    test "CASE expression" do
      sql = ~SQL[select case when a > 0 then 'positive' else 'negative' end]
      result = to_string(sql)
      assert String.contains?(result, "case")
      assert String.contains?(result, "when")
      assert String.contains?(result, "then")
      assert String.contains?(result, "else")
      assert String.contains?(result, "end")
    end

    test "subquery formatting" do
      sql = ~SQL[select * from (select id from users) as subq]
      result = to_string(sql)
      assert String.contains?(result, "(select")
    end
  end

  describe "comments" do
    test "preserves single-line comments" do
      sql = ~SQL[select 1 -- this is a comment]
      result = to_string(sql)
      assert String.contains?(result, "--")
    end

    test "preserves multi-line comments" do
      sql = ~SQL[select /* comment */ 1]
      result = to_string(sql)
      assert String.contains?(result, "/*") or String.contains?(result, "\\*")
    end
  end

  describe "special values" do
    test "null literal" do
      assert "where id is null" == to_string(~SQL[where id is null])
      assert "where id is not null" == to_string(~SQL[where id is not null])
    end

    test "boolean literals" do
      assert "where active is true" == to_string(~SQL[where active is true])
      assert "where active is false" == to_string(~SQL[where active is false])
    end

    test "unknown literal" do
      assert "where status is unknown" == to_string(~SQL[where status is unknown])
    end
  end

  describe "alias formatting" do
    test "column alias with AS" do
      assert "select id as user_id" == to_string(~SQL[select id as user_id])
    end

    test "table alias with AS" do
      assert "from users as u" == to_string(~SQL[from users as u])
    end

    test "table alias without AS" do
      assert "from users u" == to_string(~SQL[from users u])
    end
  end

  describe "MixFormatter" do
    test "features returns sigils and extensions" do
      features = SQL.MixFormatter.features([])
      assert {:sigils, [:SQL]} in features
    end

    test "format returns formatted SQL" do
      result = SQL.MixFormatter.format("select 1,2,3 from users where id=1", [])
      assert is_binary(result)
      assert String.contains?(result, "select")
    end

    test "preserves interpolation in format" do
      result = SQL.MixFormatter.format("select {{var}} from users", [])
      assert String.contains?(result, "{{var}}")
    end
  end
end
