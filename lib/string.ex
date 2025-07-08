# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.String do
  @moduledoc false

  @doc false
  def token_to_sql(value, mod \\ __MODULE__)
  def token_to_sql(value, _mod) when is_struct(value) do
    to_string(value)
  end
  def token_to_sql({:*, _, []}, _mod) do
    "*"
  end
  def token_to_sql({:fun, _, [left, right]}, mod) do
    "#{mod.token_to_sql(left)}#{mod.token_to_sql(right)}"
  end
  def token_to_sql({tag, _, [{:paren, _, _} = value]}, mod) when tag in ~w[numeric update]a do
    "#{mod.token_to_sql(tag)}#{mod.token_to_sql(value)}"
  end
  def token_to_sql({:ident, [{:keyword, :non_reserved},{:tag, tag}|_], [{:paren, _, _} = value]}, mod) do
    "#{mod.token_to_sql(tag)}#{mod.token_to_sql(value)}"
  end
  def token_to_sql({:ident, [{:keyword, :non_reserved}, {:tag, tag}|_], [{:numeric, _, _} = value]}, mod) do
    "#{mod.token_to_sql(tag)} #{mod.token_to_sql(value)}"
  end
  def token_to_sql({_tag, [{:keyword, :non_reserved}|_], value}, mod) do
    "#{mod.token_to_sql(value)}"
  end
  def token_to_sql({:numeric = tag, _, []}, mod), do: mod.token_to_sql(tag)
  def token_to_sql({tag, _, value}, _mod) when tag in ~w[ident numeric]a do
    value
  end
  def token_to_sql({:comment, _, value}, _mod) do
    "--#{value}"
  end
  def token_to_sql({:comments, _, value}, _mod) do
    "\\*#{value}*\\"
  end
  def token_to_sql({:double_quote, _, value}, _mod) do
    "\"#{value}\""
  end
  def token_to_sql({:quote, _, value}, _mod) do
    "'#{value}'"
  end
  def token_to_sql({:paren, _, value}, mod) do
    "(#{mod.token_to_sql(value)})"
  end
  def token_to_sql({:bracket, _, value}, mod) do
    "[#{mod.token_to_sql(value)}]"
  end
  def token_to_sql({:colon, _, value}, mod) do
    "; #{mod.token_to_sql(value)}"
  end
  def token_to_sql({:comma, _, value}, mod) do
    ", #{mod.token_to_sql(value)}"
  end
  def token_to_sql({:dot, _, [left, right]}, mod) do
    "#{mod.token_to_sql(left)}.#{mod.token_to_sql(right)}"
  end
  def token_to_sql({tag, _, []}, mod) do
    mod.token_to_sql(tag)
  end
  def token_to_sql({:join=tag, _, [right]}, mod) do
    "#{mod.token_to_sql(tag)} #{mod.token_to_sql(right)}"
  end
  def token_to_sql({:join=tag, _, [{t, [{:keyword, :reserved}|_], _}=p, p1, p2, right]}, mod) when t != :as do
    "#{mod.token_to_sql(p)} #{mod.token_to_sql(p1)} #{mod.token_to_sql(p2)} #{mod.token_to_sql(tag)} #{mod.token_to_sql(right)}"
  end
  def token_to_sql({:join=tag, _, [{t, [{:keyword, :reserved}|_], _}=p, p1, right]}, mod) when t != :as do
    "#{mod.token_to_sql(p)} #{mod.token_to_sql(p1)} #{mod.token_to_sql(tag)} #{mod.token_to_sql(right)}"
  end
  def token_to_sql({:join=tag, _, [{t, [{:keyword, :reserved}|_], _}=left, right]}, mod) when t != :as do
    "#{mod.token_to_sql(left)} #{mod.token_to_sql(tag)} #{mod.token_to_sql(right)}"
  end
  def token_to_sql({tag, _, [{:with = t, _, [left, right]}]}, mod) when tag in ~w[to]a do
    "#{mod.token_to_sql(tag)} #{mod.token_to_sql(left)} #{mod.token_to_sql(t)} #{mod.token_to_sql(right)}"
  end
  def token_to_sql({tag, _, value}, mod) when tag in ~w[select from fetch limit where order offset group having with join by distinct create type drop insert alter table add into delete update start grant revoke set declare open close commit rollback references recursive outer]a do
    "#{mod.token_to_sql(tag)} #{mod.token_to_sql(value)}"
  end
  def token_to_sql({:on = tag, _, [source, as, value]}, mod) do
    "#{mod.token_to_sql(source)} #{mod.token_to_sql(as)} #{mod.token_to_sql(tag)} #{mod.token_to_sql(value)}"
  end
  def token_to_sql({:not = tag, _, [ident | values]}, mod) when values != [] do
    "#{mod.token_to_sql(ident)} #{mod.token_to_sql(tag)} #{mod.token_to_sql(values)}"
  end
  def token_to_sql({tag, _, [left, [{:all = t, _, right}]]}, mod) when tag in ~w[union except intersect]a do
    "#{mod.token_to_sql(left)} #{mod.token_to_sql(tag)} #{mod.token_to_sql(t)} #{mod.token_to_sql(right)}"
  end
  def token_to_sql({:between = tag, _, [{:not = t, _, right}, left]}, mod) do
    "#{mod.token_to_sql(right)} #{mod.token_to_sql(t)} #{mod.token_to_sql(tag)} #{mod.token_to_sql(left)}"
  end
  def token_to_sql({tag, _, [left, right]}, mod) when tag in ~w[:: [\] <> <= >= != || + - ^ * / % < > = like ilike as union except intersect between and or on is not in cursor for to]a do
    "#{mod.token_to_sql(left)} #{mod.token_to_sql(tag)} #{mod.token_to_sql(right)}"
  end
  def token_to_sql({tag, _, [{:paren, _, _} = value]}, mod) when tag not in ~w[in on]a do
    "#{mod.token_to_sql(tag)}#{mod.token_to_sql(value)}"
  end
  def token_to_sql({tag, _, values}, mod) when tag in ~w[not all between asymmetric symmetric absolute relative forward backward on in for without]a do
    "#{mod.token_to_sql(tag)} #{mod.token_to_sql(values)}"
  end
  def token_to_sql({tag, _, [left]}, mod) when tag in ~w[asc desc isnull notnull not]a do
    "#{mod.token_to_sql(left)} #{mod.token_to_sql(tag)}"
  end
  def token_to_sql({:binding, _, [idx]}, _mod) when is_integer(idx) do
    "?"
  end
  def token_to_sql({:binding, _, value}, _mod) do
    "{{#{value}}}"
  end
  def token_to_sql(:*, _mod) do
    "*"
  end
  def token_to_sql(value, _mod) when is_atom(value) do
    "#{value}"
  end
  def token_to_sql(value, _mod) when is_binary(value) do
    "'#{value}'"
  end
  def token_to_sql([h|_]=values, mod) when is_tuple(h) or is_tuple(hd(h)) do
    values
    |> Enum.reduce([], fn
      token, [] = acc -> [acc,mod.token_to_sql(token, mod)]
      {:comma, _, _} = token, acc -> [acc,mod.token_to_sql(token, mod)]
      token, acc -> [acc," ",mod.token_to_sql(token, mod)]
    end)
  end
  def token_to_sql(value, _mod) do
    value
  end
end
