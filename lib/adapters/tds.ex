# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Adapters.TDS do
  @moduledoc """
    A SQL adapter for [TDS](https://www.microsoft.com/en-ca/sql-server).
  """
  @moduledoc since: "0.2.0"

  use SQL.Token

  @doc false
  def token_to_string(value, mod \\ __MODULE__)
  def token_to_string({:binding, _, [idx]}, _mod) when is_integer(idx), do: "@#{idx}"
  def token_to_string(token, mod), do: SQL.Adapters.ANSI.token_to_string(token, mod)

  @doc false
  def to_iodata({:binding, _, [idx]}, %{format: true, binding: binding}, _indent) do
    [?{,?{,Macro.to_string(Enum.at(binding, idx-1))|[?},?}]]
  end
  def to_iodata({:binding, _, [idx]}, _context, _indent) when is_integer(idx), do: ~c"@#{idx}"
  def to_iodata(token, context, indent), do: SQL.Adapters.ANSI.to_iodata(token, context, indent)
end
