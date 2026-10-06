<!--
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor
-->

# `~SQL`

<!-- MDOC !-->

`~SQL` provides **state-of-the-art, high-performance SQL integration for Elixir**, built to handle extreme concurrency with **unmatched expressiveness and ergonomic query composition**. Write **safe, composable, parameterized queries** directly, without translating to Ecto or any ORM.

`~SQL` is a **foreign language integration**, letting you write SQL naturally while Elixir handles **transactions, concurrency, and query planning** for you. Unlike typical ORMs, SQL scales **diagonally on the BEAM**, fully leveraging multicore hardware under load.


### Highlights

- **Extreme Concurrency:** Hundreds of processes can execute queries simultaneously without pool contention or mailbox bottlenecks.
- **Diagonal Scaling:** Utilizes BEAM scheduler affinity and C-level concurrency to maximize throughput far beyond traditional connection pool limits.
- **SOTA Performance Across Languages:** Reaches throughput and latency targets rarely seen outside low-level native drivers (Rust `tokio-postgres`, Go `pgx`, Java `HikariCP`, Python `asyncpg`) by eliminating Erlang reduction overhead and heap allocation churn.
- **Deterministic Queue Control:** Strict, configurable queue timeouts prevent cascading failures, head-of-line blocking, and connection pool starvation under load.
- **Composable Queries:** No need to remember `SELECT` vs `FROM` order—queries are fully composable via `~SQL`.
- **Safe Interpolation:** Automatically parameterized queries; no need to manually handle fragments or `?`.
- **Ergonomic & Expressive:** Intuitive syntax for queries, transactions, and mapping result sets.
- **Streaming Large Datasets:** Efficiently stream millions of rows without blocking memory or reducing concurrency.

### Deterministic Queue Control & Load Shedding
Standard connection pools often suffer from head-of-line blocking and cascading latency spikes when starved under heavy load. `~SQL` fundamentally avoids this by structurally enforcing strict, user-configurable queue timeouts.

Performance bounds and failure modes are entirely within your control. You can configure timeouts globally at the pool level or dynamically on a per-query basis. When the pool is exhausted, `~SQL` respects your explicit queue limits and instantly sheds excess load exactly when instructed, protecting the BEAM node from resource exhaustion and keeping latency deterministic.

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
  ~SQL"SELECT g, repeat(md5(g::text), 4) FROM generate_series(1, 5000000) AS g"
  |> SQL.stream()
  |> Stream.run()
end
```

## Pool configuration

```elixir
  config :sql, pools: [
    default: [
      username: "postgres",
      password: "postgres",
      hostname: "localhost",
      database: "sql",
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

## Syntax highlighting

Override keyword, literal, enclosed, and error colors in `config.exs`:

```elixir
config :sql, :syntax_colors,
  keyword: IO.ANSI.magenta(),
  literal: IO.ANSI.yellow(),
  enclosed: IO.ANSI.green(),
  error: IO.ANSI.red()
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
    (sql 0.6.0) lib/sql.ex:225: SQL.__inspect__/3
    (sql 0.6.0) lib/sql.ex:115: SQL.build/4
    (elixir 1.20.0) src/elixir_dispatch.erl:263: :elixir_dispatch.expand_macro_fun/7
    (elixir 1.20.0) src/elixir_dispatch.erl:122: :elixir_dispatch.dispatch_import/6
    (elixir 1.20.0) src/elixir_clauses.erl:192: :elixir_clauses.def/3
    (elixir 1.20.0) src/elixir_def.erl:218: :elixir_def."-store_definition/10-lc$^0/1-0-"/3
    (elixir 1.20.0) src/elixir_def.erl:219: :elixir_def.store_definition/10
```

## Benchmark: Real Concurrency & Bounded Latency (`sql_bench`)

Standard microbenchmarking tools often report flawed iterations per second by failing to distinguish between successful transactions and unhandled queue failures under connection starvation. To measure true database driver performance under real-world pressure, SQL is evaluated using the [sql_bench](https://github.com/elixir-dbvisor/sql_bench) suite.   
Tests track total **successful request throughput**, **p50/p99 latency distributions**, and **load-shedding error handling** across variable worker concurrency levels (C=1 to C=500).   
**Hardware Setup:** Apple M1 Max (10 CPU cores, 64 GB RAM)
**VM Configuration:** Erlang/OTP 28 running 10 BEAM Schedulers

#### Benchmark Summary
| Scenario                                        | Concurrency (C) | SQL p50      | Ecto p50 | Throughput / Behavior                            |
| ----------------------------------------------- | --------------- | ------------ | -------- |------------------------------------------------- |
| Empty Transaction (`BEGIN; COMMIT;`)            | C=1             | **12 µs**    | 80 µs    | **6.7x faster** latency                          |
| Empty Transaction                               | C=100           | **1.1 ms**   | 2.2 ms   | **+90.8k successful requests** (~2x throughput)  |
| Simple Transaction (`BEGIN; SELECT 1; COMMIT;`) | C=20            | **468 µs**   | 770 µs   | **+35.5k successful requests** (1.6x throughput) |
| Savepoints (Nested)                             | C=1             | **72 µs**    | 165 µs   | **2.3x faster** latency                          |
| Cursor Fetch (`FETCH 100`)                      | C=100           | **58.6 ms**  | 227.4 ms | **3.9x faster** latency                          |
| Heavy Schema Query                              | C=500           | **111.2 ms** | 1,100 ms | **Bounded latency** via deterministic fast-fail  |

#### Key Benchmark Insights

- **Microsecond Latency Floor:** For single-worker operations (C=1), SQL achieves a p50 latency of **12 µs** on empty transactions, eliminating VM term serialization overhead.
- **Double High-Concurrency Throughput:** At C=100, SQL processes 181,000+ successful transactions per benchmark run compared to Ecto's ~90,000, maintaining sub-2.5 ms latencies under heavy worker contention.
- **Graceful Degradation vs Queue Ballooning:** When fetching heavy metadata tables under extreme worker stress (C=500), standard drivers queue unboundedly, driving p50 latency to 1.1s and p99 past 2.0s. SQL strictly enforces queue timeout limits, shedding excess load instantly while preserving a 111.2 ms p50 latency for served queries.

You can find the benchmark suite [here](https://github.com/elixir-dbvisor/sql_bench)

## Installation

The package can be installed by adding `sql` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sql, "~> 0.6.0"}
  ]
end
```

Documentation can be found at <https://hexdocs.pm/sql>.
