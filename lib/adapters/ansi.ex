# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Adapters.ANSI do
  @moduledoc """
    A SQL adapter for [ANSI](https://blog.ansi.org/sql-standard-iso-iec-9075-2023-ansi-x3-135/).
  """
  @moduledoc since: "0.2.0"
  use SQL.Token

  @doc false
  {reserved, non_reserved, operators} = SQL.BNF.get_rules()
  for atom <- Enum.uniq(Enum.map(reserved++non_reserved++operators,&elem(&1, 0))) do
    def to_iodata(unquote(atom), %{case:  :lower}, _indent, acc) do
      [unquote("#{atom}")|acc]
    end
    def to_iodata(unquote(atom), %{case:  :upper}, _indent, acc) do
      [unquote(String.upcase("#{atom}"))|acc]
    end
  end
  def to_iodata(:comma, _context, _indent, acc) do
    [?,|acc]
  end
  def to_iodata(:dot, _context, _indent, acc) do
    [?.|acc]
  end
  def to_iodata(:paren, _context, _indent, acc) do
    [?(,?)|acc]
  end
  def to_iodata({:colon, m, values}, context, indent, acc) do
    context.module.to_iodata(values, context, indent, indention([?;|acc], context, m, indent))
  end
  def to_iodata({:binding, m, [idx]}, %{format: true, binding: binding}=context, indent, acc) do
    indention([?{,?{,Macro.to_string(Enum.at(binding, idx-1)),?},?}|acc], context, m, indent)
  end
  def to_iodata({:binding, m, _}, context, indent, acc) do
    indention([??|acc], context, m, indent)
  end
  def to_iodata({:comment, m, value}, context, indent, acc) do
    indention([?-,?-,value|acc], context, m, indent)
  end
  def to_iodata({:comments, m, value}, context, indent, acc) do
    indention([?\\,?*,value,?*,?\\|acc], context, m, indent)
  end
  def to_iodata({:quote, m, value}, context, indent, acc) do
    indention([?',value,?'|acc], context, m, indent)
  end
  def to_iodata({:backtick, m, value}, context, indent, acc) do
    indention([?`,value,?`|acc], context, m, indent)
  end
  def to_iodata({tag, m, []}, context, indent, acc) do
    indention(context.module.to_iodata(tag, context, indent, acc), context, m, indent)
  end
  def to_iodata({:paren, m, values}, context, indent, acc) do
    indention([?(|indention(context.module.to_iodata(values, context, indent, indention([?)|acc], context, m, indent)), context, m, indent)], context, m, indent)
  end
  def to_iodata({:bracket, m, values}, context, indent, acc) do
    indention([?[|context.module.to_iodata(values, context, indent, indention([?]|acc], context, m, indent))], context, m, indent)
  end
  def to_iodata({_, [], values}, context, indent, acc) do
    context.module.to_iodata(values, context, indent, acc)
  end
  def to_iodata({:ident, [_,_,_,{:tag, tag}|_]=m, [{:paren, _, _}]=values}, context, indent, acc) do
    indention(context.module.to_iodata(tag, context, indent, context.module.to_iodata(values, context, indent, acc)), context, m, indent)
  end
  def to_iodata({tag, m, [{_, [_,_,{:type, t}|_], _}=left]}, context, indent, acc) when tag in ~w[isnull notnull not]a and t not in ~w[reserved non_reserved operator]a do
    context.module.to_iodata(left, context, indent, indention(context.module.to_iodata(tag, context, indent, acc), context, m, indent))
  end
  def to_iodata({tag, m, values}, context, indent, acc) when tag in ~w[desc asc]a do
    context.module.to_iodata(values, context, indent, indention(context.module.to_iodata(tag, context, indent, acc), context, m, indent))
  end
  def to_iodata({tag, [_,_,{:type, type}|_]=m, [left, right]}, context, indent, acc) when type == :operator or tag in ~w[between cursor for to union except intersect]a do
    context.module.to_iodata(left, context, indent, indention(context.module.to_iodata(tag, context, indent, context.module.to_iodata(right, context, indent, acc)), context, m, indent))
  end
  def to_iodata({tag, m, value}=node, context, indent, acc) when tag in ~w[ident numeric special]a do
    case node in context.errors do
      true -> indention(["\e[31m", value, "\e[0m"|acc], context, m, indent)
      false -> indention([value|acc],context, m, indent)
    end
  end
  def to_iodata({:double_quote, m, value}=node, context, indent, acc) do
    case node in context.errors do
      true -> indention([?","\e[31m",value, "\e[0m", ?"|acc], context, m, indent)
      false -> indention([?", value, ?"|acc], context, m, indent)
    end
  end
  def to_iodata({tag, m, values}, context, indent, acc) do
    indention(context.module.to_iodata(tag, context, indent, context.module.to_iodata(values, context, indent, acc)), context, m, indent)
  end
  def to_iodata([token|tokens], context, indent, acc) do
    context.module.to_iodata(token, context, indent, context.module.to_iodata(tokens, context, indent, acc))
  end
  def to_iodata([], _context, _indent, acc) do
    acc
  end
end
