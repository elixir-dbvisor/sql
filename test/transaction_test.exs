# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.TransactionTest do
  use ExUnit.Case, async: true
  import SQL

  describe "transaction statements" do
    test "BEGIN statement" do
      sql = ~SQL[begin]
      assert String.contains?(to_string(sql), "begin")
    end

    test "COMMIT statement" do
      sql = ~SQL[commit]
      assert String.contains?(to_string(sql), "commit")
    end

    test "ROLLBACK statement" do
      sql = ~SQL[rollback]
      assert String.contains?(to_string(sql), "rollback")
    end

    test "SAVEPOINT statement" do
      sql = ~SQL[savepoint sp1]
      assert String.contains?(to_string(sql), "savepoint")
    end

    test "RELEASE SAVEPOINT statement" do
      sql = ~SQL[release savepoint sp1]
      assert String.contains?(to_string(sql), "release")
    end

    test "ROLLBACK TO SAVEPOINT statement" do
      sql = ~SQL[rollback to savepoint sp1]
      assert String.contains?(to_string(sql), "rollback to savepoint")
    end
  end

  describe "transaction isolation" do
    test "BEGIN with READ ONLY" do
      sql = ~SQL[begin read only]
      result = to_string(sql)
      assert String.contains?(result, "begin")
      assert String.contains?(result, "read only")
    end

    test "BEGIN with READ WRITE" do
      sql = ~SQL[begin read write]
      result = to_string(sql)
      assert String.contains?(result, "begin")
      assert String.contains?(result, "read write")
    end

    test "SET TRANSACTION ISOLATION LEVEL" do
      sql = ~SQL[set transaction isolation level serializable]
      assert String.contains?(to_string(sql), "isolation level")
    end

    test "SET TRANSACTION READ COMMITTED" do
      sql = ~SQL[set transaction isolation level read committed]
      assert String.contains?(to_string(sql), "read committed")
    end

    test "SET TRANSACTION REPEATABLE READ" do
      sql = ~SQL[set transaction isolation level repeatable read]
      assert String.contains?(to_string(sql), "repeatable read")
    end
  end

  describe "cursor statements" do
    test "DECLARE CURSOR" do
      sql = ~SQL[declare my_cursor cursor for select * from users]
      assert String.contains?(to_string(sql), "declare")
      assert String.contains?(to_string(sql), "cursor")
    end

    test "FETCH from cursor" do
      sql = ~SQL[fetch next from my_cursor]
      assert String.contains?(to_string(sql), "fetch")
    end

    test "FETCH FORWARD" do
      sql = ~SQL[fetch forward 10 from my_cursor]
      assert String.contains?(to_string(sql), "forward")
    end

    test "FETCH BACKWARD" do
      sql = ~SQL[fetch backward 10 from my_cursor]
      assert String.contains?(to_string(sql), "backward")
    end

    test "FETCH FIRST" do
      sql = ~SQL[fetch first from my_cursor]
      assert String.contains?(to_string(sql), "first")
    end

    test "FETCH LAST" do
      sql = ~SQL[fetch last from my_cursor]
      assert String.contains?(to_string(sql), "last")
    end

    test "FETCH ABSOLUTE" do
      sql = ~SQL[fetch absolute 5 from my_cursor]
      assert String.contains?(to_string(sql), "absolute")
    end

    test "FETCH RELATIVE" do
      sql = ~SQL[fetch relative -2 from my_cursor]
      assert String.contains?(to_string(sql), "relative")
    end

    test "CLOSE cursor" do
      sql = ~SQL[close my_cursor]
      assert String.contains?(to_string(sql), "close")
    end
  end

  describe "prepared statements" do
    test "PREPARE statement" do
      sql = ~SQL[prepare my_stmt as select * from users where id = $1]
      assert String.contains?(to_string(sql), "prepare")
    end

    test "EXECUTE prepared statement" do
      sql = ~SQL[execute my_stmt(1)]
      assert String.contains?(to_string(sql), "execute")
    end

    test "DEALLOCATE prepared statement" do
      sql = ~SQL[deallocate my_stmt]
      assert String.contains?(to_string(sql), "deallocate")
    end

    test "DEALLOCATE ALL" do
      sql = ~SQL[deallocate all]
      assert String.contains?(to_string(sql), "deallocate all")
    end
  end

  describe "lock statements" do
    test "LOCK TABLE" do
      sql = ~SQL[lock table users]
      assert String.contains?(to_string(sql), "lock")
    end

    test "LOCK TABLE IN ACCESS SHARE MODE" do
      sql = ~SQL[lock table users in access share mode]
      assert String.contains?(to_string(sql), "access share")
    end

    test "LOCK TABLE IN EXCLUSIVE MODE" do
      sql = ~SQL[lock table users in exclusive mode]
      assert String.contains?(to_string(sql), "exclusive")
    end

    test "LOCK TABLE NOWAIT" do
      sql = ~SQL[lock table users in access exclusive mode nowait]
      assert String.contains?(to_string(sql), "nowait")
    end
  end

  describe "set statements" do
    test "SET variable" do
      sql = ~SQL[set search_path to public, schema1]
      assert String.contains?(to_string(sql), "set")
    end

    test "SET LOCAL" do
      sql = ~SQL[set local timezone to 'UTC']
      assert String.contains?(to_string(sql), "set local")
    end

    test "SET SESSION" do
      sql = ~SQL[set session timezone to 'UTC']
      assert String.contains?(to_string(sql), "set session")
    end

    test "RESET variable" do
      sql = ~SQL[reset search_path]
      assert String.contains?(to_string(sql), "reset")
    end

    test "RESET ALL" do
      sql = ~SQL[reset all]
      assert String.contains?(to_string(sql), "reset all")
    end

    test "SHOW variable" do
      sql = ~SQL[show timezone]
      assert String.contains?(to_string(sql), "show")
    end
  end
end
