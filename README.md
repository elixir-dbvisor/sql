<!--
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor
-->

# SQL

<!-- MDOC !-->

SQL provides **state-of-the-art, high-performance SQL integration for Elixir**, built to handle extreme concurrency with **unmatched expressiveness and ergonomic query composition**. Write **safe, composable, parameterized queries** directly, without translating to Ecto or any ORM.

SQL is a **foreign language integration**, letting you write SQL naturally while Elixir handles **transactions, concurrency, and query planning** for you. Unlike typical ORMs, SQL scales **diagonally on the BEAM**, fully leveraging multicore hardware under load.


### Highlights

- **Extreme Concurrency:** Hundreds of processes can execute queries simultaneously without blocking pools.
- **Diagonal Scaling:** Utilizes BEAM concurrency to maximize throughput, far beyond traditional connection pool limits.
- **Composable Queries:** No need to remember `SELECT` vs `FROM` order—queries are fully composable via `~SQL`.
- **Safe Interpolation:** Automatically parameterized queries; no need to manually handle fragments or `?`.
- **SOTA Performance Across Languages:** Benchmarks show SQL outperforming Ecto by **orders of magnitude** under heavy load.
- **Ergonomic & Expressive:** Intuitive syntax for queries, transactions, and mapping result sets.
- **Streaming Large Datasets:** Efficiently stream millions of rows without blocking memory or reducing concurrency.

## Examples

```elixir
iex(1)> email = "john@example.com"
"john@example.com"
iex(2)> ~SQL[from users] |> ~SQL[where email = {{email}}] |> ~SQL"select id, email"
~SQL"""
select
  id,
  email
from
  users
where
  email = {{email}}
"""
iex(3)> sql = ~SQL[from users where email = {{email}} select id, email]
~SQL"""
select
  id,
  email
from
  users
where
  email = {{email}}
"""
iex(4)> to_sql(sql)
{"select id, email from users where email = ?", ["john@example.com"]}
iex(5)> to_string(sql)
"select id, email from users where email = ?"
iex(6)> inspect(sql)
"~SQL\"\"\"\nselect\n  id, \n  email\nfrom\n  users\nwhere\n  email = {{email}}\n\"\"\""
```
## Transactions

```elixir
SQL.transaction do
  Enum.to_list(~SQL"select 1")
end
```

Transactions **automatically handle nested savepoints**, rollback, and commit logic, even under extreme concurrency.

## Mapping Results
For custom mapping of rows:

```elixir
~SQL[from users select *]
|> SQL.map(fn row -> struct(User, row) end)
|> Enum.to_list()
```

## Streaming

```elixir
SQL.transaction do
  Stream.run(~SQL"SELECT g, repeat(md5(g::text), 4) FROM generate_series(1, 5000000) AS g")
end
```

## Pool configuration

```elixir
  config :sql, pools: [
    default: [
      username: "postgres",
      password: "postgres",
      hostname: "localhost",
      database: "mydatabase",
      adapter: SQL.Adapters.Postgres,
      ssl: false
    ]
  ]
```

```elixir
  defmodule MyApp.Accounts do
    use SQL, pool: :default
  
    def list_users() do
      ~SQL[from users select *]
      |> SQL.map(fn row -> struct(User, row) end)
      |> Enum.to_list()
    end
  end

  iex(1)> MyApp.Accounts.list_users()
  [%User{id: 1, email: "john@example.com"}, %User{id: 2, email: "jane@example.com"}]
```

## Compile time warning
Run `mix sql.get` to generate your `sql.lock` file for error reporting.

```elixir
  ==> myapp
  Compiling 1 file (.ex)
  warning:
    the relation OPS does not exist
    the relation email is mentioned 2 times but does not exist
    the relation users does not exist
    ~SQL"""
    select
      email,
      1 + "OPS"
    from
      users
    where
      email = 'john@example.com'
    """
    lib/myapp.ex:18: Myapp.list_users/0
    (sql 0.4.0) lib/sql.ex:225: SQL.__inspect__/3
    (sql 0.4.0) lib/sql.ex:115: SQL.build/4
    (elixir 1.20.0-dev) src/elixir_dispatch.erl:263: :elixir_dispatch.expand_macro_fun/7
    (elixir 1.20.0-dev) src/elixir_dispatch.erl:122: :elixir_dispatch.dispatch_import/6
    (elixir 1.20.0-dev) src/elixir_clauses.erl:192: :elixir_clauses.def/3
    (elixir 1.20.0-dev) src/elixir_def.erl:218: :elixir_def."-store_definition/10-lc$^0/1-0-"/3
    (elixir 1.20.0-dev) src/elixir_def.erl:219: :elixir_def.store_definition/10
```

## Benchmark: Extreme Concurrency & Diagonal Scaling
SQL is **not just fast**—it’s a **breakthrough in high-concurrency database integration**. Benchmarks were run with **500 parallel processes executing transactions simultaneously** on a **pool of 10 connections**, something most ORMs—including Ecto—cannot handle.
- **SQL** executes **thousands of transactions per second**, scaling **diagonally with BEAM concurrency**, fully utilizing cores without pool bottlenecks.
- **Ecto**, under the same conditions, falls behind by **orders of magnitude**, struggling with queueing, blocking, and memory overhead.

| Metric               | SQL     | Ecto     | Improvement          |
| -------------------- | ------- | -------- | -------------------- |
| Iterations/sec (IPS) | 5507.15 | 56.22    | ~98x faster          |
| Memory Usage         | 984 B   | 17,952 B | 18x lighter          |
| Reductions Count     | 0.092 K | 1.56 K   | 17x fewer reductions |

You can find benchmark results [here](https://github.com/elixir-dbvisor/sql/benchmarks) or run `mix sql.bench`

## Installation

The package can be installed by adding `sql` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sql, "~> 0.5.0"}
  ]
end
```

Documentation can be found at <https://hexdocs.pm/sql>.
