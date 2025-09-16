# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Adapters.Postgres do
  @moduledoc """
    A SQL adapter for [PostgreSQL](https://www.postgresql.org).
  """
  @moduledoc since: "0.2.0"
  use SQL.Token

  @doc false
  def to_iodata({:in, m, [{:not, _, left}, {:binding, _, [idx]}]}, context, indent, acc) do
    context.module.to_iodata(left, context, indent, indention(["!= ANY($#{idx})"|acc], context, m, indent))
  end
  def to_iodata({:in, m, [left, {:binding, _, [idx]} ]}, context, indent, acc) do
    context.module.to_iodata(left, context, indent, indention(["= ANY($#{idx})"|acc], context, m, indent))
  end
  def to_iodata({:binding, m, [idx]}, %{format: true, binding: binding}=context, indent, acc) do
    indention(["{{#{Macro.to_string(Enum.at(binding, idx-1))}}}"|acc], context, m, indent)
  end
  def to_iodata({:binding, m, [idx]}, context, indent, acc) do
    indention(["$#{idx}"|acc], context, m, indent)
  end
  def to_iodata(token, context, indent, acc), do: SQL.Adapters.ANSI.to_iodata(token, context, indent, acc)
end
