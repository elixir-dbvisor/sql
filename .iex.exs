# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Repo do
  use Ecto.Repo, otp_app: :sql, adapter: Ecto.Adapters.Postgres
  use SQL, adapter: SQL.Adapters.Postgres, repo: __MODULE__

  def list_ids() do
    ~SQL[select 1 as id]
    |> SQL.map(fn row, columns, repo -> repo.load(%{id: :integer}, {columns, row}) end)
    |> SQL.map(fn row -> row.id end)
    |> Enum.map(fn v -> v end)
  end
end
Application.put_env(:sql, :driver, Postgrex)
Application.put_env(:sql, :username, "postgres")
Application.put_env(:sql, :password, "postgres")
Application.put_env(:sql, :hostname, "localhost")
Application.put_env(:sql, :database, "sql_test#{System.get_env("MIX_TEST_PARTITION")}")
Application.put_env(:sql, :adapter, SQL.Adapters.Postgres)
Application.put_env(:sql, :ecto_repos, [SQL.Repo])
Application.put_env(:sql, SQL.Repo, username: "postgres", password: "postgres", hostname: "localhost", database: "sql_test#{System.get_env("MIX_TEST_PARTITION")}", pool: Ecto.Adapters.SQL.Sandbox, pool_size: 10)
Mix.Tasks.Ecto.Create.run(["-r", "SQL.Repo"])
SQL.Repo.start_link()
import SQL
alias SQL.BNF
