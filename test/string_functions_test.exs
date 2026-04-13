# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.StringFunctionsTest do
  use ExUnit.Case, async: true
  import SQL

  describe "string concatenation" do
    test "|| operator" do
      sql = ~SQL[select 'Hello' || ' ' || 'World']
      result = to_string(sql)
      assert String.contains?(result, "||")
    end

    test "concat function" do
      sql = ~SQL[select concat(first_name, ' ', last_name)]
      assert String.contains?(to_string(sql), "concat")
    end

    test "concat_ws function" do
      sql = ~SQL[select concat_ws(', ', city, state, country)]
      assert String.contains?(to_string(sql), "concat_ws")
    end
  end

  describe "string manipulation" do
    test "UPPER function" do
      sql = ~SQL[select upper(name)]
      assert String.contains?(to_string(sql), "upper")
    end

    test "LOWER function" do
      sql = ~SQL[select lower(name)]
      assert String.contains?(to_string(sql), "lower")
    end

    test "TRIM function" do
      sql = ~SQL[select trim(name)]
      assert String.contains?(to_string(sql), "trim")
    end

    test "LTRIM function" do
      sql = ~SQL[select ltrim(name)]
      assert String.contains?(to_string(sql), "ltrim")
    end

    test "RTRIM function" do
      sql = ~SQL[select rtrim(name)]
      assert String.contains?(to_string(sql), "rtrim")
    end

    test "SUBSTRING function" do
      sql = ~SQL[select substring(name from 1 for 5)]
      assert String.contains?(to_string(sql), "substring")
    end

    test "LEFT function" do
      sql = ~SQL[select left(name, 5)]
      assert String.contains?(to_string(sql), "left")
    end

    test "RIGHT function" do
      sql = ~SQL[select right(name, 5)]
      assert String.contains?(to_string(sql), "right")
    end

    test "REPLACE function" do
      sql = ~SQL[select replace(name, 'old', 'new')]
      assert String.contains?(to_string(sql), "replace")
    end

    test "REVERSE function" do
      sql = ~SQL[select reverse(name)]
      assert String.contains?(to_string(sql), "reverse")
    end

    test "REPEAT function" do
      sql = ~SQL[select repeat('x', 5)]
      assert String.contains?(to_string(sql), "repeat")
    end
  end

  describe "string information" do
    test "LENGTH function" do
      sql = ~SQL[select length(name)]
      assert String.contains?(to_string(sql), "length")
    end

    test "CHAR_LENGTH function" do
      sql = ~SQL[select char_length(name)]
      assert String.contains?(to_string(sql), "char_length")
    end

    test "POSITION function" do
      sql = ~SQL[select position('x' in name)]
      assert String.contains?(to_string(sql), "position")
    end

    test "STRPOS function" do
      sql = ~SQL[select strpos(name, 'x')]
      assert String.contains?(to_string(sql), "strpos")
    end
  end

  describe "pattern matching" do
    test "LIKE operator" do
      sql = ~SQL[where name like 'John%']
      assert String.contains?(to_string(sql), "like")
    end

    test "ILIKE operator" do
      sql = ~SQL[where name ilike 'john%']
      assert String.contains?(to_string(sql), "ilike")
    end

    test "NOT LIKE operator" do
      sql = ~SQL[where name not like 'John%']
      assert String.contains?(to_string(sql), "not")
      assert String.contains?(to_string(sql), "like")
    end

    test "SIMILAR TO" do
      sql = ~SQL[where name similar to 'John%']
      assert String.contains?(to_string(sql), "similar")
    end

    test "ESCAPE clause" do
      sql = ~SQL[where name like '100\%' escape '\']
      assert String.contains?(to_string(sql), "escape")
    end
  end

  describe "formatting functions" do
    test "TO_CHAR function" do
      sql = ~SQL[select to_char(amount, '999,999.99')]
      assert String.contains?(to_string(sql), "to_char")
    end

    test "FORMAT function" do
      sql = ~SQL[select format('%s %s', first_name, last_name)]
      assert String.contains?(to_string(sql), "format")
    end

    test "LPAD function" do
      sql = ~SQL[select lpad(id::text, 5, '0')]
      assert String.contains?(to_string(sql), "lpad")
    end

    test "RPAD function" do
      sql = ~SQL[select rpad(name, 20, ' ')]
      assert String.contains?(to_string(sql), "rpad")
    end
  end

  describe "encoding functions" do
    test "ENCODE function" do
      sql = ~SQL[select encode(data, 'base64')]
      assert String.contains?(to_string(sql), "encode")
    end

    test "DECODE function" do
      sql = ~SQL[select decode(data, 'base64')]
      assert String.contains?(to_string(sql), "decode")
    end

    test "MD5 function" do
      sql = ~SQL[select md5(password)]
      assert String.contains?(to_string(sql), "md5")
    end
  end
end
