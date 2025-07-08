# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Adapters.Postgres do
  @moduledoc """
    A SQL adapter for [PostgreSQL](https://www.postgresql.org).
  """
  @moduledoc since: "0.2.0"

  use SQL.Token

  @doc false
  def token_to_string(value, mod \\ __MODULE__)
  def token_to_string({:not, _, [left, {:in, _, [{:binding, _, _} = right]}]}, mod), do: "#{mod.token_to_string(left)} != ANY(#{mod.token_to_string(right)})"
  def token_to_string({:in, _, [left, {:binding, _, _} = right]}, mod), do: "#{mod.token_to_string(left)} = ANY(#{mod.token_to_string(right)})"
  def token_to_string({:binding, _, [idx]}, _mod) when is_integer(idx), do: "$#{idx}"
  def token_to_string({tag, _, [left, right]}, mod) when tag in ~w[>>=]a do
      "#{mod.token_to_string(left)} #{mod.token_to_string(tag)} #{mod.token_to_string(right)}"
  end
  def token_to_string(token, mod), do: SQL.Adapters.ANSI.token_to_string(token, mod)
end
