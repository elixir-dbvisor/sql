# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.LexerTest do
  use ExUnit.Case, async: true

  describe "newline" do
    test "U+000A lf" do
      assert {:ok, _, [{:colon, [{:span, {1, 9, 1, 9}}, {:offset, {0, 0}}|_], _}|_]} = SQL.Lexer.lex("SELECT 1;\nSELECT 2;")
    end
    test "U+000D cr" do
      assert {:ok, _, [{:colon, [{:span, {0, 19, 0, 19}}, {:offset, {0, 0}}|_], _}|_]} = SQL.Lexer.lex("SELECT 1;\rSELECT 2;")
    end
    test "U+000D+000A crlf" do
      assert {:ok, _, [{:colon, [{:span, {1, 9, 1, 9}}, {:offset, {0, 0}}|_], _}|_]} = SQL.Lexer.lex("SELECT 1;\r\nSELECT 2;")
    end
    test "U+0085 nel" do
      assert {:ok, _, [{:colon, [{:span, {1, 9, 1, 9}}, {:offset, {0, 0}}|_], _}|_]} = SQL.Lexer.lex("SELECT 1;\u0085SELECT 2;")
    end
    test "U+2028 line separator" do
      assert {:ok, _, [{:colon, [{:span, {1, 9, 1, 9}}, {:offset, {0, 0}}|_], _}|_]} = SQL.Lexer.lex("SELECT 1;\u2028SELECT 2;")
    end
    test "U+2029 paragraph" do
      assert {:ok, _, [{:colon, [{:span, {1, 9, 1, 9}}, {:offset, {0, 0}}|_], _}|_]} = SQL.Lexer.lex("SELECT 1;\u2029SELECT 2;")
    end
    test "U+000C form feed" do
      assert {:ok, _, [{:colon, [{:span, {1, 2, 1, 2}}, {:offset, {0, 0}}|_], _}|_]} = SQL.Lexer.lex("SELECT\f1;")
    end
    test "U+000B vertical tab" do
      assert {:ok, _, [{:colon, [{:span, {1, 2, 1, 2}}, {:offset, {0, 0}}|_], _}|_]} = SQL.Lexer.lex("SELECT\v1;")
    end
  end

  describe "spaces" do
    test "U+0020" do
      assert {:ok, _, [{:colon, [{:span, {0, 9, 0, 9}}, {:offset, {0, 0}}|_], _}|_]} = SQL.Lexer.lex("SELECT\u00201;")
    end
    test "U+00A0 no-break" do
      assert {:ok, _, [{:colon, [{:span, {0, 9, 0, 9}}, {:offset, {0, 0}}|_], _}|_]} = SQL.Lexer.lex("SELECT\u00A01;")
    end
    test "U+1680 ogham" do
      assert {:ok, _, [{:colon, [{:span, {0, 9, 0, 9}}, {:offset, {0, 0}}|_], _}|_]} = SQL.Lexer.lex("SELECT\u16801;")
    end
    test "U+2002 en" do
      assert {:ok, _, [{:colon, [{:span, {0, 9, 0, 9}}, {:offset, {0, 0}}|_], _}|_]} = SQL.Lexer.lex("SELECT\u20021;")
    end
    test "U+2003 em" do
      assert {:ok, _, [{:colon, [{:span, {0, 9, 0, 9}}, {:offset, {0, 0}}|_], _}|_]} = SQL.Lexer.lex("SELECT\u20031;")
    end
    test "U+2009 thin" do
      assert {:ok, _, [{:colon, [{:span, {0, 9, 0, 9}}, {:offset, {0, 0}}|_], _}|_]} = SQL.Lexer.lex("SELECT\u20091;")
    end
    test "U+202F narrow no-break" do
      assert {:ok, _, [{:colon, [{:span, {0, 9, 0, 9}}, {:offset, {0, 0}}|_], _}|_]} = SQL.Lexer.lex("SELECT\u202F1;")
    end
    test "U+205F medium mathematical" do
      assert {:ok, _, [{:colon, [{:span, {0, 9, 0, 9}}, {:offset, {0, 0}}|_], _}|_]} = SQL.Lexer.lex("SELECT\u205F1;")
    end
    test "U+3000 ideographic" do
      assert {:ok, _, [{:colon, [{:span, {0, 9, 0, 9}}, {:offset, {0, 0}}|_], _}|_]} = SQL.Lexer.lex("SELECT\u30001;")
    end
    test "U+0009 tab" do
      assert {:ok, _, [{:colon, [{:span, {0, 9, 0, 9}}, {:offset, {0, 0}}|_], _}|_]} = SQL.Lexer.lex("SELECT\t1;")
    end
  end

  describe "zero-width" do
    test "U+200B space" do
      assert_raise SyntaxError, ~r"illegal zero width character", fn ->
        SQL.Lexer.lex("SEL\u200BECT 1;")
      end
    end
    test "U+200C non-joiner" do
      assert_raise SyntaxError, ~r"illegal zero width character", fn ->
        SQL.Lexer.lex("SEL\u200CECT 1;")
      end
    end
    test "U+200D joiner" do
      assert_raise SyntaxError, ~r"illegal zero width character", fn ->
        SQL.Lexer.lex("SEL\u200DECT 1;")
      end
    end
    test "U+2060 word joiner" do
      assert_raise SyntaxError, ~r"illegal zero width character", fn ->
        SQL.Lexer.lex("SEL\u2060ECT 1;")
      end
    end
    test "U+FEFF BOM at start" do
      assert_raise SyntaxError, ~r"illegal zero width character", fn ->
        SQL.Lexer.lex("\uFEFFSELECT 1;")
      end
    end
    test "U+FEFF BOM in the middle" do
      assert_raise SyntaxError, ~r"illegal zero width character", fn ->
        SQL.Lexer.lex("SEL\uFEFFECT 1;")
      end
    end
    test "U+17B4 khmer inherent vowel" do
      assert_raise SyntaxError, ~r"illegal zero width character", fn ->
        SQL.Lexer.lex("SEL\u17B4ECT 1;")
      end
    end
    test "U+17B5 khmer inherent vowel" do
      assert_raise SyntaxError, ~r"illegal zero width character", fn ->
        SQL.Lexer.lex("SEL\u17B5ECT 1;")
      end
    end
    test "U+180E mongolian vowel separator" do
      assert_raise SyntaxError, ~r"illegal zero width character", fn ->
        SQL.Lexer.lex("SEL\u180EECT 1;")
      end
    end
  end

  describe "bidi" do
    test "U+202A ltr embedding" do
      assert_raise SyntaxError, ~r"illegal bidi character", fn ->
        SQL.Lexer.lex("SEL\u202AECT 1;")
      end
    end
    test "U+202B rtl embedding" do
      assert_raise SyntaxError, ~r"illegal bidi character", fn ->
        SQL.Lexer.lex("SEL\u202BECT 1;")
      end
    end
    test "U+202C pdf formatting" do
      assert_raise SyntaxError, ~r"illegal bidi character", fn ->
        SQL.Lexer.lex("SEL\u202CECT 1;")
      end
    end
    test "U+202D ltr override" do
      assert_raise SyntaxError, ~r"illegal bidi character", fn ->
        SQL.Lexer.lex("SEL\u202DECT 1;")
      end
    end
    test "U+202E rtl override" do
      assert_raise SyntaxError, ~r"illegal bidi character", fn ->
        SQL.Lexer.lex("SEL\u202EECT 1;")
      end
    end
    test "U+2066 ltr isolate" do
      assert_raise SyntaxError, ~r"illegal bidi character", fn ->
        SQL.Lexer.lex("SEL\u2066ECT 1;")
      end
    end
    test "U+2067 rtl isolate" do
      assert_raise SyntaxError, ~r"illegal bidi character", fn ->
        SQL.Lexer.lex("SEL\u2067ECT 1;")
      end
    end
    test "U+2068 fs isolate" do
      assert_raise SyntaxError, ~r"illegal bidi character", fn ->
        SQL.Lexer.lex("SEL\u2068ECT 1;")
      end
    end
    test "U+2069 pd isolate" do
      assert_raise SyntaxError, ~r"illegal bidi character", fn ->
        SQL.Lexer.lex("SEL\u2069ECT 1;")
      end
    end
  end

  describe "combining grapheme joiner" do
    test "U+034F" do
      assert_raise SyntaxError, ~r"illegal cgj character", fn ->
        SQL.Lexer.lex("SEL\u034FECT 1;")
      end
    end
  end

  describe "multiline" do
    test "line separator before from" do
      assert {:ok, _, [{:colon, [{:span, {1, 10, 1, 10}}, {:offset, {0, 0}}|_], _}|_]} = SQL.Lexer.lex("SELECT 1;\u2028FROM dual;")
    end
    test "paragraph separator before from" do
      assert {:ok, _, [{:colon, [{:span, {1, 10, 1, 10}}, {:offset, {0, 0}}|_], _}|_]} = SQL.Lexer.lex("SELECT 1;\u2029FROM dual;")
    end
  end
end
