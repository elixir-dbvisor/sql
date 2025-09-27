# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule Mix.Tasks.Sql.Get do
  use Mix.Task
  import SQL
  import Mix.Generator
  @moduledoc since: "0.3.0"

  @shortdoc "Generates a sql.lock"
  def run(args) do
    app = Mix.Project.config()[:app]
    Application.load(app)
    repos = Application.get_env(app, :ecto_repos)
    Mix.Task.run("app.config", args)
    Application.ensure_all_started(:ecto_sql, :permanent)
    lock = Enum.reduce(repos, [], fn repo, acc ->
      repo.__adapter__().ensure_all_started(repo.config(), [])
      repo.start_link(repo.config())
      get(repo)++acc
    end)
    create_file("sql.lock", lock_template(lock: lock), force: true)
  end

  defp get(repo) do
    sql = to_query(repo.__adapter__())
    {:ok, %{columns: columns, rows: rows}} = repo.query(to_string(sql), [])
    columns = Enum.map(columns, &String.to_atom(String.downcase(&1)))
    Enum.map(rows, &Map.new(Enum.zip(columns, &1)))
  end

  defp to_query(value) when value in [Ecto.Adapters.Postgres, Postgrex], do: ~SQL"select * from information_schema.columns where table_schema not in ('information_schema', 'pg_catalog')"
  defp to_query(value) when value in [Ecto.Adapters.Tds, Tds], do: ~SQL"select * from information_schema.columns where table_schema not in ('information_schema', 'pg_catalog')"
  defp to_query(value) when value in [Ecto.Adapters.MyXQL, MyXQL], do: ~SQL"select * from information_schema.columns where table_schema not in ('mysql', 'performance_schema', 'sys')"
  defp to_query(value) when value in [Ecto.Adapters.SQLite3, Exqlite], do: ~SQL"select * from sqlite_master join pragma_table_info (sqlite_master.name)"

  embed_template(:lock, """
    %{
      columns: <%= inspect @lock, pretty: true, limit: :infinity %>,
      validate: fn
      <%= for %{table_name: table, column_name: column} <- @lock do %>
        <%= inspect String.to_charlist(table) %>, nil -> true
        <%= inspect String.to_charlist(table) %>, <%= inspect String.to_charlist(column) %> -> true
      <% end %>
      _, _ -> false
      end
    }
  """)
end
