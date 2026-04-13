# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.ParserAdvancedTest do
  use ExUnit.Case, async: true
  import SQL

  describe "subqueries" do
    test "subquery in SELECT" do
      sql = ~SQL[select id, (select count(*) from orders where orders.user_id = users.id) as order_count from users]
      assert String.contains?(to_string(sql), "select")
      assert String.contains?(to_string(sql), "order_count")
    end

    test "subquery in FROM" do
      sql = ~SQL[select * from (select id, name from users where active = true) as active_users]
      assert String.contains?(to_string(sql), "active_users")
    end

    test "subquery in WHERE with IN" do
      sql = ~SQL[select * from users where id in (select user_id from orders)]
      assert String.contains?(to_string(sql), "in")
    end

    test "subquery in WHERE with EXISTS" do
      sql = ~SQL[select * from users where exists (select 1 from orders where orders.user_id = users.id)]
      assert String.contains?(to_string(sql), "exists")
    end

    test "correlated subquery" do
      sql = ~SQL[select u.* from users u where u.salary > (select avg(salary) from users where department_id = u.department_id)]
      assert String.contains?(to_string(sql), "avg")
    end
  end

  describe "window functions" do
    test "basic window function" do
      sql = ~SQL[select id, row_number() over() from users]
      assert String.contains?(to_string(sql), "over")
    end

    test "window function with partition" do
      sql = ~SQL[select id, row_number() over(partition by department_id) from users]
      assert String.contains?(to_string(sql), "partition")
    end

    test "window function with order by" do
      sql = ~SQL[select id, rank() over(order by salary desc) from users]
      assert String.contains?(to_string(sql), "rank")
    end

    test "window function with partition and order" do
      sql = ~SQL[select id, dense_rank() over(partition by department_id order by salary desc) from users]
      assert String.contains?(to_string(sql), "dense_rank")
    end

    test "named window" do
      sql = ~SQL[select id, sum(amount) over w from orders window w as (partition by user_id order by created_at)]
      assert String.contains?(to_string(sql), "window")
    end

    test "lead/lag functions" do
      sql = ~SQL[select id, lead(price, 1) over (order by date) from stocks]
      assert String.contains?(to_string(sql), "lead")
    end

    test "first_value/last_value functions" do
      sql = ~SQL[select id, first_value(name) over (partition by category order by date) from products]
      assert String.contains?(to_string(sql), "first_value")
    end

    test "ntile function" do
      sql = ~SQL[select id, ntile(4) over (order by score desc) from students]
      assert String.contains?(to_string(sql), "ntile")
    end
  end

  describe "complex expressions" do
    test "CASE expression" do
      sql = ~SQL[select case when status = 'active' then 'Active' when status = 'inactive' then 'Inactive' else 'Unknown' end from users]
      assert String.contains?(to_string(sql), "case")
      assert String.contains?(to_string(sql), "when")
      assert String.contains?(to_string(sql), "then")
      assert String.contains?(to_string(sql), "else")
      assert String.contains?(to_string(sql), "end")
    end

    test "simple CASE expression" do
      sql = ~SQL[select case status when 'a' then 'Active' when 'i' then 'Inactive' end from users]
      assert String.contains?(to_string(sql), "case")
    end

    test "COALESCE function" do
      sql = ~SQL[select coalesce(name, 'Unknown') from users]
      assert String.contains?(to_string(sql), "coalesce")
    end

    test "NULLIF function" do
      sql = ~SQL[select nullif(value, 0) from data]
      assert String.contains?(to_string(sql), "nullif")
    end

    test "CAST expression" do
      sql = ~SQL[select cast(id as varchar) from users]
      assert String.contains?(to_string(sql), "cast")
    end

    test "nested CASE expressions" do
      sql = ~SQL[select case when a > 0 then case when b > 0 then 'both' else 'a only' end else 'neither' end from t]
      assert String.contains?(to_string(sql), "case")
    end
  end

  describe "aggregate functions" do
    test "COUNT" do
      assert "select count(*)" == to_string(~SQL[select count(*)])
      assert "select count(id)" == to_string(~SQL[select count(id)])
      assert "select count(distinct id)" == to_string(~SQL[select count(distinct id)])
    end

    test "SUM" do
      assert "select sum(amount)" == to_string(~SQL[select sum(amount)])
    end

    test "AVG" do
      assert "select avg(price)" == to_string(~SQL[select avg(price)])
    end

    test "MIN and MAX" do
      assert "select min(value)" == to_string(~SQL[select min(value)])
      assert "select max(value)" == to_string(~SQL[select max(value)])
    end

    test "aggregate with filter" do
      sql = ~SQL[select count(*) filter (where active = true) from users]
      assert String.contains?(to_string(sql), "filter")
    end

    test "string_agg" do
      sql = ~SQL[select string_agg(name, ', ') from users]
      assert String.contains?(to_string(sql), "string_agg")
    end

    test "array_agg" do
      sql = ~SQL[select array_agg(id) from users]
      assert String.contains?(to_string(sql), "array_agg")
    end
  end

  describe "multiple joins" do
    test "multiple inner joins" do
      sql = ~SQL[select * from users join orders on users.id = orders.user_id join products on orders.product_id = products.id]
      assert String.contains?(to_string(sql), "join")
    end

    test "mixed join types" do
      sql = ~SQL[select * from users left join orders on users.id = orders.user_id inner join products on orders.product_id = products.id]
      assert String.contains?(to_string(sql), "left join")
      assert String.contains?(to_string(sql), "inner join")
    end

    test "self join" do
      sql = ~SQL[select e.name, m.name as manager from employees e left join employees m on e.manager_id = m.id]
      assert String.contains?(to_string(sql), "left join")
    end

    test "join with USING" do
      sql = ~SQL[select * from users join profiles using (user_id)]
      assert String.contains?(to_string(sql), "using")
    end

    test "lateral join" do
      sql = ~SQL[select * from users, lateral (select * from orders where orders.user_id = users.id limit 3) as recent_orders]
      assert String.contains?(to_string(sql), "lateral")
    end
  end

  describe "set operations" do
    test "UNION" do
      assert "(select id from users) union (select id from admins)" == to_string(~SQL[(select id from users) union (select id from admins)])
    end

    test "UNION ALL" do
      assert "(select id from users) union all (select id from admins)" == to_string(~SQL[(select id from users) union all (select id from admins)])
    end

    test "INTERSECT" do
      assert "(select id from users) intersect (select id from admins)" == to_string(~SQL[(select id from users) intersect (select id from admins)])
    end

    test "EXCEPT" do
      assert "(select id from users) except (select id from admins)" == to_string(~SQL[(select id from users) except (select id from admins)])
    end

    test "multiple set operations" do
      sql = ~SQL[(select id from a) union (select id from b) union (select id from c)]
      assert String.contains?(to_string(sql), "union")
    end
  end

  describe "DISTINCT and ORDER BY" do
    test "DISTINCT" do
      assert "select distinct name" == to_string(~SQL[select distinct name])
    end

    test "DISTINCT ON" do
      assert "select distinct on (category) id, name" == to_string(~SQL[select distinct on (category) id, name])
    end

    test "ORDER BY with multiple columns" do
      assert "order by name asc, created_at desc" == to_string(~SQL[order by name asc, created_at desc])
    end

    test "ORDER BY with NULLS FIRST/LAST" do
      sql = ~SQL[order by name nulls first]
      assert String.contains?(to_string(sql), "nulls")
    end
  end

  describe "LIMIT and OFFSET" do
    test "LIMIT" do
      assert "limit 10" == to_string(~SQL[limit 10])
    end

    test "OFFSET" do
      assert "offset 20" == to_string(~SQL[offset 20])
    end

    test "LIMIT with OFFSET" do
      sql = ~SQL[select * from users limit 10 offset 20]
      assert String.contains?(to_string(sql), "limit")
      assert String.contains?(to_string(sql), "offset")
    end

    test "FETCH FIRST/NEXT" do
      sql = ~SQL[fetch first 10 rows only]
      assert String.contains?(to_string(sql), "fetch")
    end
  end

  describe "complex queries" do
    test "query with all clauses" do
      sql = ~SQL[
        select u.id, u.name, count(o.id) as order_count
        from users u
        left join orders o on u.id = o.user_id
        where u.active = true
        group by u.id, u.name
        having count(o.id) > 5
        order by order_count desc
        limit 10
      ]
      result = to_string(sql)
      assert String.contains?(result, "select")
      assert String.contains?(result, "from")
      assert String.contains?(result, "join")
      assert String.contains?(result, "where")
      assert String.contains?(result, "group by")
      assert String.contains?(result, "having")
      assert String.contains?(result, "order by")
      assert String.contains?(result, "limit")
    end
  end
end
