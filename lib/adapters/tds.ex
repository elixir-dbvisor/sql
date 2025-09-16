# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Adapters.TDS do
  @moduledoc """
    A SQL adapter for [TDS](https://www.microsoft.com/en-ca/sql-server).
  """
  @moduledoc since: "0.2.0"
  use SQL.Token

  @doc false
  def to_iodata({:binding, m, [idx]}, %{format: true, binding: binding} = context, indent, acc) do
    indention(["{{#{Macro.to_string(Enum.at(binding, idx-1))}}}"|acc], context, m, indent)
  end
  def to_iodata({:binding, m, [idx]}, context, indent, acc) when is_integer(idx), do: indention(["@#{idx}"|acc], context, m, indent)
  def to_iodata(token, context, indent, acc), do: SQL.Adapters.ANSI.to_iodata(token, context, indent, acc)
end
