# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.DateTimeTest do
  use ExUnit.Case, async: true
  import SQL

  describe "date literals" do
    test "DATE literal" do
      sql = ~SQL[select date '2024-01-15']
      assert String.contains?(to_string(sql), "date")
      assert String.contains?(to_string(sql), "2024-01-15")
    end

    test "TIME literal" do
      sql = ~SQL[select time '14:30:00']
      assert String.contains?(to_string(sql), "time")
      assert String.contains?(to_string(sql), "14:30:00")
    end

    test "TIMESTAMP literal" do
      sql = ~SQL[select timestamp '2024-01-15 14:30:00']
      assert String.contains?(to_string(sql), "timestamp")
    end

    test "TIMESTAMP WITH TIME ZONE" do
      sql = ~SQL[select timestamp with time zone '2024-01-15 14:30:00+00']
      assert String.contains?(to_string(sql), "timestamp")
    end

    test "INTERVAL literal" do
      sql = ~SQL[select interval '1 day']
      assert String.contains?(to_string(sql), "interval")
    end
  end

  describe "date functions" do
    test "CURRENT_DATE" do
      sql = ~SQL[select current_date]
      assert String.contains?(to_string(sql), "current_date")
    end

    test "CURRENT_TIME" do
      sql = ~SQL[select current_time]
      assert String.contains?(to_string(sql), "current_time")
    end

    test "CURRENT_TIMESTAMP" do
      sql = ~SQL[select current_timestamp]
      assert String.contains?(to_string(sql), "current_timestamp")
    end

    test "NOW()" do
      sql = ~SQL[select now()]
      assert String.contains?(to_string(sql), "now()")
    end

    test "EXTRACT" do
      sql = ~SQL[select extract(year from created_at)]
      assert String.contains?(to_string(sql), "extract")
    end

    test "DATE_PART" do
      sql = ~SQL[select date_part('year', created_at)]
      assert String.contains?(to_string(sql), "date_part")
    end

    test "DATE_TRUNC" do
      sql = ~SQL[select date_trunc('month', created_at)]
      assert String.contains?(to_string(sql), "date_trunc")
    end
  end

  describe "date arithmetic" do
    test "date + interval" do
      sql = ~SQL[select created_at + interval '1 day']
      assert String.contains?(to_string(sql), "+")
      assert String.contains?(to_string(sql), "interval")
    end

    test "date - interval" do
      sql = ~SQL[select created_at - interval '1 month']
      assert String.contains?(to_string(sql), "-")
      assert String.contains?(to_string(sql), "interval")
    end

    test "date difference" do
      sql = ~SQL[select end_date - start_date]
      assert String.contains?(to_string(sql), "-")
    end
  end

  describe "date comparisons" do
    test "date equals" do
      sql = ~SQL[where created_at = date '2024-01-15']
      assert String.contains?(to_string(sql), "=")
    end

    test "date range" do
      sql = ~SQL[where created_at between date '2024-01-01' and date '2024-12-31']
      assert String.contains?(to_string(sql), "between")
    end

    test "date less than" do
      sql = ~SQL[where created_at < now()]
      assert String.contains?(to_string(sql), "<")
    end
  end
end
