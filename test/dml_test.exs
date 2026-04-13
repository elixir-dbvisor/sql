# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.DMLTest do
  use ExUnit.Case, async: true
  import SQL

  describe "INSERT" do
    test "simple insert" do
      sql = ~SQL[insert into users (id, name) values (1, 'John')]
      assert String.contains?(to_string(sql), "insert into")
      assert String.contains?(to_string(sql), "values")
    end

    test "insert with default values" do
      sql = ~SQL[insert into users default values]
      assert String.contains?(to_string(sql), "default values")
    end

    test "insert multiple rows" do
      sql = ~SQL[insert into users (id, name) values (1, 'John'), (2, 'Jane'), (3, 'Bob')]
      assert String.contains?(to_string(sql), "values")
    end

    test "insert from select" do
      sql = ~SQL[insert into users_backup (id, name) select id, name from users]
      assert String.contains?(to_string(sql), "insert into")
      assert String.contains?(to_string(sql), "select")
    end

    test "insert with returning" do
      sql = ~SQL[insert into users (name) values ('John') returning id]
      assert String.contains?(to_string(sql), "returning")
    end

    test "insert with on conflict do nothing" do
      sql = ~SQL[insert into users (id, name) values (1, 'John') on conflict do nothing]
      assert String.contains?(to_string(sql), "on conflict")
    end

    test "insert with on conflict do update" do
      sql = ~SQL[insert into users (id, name) values (1, 'John') on conflict (id) do update set name = excluded.name]
      assert String.contains?(to_string(sql), "on conflict")
      assert String.contains?(to_string(sql), "do update")
    end

    test "insert with interpolated value" do
      name = "John"
      sql = ~SQL[insert into users (name) values ({{name}})]
      assert sql.params == [name]
    end
  end

  describe "UPDATE" do
    test "simple update" do
      sql = ~SQL[update users set name = 'John']
      assert String.contains?(to_string(sql), "update")
      assert String.contains?(to_string(sql), "set")
    end

    test "update with where" do
      sql = ~SQL[update users set name = 'John' where id = 1]
      assert String.contains?(to_string(sql), "where")
    end

    test "update multiple columns" do
      sql = ~SQL[update users set name = 'John', email = 'john@example.com' where id = 1]
      assert String.contains?(to_string(sql), "name")
      assert String.contains?(to_string(sql), "email")
    end

    test "update with from clause" do
      sql = ~SQL[update users set total = orders.total from orders where users.id = orders.user_id]
      assert String.contains?(to_string(sql), "from")
    end

    test "update with returning" do
      sql = ~SQL[update users set name = 'John' where id = 1 returning *]
      assert String.contains?(to_string(sql), "returning")
    end

    test "update with subquery" do
      sql = ~SQL[update users set order_count = (select count(*) from orders where orders.user_id = users.id)]
      assert String.contains?(to_string(sql), "select")
    end

    test "update with interpolated value" do
      name = "John"
      id = 1
      sql = ~SQL[update users set name = {{name}} where id = {{id}}]
      assert sql.params == [id, name]
    end

    test "update with increment" do
      sql = ~SQL[update products set quantity = quantity - 1 where id = 1]
      assert String.contains?(to_string(sql), "quantity - 1")
    end
  end

  describe "DELETE" do
    test "simple delete" do
      sql = ~SQL[delete from users]
      assert String.contains?(to_string(sql), "delete from")
    end

    test "delete with where" do
      sql = ~SQL[delete from users where id = 1]
      assert String.contains?(to_string(sql), "where")
    end

    test "delete with returning" do
      sql = ~SQL[delete from users where id = 1 returning *]
      assert String.contains?(to_string(sql), "returning")
    end

    test "delete with using" do
      sql = ~SQL[delete from orders using users where orders.user_id = users.id and users.deleted = true]
      assert String.contains?(to_string(sql), "using")
    end

    test "delete with subquery" do
      sql = ~SQL[delete from users where id in (select user_id from inactive_users)]
      assert String.contains?(to_string(sql), "delete")
      assert String.contains?(to_string(sql), "select")
    end

    test "delete with interpolated value" do
      id = 1
      sql = ~SQL[delete from users where id = {{id}}]
      assert sql.params == [id]
    end
  end

  describe "MERGE" do
    test "basic merge" do
      sql = ~SQL[merge into target_table t using source_table s on t.id = s.id when matched then update set t.value = s.value when not matched then insert (id, value) values (s.id, s.value)]
      assert String.contains?(to_string(sql), "merge")
    end
  end

  describe "UPSERT patterns" do
    test "insert on conflict update" do
      sql = ~SQL[insert into users (id, name, updated_at) values (1, 'John', now()) on conflict (id) do update set name = excluded.name, updated_at = excluded.updated_at]
      assert String.contains?(to_string(sql), "on conflict")
      assert String.contains?(to_string(sql), "excluded")
    end

    test "insert on conflict with where" do
      sql = ~SQL[insert into users (id, name) values (1, 'John') on conflict (id) where active = true do update set name = excluded.name]
      assert String.contains?(to_string(sql), "on conflict")
    end
  end

  describe "COPY" do
    test "copy to stdout" do
      sql = ~SQL[copy users to stdout]
      assert String.contains?(to_string(sql), "copy")
    end

    test "copy from stdin" do
      sql = ~SQL[copy users from stdin]
      assert String.contains?(to_string(sql), "copy")
    end

    test "copy with options" do
      sql = ~SQL[copy users to stdout with (format csv, header true)]
      assert String.contains?(to_string(sql), "with")
    end

    test "copy columns" do
      sql = ~SQL[copy users (id, name, email) to stdout]
      assert String.contains?(to_string(sql), "copy")
    end
  end
end
