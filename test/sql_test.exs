# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQLTest do
  use ExUnit.Case
  import SQL

  def from() do
    var = "users"
    ~SQL[from #{var} u]
  end

  def where(sql) do
    var = "john@example.com"
    sql |> ~SQL[where u.email = #{var}]
  end

  describe "composable" do
    test "pipedream" do
      sql = ~SQL[from users u]
      |> ~SQL[where u.email = "john@example.com"]
      |> ~SQL[select id, email, inserted_at, updated_at]

      assert [{:from, _, _}, {:where, _, _}, {:select, _, _}] = sql.tokens
    end

    test "functional" do
      from()

      sql = from()
      |> ~SQL[select id, email, inserted_at, updated_at]
      |> where()

      assert ["users", "john@example.com"] = sql.params
      assert [{:from, _, _}, {:select, _, _}, {:where, _, _}] = sql.tokens
    end
  end

  test "inspect/1" do
    assert "#SQL<select +1000;>" == inspect(~SQL[select +1000])
  end

  test "to_sql/1" do
    email = "john@example.com"
    assert {"select id, email from users where email = $0", ["john@example.com"]} == to_sql(~SQL"""
    select id, email
    where email = #{email}
    from users
    """)
  end

  test "can parse multiple queries" do
    email = "john@example.com"
    assert {"select id, email where email = $0 from users; select id from users", [email]} == to_sql(~SQL"""
    select id, email
    where email = #{email}
    from users;
    select id from users
    """)
  end


  describe "error" do
    test "missing )" do
      assert_raise TokenMissingError, ~r"token missing on", fn ->
        ~SQL[select id in (1, 2].tokens
      end
      assert_raise TokenMissingError, ~r"token missing on", fn ->
        ~SQL[select id from users join orgs on (id = id].tokens
      end
    end

    test "missing }" do
      assert_raise TokenMissingError, ~r"token missing on", fn ->
        ~SQL[select id in #{1].tokens
      end
      assert_raise TokenMissingError, ~r"token missing on", fn ->
        ~SQL[select id from users join orgs on #{id].tokens
      end
    end

    test "missing \"" do
      assert_raise TokenMissingError, ~r"token missing on", fn ->
        ~SQL[select id in "1].tokens
      end
      assert_raise TokenMissingError, ~r"token missing on", fn ->
        ~SQL[select id from users join orgs on "id].tokens
      end
    end

    test "missing \'" do
      assert_raise TokenMissingError, ~r"token missing on", fn ->
        ~SQL[select id in '1].tokens
      end
      assert_raise TokenMissingError, ~r"token missing on", fn ->
        ~SQL[select id from users join orgs on 'id].tokens
      end
    end
  end

  describe "with" do
    test "recursive" do
      assert [{:with, _, [{:as, _, [{:recursive, _, [{:ident, _, [~c"temp"]}, {:"()", _, [{:",", _, [{:ident, _, [~c"n"]}]}, {:ident, _, [~c"fact"]}]}]}, {:"()", _, [{:union, _, [[{:select, _, [{:",", _, [{:integer, _, [~c"0"]}]}, {:integer, _, [~c"1"]}]}], {:all, _, [{:select, _, [{:",", _, [{:+, _, [{:ident, _, [~c"n"]}, {:integer, _, [~c"1"]}]}]}, {:*, _, [{:"()", _, [{:+, _, [{:ident, _, [~c"n"]}, {:integer, _, [~c"1"]}]}]}, {:ident, _, [~c"fact"]}]}]}, {:from, _, [{:ident, _, [~c"temp"]}]}, {:where, _, [{:<, _, [{:ident, _, [~c"n"]}, {:integer, _, [~c"9"]}]}]}]}]}]}]}]}] = ~SQL[with recursive temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)].tokens
    end

    test "regular" do
      assert [{:with, _, [{:as, _, [[{:ident, _, [~c"temp"]}, {:"()", _, [{:",", _, [{:ident, _, [~c"n"]}]}, {:ident, _, [~c"fact"]}]}], {:"()", _, [{:union, _, [[{:select, _, [{:",", _, [{:integer, _, [~c"0"]}]}, {:integer, _, [~c"1"]}]}], {:all, _, [{:select, _, [{:",", _, [{:+, _, [{:ident, _, [~c"n"]}, {:integer, _, [~c"1"]}]}]}, {:*, _, [{:"()", _, [{:+, _, [{:ident, _, [~c"n"]}, {:integer, _, [~c"1"]}]}]}, {:ident, _, [~c"fact"]}]}]}, {:from, _, [{:ident, _, [~c"temp"]}]}, {:where, _, [{:<, _, [{:ident, _, [~c"n"]}, {:integer, _, [~c"9"]}]}]}]}]}]}]}]}] = ~SQL[with temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)].tokens
    end
  end

  describe "combinations" do
    test "except" do
      assert [{:except, _, [{:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}, {:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}]}] = ~SQL[(select id from users) except (select id from users)].tokens
      assert [{:except, _, [{:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]]}] = ~SQL[(select id from users) except select id from users].tokens
      assert [{:except, _, [[{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}], {:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}]}] = ~SQL[select id from users except (select id from users)].tokens
      assert [{:except, _, [[{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}], [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]]}] = ~SQL[select id from users except select id from users].tokens

      assert [{:except, _, [{:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}, {:all, _, [{:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}]}]}] = ~SQL[(select id from users) except all (select id from users)].tokens
      assert [{:except, _, [{:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}, {:all, _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}]}] = ~SQL[(select id from users) except all select id from users].tokens
      assert [{:except, _, [[{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}], {:all, _, [{:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}]}]}] = ~SQL[select id from users except all (select id from users)].tokens
      assert [{:except, _, [[{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}], {:all, _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}]}] = ~SQL[select id from users except all select id from users].tokens
    end

    test "intersect" do
      assert [{:intersect, _, [{:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}, {:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}]}] = ~SQL[(select id from users) intersect (select id from users)].tokens
      assert [{:intersect, _, [{:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]]}] = ~SQL[(select id from users) intersect select id from users].tokens
      assert [{:intersect, _, [[{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}], {:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}]}] = ~SQL[select id from users intersect (select id from users)].tokens
      assert [{:intersect, _, [[{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}], [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]]}] = ~SQL[select id from users intersect select id from users].tokens

      assert [{:intersect, _, [{:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}, {:all, _, [{:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}]}]}] = ~SQL[(select id from users) intersect all (select id from users)].tokens
      assert [{:intersect, _, [{:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}, {:all, _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}]}] = ~SQL[(select id from users) intersect all select id from users].tokens
      assert [{:intersect, _, [[{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}], {:all, _, [{:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}]}]}] = ~SQL[select id from users intersect all (select id from users)].tokens
      assert [{:intersect, _, [[{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}], {:all, _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}]}] = ~SQL[select id from users intersect all select id from users].tokens
    end

    test "union" do
      assert [{:union, _, [{:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}, {:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}]}] = ~SQL[(select id from users) union (select id from users)].tokens
      assert [{:union, _, [{:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]]}] = ~SQL[(select id from users) union select id from users].tokens
      assert [{:union, _, [[{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}], {:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}]}] = ~SQL[select id from users union (select id from users)].tokens
      assert [{:union, _, [[{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}], [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]]}] = ~SQL[select id from users union select id from users].tokens

      assert [{:union, _, [{:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}, {:all, _, [{:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}]}]}] = ~SQL[(select id from users) union all (select id from users)].tokens
      assert [{:union, _, [{:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}, {:all, _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}]}] = ~SQL[(select id from users) union all select id from users].tokens
      assert [{:union, _, [[{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}], {:all, _, [{:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}]}]}] = ~SQL[select id from users union all (select id from users)].tokens
      assert [{:union, _, [[{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}], {:all, _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}]}] = ~SQL[select id from users union all select id from users].tokens
    end
  end

  describe "query" do
    test "select" do
      assert [{:select, _, [{:ident, _, [~c"id"]}]}] = ~SQL[select id].tokens
      assert [{:select, _, [{:",", _, [{:ident, _, [~c"id"]}]}, {:as, _, [{:ident, _, [~c"id"]}, {:ident, _, [~c"di"]}]}]}] = ~SQL[select id, id as di].tokens
      assert [{:select, _, [{:",", _, [{:ident, _, [~c"id"]}]}, {:as, _, [{:"()", _, [{:select, _, [{:ident, _, [~c"id"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}, {:ident, _, [~c"di"]}]}]}] = ~SQL[select id, (select id from users) as di].tokens
      assert [{:select, _, [{:ident, _, [~c"unknownn"]}]}] = ~SQL[select unknownn].tokens
      assert [{:select, _, [{:ident, _, [~c"truee"]}]}] = ~SQL[select truee].tokens
      assert [{:select, _, [{:ident, _, [~c"falsee"]}]}] = ~SQL[select falsee].tokens
      assert [{:select, _, [{:ident, _, [~c"nulll"]}]}] = ~SQL[select nulll].tokens
      assert [{:select, _, [{:ident, _, [~c"isnulll"]}]}] = ~SQL[select isnulll].tokens
      assert [{:select, _, [{:ident, _, [~c"notnulll"]}]}] = ~SQL[select notnulll].tokens
      assert [{:select, _, [{:ident, _, [~c"ascc"]}]}] = ~SQL[select ascc].tokens
      assert [{:select, _, [{:ident, _, [~c"descc"]}]}] = ~SQL[select descc].tokens
      assert [{:select, _, [{:distinct, _, []}, {:ident, _, [~c"id"]}]}] = ~SQL[select distinct id].tokens
      assert [{:select, _, [{:distinct, _, [{:on, _, [{:"()", _, [{:",", _, [{:ident, _, [~c"id"]}]}, {:ident, _, [~c"users"]}]}]}]}, {:ident, _, [~c"id"]}]}] = ~SQL[select distinct on (id, users) id].tokens
    end

    test "from" do
      assert [{:from, _, [{:ident, _, [~c"users"]}]}] = ~SQL[from users].tokens
      assert [{:from, _, [{:ident, _, [~c"users"]}, {:ident, _, [~c"u"]}]}] = ~SQL[from users u].tokens
      assert [{:from, _, [{:as, _, [{:ident, _, [~c"users"]}, {:ident, _, [~c"u"]}]}]}] = ~SQL[from users as u].tokens
    end

    test "join" do
      assert [{:join, _, [[{:inner, _, []}], {:ident, _, [~c"users"]}]}] = ~SQL[inner join users].tokens
      assert [{:join, _, [{:ident, _, [~c"users"]}]}] = ~SQL[join users].tokens
      assert [{:join, _, [[{:left, _, []}, {:outer, _, []}], {:ident, _, [~c"users"]}]}] = ~SQL[left outer join users].tokens
      assert [{:join, _, [[{:left, _, []}], {:ident, _, [~c"users"]}]}] = ~SQL[left join users].tokens
      assert [{:join, _, [[{:natural, _, []}], {:ident, _, [~c"users"]}]}] = ~SQL[natural join users].tokens
      assert [{:join, _, [[{:full, _, []}], {:ident, _, [~c"users"]}]}] = ~SQL[full join users].tokens
      assert [{:join, _, [[{:cross, _, []}], {:ident, _, [~c"users"]}]}] = ~SQL[cross join users].tokens
      assert [{:join, _, [{:ident, _, [~c"users"]}, {:ident, _, [~c"u"]}]}] = ~SQL[join users u].tokens
      assert [{:join, _, [{:on, _, [{:ident, _, [~c"users"]}, {:=, _, [{:ident, _, [~c"id"]}, {:ident, _, [~c"id"]}]}]}]}]  = ~SQL[join users on id = id].tokens
      assert [{:join, _, [{:on, _, [[{:ident, _, [~c"users"]}, {:ident, _, [~c"u"]}], {:=, _, [{:ident, _, [~c"id"]}, {:ident, _, [~c"id"]}]}]}]}] = ~SQL[join users u on id = id].tokens
      assert [{:join, _, [{:on, _, [{:ident, _, [~c"users"]}, {:"()", _, [{:=, _, [{:ident, _, [~c"id"]}, {:ident, _, [~c"id"]}]}]}]}]}] = ~SQL[join users on (id = id)].tokens
      assert [{:join, _, [{:on, _, [{:"()", _, [{:select, _, [{:*, _, []}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}, {:"()", _, [{:=, _, [{:ident, _, [~c"id"]}, {:ident, _, [~c"id"]}]}]}]}]}] = ~SQL[join (select * from users) on (id = id)].tokens
      assert [{:join, _, [{:on, _, [[{:"()", _, [{:select, _, [{:*, _, []}]}, {:from, _, [{:ident, _, [~c"users"]}]}]}, {:ident, _, [~c"u"]}], {:"()", _, [{:=, _, [{:ident, _, [~c"id"]}, {:ident, _, [~c"id"]}]}]}]}]}] = ~SQL[join (select * from users) u on (id = id)].tokens
    end

    test "where" do
      assert [{:where, _, [{:=, _, [{:integer, _, [~c"1"]}, {:integer, _, [~c"2"]}]}]}] = ~SQL[where 1 = 2].tokens
      assert [{:where, _, [{:=, _, [{:integer, _, [~c"1"]}, {:integer, _, [~c"2"]}]}]}] = ~SQL[where 1=2].tokens
      assert [{:where, _, [{:!=, _, [{:integer, _, [~c"1"]}, {:integer, _, [~c"2"]}]}]}] = ~SQL[where 1 != 2].tokens
      assert [{:where, _, [{:<>, _, [{:integer, _, [~c"1"]}, {:integer, _, [~c"2"]}]}]}] = ~SQL[where 1 <> 2].tokens
      assert [{:where, _, [{:or ,_, [{:and, _, [{:and, _, [{:and, _, [{:=, _, [{:integer, _, [~c"1"]}, {:integer, _, [~c"2"]}]}, {:=, _, [{:ident, _, [~c"id"]}, {:., _, [{:ident, _, [~c"users"]}, {:ident, _, [~c"id"]}]}]}]}, {:>, _, [{:., _, [{:., _, [{:ident, _, [~c"db"]}, {:ident, _, [~c"users"]}]}, {:ident, _, [~c"id"]}]}, {:integer, _, [~c"3"]}]}]}, {:between, _, [{:., _, [{:., _, [{:ident, _, [~c"db"]},{:ident, _, [~c"users"]}]}, {:ident, _, [~c"id"]}]}, {:and, _, [{:integer, _, [~c"1"]}, {:integer, _, [~c"2"]}]}]}]}, {true, _, []}]}]}] = ~SQL[where 1 = 2 and id = users.id and db.users.id > 3 and db.users.id between 1 and 2 or true].tokens
    end

    test "group by" do
      assert [{:group, _, [{:by, _, [{:ident, _, [~c"id"]}]}]}] = ~SQL[group by id].tokens
      assert [{:group, _, [{:by, _, [{:., _, [{:ident, _, [~c"users"]}, {:ident, _, [~c"id"]}]}]}]}] = ~SQL[group by users.id].tokens
      assert [{:group, _, [{:by, _, [{:",", _, [{:ident, _, [~c"id"]}]}, {:., _, [{:ident, _, [~c"users"]}, {:ident, _, [~c"id"]}]}]}]}] = ~SQL[group by id, users.id].tokens
    end

    test "having" do
      assert [{:having, _, [{:=, _, [{:integer, _, [~c"1"]}, {:integer, _, [~c"2"]}]}]}] = ~SQL[having 1 = 2].tokens
      assert [{:having, _, [{:!=, _, [{:integer, _, [~c"1"]}, {:integer, _, [~c"2"]}]}]}] = ~SQL[having 1 != 2].tokens
      assert [{:having, _, [{:<>, _, [{:integer, _, [~c"1"]}, {:integer, _, [~c"2"]}]}]}] = ~SQL[having 1 <> 2].tokens
    end

    test "order by" do
      assert [{:order, _, [{:by, _, [{:ident, _, [~c"id"]}]}]}] = ~SQL[order by id].tokens
      assert [{:order, _, [{:by, _, [{:., _, [{:ident, _, [~c"users"]}, {:ident, _, [~c"id"]}]}]}]}] = ~SQL[order by users.id].tokens
      assert [{:order, _, [{:by, _, [{:",", _, [{:ident, _, [~c"id"]}]}, {:",", _, [{:., _, [{:ident, _, [~c"users"]}, {:ident, _, [~c"id"]}]}]}, {:",", _, [{:asc, _, [{:., _, [{:ident, _, [~c"users"]}, {:ident, _, [~c"id"]}]}]}]}, {:desc, _, [{:ident, _, [~c"id"]}]}]}]}] = ~SQL[order by id, users.id, users.id asc, id desc].tokens
    end

    test "offset" do
      assert [{:offset, _, [{:integer, _, [~c"1"]}]}] = ~SQL[offset 1].tokens
    end

    test "limit" do
      assert [{:limit, _, [{:integer, _, [~c"1"]}]}] = ~SQL[limit 1].tokens
    end

    test "fetch" do
      assert [{:fetch, _, [{:next, _, []}]}, {:from, _, [{:ident, _, [~c"users"]}]}] = ~SQL[fetch next from users].tokens
      assert [{:fetch, _, [{:prior, _, []}]}, {:from, _, [{:ident, _, [~c"users"]}]}] = ~SQL[fetch prior from users].tokens
      assert [{:fetch, _, [{:first, _, []}]}, {:from, _, [{:ident, _, [~c"users"]}]}] = ~SQL[fetch first from users].tokens
      assert [{:fetch, _, [{:last, _, []}]}, {:from, _, [{:ident, _, [~c"users"]}]}] = ~SQL[fetch last from users].tokens
      assert [{:fetch, _, [{:absolute, _, [{:integer, _, [~c"1"]}]}]}, {:from, _, [{:ident, _, [~c"users"]}]}] = ~SQL[fetch absolute 1 from users].tokens
      assert [{:fetch, _, [{:relative, _, [{:integer, _, [~c"1"]}]}]}, {:from, _, [{:ident, _, [~c"users"]}]}] = ~SQL[fetch relative 1 from users].tokens
      assert [{:fetch, _, [{:integer, _, [~c"1"]}]}, {:from, _, [{:ident, _, [~c"users"]}]}] = ~SQL[fetch 1 from users].tokens
      assert [{:fetch, _, [{:all, _, []}]}, {:from, _, [{:ident, _, [~c"users"]}]}] = ~SQL[fetch all from users].tokens
      assert [{:fetch, _, [{:forward, _, []}]}, {:from, _, [{:ident, _, [~c"users"]}]}] = ~SQL[fetch forward from users].tokens
      assert [{:fetch, _, [{:forward, _, [{:integer, _, [~c"1"]}]}]}, {:from, _, [{:ident, _, [~c"users"]}]}] = ~SQL[fetch forward 1 from users].tokens
      assert [{:fetch, _, [{:forward, _, [{:all, _, []}]}]}, {:from, _, [{:ident, _, [~c"users"]}]}] = ~SQL[fetch forward all from users].tokens
      assert [{:fetch, _, [{:backward, _, []}]}, {:from, _, [{:ident, _, [~c"users"]}]}] = ~SQL[fetch backward from users].tokens
      assert [{:fetch, _, [{:backward, _, [{:integer, _, [~c"1"]}]}]}, {:from, _, [{:ident, _, [~c"users"]}]}] = ~SQL[fetch backward 1 from users].tokens
      assert [{:fetch, _, [{:backward, _, [{:all, _, []}]}]}, {:from, _, [{:ident, _, [~c"users"]}]}] = ~SQL[fetch backward all from users].tokens

      assert [{:fetch, _, [{:in, _, [{:next, _, []}, {:ident, _, [~c"users"]}]}]}] = ~SQL[fetch next in users].tokens
      assert [{:fetch, _, [{:in, _, [{:prior, _, []}, {:ident, _, [~c"users"]}]}]}] = ~SQL[fetch prior in users].tokens
      assert [{:fetch, _, [{:in, _, [{:first, _, []}, {:ident, _, [~c"users"]}]}]}] = ~SQL[fetch first in users].tokens
      assert [{:fetch, _, [{:in, _, [{:last, _, []}, {:ident, _, [~c"users"]}]}]}] = ~SQL[fetch last in users].tokens
      assert [{:fetch, _, [{:in, _, [{:absolute, _, [{:integer, _, [~c"1"]}]}, {:ident, _, [~c"users"]}]}]}] = ~SQL[fetch absolute 1 in users].tokens
      assert [{:fetch, _, [{:in, _, [{:relative, _, [{:integer, _, [~c"1"]}]}, {:ident, _, [~c"users"]}]}]}] = ~SQL[fetch relative 1 in users].tokens
      assert [{:fetch, _, [{:in, _, [{:integer, _, [~c"1"]}, {:ident, _, [~c"users"]}]}]}] = ~SQL[fetch 1 in users].tokens
      assert [{:fetch, _, [{:in, _, [{:all, _, []}, {:ident, _, [~c"users"]}]}]}] = ~SQL[fetch all in users].tokens
      assert [{:fetch, _, [{:in, _, [{:forward, _, []}, {:ident, _, [~c"users"]}]}]}] = ~SQL[fetch forward in users].tokens
      assert [{:fetch, _, [{:in, _, [{:forward, _, [{:integer, _, [~c"1"]}]}, {:ident, _, [~c"users"]}]}]}] = ~SQL[fetch forward 1 in users].tokens
      assert [{:fetch, _, [{:in, _, [{:forward, _, [{:all, _, []}]}, {:ident, _, [~c"users"]}]}]}] = ~SQL[fetch forward all in users].tokens
      assert [{:fetch, _, [{:in, _, [{:backward, _, []}, {:ident, _, [~c"users"]}]}]}] = ~SQL[fetch backward in users].tokens
      assert [{:fetch, _, [{:in, _, [{:backward, _, [{:integer, _, [~c"1"]}]}, {:ident, _, [~c"users"]}]}]}] = ~SQL[fetch backward 1 in users].tokens
      assert [{:fetch, _, [{:in, _, [{:backward, _, [{:all, _, []}]}, {:ident, _, [~c"users"]}]}]}] = ~SQL[fetch backward all in users].tokens
    end
  end

  describe "datatypes" do
    test "integer" do
      assert [{:select, _, [{:integer, _, [~c"1"]}]}] = ~SQL[select 1].tokens
      assert [{:select, _, [{:integer, _, [~c"1000"]}]}] = ~SQL[select 1000].tokens
      assert [{:select, _, [{:integer, _, [~c"-1000"]}]}] = ~SQL[select -1000].tokens
      assert [{:select, _, [{:integer, _, [~c"+1000"]}]}] = ~SQL[select +1000].tokens
    end

    test "float" do
      assert [{:select, _, [{:float, _, [~c"+10.00"]}]}] = ~SQL[select +10.00].tokens
      assert [{:select, _, [{:float, _, [~c"-10.00"]}]}] = ~SQL[select -10.00].tokens
    end

    test "identifier" do
      assert [{:select, _, [{:., _, [{:., _, [{:"[]", _, [{:ident, _, [~c"db"]}]}, {:"[]", _, [{:ident, _, [~c"users"]}]}]}, {:"[]", _, [{:ident, _, [~c"id"]}]}]}]}] = ~SQL{select [db].[users].[id]}.tokens
      assert [{:select, _, [{:., _, [{:., _, [{:"", _, [{:ident, _, [~c"db"]}]}, {:"", _, [{:ident, _, [~c"users"]}]}]}, {:"", _, [{:ident, _, [~c"id"]}]}]}]}] = ~SQL[select "db"."users"."id"].tokens
      assert [{:select, _, [{:., _, [{:., _, [{:ident, _, [~c"db"]}, {:ident, _, [~c"users"]}]}, {:ident, _, [~c"id"]}]}]}] = ~SQL[select db.users.id].tokens
      assert [{:select, _, [{:., _, [{:ident, _, [~c"db"]}, {:ident, _, [~c"users"]}]}]}] = ~SQL[select db.users].tokens
      assert [{:select, _, [{:ident, _, [~c"db"]}]}] = ~SQL[select db].tokens
    end

    test "qouted" do
      assert [{:select, _, [{:"", _, [{:ident, _, [~c"db.users.id"]}]}]}] = ~SQL[select "db.users.id"].tokens
      assert [{:select, _, [{:"''", _, [{:ident, _, [~c"db.users"]}]}]}] = ~SQL[select 'db.users'].tokens
      assert [{:select, _, [{:",", _, [{:"", _, [{:ident, _, [~c"db.users.id"]}]}]}, {:"''", _,  [{:ident, _,  [~c"db.users"]}]}]}] = ~SQL[select "db.users.id", 'db.users'].tokens
    end
  end

  test "interpolation" do
    var = 1
    assert [{:select, _, [{:binding, _, [0]}]}] = ~SQL[select #{var}].tokens
    assert [{:select, _, [{:binding, _, [0]}]}] = ~SQL[select #{
      {}
      }].tokens
  end

  describe "operators" do
    test "=" do
      assert [{:where, _, [{:=, _, [{:ident, _, [~c"id"]}, {:integer, _, [~c"1"]}]}]}] = ~SQL[where id = 1].tokens
      assert [{:where, _, [{:=, _, [{:ident, _, [~c"id"]}, {:integer, _, [~c"1"]}]}]}] = ~SQL[where id=1].tokens
    end
    test "-" do
      assert [{:where, _, [{:-, _, [{:ident, _, [~c"id"]}, {:integer, _, [~c"1"]}]}]}] = ~SQL[where id - 1].tokens
      assert [{:where, _, [{:-, _, [{:ident, _, [~c"id"]}, {:integer, _, [~c"1"]}]}]}] = ~SQL[where id-1].tokens
    end
    test "+" do
      assert [{:where, _, [{:+, _, [{:ident, _, [~c"id"]}, {:integer, _, [~c"1"]}]}]}] = ~SQL[where id + 1].tokens
      assert [{:where, _, [{:+, _, [{:ident, _, [~c"id"]}, {:integer, _, [~c"1"]}]}]}] = ~SQL[where id+1].tokens
    end
    test "*" do
      assert [{:where, _, [{:*, _, [{:ident, _, [~c"id"]}, {:integer, _, [~c"1"]}]}]}] = ~SQL[where id * 1].tokens
      assert [{:where, _, [{:*, _, [{:ident, _, [~c"id"]}, {:integer, _, [~c"1"]}]}]}] = ~SQL[where id*1].tokens
    end
    test "/" do
      assert [{:where, _, [{:/, _, [{:ident, _, [~c"id"]}, {:integer, _, [~c"1"]}]}]}] = ~SQL[where id / 1].tokens
      assert [{:where, _, [{:/, _, [{:ident, _, [~c"id"]}, {:integer, _, [~c"1"]}]}]}] = ~SQL[where id/1].tokens
    end
    test "<>" do
      assert [{:where, _, [{:<>, _, [{:ident, _, [~c"id"]}, {:integer, _, [~c"1"]}]}]}] = ~SQL[where id <> 1].tokens
      assert [{:where, _, [{:<>, _, [{:ident, _, [~c"id"]}, {:integer, _, [~c"1"]}]}]}] = ~SQL[where id<>1].tokens
    end
    test ">" do
      assert [{:where, _, [{:>, _, [{:ident, _, [~c"id"]}, {:integer, _, [~c"1"]}]}]}] = ~SQL[where id > 1].tokens
      assert [{:where, _, [{:>, _, [{:ident, _, [~c"id"]}, {:integer, _, [~c"1"]}]}]}] = ~SQL[where id>1].tokens
    end
    test "<" do
      assert [{:where, _, [{:<, _, [{:ident, _, [~c"id"]}, {:integer, _, [~c"1"]}]}]}] = ~SQL[where id < 1].tokens
      assert [{:where, _, [{:<, _, [{:ident, _, [~c"id"]}, {:integer, _, [~c"1"]}]}]}] = ~SQL[where id<1].tokens
    end
    test ">=" do
      assert [{:where, _, [{:>=, _, [{:ident, _, [~c"id"]}, {:integer, _, [~c"1"]}]}]}] = ~SQL[where id >= 1].tokens
      assert [{:where, _, [{:>=, _, [{:ident, _, [~c"id"]}, {:integer, _, [~c"1"]}]}]}] = ~SQL[where id>=1].tokens
    end
    test "<=" do
      assert [{:where, _, [{:<=, _, [{:ident, _, [~c"id"]}, {:integer, _, [~c"1"]}]}]}] = ~SQL[where id <= 1].tokens
      assert [{:where, _, [{:<=, _, [{:ident, _, [~c"id"]}, {:integer, _, [~c"1"]}]}]}] = ~SQL[where id<=1].tokens
    end
    test "between" do
      assert [{:where, _, [{:between, _, [{:ident, _, [~c"id"]}, {:and, _, [{:integer, _, [~c"1"]}, {:integer, _, [~c"2"]}]}]}]}] = ~SQL[where id between 1 and 2].tokens
      assert [{:where, _, [{:between, _, [{:not, _, [{:ident, _, [~c"id"]}]}, {:and, _, [{:integer, _, [~c"1"]}, {:integer, _, [~c"2"]}]}]}]}] = ~SQL[where id not between 1 and 2].tokens
      assert [{:where, _, [{:between, _, [{:ident, _, [~c"id"]}, {:symmetric, _, [{:and, _, [{:integer, _, [~c"1"]}, {:integer, _, [~c"2"]}]}]}]}]}] = ~SQL[where id between symmetric 1 and 2].tokens
      assert [{:where, _, [{:between, _, [{:not, _, [{:ident, _, [~c"id"]}]}, {:symmetric, _, [{:and, _, [{:integer, _, [~c"1"]}, {:integer, _, [~c"2"]}]}]}]}]}] = ~SQL[where id not between symmetric 1 and 2].tokens
    end
    test "like" do
      assert [{:where, _, [{:like, _, [{:ident, _, [~c"id"]}, {:integer, _, [~c"1"]}]}]}] = ~SQL[where id like 1].tokens
    end
    test "ilike" do
      assert [{:where, _, [{:ilike, _, [{:ident, _, [~c"id"]}, {:integer, _, [~c"1"]}]}]}] = ~SQL[where id ilike 1].tokens
    end
    test "in" do
      assert [{:where, _, [{:in, _, [{:ident, _, [~c"id"]}, {:"()", _, [{:",", _, [{:integer, _, [~c"1"]}]}, {:integer, _, [~c"2"]}]}]}]}] = ~SQL[where id in (1, 2)].tokens
    end
    test "is" do
      assert [{:where, _, [{:is, _, [{:ident, _, [~c"id"]}, {:null, _, []}]}]}] = ~SQL[where id is null].tokens
      assert [{:where, _, [{:is, _, [{:ident, _, [~c"id"]}, {false, _, []}]}]}] = ~SQL[where id is false].tokens
      assert [{:where, _, [{:is, _, [{:ident, _, [~c"id"]}, {true, _, []}]}]}] = ~SQL[where id is true].tokens
      assert [{:where, _, [{:is, _, [{:ident, _, [~c"id"]}, {:unknown, _, []}]}]}] = ~SQL[where id is unknown].tokens

      assert [{:where, _, [{:is, _, [{:ident, _, [~c"id"]}, {:not, _, [{:null, _, []}]}]}]}] = ~SQL[where id is not null].tokens
      assert [{:where, _, [{:is, _, [{:ident, _, [~c"id"]}, {:not, _, [{false, _, []}]}]}]}] = ~SQL[where id is not false].tokens
      assert [{:where, _, [{:is, _, [{:ident, _, [~c"id"]}, {:not, _, [{true, _, []}]}]}]}] = ~SQL[where id is not true].tokens
      assert [{:where, _, [{:is, _, [{:ident, _, [~c"id"]}, {:not, _, [{:unknown, _, []}]}]}]}] = ~SQL[where id is not unknown].tokens

      assert [{:where, _, [{:is, _, [{:ident, _, [~c"id"]}, {:distinct, _, [{:from, _, [{:integer, _, [~c"1"]}]}]}]}]}] = ~SQL[where id is distinct from 1].tokens
      assert [{:where, _, [{:is, _, [{:ident, _, [~c"id"]}, {:not, _, [{:distinct, _, []}]}, {:from, _, [{:integer, _, [~c"1"]}]}]}]}] = ~SQL[where id is not distinct from 1].tokens

      assert [{:where, _, [{:isnull, _, [{:ident, _, [~c"id"]}]}]}] = ~SQL[where id isnull].tokens
      assert [{:where, _, [{:notnull, _, [{:ident, _, [~c"id"]}]}]}] = ~SQL[where id notnull].tokens
    end
    test "as" do
      assert [{:select, _, [{:as, _, [{:ident, _, [~c"id"]}, {:ident, _, [~c"dd"]}]}]}] = ~SQL[select id as dd].tokens
    end
  end
end
