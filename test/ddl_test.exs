# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.DDLTest do
  use ExUnit.Case, async: true
  import SQL

  describe "CREATE TABLE" do
    test "simple create table" do
      sql = ~SQL[create table users (id int, name varchar)]
      assert String.contains?(to_string(sql), "create table")
    end

    test "create table with primary key" do
      sql = ~SQL[create table users (id int primary key, name varchar)]
      assert String.contains?(to_string(sql), "primary key")
    end

    test "create table with not null" do
      sql = ~SQL[create table users (id int not null, name varchar not null)]
      assert String.contains?(to_string(sql), "not null")
    end

    test "create table with default" do
      sql = ~SQL[create table users (id int, status varchar default 'active')]
      assert String.contains?(to_string(sql), "default")
    end

    test "create table with unique" do
      sql = ~SQL[create table users (id int, email varchar unique)]
      assert String.contains?(to_string(sql), "unique")
    end

    test "create table with foreign key" do
      sql = ~SQL[create table orders (id int, user_id int references users(id))]
      assert String.contains?(to_string(sql), "references")
    end

    test "create table with check constraint" do
      sql = ~SQL[create table users (id int, age int check (age > 0))]
      assert String.contains?(to_string(sql), "check")
    end

    test "create table if not exists" do
      sql = ~SQL[create table if not exists users (id int)]
      assert String.contains?(to_string(sql), "if not exists")
    end

    test "create temporary table" do
      sql = ~SQL[create temporary table temp_users (id int)]
      assert String.contains?(to_string(sql), "temporary")
    end
  end

  describe "ALTER TABLE" do
    test "add column" do
      sql = ~SQL[alter table users add column email varchar]
      assert String.contains?(to_string(sql), "alter table")
      assert String.contains?(to_string(sql), "add column")
    end

    test "drop column" do
      sql = ~SQL[alter table users drop column email]
      assert String.contains?(to_string(sql), "drop column")
    end

    test "rename column" do
      sql = ~SQL[alter table users rename column name to full_name]
      assert String.contains?(to_string(sql), "rename")
    end

    test "alter column type" do
      sql = ~SQL[alter table users alter column name type text]
      assert String.contains?(to_string(sql), "alter column")
    end

    test "add constraint" do
      sql = ~SQL[alter table users add constraint pk_users primary key (id)]
      assert String.contains?(to_string(sql), "add constraint")
    end

    test "drop constraint" do
      sql = ~SQL[alter table users drop constraint pk_users]
      assert String.contains?(to_string(sql), "drop constraint")
    end

    test "rename table" do
      sql = ~SQL[alter table users rename to customers]
      assert String.contains?(to_string(sql), "rename to")
    end
  end

  describe "DROP TABLE" do
    test "simple drop table" do
      sql = ~SQL[drop table users]
      assert String.contains?(to_string(sql), "drop table")
    end

    test "drop table if exists" do
      sql = ~SQL[drop table if exists users]
      assert String.contains?(to_string(sql), "if exists")
    end

    test "drop table cascade" do
      sql = ~SQL[drop table users cascade]
      assert String.contains?(to_string(sql), "cascade")
    end

    test "drop table restrict" do
      sql = ~SQL[drop table users restrict]
      assert String.contains?(to_string(sql), "restrict")
    end
  end

  describe "CREATE INDEX" do
    test "simple create index" do
      sql = ~SQL[create index idx_users_name on users (name)]
      assert String.contains?(to_string(sql), "create index")
    end

    test "create unique index" do
      sql = ~SQL[create unique index idx_users_email on users (email)]
      assert String.contains?(to_string(sql), "unique index")
    end

    test "create index on multiple columns" do
      sql = ~SQL[create index idx_users_name_email on users (name, email)]
      assert String.contains?(to_string(sql), "create index")
    end

    test "create index if not exists" do
      sql = ~SQL[create index if not exists idx_users_name on users (name)]
      assert String.contains?(to_string(sql), "if not exists")
    end

    test "create index concurrently" do
      sql = ~SQL[create index concurrently idx_users_name on users (name)]
      assert String.contains?(to_string(sql), "concurrently")
    end
  end

  describe "DROP INDEX" do
    test "simple drop index" do
      sql = ~SQL[drop index idx_users_name]
      assert String.contains?(to_string(sql), "drop index")
    end

    test "drop index if exists" do
      sql = ~SQL[drop index if exists idx_users_name]
      assert String.contains?(to_string(sql), "if exists")
    end

    test "drop index concurrently" do
      sql = ~SQL[drop index concurrently idx_users_name]
      assert String.contains?(to_string(sql), "concurrently")
    end
  end

  describe "CREATE VIEW" do
    test "simple create view" do
      sql = ~SQL[create view active_users as select * from users where active = true]
      assert String.contains?(to_string(sql), "create view")
    end

    test "create or replace view" do
      sql = ~SQL[create or replace view active_users as select * from users where active = true]
      assert String.contains?(to_string(sql), "create or replace view")
    end

    test "create view with column names" do
      sql = ~SQL[create view user_summary (id, full_name, order_count) as select u.id, u.name, count(o.id) from users u left join orders o on u.id = o.user_id group by u.id, u.name]
      assert String.contains?(to_string(sql), "create view")
    end
  end

  describe "DROP VIEW" do
    test "simple drop view" do
      sql = ~SQL[drop view active_users]
      assert String.contains?(to_string(sql), "drop view")
    end

    test "drop view if exists" do
      sql = ~SQL[drop view if exists active_users]
      assert String.contains?(to_string(sql), "if exists")
    end
  end

  describe "TRUNCATE" do
    test "truncate table" do
      sql = ~SQL[truncate table users]
      assert String.contains?(to_string(sql), "truncate")
    end

    test "truncate multiple tables" do
      sql = ~SQL[truncate table users, orders]
      assert String.contains?(to_string(sql), "truncate")
    end

    test "truncate restart identity" do
      sql = ~SQL[truncate table users restart identity]
      assert String.contains?(to_string(sql), "restart identity")
    end

    test "truncate cascade" do
      sql = ~SQL[truncate table users cascade]
      assert String.contains?(to_string(sql), "cascade")
    end
  end
end
