# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.LexerEdgeCasesTest do
  use ExUnit.Case, async: true

  describe "comments" do
    test "single line comment" do
      assert {:ok, _, tokens} = SQL.Lexer.lex("SELECT 1 -- this is a comment")
      assert Enum.any?(tokens, fn {type, _, _} -> type == :comment end)
    end

    test "single line comment at end of statement" do
      assert {:ok, _, _} = SQL.Lexer.lex("SELECT 1; -- comment\nSELECT 2")
    end

    test "multi-line comment" do
      sql = """
      SELECT /* this is
      a multiline
      comment */ 1
      """
      assert {:ok, _, tokens} = SQL.Lexer.lex(sql)
      assert Enum.any?(tokens, fn {type, _, _} -> type == :comments end)
    end

    test "nested comment-like content in string" do
      assert {:ok, _, _} = SQL.Lexer.lex("SELECT '-- not a comment'")
    end

    test "empty comment" do
      assert {:ok, _, _} = SQL.Lexer.lex("SELECT 1 --")
    end
  end

  describe "numeric literals" do
    test "integer" do
      assert {:ok, _, [{:numeric, _, "1"} | _]} = SQL.Lexer.lex("SELECT 1")
    end

    test "decimal with leading zero" do
      assert {:ok, _, [{:numeric, _, "0.123"} | _]} = SQL.Lexer.lex("SELECT 0.123")
    end

    test "decimal without leading zero" do
      assert {:ok, _, [{:numeric, _, ".123"} | _]} = SQL.Lexer.lex("SELECT .123")
    end

    test "negative number" do
      assert {:ok, _, _} = SQL.Lexer.lex("SELECT -1000")
    end

    test "positive number with sign" do
      assert {:ok, _, _} = SQL.Lexer.lex("SELECT +1000")
    end

    test "scientific notation" do
      assert {:ok, _, _} = SQL.Lexer.lex("SELECT 1e10")
    end

    test "hexadecimal lowercase" do
      assert {:ok, _, [{:numeric, _, "0x1f"} | _]} = SQL.Lexer.lex("SELECT 0x1f")
    end

    test "hexadecimal uppercase" do
      assert {:ok, _, [{:numeric, _, "0XFF"} | _]} = SQL.Lexer.lex("SELECT 0XFF")
    end

    test "binary literal lowercase" do
      assert {:ok, _, [{:numeric, _, "0b1010"} | _]} = SQL.Lexer.lex("SELECT 0b1010")
    end

    test "binary literal uppercase" do
      assert {:ok, _, [{:numeric, _, "0B1100"} | _]} = SQL.Lexer.lex("SELECT 0B1100")
    end

    test "octal literal lowercase" do
      assert {:ok, _, [{:numeric, _, "0o755"} | _]} = SQL.Lexer.lex("SELECT 0o755")
    end

    test "octal literal uppercase" do
      assert {:ok, _, [{:numeric, _, "0O644"} | _]} = SQL.Lexer.lex("SELECT 0O644")
    end

    test "number with underscores" do
      assert {:ok, _, [{:numeric, _, "1_000_000"} | _]} = SQL.Lexer.lex("SELECT 1_000_000")
    end
  end

  describe "string literals" do
    test "single quoted string" do
      assert {:ok, _, [{:quote, _, "hello"} | _]} = SQL.Lexer.lex("SELECT 'hello'")
    end

    test "double quoted identifier" do
      assert {:ok, _, [{:double_quote, _, "column name"} | _]} = SQL.Lexer.lex("SELECT \"column name\"")
    end

    test "escaped single quote" do
      assert {:ok, _, [{:quote, _, "it''s"} | _]} = SQL.Lexer.lex("SELECT 'it''s'")
    end

    test "empty string" do
      assert {:ok, _, [{:quote, _, ""} | _]} = SQL.Lexer.lex("SELECT ''")
    end

    test "string with unicode" do
      assert {:ok, _, [{:quote, _, "日本語"} | _]} = SQL.Lexer.lex("SELECT '日本語'")
    end

    test "backtick quoted identifier" do
      assert {:ok, _, [{:backtick, _, "table"} | _]} = SQL.Lexer.lex("SELECT `table`")
    end
  end

  describe "identifiers" do
    test "simple identifier" do
      assert {:ok, _, [{:ident, _, "users"} | _]} = SQL.Lexer.lex("SELECT users")
    end

    test "identifier with underscore" do
      assert {:ok, _, [{:ident, _, "user_id"} | _]} = SQL.Lexer.lex("SELECT user_id")
    end

    test "identifier starting with underscore" do
      assert {:ok, _, [{:ident, _, "_id"} | _]} = SQL.Lexer.lex("SELECT _id")
    end

    test "qualified identifier" do
      assert {:ok, _, _} = SQL.Lexer.lex("SELECT schema.table.column")
    end

    test "reserved word as identifier when quoted" do
      assert {:ok, _, [{:double_quote, _, "select"} | _]} = SQL.Lexer.lex("SELECT \"select\"")
    end
  end

  describe "operators" do
    test "comparison operators" do
      for op <- ["=", "<>", "!=", "<", ">", "<=", ">="] do
        assert {:ok, _, _} = SQL.Lexer.lex("SELECT 1 #{op} 2")
      end
    end

    test "arithmetic operators" do
      for op <- ["+", "-", "*", "/", "%"] do
        assert {:ok, _, _} = SQL.Lexer.lex("SELECT 1 #{op} 2")
      end
    end

    test "cast operator ::" do
      assert {:ok, _, _} = SQL.Lexer.lex("SELECT id::text")
    end

    test "array subscript []" do
      assert {:ok, _, _} = SQL.Lexer.lex("SELECT arr[1]")
    end

    test "concatenation operator ||" do
      assert {:ok, _, _} = SQL.Lexer.lex("SELECT 'a' || 'b'")
    end
  end

  describe "delimiters" do
    test "semicolon" do
      assert {:ok, _, [{:colon, _, _} | _]} = SQL.Lexer.lex("SELECT 1;")
    end

    test "comma" do
      assert {:ok, _, _} = SQL.Lexer.lex("SELECT 1, 2, 3")
    end

    test "parentheses" do
      assert {:ok, _, _} = SQL.Lexer.lex("SELECT (1 + 2)")
    end

    test "brackets" do
      assert {:ok, _, _} = SQL.Lexer.lex("SELECT [public].[users]")
    end
  end

  describe "interpolation" do
    test "basic interpolation" do
      assert {:ok, context, _} = SQL.Lexer.lex("SELECT {{var}}")
      assert context.binding > 0
    end

    test "multiple interpolations" do
      assert {:ok, context, _} = SQL.Lexer.lex("SELECT {{var1}}, {{var2}}")
      assert context.binding >= 2
    end

    test "interpolation in WHERE clause" do
      assert {:ok, context, _} = SQL.Lexer.lex("SELECT * FROM users WHERE id = {{id}}")
      assert context.binding > 0
    end
  end

  describe "case sensitivity" do
    test "keywords are case insensitive" do
      assert {:ok, _, _} = SQL.Lexer.lex("SELECT 1")
      assert {:ok, _, _} = SQL.Lexer.lex("select 1")
      assert {:ok, _, _} = SQL.Lexer.lex("SeLeCt 1")
    end

    test "identifiers preserve case" do
      {:ok, _, [{:ident, _, "MyColumn"} | _]} = SQL.Lexer.lex("SELECT MyColumn")
    end
  end

  describe "error cases" do
    test "unterminated string raises" do
      assert_raise TokenMissingError, fn ->
        SQL.Lexer.lex("SELECT 'unterminated")
      end
    end

    test "unterminated double quote raises" do
      assert_raise TokenMissingError, fn ->
        SQL.Lexer.lex("SELECT \"unterminated")
      end
    end

    test "unterminated bracket raises" do
      assert_raise TokenMissingError, fn ->
        SQL.Lexer.lex("SELECT [unterminated")
      end
    end

    test "unterminated brace raises" do
      assert_raise TokenMissingError, fn ->
        SQL.Lexer.lex("SELECT {{unterminated")
      end
    end
  end
end
