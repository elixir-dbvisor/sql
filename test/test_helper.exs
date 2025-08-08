# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Repo do
  use Ecto.Repo, otp_app: :sql, adapter: Ecto.Adapters.Postgres
end
defmodule SQLTest.Helpers do
  def table_name([[[[[], b1], b2], b3],b4]) when b1 in ~c"tT" and  b2 in ~c"eE" and  b3 in ~c"sS" and b4 in ~c"tT", do: true
  def table_name(_), do: false
  def set_sql_lock(context \\ %{}), do: Map.merge(context, %{sql_lock: %{tables: [%{table_name: {"test", :test, &table_name/1}}], columns: [%{column_name: {"test", :test, &table_name/1}}]}, module: SQL.Adapters.ANSI})
end
ExUnit.start()
