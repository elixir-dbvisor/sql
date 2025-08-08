# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.ParserTest do
  use ExUnit.Case, async: true

  @query """
  select *
  from users, users as u, users, public.users, [public].[users], "public"."users"
  inner join users
  join users
  left outer join users
  left join users
  natural join users
  full join users
  cross join users
  join users u
  join users on id = id
  join users u on id = id
  join users on (id = id)
  join (select * from users) on (id = id)
  join (select * from users) u on (id = id)
  """

  describe "error" do
    test "missing table with sql.lock and with tables in it" do
      {:ok, context, tokens} = SQL.Lexer.lex(@query)
      {:ok, %{errors: errors}, _tokens} = SQL.Parser.parse(tokens, SQLTest.Helpers.set_sql_lock(context))
      assert length(errors) == 20
    end

    test "missing table with sql.lock and without tables in it" do
      {:ok, context, tokens} = SQL.Lexer.lex(@query)
      context = Map.put(context, :sql_lock, %{tables: [], columns: []})
      {:ok, %{errors: []}, _tokens} = SQL.Parser.parse(tokens, context)
    end

    test "missing table without sql.lock" do
      {:ok, context, tokens} = SQL.Lexer.lex(@query)
      context = Map.put(context, :sql_lock, nil)
      {:ok, %{errors: []}, _tokens} = SQL.Parser.parse(tokens, context)
    end
  end
end
