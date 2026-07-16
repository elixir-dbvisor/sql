# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule Mix.Tasks.Sql.Get do
  use Mix.Task
  import Mix.Generator
  @moduledoc since: "0.3.0"

  @shortdoc "Generates a sql.lock"
  def run(args) do
    app = Mix.Project.config()[:app]
    Application.load(app)
    Mix.Task.run("app.config", args)
    Application.ensure_all_started(:sql, :permanent)
    lock = Enum.reduce(Application.get_env(:sql, :pools), [], &(Module.concat(elem(&1, 1)[:adapter], Queries).columns(elem(&1, 0))++&2))
    create_file("sql.lock", lock_template(lock: lock), force: true)
  end

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
