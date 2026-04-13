# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.PostgresSpecificTest do
  use ExUnit.Case, async: true
  use SQL, adapter: SQL.Adapters.Postgres

  describe "postgres specific datatypes" do
    test "UUID type" do
      sql = ~SQL[select uuid from users]
      assert String.contains?(to_string(sql), "uuid")
    end

    test "SERIAL type reference" do
      sql = ~SQL[select id from users where id > 0]
      assert is_binary(to_string(sql))
    end

    test "INET type" do
      sql = ~SQL[select ip_address from logs where ip_address << '192.168.0.0/16']
      assert String.contains?(to_string(sql), "<<")
    end

    test "CIDR type operations" do
      sql = ~SQL[select network from subnets where network >>= '192.168.1.0/24']
      assert String.contains?(to_string(sql), ">>=")
    end

    test "MACADDR type" do
      sql = ~SQL[select mac from devices]
      assert String.contains?(to_string(sql), "mac")
    end

    test "MONEY type" do
      sql = ~SQL[select price::money from products]
      assert String.contains?(to_string(sql), "money")
    end

    test "BYTEA type" do
      sql = ~SQL[select data::bytea from files]
      assert String.contains?(to_string(sql), "bytea")
    end

    test "HSTORE type" do
      sql = ~SQL[select attributes -> 'color' from products]
      assert String.contains?(to_string(sql), "->")
    end

    test "RANGE types" do
      sql = ~SQL[select daterange('2024-01-01', '2024-12-31')]
      assert String.contains?(to_string(sql), "daterange")
    end

    test "geometric types - point" do
      sql = ~SQL[select point(1.0, 2.0)]
      assert String.contains?(to_string(sql), "point")
    end

    test "geometric types - box" do
      sql = ~SQL[select box(point(0,0), point(1,1))]
      assert String.contains?(to_string(sql), "box")
    end

    test "tsvector type" do
      sql = ~SQL[select to_tsvector('english', title)]
      assert String.contains?(to_string(sql), "to_tsvector")
    end

    test "tsquery type" do
      sql = ~SQL[select to_tsquery('english', 'search & term')]
      assert String.contains?(to_string(sql), "to_tsquery")
    end
  end

  describe "postgres specific operators" do
    test "text search match @@" do
      sql = ~SQL[where to_tsvector(content) @@ to_tsquery('search')]
      assert String.contains?(to_string(sql), "@@")
    end

    test "regex match ~" do
      sql = ~SQL[where name ~ '^John']
      assert String.contains?(to_string(sql), "~")
    end

    test "regex match case insensitive ~*" do
      sql = ~SQL[where name ~* '^john']
      assert String.contains?(to_string(sql), "~*")
    end

    test "regex not match !~" do
      sql = ~SQL[where name !~ '^John']
      assert String.contains?(to_string(sql), "!~")
    end

    test "inet containment <<" do
      sql = ~SQL[where ip << '192.168.0.0/16'::inet]
      assert String.contains?(to_string(sql), "<<")
    end

    test "inet contains >>" do
      sql = ~SQL[where '192.168.0.0/16'::inet >> ip]
      assert String.contains?(to_string(sql), ">>")
    end

    test "range adjacent -|-" do
      sql = ~SQL[where daterange -|- daterange2]
      assert String.contains?(to_string(sql), "-|-")
    end
  end

  describe "postgres specific clauses" do
    test "RETURNING clause" do
      sql = ~SQL[insert into users (name) values ('John') returning id, created_at]
      assert String.contains?(to_string(sql), "returning")
    end

    test "ON CONFLICT DO NOTHING" do
      sql = ~SQL[insert into users (email) values ('test@example.com') on conflict do nothing]
      assert String.contains?(to_string(sql), "on conflict")
    end

    test "ON CONFLICT DO UPDATE" do
      sql = ~SQL[insert into users (id, name) values (1, 'John') on conflict (id) do update set name = excluded.name]
      assert String.contains?(to_string(sql), "excluded")
    end

    test "DISTINCT ON" do
      sql = ~SQL[select distinct on (category) * from products order by category, created_at desc]
      assert String.contains?(to_string(sql), "distinct on")
    end

    test "FOR UPDATE" do
      sql = ~SQL[select * from users where id = 1 for update]
      assert String.contains?(to_string(sql), "for update")
    end

    test "FOR SHARE" do
      sql = ~SQL[select * from users where id = 1 for share]
      assert String.contains?(to_string(sql), "for share")
    end

    test "SKIP LOCKED" do
      sql = ~SQL[select * from jobs where status = 'pending' for update skip locked limit 1]
      assert String.contains?(to_string(sql), "skip locked")
    end
  end

  describe "postgres functions" do
    test "generate_series" do
      sql = ~SQL[select * from generate_series(1, 10)]
      assert String.contains?(to_string(sql), "generate_series")
    end

    test "regexp_matches" do
      sql = ~SQL[select regexp_matches(text, 'pattern')]
      assert String.contains?(to_string(sql), "regexp_matches")
    end

    test "regexp_replace" do
      sql = ~SQL[select regexp_replace(text, 'old', 'new')]
      assert String.contains?(to_string(sql), "regexp_replace")
    end

    test "regexp_split_to_array" do
      sql = ~SQL[select regexp_split_to_array(text, ',')]
      assert String.contains?(to_string(sql), "regexp_split_to_array")
    end

    test "coalesce" do
      sql = ~SQL[select coalesce(name, 'Unknown')]
      assert String.contains?(to_string(sql), "coalesce")
    end

    test "nullif" do
      sql = ~SQL[select nullif(value, 0)]
      assert String.contains?(to_string(sql), "nullif")
    end

    test "greatest" do
      sql = ~SQL[select greatest(a, b, c)]
      assert String.contains?(to_string(sql), "greatest")
    end

    test "least" do
      sql = ~SQL[select least(a, b, c)]
      assert String.contains?(to_string(sql), "least")
    end

    test "row_to_json" do
      sql = ~SQL[select row_to_json(users) from users]
      assert String.contains?(to_string(sql), "row_to_json")
    end

    test "json_populate_record" do
      sql = ~SQL[select * from json_populate_record(null::users, '{"id": 1, "name": "John"}')]
      assert String.contains?(to_string(sql), "json_populate_record")
    end

    test "pg_typeof" do
      sql = ~SQL[select pg_typeof(column)]
      assert String.contains?(to_string(sql), "pg_typeof")
    end
  end

  describe "postgres IN optimization" do
    test "IN with array parameter converts to = ANY" do
      items = [1, 2, 3]
      sql = ~SQL[select * from users where id in {{items}}]
      assert String.contains?(to_string(sql), "= ANY($")
    end

    test "NOT IN with array parameter converts to != ANY" do
      items = [1, 2, 3]
      sql = ~SQL[select * from users where id not in {{items}}]
      assert String.contains?(to_string(sql), "!= ANY($")
    end
  end

  describe "unicode identifiers" do
    test "U& syntax for unicode identifiers" do
      sql = ~SQL[select U&"d\0061t\+000061"]
      result = to_string(sql)
      assert String.contains?(result, "u&")
    end

    test "U& syntax for unicode strings" do
      sql = ~SQL[select U&'\0441\043B\043E\043D']
      result = to_string(sql)
      assert String.contains?(result, "u&")
    end

    test "UESCAPE clause" do
      sql = ~SQL[select U&'d!0061t!+000061' UESCAPE '!']
      result = to_string(sql)
      assert String.contains?(result, "uescape")
    end
  end

  describe "binary literals" do
    test "binary format 0b" do
      sql = ~SQL[select 0b100101]
      assert String.contains?(to_string(sql), "0b100101")
    end

    test "octal format 0o" do
      sql = ~SQL[select 0o755]
      assert String.contains?(to_string(sql), "0o755")
    end

    test "hexadecimal format 0x" do
      sql = ~SQL[select 0xFFFF]
      assert String.contains?(to_string(sql), "0xFFFF")
    end

    test "numeric with underscores" do
      sql = ~SQL[select 1_000_000]
      assert String.contains?(to_string(sql), "1_000_000")
    end
  end
end
