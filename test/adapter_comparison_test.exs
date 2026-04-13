# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.AdapterComparisonTest do
  use ExUnit.Case, async: true

  @adapters [
    SQL.Adapters.ANSI,
    SQL.Adapters.Postgres,
    SQL.Adapters.MySQL,
    SQL.Adapters.TDS
  ]

  describe "adapter consistency" do
    test "all adapters handle basic select" do
      for adapter <- @adapters do
        {:ok, context, tokens} = SQL.Lexer.lex("SELECT id, name FROM users")
        context = %{context | module: adapter, case: :lower}
        {:ok, context, tokens} = SQL.Parser.parse(tokens, context)
        result = IO.iodata_to_binary(adapter.to_iodata(tokens, context))
        assert String.contains?(result, "select")
        assert String.contains?(result, "from")
      end
    end

    test "all adapters handle joins" do
      for adapter <- @adapters do
        {:ok, context, tokens} = SQL.Lexer.lex("SELECT * FROM users JOIN orders ON users.id = orders.user_id")
        context = %{context | module: adapter, case: :lower}
        {:ok, context, tokens} = SQL.Parser.parse(tokens, context)
        result = IO.iodata_to_binary(adapter.to_iodata(tokens, context))
        assert String.contains?(result, "join")
        assert String.contains?(result, "on")
      end
    end

    test "all adapters handle WHERE clauses" do
      for adapter <- @adapters do
        {:ok, context, tokens} = SQL.Lexer.lex("SELECT * FROM users WHERE active = true AND age > 18")
        context = %{context | module: adapter, case: :lower}
        {:ok, context, tokens} = SQL.Parser.parse(tokens, context)
        result = IO.iodata_to_binary(adapter.to_iodata(tokens, context))
        assert String.contains?(result, "where")
        assert String.contains?(result, "and")
      end
    end

    test "all adapters handle GROUP BY" do
      for adapter <- @adapters do
        {:ok, context, tokens} = SQL.Lexer.lex("SELECT department_id, COUNT(*) FROM users GROUP BY department_id")
        context = %{context | module: adapter, case: :lower}
        {:ok, context, tokens} = SQL.Parser.parse(tokens, context)
        result = IO.iodata_to_binary(adapter.to_iodata(tokens, context))
        assert String.contains?(result, "group by")
      end
    end

    test "all adapters handle ORDER BY" do
      for adapter <- @adapters do
        {:ok, context, tokens} = SQL.Lexer.lex("SELECT * FROM users ORDER BY name ASC, created_at DESC")
        context = %{context | module: adapter, case: :lower}
        {:ok, context, tokens} = SQL.Parser.parse(tokens, context)
        result = IO.iodata_to_binary(adapter.to_iodata(tokens, context))
        assert String.contains?(result, "order by")
        assert String.contains?(result, "asc")
        assert String.contains?(result, "desc")
      end
    end

    test "all adapters handle LIMIT" do
      for adapter <- @adapters do
        {:ok, context, tokens} = SQL.Lexer.lex("SELECT * FROM users LIMIT 10")
        context = %{context | module: adapter, case: :lower}
        {:ok, context, tokens} = SQL.Parser.parse(tokens, context)
        result = IO.iodata_to_binary(adapter.to_iodata(tokens, context))
        assert String.contains?(result, "limit")
      end
    end

    test "all adapters handle subqueries" do
      for adapter <- @adapters do
        {:ok, context, tokens} = SQL.Lexer.lex("SELECT * FROM (SELECT id FROM users) AS subq")
        context = %{context | module: adapter, case: :lower}
        {:ok, context, tokens} = SQL.Parser.parse(tokens, context)
        result = IO.iodata_to_binary(adapter.to_iodata(tokens, context))
        assert String.contains?(result, "select")
      end
    end

    test "all adapters handle UNION" do
      for adapter <- @adapters do
        {:ok, context, tokens} = SQL.Lexer.lex("(SELECT id FROM users) UNION (SELECT id FROM admins)")
        context = %{context | module: adapter, case: :lower}
        {:ok, context, tokens} = SQL.Parser.parse(tokens, context)
        result = IO.iodata_to_binary(adapter.to_iodata(tokens, context))
        assert String.contains?(result, "union")
      end
    end

    test "all adapters handle CTEs" do
      for adapter <- @adapters do
        {:ok, context, tokens} = SQL.Lexer.lex("WITH active_users AS (SELECT * FROM users WHERE active = true) SELECT * FROM active_users")
        context = %{context | module: adapter, case: :lower}
        {:ok, context, tokens} = SQL.Parser.parse(tokens, context)
        result = IO.iodata_to_binary(adapter.to_iodata(tokens, context))
        assert String.contains?(result, "with")
      end
    end
  end

  describe "parameter placeholders" do
    test "ANSI uses ? placeholder" do
      {:ok, context, tokens} = SQL.Lexer.lex("SELECT * FROM users WHERE id = {{id}}")
      context = %{context | module: SQL.Adapters.ANSI, case: :lower}
      {:ok, context, tokens} = SQL.Parser.parse(tokens, context)
      result = IO.iodata_to_binary(SQL.Adapters.ANSI.to_iodata(tokens, context))
      assert String.contains?(result, "?")
    end

    test "MySQL uses ? placeholder" do
      {:ok, context, tokens} = SQL.Lexer.lex("SELECT * FROM users WHERE id = {{id}}")
      context = %{context | module: SQL.Adapters.MySQL, case: :lower}
      {:ok, context, tokens} = SQL.Parser.parse(tokens, context)
      result = IO.iodata_to_binary(SQL.Adapters.MySQL.to_iodata(tokens, context))
      assert String.contains?(result, "?")
    end

    test "Postgres uses $N placeholder" do
      {:ok, context, tokens} = SQL.Lexer.lex("SELECT * FROM users WHERE id = {{id}}")
      context = %{context | module: SQL.Adapters.Postgres, case: :lower}
      {:ok, context, tokens} = SQL.Parser.parse(tokens, context)
      result = IO.iodata_to_binary(SQL.Adapters.Postgres.to_iodata(tokens, context))
      assert String.contains?(result, "$")
    end

    test "TDS uses @N placeholder" do
      {:ok, context, tokens} = SQL.Lexer.lex("SELECT * FROM users WHERE id = {{id}}")
      context = %{context | module: SQL.Adapters.TDS, case: :lower}
      {:ok, context, tokens} = SQL.Parser.parse(tokens, context)
      result = IO.iodata_to_binary(SQL.Adapters.TDS.to_iodata(tokens, context))
      assert String.contains?(result, "@")
    end
  end
end
