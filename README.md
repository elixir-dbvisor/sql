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
where email = {{email}} from users select id, email
"""
iex(4)> sql = ~SQL[from users where email = {{email}} select id, email]
~SQL"""
from users where email = {{email}} select id, email
"""
iex(5)> to_sql(sql)
{"select id, email from users where email = ?", ["john@example.com"]}
iex(6)> to_string(sql)
"select id, email from users where email = ?"
iex(7)> inspect(sql)
"~SQL\"\"\"\nfrom users where email = {{email}} select id, email\n\"\"\""
```

### Leverage the Enumerable protocol in your repository

```elixir
  defmodule MyApp.Repo do
    use Ecto.Repo, otp_app: :myapp, adapter: Ecto.Adapters.Postgres
    use SQL, adapter: SQL.Adapters.Postgres

    defimpl Enumerable, for: SQL do
      def count(_enumerable) do
        {:error, __MODULE__}
      end
      def member?(_enumerable, _element) do
        {:error, __MODULE__}
      end
      def reduce(%SQL{} = enumerable, _acc, _fun) do
        {sql, params} = SQL.to_sql(enumerable)
        result = __MODULE__.query!(sql, params)
        {:done, Enum.map(result.rows, &Map.new(Enum.zip(result.columns, &1)))}
      end
      def slice(_enumerable) do
        {:error, __MODULE__}
      end
    end
  end

  iex(1)> Enum.map(~SQL[from users select *], &IO.inspect/1)
  %{"id" => 1, "email" => "john@example.com"}
  %{"id" => 2, "email" => "jane@example.com"}
  [%{"id" => 1, "email" => "john@example.com"}, %{"id" => 2, "email" => "jane@example.com"}]
```

## Benchmark
You can find benchmark results [here](benchmarks) or run `mix sql.bench`
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `sql` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sql, "~> 0.2.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/sql>.
