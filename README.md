<!--
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor
-->

# SQL

<!-- MDOC !-->

Brings an extensible SQL parser and sigil to Elixir, confidently write SQL with automatic parameterized queries.

- Lower the barrier for DBAs to contribute in your codebase, without having to translate SQL to Ecto.Query.
- Composable queries, no need for you to remember, when to start with select or from.
- Interpolation-al queries, don't fiddle with fragments and `?`.

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

```elixir
  defmodule MyApp.Accounts do
    use SQL, adapter: SQL.Adapters.Postgres, repo: MyApp.Repo

    def list_users() do
      ~SQL[from users select *]
      |> SQL.map(fn row, columns, repo -> repo.load(User, {columns, row}) end)
      |> Enum.to_list()
    end
  end

  iex(1)> MyApp.Accounts.list_users()
  [%User{id: 1, email: "john@example.com"}, %User{id: 2, email: "jane@example.com"}]
```

## Benchmark
You can find benchmark results [here](https://github.com/elixir-dbvisor/sql/benchmarks) or run `mix sql.bench`

## Installation

The package can be installed by adding `sql` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sql, "~> 0.4.0"}
  ]
end
```

Documentation can be found at <https://hexdocs.pm/sql>.
