# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Format do
  @moduledoc false
  @moduledoc since: "0.4.0"

  @compile {:inline, indention: 3, newline: 2}

  @doc false
  @doc since: "0.4.0"
  def to_iodata(tokens, context, indent \\ 0), do: newline(to_iodata(tokens, context.binding, context.case, context.errors, indent, []), indent)

  defp indention(acc, [{:preset, {_,0}},_,{:offset, {_,0,_,_}}|_], _), do: acc
  defp indention(acc, [_,{:offset, {_,0}}|_], 0), do: acc
  defp indention(["\e[33m"|_]=acc, [_,{:offset, {_,0}}|_], _), do: acc
  defp indention(acc, _, 0), do: [?\s|acc]
  defp indention(acc, _, 1), do: [?\s,?\s|acc]
  defp indention(acc, _, 2), do: [?\s,?\s,?\s,?\s|acc]
  defp indention(acc, _, indent), do: [:lists.duplicate(?\s, indent*2)|acc]

  defp newline([?\n, ?\s|acc], 0), do: [?\n|acc]
  defp newline([?\s|acc], 0), do: [?\n|acc]
  defp newline([?\n|_]=acc, _indent), do: acc
  defp newline(acc, _indent), do: [?\n|acc]

  newline = ~w[select from join where group having window order limit offset fetch]a
  {reserved, non_reserved, operators} = SQL.BNF.get_rules()
  for atom <- Enum.uniq(Enum.map(reserved++non_reserved++operators,&elem(&1, 0))), atom not in newline do
    defp to_iodata(unquote(atom), _binding ,:lower, _errors, _indent, acc) do
      ["\e[35m", unquote("#{atom}"), "\e[0m"|acc]
    end
    defp to_iodata(unquote(atom), _binding, :upper, _errors, _indent, acc) do
     ["\e[35m", unquote(String.upcase("#{atom}")), "\e[0m"|acc]
    end
  end
  for atom <- newline do
    defp to_iodata({unquote(atom), m, values}, binding, :lower=case, errors, indent, acc) do
      newline(indention(["\e[35m", unquote("#{atom}"), "\e[0m"|newline(to_iodata(values, binding, case, errors, indent+1, acc), indent+1)], m, indent), indent)
    end
    defp to_iodata({unquote(atom), m, values}, binding, :upper=case, errors, indent, acc) do
      newline(indention(["\e[35m", unquote(String.upcase("#{atom}")), "\e[0m"|newline(to_iodata(values, binding, case, errors, indent+1, acc), indent+1)], m, indent), indent)
    end
  end
  defp to_iodata(:comma, _binding, _case, _errors, 0, acc) do
    [?,|acc]
  end
  defp to_iodata(:comma, _binding, _case, _errors, indent, acc) do
    [?,|newline(acc, indent)]
  end
  defp to_iodata(:dot, _binding, _case, _errors, _indent, acc) do
    [?.|acc]
  end
  defp to_iodata(:paren, _binding, _case, _errors, _indent, acc) do
    [?(,?)|acc]
  end
  defp to_iodata({:colon, _m, values}, binding, case, errors, indent, acc) do
    to_iodata(values, binding, case, errors, indent, [?;|acc])
  end
  defp to_iodata({:binding, m, [idx]}, binding, _case, _errors, indent, acc) do
    indention([?{,?{,Macro.to_string(Enum.at(binding, idx-1)),?},?}|acc], m, indent)
  end
  defp to_iodata({:comment, _m, value}, _binding, _case, _errors, _indent, acc) do
    [?-,?-,value|acc]
  end
  defp to_iodata({:comments, _m, value}, _binding, _case, _errors, _indent, acc) do
    [?\\,?*,value,?*,?\\|acc]
  end
  defp to_iodata({:quote, m, value}, _binding, _case, _errors, indent, acc) do
    indention([?',"\e[32m" , value, "\e[0m",?'|acc], m, indent)
  end
  defp to_iodata({:backtick, m, value}, _binding, _case, _errors, indent, acc) do
    indention([?`,"\e[32m" , value, "\e[0m",?`|acc], m, indent)
  end
  defp to_iodata({tag, m, []}, binding, case, errors, indent, acc) do
    indention(to_iodata(tag, binding, case, errors, indent, acc), m, indent)
  end
  defp to_iodata({:paren, m, [{t, _, _}|_]=values}, binding, case, errors, indent, acc) when t in unquote(newline++~w[union except intersect]a) do
    indention([?(|to_iodata(values, binding, case, errors, indent+1, [?\n,?)|acc])], m, indent)
  end
  defp to_iodata({:paren, m, values}, binding, case, errors, indent, acc) do
    indention([?(|to_iodata(values, binding, case, errors, 0, [?)|acc])], m, indent)
  end
  defp to_iodata({:bracket, _m, values}, binding, case, errors, indent, acc) do
    [?[|to_iodata(values, binding, case, errors, indent, [?]|acc])]
  end
  defp to_iodata({_, [], values}, binding, case, errors, indent, acc) do
    to_iodata(values, binding, case, errors, indent, acc)
  end
  defp to_iodata({:ident, [_,_,_,{:tag, tag}|_]=m, [{:paren, _, _}]=values}, binding, case, errors, indent, acc) do
    indention(to_iodata(tag, binding, case, errors, indent, to_iodata(values, binding, case, errors, indent, acc)), m, indent)
  end
  defp to_iodata({tag, [{:span, {l, c, _, _}}|_]=m, [{_, [{:span, {ll, cc, _, _}}|_], _}]=values}, binding, case, errors, indent, acc) when l >= ll and c >= cc do
    to_iodata(values, binding, case, errors, indent, indention(to_iodata(tag, binding, case, errors, indent, acc), m, 0))
  end
  defp to_iodata({tag, m, [left, right]}, binding, case, errors, indent, acc) when tag in ~w[union except intersect]a do
    to_iodata(left, binding, case, errors, indent, newline(indention(to_iodata(tag, binding, case, errors, indent, to_iodata(right, binding, case, errors, indent, acc)), m, indent), indent))
  end
  defp to_iodata({tag, [_,_,{:type, type}|_]=m, [left, right]}, binding, case, errors, indent, acc) when type == :operator or tag in ~w[between cursor for to]a do
    to_iodata(left, binding, case, errors, indent, indention(to_iodata(tag, binding, case, errors, indent, to_iodata(right, binding, case, errors, 0, acc)), m, 0))
  end
  defp to_iodata({tag, m, value}=node, _binding, _case, errors, indent, acc) when tag in ~w[ident numeric special]a do
    case node in errors do
      true -> indention(["\e[31m", value, "\e[0m"|acc], m, indent)
      false -> indention(["\e[33m", value, "\e[0m"|acc], m, indent)
    end
  end
  defp to_iodata({:double_quote, m, value}=node, _binding, _case, errors, indent, acc) do
    case node in errors do
      true -> indention([?","\e[31m",value, "\e[0m", ?"|acc], m, indent)
      false -> indention([?", "\e[32m" , value, "\e[0m", ?"|acc], m, indent)
    end
  end
  defp to_iodata({tag, m, values}, binding, case, errors, indent, acc) do
    indention(to_iodata(tag, binding, case, errors, indent, to_iodata(values, binding, case, errors, indent, acc)), m, 0)
  end
  defp to_iodata([token|tokens], binding, case, errors, indent, acc) do
    to_iodata(token, binding, case, errors, indent, to_iodata(tokens, binding, case, errors, indent, acc))
  end
  defp to_iodata([], _binding, _case, _errors, _indent, acc) do
    acc
  end
end
