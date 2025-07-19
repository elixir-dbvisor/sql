# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Adapters.PostgresTest do
  use ExUnit.Case, async: true
  use SQL, adapter: SQL.Adapters.Postgres

  describe "with" do
    test "recursive" do
      assert "with recursive temp (n, fact) as (select 0, 1 union all select n + 1, (n + 1) * fact from temp where n < 9)" == to_string(~SQL[with recursive temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)])
    end

    test "regular" do
      assert "with temp (n, fact) as (select 0, 1 union all select n + 1, (n + 1) * fact from temp where n < 9)" == to_string(~SQL[with temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)])
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

    test "qouted" do
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
      assert "select $1, $2" == to_string(sql)
    end

    test ". syntax" do
      map = %{k: "v"}
      sql = ~SQL[select {{map.k <> "v"}}]
      assert ["vv"] == sql.params
      assert "select $1" == to_string(sql)
    end

    test "code" do
      sql = ~SQL[select {{0}}, {{%{k: 1}}}]
      assert [0, %{k: 1}] == sql.params
      assert "select $1, $2" == to_string(sql)
    end

    test "in" do
      sql = ~SQL"select {{1}} in {{[1, 2]}}"
      assert [1, [1, 2]] == sql.params
      assert "select $1 = ANY($2)" == to_string(sql)

      sql = ~SQL"select {{1}} not in {{[1, 2]}}"
      assert [1, [1, 2]] == sql.params
      assert "select $1 != ANY($2)" == to_string(sql)
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
    test "<<" do
      assert "where id << 1" == to_string(~SQL[where id << 1])
    end
    test "&<" do
      assert "where id &< 1" == to_string(~SQL[where id &< 1])
    end
    test "&&" do
      assert "where id && 1" == to_string(~SQL[where id && 1])
    end
    test "&>" do
      assert "where id &> 1" == to_string(~SQL[where id &> 1])
    end
    test ">>" do
      assert "where id >> 1" == to_string(~SQL[where id >> 1])
    end
    test "~=" do
      assert "where id ~= 1" == to_string(~SQL[where id ~= 1])
    end
    test "@>" do
      assert "where id @> 1" == to_string(~SQL[where id @> 1])
    end
    test "<@" do
      assert "where id <@ 1" == to_string(~SQL[where id <@ 1])
    end
    test "&<|" do
      assert "where id &<| 1" == to_string(~SQL[where id &<| 1])
    end
    test "<<|" do
      assert "where id <<| 1" == to_string(~SQL[where id <<| 1])
    end
    test "|>>" do
      assert "where id |>> 1" == to_string(~SQL[where id |>> 1])
    end
    test "|&>" do
      assert "where id |&> 1" == to_string(~SQL[where id |&> 1])
    end
    test "@@" do
      assert "where id @@ 1" == to_string(~SQL[where id @@ 1])
    end
    test ">>=" do
      assert "where id >>= 1" == to_string(~SQL[where id >>= 1])
    end
    test "-|-" do
      assert "where id -|- 1" == to_string(~SQL[where id -|- 1])
    end
    test "between" do
      assert "where id between 1 and 2" == to_string(~SQL[where id between 1 and 2])
      assert "where id not between 1 and 2" == to_string(~SQL[where id not between 1 and 2])
      assert "where id between symmetric 1 and 2" == to_string(~SQL[where id between symmetric 1 and 2])
      assert "where id not between symmetric 1 and 2" == to_string(~SQL[where id not between symmetric 1 and 2])
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
