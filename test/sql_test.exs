# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQLTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  import SQLTest.Helpers
  import SQL

  def from(var \\ "users") do
    ~SQL[from {{var}} u]
  end

  def where(sql, var \\ "john@example.com") do
    sql |> ~SQL[where u.email = {{var}}]
  end

  describe "composable" do
    test "pipedream" do
      sql = ~SQL[from users u]
      |> ~SQL{where u.email = 'john@example.com'}
      |> ~SQL[select id, email, inserted_at, updated_at]

      assert ~s(select id, email, inserted_at, updated_at from users u where u.email = 'john@example.com') == to_string(sql)
    end

    test "functional" do
      sql = from()
      |> ~SQL[select id, email, inserted_at, updated_at]
      |> where()

      assert ["users", "john@example.com"] = sql.params
      assert "select id, email, inserted_at, updated_at from ? u where u.email = ?" == to_string(sql)
    end
  end

  test "map/2" do
    columns = ~w[id email inserted_at updated_at]a
    sql =
    from()
    |> ~SQL[select id, email, inserted_at, updated_at]
    |> where()
    |> SQL.map(fn row -> row end)
    |> SQL.map(fn row -> Map.new(Enum.zip(columns, row)) end)
    |> SQL.map(&(&1.id))

    assert ["id"] == Enum.map([["id", "email", "inserted_at", "updated_at"]], fn row -> sql.fn.(row) end)
  end


  test "inspect/1" do
    assert ~s(~SQL"""\nselect\n  +1000\n""") == inspect(~SQL[select +1000])
  end

  test "to_sql/1" do
    email = "john@example.com"
    assert {"select id, email from users where email = ?", ["john@example.com"]} == to_sql(~SQL"""
    select id, email
    where email = {{email}}
    from users
    """)
  end

  test "can parse multiple queries" do
    email = "john@example.com"
    assert {"select id, email from users where email = ?; select id from users", [email]} == to_sql(~SQL"""
    select id, email
    where email = {{email}}
    from users;
    select id from users
    """)
  end


  describe "error" do
    test "missing )" do
      assert_raise TokenMissingError, ~r"token missing on", fn ->
        SQL.parse("select id in (1, 2")
      end
      assert_raise TokenMissingError, ~r"token missing on", fn ->
        SQL.parse("select id from users join orgs on (id = id")
      end
    end

    test "missing ]" do
      assert_raise TokenMissingError, ~r"token missing on", fn ->
        SQL.parse("select id in ([1)")
      end
      assert_raise TokenMissingError, ~r"token missing on", fn ->
        SQL.parse("select id from users join orgs on ([1)")
      end
    end

    test "missing }" do
      assert_raise TokenMissingError, ~r"token missing on", fn ->
        SQL.parse("select id in {{1")
      end
      assert_raise TokenMissingError, ~r"token missing on", fn ->
        SQL.parse("select id from users join orgs on {{id")
      end
    end

    test "missing \"" do
      assert_raise TokenMissingError, ~r"token missing on", fn ->
        SQL.parse("select id in \"1")
      end
      assert_raise TokenMissingError, ~r"token missing on", fn ->
        SQL.parse("select id from users join orgs on \"id")
      end
    end

    test "missing \'" do
      assert_raise TokenMissingError, ~r"token missing on", fn ->
        SQL.parse("select id in '1")
      end
      assert_raise TokenMissingError, ~r"token missing on", fn ->
        SQL.parse("select id from users join orgs on 'id")
      end
    end

    test "missing relation" do
      assert capture_io(:stderr, fn -> SQL.parse("select id from users", set_sql_lock()) end) =~ "does not exist"
    end
  end

  describe "functions" do
    test "avg" do
      assert "select avg(id)" == to_string(~SQL[select avg(id)])
    end
    test "any" do
      assert "select any(select *)" == to_string(~SQL[select any(select *)])
    end
    test "all" do
      assert "select all(select *)" == to_string(~SQL[select all(select *)])
    end
    test "count" do
      assert "select count(*)" == to_string(~SQL[select count(*)])
      assert "select count(id)" == to_string(~SQL[select count(id)])
    end
    test "coalesce" do
      assert "select coalesce(a, b)" == to_string(~SQL[select coalesce(a, b)])
    end
    test "exists" do
      assert "select exists(select *)" == to_string(~SQL[select exists(select *)])
    end
    test "min" do
      assert "select min(a, b)" == to_string(~SQL[select min(a, b)])
    end
    test "max" do
      assert "select max(a, b)" == to_string(~SQL[select max(a, b)])
    end
    test "sum" do
      assert "select sum(id)" == to_string(~SQL[select sum(id)])
    end
  end

  describe "with" do
    test "recursive" do
      assert "with recursive temp (n, fact) as (select 0, 1 union all select n + 1, (n + 1) * fact from temp where n < 9)" == to_string(~SQL[with recursive temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)])
    end

    test "regular" do
      assert "with temp (n, fact) as (select 0, 1 union all select n + 1, (n + 1) * fact from temp where n < 9)" == to_string(~SQL[with temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)])
    end

    test "complex with" do
      sql = ~SQL[
      with customer_rankings as(
          from transactions
          group by customer_id
          select customer_id,
                sum(amount) as total_spent,
                rank() over(order by sum(amount) desc) as spending_rank
      ),
      top_customers as(
          from customer_rankings cr
          join customers c on c.customer_id = cr.customer_id
          where cr.spending_rank <= 10
          select c.customer_id,
                c.name,
                cr.total_spent,
                cr.spending_rank
      )
      from top_customers tc
      order by tc.spending_rank
      select tc.name,
            tc.total_spent,
            tc.spending_rank
      ]
      assert "with customer_rankings as (select customer_id, sum(amount) as total_spent, rank() over(order by sum(amount) desc) as spending_rank from transactions group by customer_id), top_customers as (select c.customer_id, c.name, cr.total_spent, cr.spending_rank from customer_rankings cr join customers c on c.customer_id = cr.customer_id where cr.spending_rank <= 10) select tc.name, tc.total_spent, tc.spending_rank from top_customers tc order by tc.spending_rank" == to_string(sql)
    end

    test "complex with multiple ctes" do
      sql = ~SQL[
        with customer_rankings as (
          select
            customer_id,
            sum(amount) as total_spent,
            rank() over (order by sum(amount) desc) as spending_rank
          from transactions
          group by customer_id
        ),
        top_customers as (
          select
            c.customer_id,
            c.name,
            cr.total_spent,
            cr.spending_rank
          from customer_rankings cr
          join customers c on c.customer_id = cr.customer_id
          where cr.spending_rank <= 10
        )
        select
          tc.name,
          tc.total_spent,
          tc.spending_rank,
          case
            when tc.total_spent > tc.avg_amount * 2 then 'High Value'
            when tc.total_spent > tc.avg_amount then 'Medium Value'
            else 'Low Value'
          end as customer_segment
        from top_customers tc
        order by tc.spending_rank, tc.month
      ]
      assert "with customer_rankings as (select customer_id, sum(amount) as total_spent, rank() over (order by sum(amount) desc) as spending_rank from transactions group by customer_id), top_customers as (select c.customer_id, c.name, cr.total_spent, cr.spending_rank from customer_rankings cr join customers c on c.customer_id = cr.customer_id where cr.spending_rank <= 10) select tc.name, tc.total_spent, tc.spending_rank, case when tc.total_spent > tc.avg_amount * 2 then 'High Value' when tc.total_spent > tc.avg_amount then 'Medium Value' else 'Low Value' end as customer_segment from top_customers tc order by tc.spending_rank, tc.month" == to_string(sql)
    end
  end

  describe "combinations" do
    test "except" do
      assert "(select id from users) except (select id from users)" == to_string(~SQL[(select id from users) except (select id from users)])
      assert "(select id from users) except select id from users" == to_string(~SQL[(select id from users) except select id from users])
      assert "select id from users except (select id from users)" == to_string(~SQL[select id from users except (select id from users)])
      assert "select id from users except select id from users" == to_string(~SQL[select id from users except select id from users])

      assert "(select id from users) except all (select id from users)" == to_string(~SQL[(select id from users) except all (select id from users)])
      assert "(select id from users) except all select id from users" == to_string(~SQL[(select id from users) except all select id from users])
      assert "select id from users except all (select id from users)" == to_string(~SQL[select id from users except all (select id from users)])
      assert "select id from users except all select id from users" == to_string(~SQL[select id from users except all select id from users])
    end

    test "intersect" do
      assert "(select id from users) intersect (select id from users)" == to_string(~SQL[(select id from users) intersect (select id from users)])
      assert "(select id from users) intersect select id from users" == to_string(~SQL[(select id from users) intersect select id from users])
      assert "select id from users intersect (select id from users)" == to_string(~SQL[select id from users intersect (select id from users)])
      assert "select id from users intersect select id from users" == to_string(~SQL[select id from users intersect select id from users])

      assert "(select id from users) intersect all (select id from users)" == to_string(~SQL[(select id from users) intersect all (select id from users)])
      assert "(select id from users) intersect all select id from users" == to_string(~SQL[(select id from users) intersect all select id from users])
      assert "select id from users intersect all (select id from users)" == to_string(~SQL[select id from users intersect all (select id from users)])
      assert "select id from users intersect all select id from users" == to_string(~SQL[select id from users intersect all select id from users])
    end

    test "union" do
      assert "(select id from users) union (select id from users)" == to_string(~SQL[(select id from users) union (select id from users)])
      assert "(select id from users) union select id from users" == to_string(~SQL[(select id from users) union select id from users])
      assert "select id from users union (select id from users)" == to_string(~SQL[select id from users union (select id from users)])
      assert "select id from users union select id from users" == to_string(~SQL[select id from users union select id from users])

      assert "(select id from users) union all (select id from users)" == to_string(~SQL[(select id from users) union all (select id from users)])
      assert "(select id from users) union all select id from users" == to_string(~SQL[(select id from users) union all select id from users])
      assert "select id from users union all (select id from users)" == to_string(~SQL[select id from users union all (select id from users)])
      assert "select id from users union all select id from users" == to_string(~SQL[select id from users union all select id from users])
    end
  end

  describe "query" do
    test "select" do
      assert "select id" == to_string(~SQL[select id])
      assert "select id, id as di" == to_string(~SQL[select id, id as di])
      assert "select id, (select id from users) as di" == to_string(~SQL[select id, (select id from users) as di])
      assert "select unknownn" == to_string(~SQL[select unknownn])
      assert "select truee" == to_string(~SQL[select truee])
      assert "select falsee" == to_string(~SQL[select falsee])
      assert "select nulll" == to_string(~SQL[select nulll])
      assert "select isnulll" == to_string(~SQL[select isnulll])
      assert "select notnulll" == to_string(~SQL[select notnulll])
      assert "select ascc" == to_string(~SQL[select ascc])
      assert "select descc" == to_string(~SQL[select descc])
      assert "select distinct id" == to_string(~SQL[select distinct id])
      assert "select distinct on (id, users) id" == to_string(~SQL[select distinct on (id, users) id])
    end

    test "from" do
      assert "from users" == to_string(~SQL[from users])
      assert "from users u, persons p" == to_string(~SQL[from users u, persons p])
      assert "from users u" == to_string(~SQL[from users u])
      assert "from users as u" == to_string(~SQL[from users as u])
      assert "from users u" == to_string(~SQL[from users u])
    end

    test "join" do
      assert "inner join users" == to_string(~SQL[inner join users])
      assert "join users" == to_string(~SQL[join users])
      assert "left outer join users" == to_string(~SQL[left outer join users])
      assert "left join users" == to_string(~SQL[left join users])
      assert "natural join users" == to_string(~SQL[natural join users])
      assert "full join users" == to_string(~SQL[full join users])
      assert "cross join users" == to_string(~SQL[cross join users])
      assert "join users u" == to_string(~SQL[join users u])
      assert "join users on id = id" == to_string(~SQL[join users on id = id])
      assert "join users u on id = id" == to_string(~SQL[join users u on id = id])
      assert "join users on (id = id)" == to_string(~SQL[join users on (id = id)])
      assert "join (select * from users) on (id = id)" == to_string(~SQL[join (select * from users) on (id = id)])
      assert "join (select * from users) u on (id = id)" == to_string(~SQL[join (select * from users) u on (id = id)])
    end

    test "where" do
      assert "where 1 = 2" == to_string(~SQL[where 1 = 2])
      assert "where 1 = 2" == to_string(~SQL[where 1=2])
      assert "where 1 != 2" == to_string(~SQL[where 1 != 2])
      assert "where 1 <> 2" == to_string(~SQL[where 1 <> 2])
      assert "where 1 = 2 and id = users.id and id > 3 or true" == to_string(~SQL[where 1 = 2 and id = users.id and id > 3 or true])
    end

    test "group by" do
      assert "group by id" == to_string(~SQL[group by id])
      assert "group by users.id" == to_string(~SQL[group by users.id])
      assert "group by id, users.id" == to_string(~SQL[group by id, users.id])
    end

    test "having" do
      assert "having 1 = 2" == to_string(~SQL[having 1 = 2])
      assert "having 1 != 2" == to_string(~SQL[having 1 != 2])
      assert "having 1 <> 2" == to_string(~SQL[having 1 <> 2])
    end

    test "order by" do
      assert "order by id" == to_string(~SQL[order by id])
      assert "order by users.id" == to_string(~SQL[order by users.id])
      assert "order by id, users.id, users.id asc, id desc" == to_string(~SQL[order by id, users.id, users.id asc, id desc])
    end

    test "offset" do
      assert "offset 1" == to_string(~SQL[offset 1])
    end

    test "limit" do
      assert "limit 1" == to_string(~SQL[limit 1])
    end

    test "fetch" do
      assert "fetch next from users" == to_string(~SQL[fetch next from users])
      assert "fetch prior from users" == to_string(~SQL[fetch prior from users])
      assert "fetch first from users" == to_string(~SQL[fetch first from users])
      assert "fetch last from users" == to_string(~SQL[fetch last from users])
      assert "fetch absolute 1 from users" == to_string(~SQL[fetch absolute 1 from users])
      assert "fetch relative 1 from users" == to_string(~SQL[fetch relative 1 from users])
      assert "fetch 1 from users" == to_string(~SQL[fetch 1 from users])
      assert "fetch all from users" == to_string(~SQL[fetch all from users])
      assert "fetch forward from users" == to_string(~SQL[fetch forward from users])
      assert "fetch forward 1 from users" == to_string(~SQL[fetch forward 1 from users])
      assert "fetch forward all from users" == to_string(~SQL[fetch forward all from users])
      assert "fetch backward from users" == to_string(~SQL[fetch backward from users])
      assert "fetch backward 1 from users" == to_string(~SQL[fetch backward 1 from users])
      assert "fetch backward all from users" == to_string(~SQL[fetch backward all from users])

      assert "fetch next in users" == to_string(~SQL[fetch next in users])
      assert "fetch prior in users" == to_string(~SQL[fetch prior in users])
      assert "fetch first in users" == to_string(~SQL[fetch first in users])
      assert "fetch last in users" == to_string(~SQL[fetch last in users])
      assert "fetch absolute 1 in users" == to_string(~SQL[fetch absolute 1 in users])
      assert "fetch relative 1 in users" == to_string(~SQL[fetch relative 1 in users])
      assert "fetch 1 in users" == to_string(~SQL[fetch 1 in users])
      assert "fetch all in users" == to_string(~SQL[fetch all in users])
      assert "fetch forward in users" == to_string(~SQL[fetch forward in users])
      assert "fetch forward 1 in users" == to_string(~SQL[fetch forward 1 in users])
      assert "fetch forward all in users" == to_string(~SQL[fetch forward all in users])
      assert "fetch backward in users" == to_string(~SQL[fetch backward in users])
      assert "fetch backward 1 in users" == to_string(~SQL[fetch backward 1 in users])
      assert "fetch backward all in users" == to_string(~SQL[fetch backward all in users])
    end
  end

  describe "datatypes" do
    test "numeric" do
      assert "select 1" == to_string(~SQL[select 1])
      assert "select 1000" == to_string(~SQL[select 1000])
      assert "select -1000" == to_string(~SQL[select -1000])
      assert "select +1000" == to_string(~SQL[select +1000])
      assert "select +10.00" == to_string(~SQL[select +10.00])
      assert "select -10.00" == to_string(~SQL[select -10.00])
    end

    test "identifier" do
      assert "select db.users.id" == to_string(~SQL[select db.users.id])
      assert "select db.users" == to_string(~SQL[select db.users])
      assert "select db" == to_string(~SQL[select db])
    end

    test "quoted" do
      assert "select \"db.users.id\"" == to_string(~SQL[select "db.users.id"])
      assert "select 'db.users'" == to_string(~SQL[select 'db.users'])
      assert "select \"db.users.id\", 'db.users'" == to_string(~SQL[select "db.users.id", 'db.users'])
    end
  end

  describe "interpolation" do
    test "binding" do
      var1 = 1
      var0 = "id"
      var2 = ~SQL[select {{var0}}]
      assert ["id"] == var2.params
      sql = ~SQL[select {{var2}}, {{var1}}]
      assert [var2, 1] == sql.params
      assert "select ?, ?" == to_string(sql)
    end

    test ". syntax" do
      map = %{k: "v"}
      sql = ~SQL[select {{map.k <> "v"}}]
      assert ["vv"] == sql.params
      assert "select ?" == to_string(sql)
    end

    test "code" do
      sql = ~SQL[select {{0}}, {{%{k: 1}}}]
      assert [0, %{k: 1}] == sql.params
      assert "select ?, ?" == to_string(sql)
    end

    test "in" do
      sql = ~SQL"select {{1}} in {{[1, 2]}}"
      assert [1, [1, 2]] == sql.params
      assert "select ? in ?" == to_string(sql)

      sql = ~SQL"select {{1}} not in {{[1, 2]}}"
      assert [1, [1, 2]] == sql.params
      assert "select ? not in ?" == to_string(sql)
    end

    test "mixin" do
      for email <- ["1@example.com", "2@example.com", "3@example.com"] do
        sql = from() |> ~SQL[select id, email, inserted_at, updated_at] |> where(email)
        assert {"select id, email, inserted_at, updated_at from ? u where u.email = ?", ["users", email]} == SQL.to_sql(sql)
      end
    end
  end

  describe "operators" do
    test "=" do
      assert "where id = 1" == to_string(~SQL[where id = 1])
      assert "where id = 1" == to_string(~SQL[where id=1])
    end
    test "-" do
      assert "where id - 1" == to_string(~SQL[where id - 1])
      assert "where id - 1" == to_string(~SQL[where id-1])
    end
    test "+" do
      assert "where id + 1" == to_string(~SQL[where id + 1])
      assert "where id + 1" == to_string(~SQL[where id+1])
    end
    test "*" do
      assert "where id * 1" == to_string(~SQL[where id * 1])
      assert "where id * 1" == to_string(~SQL[where id*1])
    end
    test "/" do
      assert "where id / 1" == to_string(~SQL[where id / 1])
      assert "where id / 1" == to_string(~SQL[where id/1])
    end
    test "<>" do
      assert "where id <> 1" == to_string(~SQL[where id <> 1])
      assert "where id <> 1" == to_string(~SQL[where id<>1])
    end
    test ">" do
      assert "where id > 1" == to_string(~SQL[where id > 1])
      assert "where id > 1" == to_string(~SQL[where id>1])
    end
    test "<" do
      assert "where id < 1" == to_string(~SQL[where id < 1])
      assert "where id < 1" == to_string(~SQL[where id<1])
    end
    test ">=" do
      assert "where id >= 1" == to_string(~SQL[where id >= 1])
      assert "where id >= 1" == to_string(~SQL[where id>=1])
    end
    test "<=" do
      assert "where id <= 1" == to_string(~SQL[where id <= 1])
      assert "where id <= 1" == to_string(~SQL[where id<=1])
    end
    test "between" do
      assert "where id between 1 and 2" == to_string(~SQL[where id between 1 and 2])
      assert "where id not between 1 and 2" == to_string(~SQL[where id not between 1 and 2])
      assert "where id between symmetric 1 and 2" == to_string(~SQL[where id between symmetric 1 and 2])
      assert "where id not between symmetric 1 and 2" == to_string(~SQL[where id not between symmetric 1 and 2])
      assert "where id between asymmetric 1 and 2" == to_string(~SQL[where id between asymmetric 1 and 2])
      assert "where id not between asymmetric 1 and 2" == to_string(~SQL[where id not between asymmetric 1 and 2])
    end
    test "like" do
      assert "where id like 1" == to_string(~SQL[where id like 1])
    end
    test "ilike" do
      assert "where id ilike 1" == to_string(~SQL[where id ilike 1])
    end
    test "in" do
      assert "where id in (1, 2)" == to_string(~SQL[where id in (1, 2)])
    end
    test "is" do
      assert "where id is null" == to_string(~SQL[where id is null])
      assert "where id is false" == to_string(~SQL[where id is false])
      assert "where id is true" == to_string(~SQL[where id is true])
      assert "where id is unknown" == to_string(~SQL[where id is unknown])

      assert "where id is not null" == to_string(~SQL[where id is not null])
      assert "where id is not false" == to_string(~SQL[where id is not false])
      assert "where id is not true" == to_string(~SQL[where id is not true])
      assert "where id is not unknown" == to_string(~SQL[where id is not unknown])

      assert "where id is distinct from 1" == to_string(~SQL[where id is distinct from 1])
      assert "where id is not distinct from 1" == to_string(~SQL[where id is not distinct from 1])

      assert "where id isnull" == to_string(~SQL[where id isnull])
      assert "where id notnull" == to_string(~SQL[where id notnull])
    end
    test "as" do
      assert "select id as dd" == to_string(~SQL[select id as dd])
    end
  end
end
