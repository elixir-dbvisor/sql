# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Adapters.ANSI do
  @moduledoc """
    A SQL adapter for [ANSI](https://blog.ansi.org/sql-standard-iso-iec-9075-2023-ansi-x3-135/).
  """
  @moduledoc since: "0.2.0"

  use SQL.Token

  @doc false
  def token_to_string(value, mod \\ __MODULE__)
  def token_to_string(value, _mod) when is_struct(value) do
    to_string(value)
  end
  def token_to_string({:as, [], [left, right]}, mod) do
    "#{mod.token_to_string(left)} #{mod.token_to_string(right)}"
  end
  def token_to_string({tag, _, [left]}, mod) when tag in ~w[asc desc isnull notnull]a do
    "#{mod.token_to_string(left)} #{mod.token_to_string(tag)}"
  end
  def token_to_string({:fun, _, [left, right]}, mod) do
    "#{mod.token_to_string(left)}#{mod.token_to_string(right)}"
  end
  def token_to_string({:ident, [{:keyword, :non_reserved},{:tag, tag}|_], [{:paren, _, _} = value]}, mod) do
    "#{mod.token_to_string(tag)}#{mod.token_to_string(value)}"
  end
  def token_to_string({:ident, [{:keyword, :non_reserved}, {:tag, tag}|_], [{:numeric, _, _} = value]}, mod) do
    "#{mod.token_to_string(tag)} #{mod.token_to_string(value)}"
  end
  def token_to_string({:ident, [{:keyword, :non_reserved}, {:tag, tag}|_], _}, mod) do
      mod.token_to_string(tag)
  end
  def token_to_string({tag, [{:keyword, :reserved}|_], [{:paren, _, _} = value]}, mod) when tag not in ~w[on as in select]a do
    "#{mod.token_to_string(tag)}#{mod.token_to_string(value)}"
  end
  def token_to_string({tag, [{:keyword, :reserved}|_], []}, mod) do
    mod.token_to_string(tag)
  end
  def token_to_string({tag, _, [left, {:all = t, _, right}]}, mod) when tag in ~w[union except intersect]a do
    "#{mod.token_to_string(left)} #{mod.token_to_string(tag)} #{mod.token_to_string(t)} #{mod.token_to_string(right)}"
  end
  def token_to_string({:between = tag, _, [{:not = t, _, right}, left]}, mod) do
    "#{mod.token_to_string(right)} #{mod.token_to_string(t)} #{mod.token_to_string(tag)} #{mod.token_to_string(left)}"
  end
  def token_to_string({:binding, _, [idx]}, _mod) when is_integer(idx) do
    "?"
  end
  def token_to_string({:binding, _, value}, _mod) do
    "{{#{value}}}"
  end
  def token_to_string({:comment, _, value}, _mod) do
    "--#{value}"
  end
  def token_to_string({:comments, _, value}, _mod) do
    "\\*#{value}*\\"
  end
  def token_to_string({:double_quote, _, value}, _mod) do
    "\"#{value}\""
  end
  def token_to_string({:quote, _, value}, _mod) do
    "'#{value}'"
  end
  def token_to_string({:paren, _, value}, mod) do
    "(#{mod.token_to_string(value)})"
  end
  def token_to_string({:bracket, _, value}, mod) do
    "[#{mod.token_to_string(value)}]"
  end
  def token_to_string({:colon, _, value}, mod) do
    "#{mod.token_to_string(value)};"
  end
  def token_to_string({:comma, _, value}, mod) do
    ", #{mod.token_to_string(value)}"
  end
  def token_to_string({:dot, _, [left, right]}, mod) do
    "#{mod.token_to_string(left)}.#{mod.token_to_string(right)}"
  end
  def token_to_string({tag, _, value}, _mod) when tag in ~w[ident numeric]a do
    "#{value}"
  end
  def token_to_string(value, _mod) when is_atom(value) do
    "#{value}"
  end
  def token_to_string(value, _mod) when is_binary(value) do
    "'#{value}'"
  end
  def token_to_string(value, _mod) when is_integer(value) do
    [value]
  end
  def token_to_string({tag, _, [left, right]}, mod) when tag in ~w[:: [\] <> <= >= != || + - ^ * / % < > = like ilike as union except intersect between and or is not in cursor for to]a do
    "#{mod.token_to_string(left)} #{mod.token_to_string(tag)} #{mod.token_to_string(right)}"
  end
  def token_to_string({tag, [{:keyword, :reserved}|_], values}, mod) do
    "#{mod.token_to_string(tag)} #{mod.token_to_string(values)}"
  end
  def token_to_string({tag, [{:keyword, :non_reserved}|_], values}, mod) when tag != :ident do
    "#{mod.token_to_string(tag)} #{mod.token_to_string(values)}"
  end
  def token_to_string({tag, _, []}, mod) do
    mod.token_to_string(tag)
  end
  def token_to_string(values, mod) do
    values
    |> Enum.reduce([], fn
      [], acc -> acc
      token, [] -> [mod.token_to_string(token)]
      {:comma, _, _} = token, acc -> [acc,mod.token_to_string(token)]
      token, acc -> [acc, " ", mod.token_to_string(token)]
    end)
  end
end
