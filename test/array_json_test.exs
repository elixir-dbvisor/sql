# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.ArrayJSONTest do
  use ExUnit.Case, async: true
  import SQL

  describe "array operations" do
    test "array literal" do
      sql = ~SQL[select array[1, 2, 3]]
      assert String.contains?(to_string(sql), "array")
    end

    test "array subscript" do
      sql = ~SQL[select tags[1]]
      assert String.contains?(to_string(sql), "[1]")
    end

    test "array slice" do
      sql = ~SQL[select tags[1:3]]
      assert String.contains?(to_string(sql), "[1:3]")
    end

    test "ANY with array" do
      sql = ~SQL[where id = any(array[1, 2, 3])]
      assert String.contains?(to_string(sql), "any")
    end

    test "ALL with array" do
      sql = ~SQL[where id > all(array[1, 2, 3])]
      assert String.contains?(to_string(sql), "all")
    end

    test "array_agg function" do
      sql = ~SQL[select array_agg(name)]
      assert String.contains?(to_string(sql), "array_agg")
    end

    test "unnest function" do
      sql = ~SQL[select unnest(tags)]
      assert String.contains?(to_string(sql), "unnest")
    end

    test "array_length function" do
      sql = ~SQL[select array_length(tags, 1)]
      assert String.contains?(to_string(sql), "array_length")
    end

    test "array containment @>" do
      sql = ~SQL[where tags @> array['important']]
      assert String.contains?(to_string(sql), "@>")
    end

    test "array contained by <@" do
      sql = ~SQL[where array['a', 'b'] <@ tags]
      assert String.contains?(to_string(sql), "<@")
    end

    test "array overlap &&" do
      sql = ~SQL[where tags && array['a', 'b']]
      assert String.contains?(to_string(sql), "&&")
    end

    test "array concatenation ||" do
      sql = ~SQL[select array[1, 2] || array[3, 4]]
      assert String.contains?(to_string(sql), "||")
    end
  end

  describe "JSON operations" do
    test "JSON extract with ->" do
      sql = ~SQL[select data -> 'key']
      assert String.contains?(to_string(sql), "->")
    end

    test "JSON extract text with ->>" do
      sql = ~SQL[select data ->> 'key']
      assert String.contains?(to_string(sql), "->>")
    end

    test "JSON path with #>" do
      sql = ~SQL[select data #> '{a,b,c}']
      assert String.contains?(to_string(sql), "#>")
    end

    test "JSON path text with #>>" do
      sql = ~SQL[select data #>> '{a,b,c}']
      assert String.contains?(to_string(sql), "#>>")
    end

    test "JSON containment @>" do
      sql = ~SQL[where data @> '{"key": "value"}']
      assert String.contains?(to_string(sql), "@>")
    end

    test "JSON contained <@" do
      sql = ~SQL[where '{"key": "value"}' <@ data]
      assert String.contains?(to_string(sql), "<@")
    end

    test "JSON key exists ?" do
      sql = ~SQL[where data ? 'key']
      assert String.contains?(to_string(sql), "?")
    end

    test "json_build_object function" do
      sql = ~SQL[select json_build_object('name', name, 'age', age)]
      assert String.contains?(to_string(sql), "json_build_object")
    end

    test "jsonb_build_object function" do
      sql = ~SQL[select jsonb_build_object('name', name, 'age', age)]
      assert String.contains?(to_string(sql), "jsonb_build_object")
    end

    test "json_agg function" do
      sql = ~SQL[select json_agg(row_to_json(t))]
      assert String.contains?(to_string(sql), "json_agg")
    end

    test "jsonb_array_elements function" do
      sql = ~SQL[select jsonb_array_elements(data)]
      assert String.contains?(to_string(sql), "jsonb_array_elements")
    end

    test "jsonb_each function" do
      sql = ~SQL[select * from jsonb_each(data)]
      assert String.contains?(to_string(sql), "jsonb_each")
    end

    test "jsonb_set function" do
      sql = ~SQL[select jsonb_set(data, '{key}', '"value"')]
      assert String.contains?(to_string(sql), "jsonb_set")
    end

    test "jsonb_strip_nulls function" do
      sql = ~SQL[select jsonb_strip_nulls(data)]
      assert String.contains?(to_string(sql), "jsonb_strip_nulls")
    end
  end

  describe "JSONB concatenation and deletion" do
    test "JSONB concatenation ||" do
      sql = ~SQL[select '{"a": 1}'::jsonb || '{"b": 2}'::jsonb]
      assert String.contains?(to_string(sql), "||")
    end

    test "JSONB key deletion -" do
      sql = ~SQL[select data - 'key']
      assert String.contains?(to_string(sql), "-")
    end

    test "JSONB path deletion #-" do
      sql = ~SQL[select data #- '{a,b}']
      assert String.contains?(to_string(sql), "#-")
    end
  end
end
