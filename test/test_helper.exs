# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Repo do
  use Ecto.Repo, otp_app: :sql, adapter: Ecto.Adapters.Postgres
end
defmodule SQLTest.Helpers do
  def validate([[[[[], b1], b2], b3],b4], _) when b1 in ~c"tT" and  b2 in ~c"eE" and  b3 in ~c"sS" and b4 in ~c"tT", do: true
  def validate(_, _), do: false
  def set_validate(context \\ %{}), do: Map.merge(context, %{validate: &validate/2, module: SQL.Adapters.ANSI})
end
ExUnit.start()
