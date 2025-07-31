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
  def token_to_string({tag, [{:type, :operator}|_], [left, right]}, mod) do
    "#{mod.token_to_string(left)} #{mod.token_to_string(tag)} #{mod.token_to_string(right)}"
  end
  def token_to_string({:ident, [{:type, :non_reserved},{:tag, tag}|_], [{:paren, _, _} = value]}, mod) do
    "#{mod.token_to_string(tag)}#{mod.token_to_string(value)}"
  end
  def token_to_string({:ident, [{:type, :non_reserved}, {:tag, tag}|_], [{:numeric, _, _} = value]}, mod) do
    "#{mod.token_to_string(tag)} #{mod.token_to_string(value)}"
  end
  def token_to_string({:ident, [{:type, :non_reserved}, {:tag, tag}|_], _}, mod) do
      mod.token_to_string(tag)
  end
  def token_to_string({tag, [{:type, :reserved}|_], [{:paren, _, _} = value]}, mod) when tag not in ~w[on as in select]a do
    "#{mod.token_to_string(tag)}#{mod.token_to_string(value)}"
  end
  def token_to_string({tag, [{:type, :reserved}|_], []}, mod) do
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
    "#{mod.token_to_string(value)},"
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
  def token_to_string({tag, _, [left, right]}, mod) when tag in ~w[like ilike as union except intersect between and or is not in cursor for to]a do
    "#{mod.token_to_string(left)} #{mod.token_to_string(tag)} #{mod.token_to_string(right)}"
  end
  def token_to_string({tag, [{:type, :reserved}|_], values}, mod) do
    "#{mod.token_to_string(tag)} #{mod.token_to_string(values)}"
  end
  def token_to_string({tag, [{:type, :non_reserved}|_], values}, mod) when tag != :ident do
    "#{mod.token_to_string(tag)} #{mod.token_to_string(values)}"
  end
  def token_to_string({tag, _, []}, mod) do
    mod.token_to_string(tag)
  end
  def token_to_string(values, mod) do
    values
    |> Enum.reduce([], fn
      [], acc -> acc
      {:comma, _, _} = token, acc -> [acc, mod.token_to_string(token), " "]
      token, [] -> mod.token_to_string(token)
      token, [_, _, " "] = acc -> [acc, mod.token_to_string(token)]
      token, [_, " "] = acc -> [acc, mod.token_to_string(token)]
      token, acc -> [acc, " ", mod.token_to_string(token)]
    end)
  end

  @doc false
  def to_iodata({tag, _, values}, context, indent) when tag in ~w[inner outer left right full natural cross]a do
    [context.module.to_iodata(tag, context, indent),context.module.to_iodata(values, context, indent, [?\s])]
  end
  def to_iodata({tag, _, values}, context, indent) when tag in ~w[join]a do
    v = Enum.reduce(values, [], fn token, acc -> [acc, ?\s, context.module.to_iodata(token, context, indent)] end)

    [indention(indent), context.module.to_iodata(tag, context, indent) | [v, ?\n]]
  end
  def to_iodata({tag, _, values}, context, indent) when tag in ~w[select from join where group having window order limit offset fetch]a do
    v = Enum.reduce(values, [?\n], fn token, acc -> [acc, indention(indent+1), context.module.to_iodata(token, context, indent+1), ?\n] end)

    [indention(indent), context.module.to_iodata(tag, context, indent) | v]
  end
  def to_iodata({:as, [], [left, right]}, context, indent) do
    [context.module.to_iodata(left, context, indent),?\s|context.module.to_iodata(right, context, indent)]
  end
  def to_iodata({tag, _, [left]}, context, indent) when tag in ~w[asc desc isnull notnull]a do
    [context.module.to_iodata(left, context, indent),?\s|context.module.to_iodata(tag, context, indent)]
  end
  def to_iodata({:fun, _, [left, right]}, context, indent) do
    [context.module.to_iodata(left, context, indent)|context.module.to_iodata(right, context, indent)]
  end
  def to_iodata({tag, [{:type, :operator}|_], [left, {:paren, _, _} = right]}, context, indent) do
    [context.module.to_iodata(left, context, indent),?\s,context.module.to_iodata(tag, context, indent),?\s|context.module.to_iodata(right, context, indent)]
  end
  def to_iodata({tag, [{:type, :operator}|_], [left, right]}, context, indent) do
    [context.module.to_iodata(left, context, indent),?\s,context.module.to_iodata(tag, context, indent),?\s|context.module.to_iodata(right, context, indent)]
  end
  def to_iodata({:ident, [{:type, :non_reserved},{:tag, tag}|_], [{:paren, _, _} = value]}, context, indent) do
    [context.module.to_iodata(tag, context, indent)|context.module.to_iodata(value, context, indent)]
  end
  def to_iodata({:ident, [{:type, :non_reserved}, {:tag, tag}|_], [{:numeric, _, _} = value]}, context, indent) do
    [context.module.to_iodata(tag, context, indent),?\s|context.module.to_iodata(value, context, indent)]
  end
  def to_iodata({:ident, [{:type, :non_reserved}, {:tag, tag}|_], _}, context, indent) do
    context.module.to_iodata(tag, context, indent)
  end
  def to_iodata({tag, [{:type, :reserved}|_], [{:paren, _, _} = value]}, context, indent) when tag not in ~w[on in select]a do
    [context.module.to_iodata(tag, context, indent)|context.module.to_iodata(value, context, indent)]
  end
  def to_iodata({tag, [{:type, :reserved}|_], []}, context, indent) do
    [?\s, context.module.to_iodata(tag, context, indent)]
  end
  def to_iodata({tag, _, [left, {:all = t, _, right}]}, context, indent) when tag in ~w[union except intersect]a do
    [context.module.to_iodata(left, context, indent), indention(indent), context.module.to_iodata(tag, context, indent),?\s,context.module.to_iodata(t, context, indent),?\n|context.module.to_iodata(right, context, indent)]
  end
  def to_iodata({:between = tag, _, [{:not = t, _, right}, left]}, context, indent) do
    [context.module.to_iodata(right, context, indent),?\s,context.module.to_iodata(t, context, indent),?\s,context.module.to_iodata(tag, context, indent),?\s|context.module.to_iodata(left, context, indent)]
  end
  def to_iodata({:binding, _, [idx]}, %{format: true, binding: binding}, _indent) do
    [?{,?{,Macro.to_string(Enum.at(binding, idx-1))|[?},?}]]
  end
  def to_iodata({:binding, _, _}, _context, _indent) do
    [??]
  end
  def to_iodata({:comment, _, value}, _context, _indent) do
    [?-,?-|value]
  end
  def to_iodata({:comments, _, value}, _context, _indent) do
    [?\\,?*,value|[?*, ?\\]]
  end
  def to_iodata({:double_quote, _, value}=node, context, _indent) do
    case node in context.errors do
      true -> [[?",:red,value|[:reset, ?"]]]
      false -> value
    end
  end
  def to_iodata({:quote, _, value}, _context, _indent) do
    [?',value|[?']]
  end
  def to_iodata({:paren, _, [{_,[{:type, :reserved}|_],_}|_] = value}, context, indent) do
    [?(,?\n, context.module.to_iodata(value, context, indent+1)|?)]
  end
  def to_iodata({:paren, _, value}, context, indent) do
    [?(,context.module.to_iodata(value, context, indent)|[?)]]
  end
  def to_iodata({:bracket, _, value}, context, indent) do
    [?[,context.module.to_iodata(value, context, indent)|[?]]]
  end
  def to_iodata({:colon, _, value}, context, indent) do
    [context.module.to_iodata(value, context, indent)|[?;,?\n]]
  end
  def to_iodata({:comma, _, value}, context, indent) do
    [context.module.to_iodata(value, context, indent), ?,, ?\s]
  end
  def to_iodata({:dot, _, [left, right]}, context, indent) do
    [context.module.to_iodata(left, context, indent),?\.|context.module.to_iodata(right, context, indent)]
  end
  def to_iodata({tag, _, value} = node, context, _indent) when tag in ~w[ident numeric]a do
    case node in context.errors do
      true -> [:red, value, :reset]
      false -> value
    end
  end
  def to_iodata(value, _context, _indent) when is_atom(value) do
    ~c"#{value}"
  end
  def to_iodata(value, _context, _indent) when is_binary(value) do
    [?',value|[?']]
  end
  def to_iodata(value, _context, _indent) when is_integer(value) do
    [value]
  end
  def to_iodata(value, _context, _indent) when is_struct(value) do
    to_string(value)
  end
  def to_iodata({tag, _, [left, right]}, context, indent) when tag in ~w[like ilike union except intersect between and or is not in cursor for to]a do
    [context.module.to_iodata(left, context, indent),?\s,context.module.to_iodata(tag, context, indent),?\s|context.module.to_iodata(right, context, indent)]
  end
  def to_iodata({tag, [{:type, :reserved}|_], values}, context, indent) do
    [context.module.to_iodata(tag, context, indent),?\s|context.module.to_iodata(values, context, indent)]
  end
  def to_iodata({tag, [{:type, :non_reserved}|_], values}, context, indent) when tag != :ident do
    [context.module.to_iodata(tag, context, indent),?\s|context.module.to_iodata(values, context, indent)]
  end
  def to_iodata({tag, _, []}, context, indent) do
    [indention(indent), context.module.to_iodata(tag, context, indent)]
  end
  def to_iodata([[{_,_,_}|_]|_]=tokens, context, indent) do
    to_iodata(tokens, context, indent, [])
  end
  def to_iodata([{_,_,_}|_]=tokens, context, indent) do
    to_iodata(tokens, context, indent, [])
  end
  def to_iodata([]=tokens, _context, _indent) do
    tokens
  end
end
