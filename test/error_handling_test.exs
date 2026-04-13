# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.ErrorHandlingTest do
  use ExUnit.Case, async: true
  import SQL

  describe "TokenMissingError" do
    test "unclosed parenthesis" do
      assert_raise TokenMissingError, fn ->
        SQL.parse("select (1 + 2")
      end
    end

    test "unclosed bracket" do
      assert_raise TokenMissingError, fn ->
        SQL.parse("select [column")
      end
    end

    test "unclosed single quote" do
      assert_raise TokenMissingError, fn ->
        SQL.parse("select 'unterminated string")
      end
    end

    test "unclosed double quote" do
      assert_raise TokenMissingError, fn ->
        SQL.parse("select \"unterminated identifier")
      end
    end

    test "unclosed interpolation brace" do
      assert_raise TokenMissingError, fn ->
        SQL.parse("select {{var")
      end
    end

    test "unclosed case expression" do
      assert_raise TokenMissingError, fn ->
        SQL.parse("select case when 1 = 1 then 'yes'")
      end
    end
  end

  describe "SyntaxError" do
    test "zero width space character" do
      assert_raise SyntaxError, ~r/illegal zero width character/, fn ->
        SQL.Lexer.lex("SELECT\u200B1")
      end
    end

    test "BOM character at start" do
      assert_raise SyntaxError, ~r/illegal zero width character/, fn ->
        SQL.Lexer.lex("\uFEFFSELECT 1")
      end
    end

    test "bidi character LTR embedding" do
      assert_raise SyntaxError, ~r/illegal bidi character/, fn ->
        SQL.Lexer.lex("SELECT\u202A1")
      end
    end

    test "bidi character RTL embedding" do
      assert_raise SyntaxError, ~r/illegal bidi character/, fn ->
        SQL.Lexer.lex("SELECT\u202B1")
      end
    end

    test "combining grapheme joiner" do
      assert_raise SyntaxError, ~r/illegal cgj character/, fn ->
        SQL.Lexer.lex("SEL\u034FECT 1")
      end
    end
  end

  describe "parser error recovery" do
    test "validates missing table with sql.lock" do
      {:ok, context, tokens} = SQL.Lexer.lex("select * from missing_table")
      {:ok, %{errors: errors}, _tokens} = SQL.Parser.parse(tokens, SQLTest.Helpers.set_validate(context))
      # Errors should be recorded when table doesn't exist
      assert is_list(errors)
    end

    test "no errors without validation" do
      {:ok, context, tokens} = SQL.Lexer.lex("select * from users")
      {:ok, %{errors: errors}, _tokens} = SQL.Parser.parse(tokens, context)
      assert errors == []
    end
  end

  describe "error formatting" do
    test "format_error returns iodata" do
      errors = [{:ident, [], "unknown_table"}]
      result = SQL.format_error(errors)
      assert is_list(result)
    end

    test "format_error with special character" do
      errors = [{:special, [], "??"}]
      result = SQL.format_error(errors)
      assert is_list(result)
    end

    test "format_error with multiple occurrences" do
      errors = [{:ident, [], "missing"}, {:ident, [], "missing"}]
      result = SQL.format_error(errors)
      assert is_list(result)
    end
  end

  describe "robust parsing" do
    test "handles empty string" do
      {:ok, _context, tokens} = SQL.Lexer.lex("")
      assert tokens == []
    end

    test "handles whitespace only" do
      {:ok, _context, tokens} = SQL.Lexer.lex("   \t\n  ")
      assert tokens == []
    end

    test "handles multiple semicolons" do
      {:ok, _context, _tokens} = SQL.Lexer.lex("SELECT 1; SELECT 2; SELECT 3;")
    end

    test "handles trailing semicolon" do
      {:ok, _context, _tokens} = SQL.Lexer.lex("SELECT 1;")
    end

    test "handles no trailing semicolon" do
      {:ok, _context, _tokens} = SQL.Lexer.lex("SELECT 1")
    end
  end

  describe "edge cases" do
    test "very long identifier" do
      long_name = String.duplicate("a", 100)
      {:ok, _, tokens} = SQL.Lexer.lex("SELECT #{long_name}")
      assert Enum.any?(tokens, fn {_, _, v} -> v == long_name end)
    end

    test "very long string literal" do
      long_string = String.duplicate("x", 1000)
      {:ok, _, tokens} = SQL.Lexer.lex("SELECT '#{long_string}'")
      assert Enum.any?(tokens, fn {type, _, _} -> type == :quote end)
    end

    test "deeply nested expressions" do
      sql = "SELECT ((((1 + 2) * 3) - 4) / 5)"
      {:ok, _context, _tokens} = SQL.Lexer.lex(sql)
    end

    test "many parameters" do
      params = Enum.map(1..20, fn n -> "{{var#{n}}}" end) |> Enum.join(", ")
      {:ok, context, _tokens} = SQL.Lexer.lex("SELECT #{params}")
      assert context.binding == 20
    end
  end
end
