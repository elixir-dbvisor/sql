# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Format do
  @moduledoc false
  @moduledoc since: "0.4.0"

  @error IO.ANSI.red()
  @reset IO.ANSI.reset()
  @keyword IO.ANSI.magenta()
  @literal IO.ANSI.yellow()
  @enclosed IO.ANSI.green()

  @compile {:inline, indention: 3, newline: 2, pad: 1, keyword: 2, color: 3}

  @doc false
  @doc since: "0.4.0"
  def to_iodata(tokens, context, indent, color), do: pad(to_iodata(tokens, color, context.case, context.errors, indent, []))

  defp indention(acc, [{_, {_,_,_,_,_,0}}|_], _), do: acc
  defp indention(acc, [{_, {_,_,_,_,_,0,_,_}}|_], _), do: acc
  defp indention(acc, [{_, {_,_,_,_,_,_}}|_], 0), do: [?\s|acc]
  defp indention(acc, [{_, {_,_,_,_,_,_,_,_}}|_], 0), do: [?\s|acc]
  defp indention(acc, 0, 0), do: acc
  defp indention(acc, _, 0), do: acc
  defp indention(acc, _, 1), do: [?\s,?\s|acc]
  defp indention(acc, m, indent), do: indention([?\s,?\s|acc], m, indent-1)

  defp newline(acc, indent), do: [?\n|indention(acc, 0, indent)]

  defp pad([?\n|_]=acc), do: acc
  defp pad(acc), do: [?\n|acc]

  defp color(true, string, acc), do: [@keyword, string, @reset | acc]
  defp color(false, string, acc), do: [string | acc]

  newline = ~w[select from join where having window limit offset fetch when else end returning set]a
  {reserved, non_reserved, operators} = SQL.BNF.get_rules()

  defp keyword(:upper, value), do: String.upcase(Atom.to_string(value))
  defp keyword(:lower, value), do: Atom.to_string(value)

  for atom <- Enum.uniq(Enum.map(reserved++non_reserved++operators,&elem(&1, 0))), atom not in newline do
    defp to_iodata(unquote(atom), color, case, _errors, _indent, acc) do
      color(color, keyword(case, unquote(atom)), acc)
    end
  end
  for atom <- newline do
    defp to_iodata({unquote(atom), _m, values}, color, case, errors, indent, acc) do
      newline(color(color, keyword(case, unquote(atom)), pad(to_iodata(values, color, case, errors, indent+1, acc))), indent)
    end
  end
  for atom <- ~w[group order]a do
    defp to_iodata({unquote(atom), _m, values}, color, case, errors, indent, acc) do
      newline(color(color, keyword(case, unquote(atom)), to_iodata(values, color, case, errors, indent, acc)), indent)
    end
  end
  for atom <- ~w[inner outer left right full natural lateral]a do
    defp to_iodata({unquote(atom), _, [{atom, _, values}]}, color, case, errors, indent, acc) when atom in ~w[inner outer left right full natural lateral join]a do
      if atom == :join do
        newline([@keyword, keyword(case, unquote(atom)),?\s,keyword(case, atom),@reset,?\n|to_iodata(values, color, case, errors, indent+1, acc)], indent)
      else
        newline([@keyword, keyword(case, unquote(atom)),?\s,keyword(case, atom),@reset|to_iodata(values, color, case, errors, indent, acc)], indent)
      end
    end
  end
  defp to_iodata({tag, m, values}, color, case, errors, indent, acc) when tag in ~w[by on]a do
    indention(to_iodata(tag, color, case, errors, 0, newline(to_iodata(values, color, case, errors, indent, acc), indent)), m, 0)
  end
  defp to_iodata(:comma, _color, _case, _errors, 0, acc) do
    [?,|acc]
  end
  defp to_iodata(:comma, _color, _case, _errors, _indent, acc) do
    [?,|pad(acc)]
  end
  defp to_iodata(:dot, _color, _case, _errors, _indent, acc) do
    [?.|acc]
  end
  defp to_iodata(:paren, _color, _case, _errors, _indent, acc) do
    [?(,?)|acc]
  end
  defp to_iodata({:colon, _m, values}, color, case, errors, indent, acc) do
    to_iodata(values, color, case, errors, indent, [?;|acc])
  end
  defp to_iodata({:binding, m, [value]}, _color, _case, _errors, indent, acc) do
    indention([?{,?{,Macro.to_string(value),?},?}|acc], m, indent)
  end
  defp to_iodata({:comment, _m, value}, _color, _case, _errors, _indent, acc) do
    [?-,?-,value|acc]
  end
  defp to_iodata({:comments, _m, value}, _color, _case, _errors, _indent, acc) do
    [?\\,?*,value,?*,?\\|acc]
  end
  defp to_iodata({:quote, m, value}, true, _case, _errors, indent, acc) do
    indention([?',@enclosed, value, @reset,?'|acc], m, indent)
  end
  defp to_iodata({:quote, m, value}, false, _case, _errors, indent, acc) do
    indention([?', value,?'|acc], m, indent)
  end
  defp to_iodata({:backtick, m, value}, true, _case, _errors, indent, acc) do
    indention([?`,@enclosed, value, @reset,?`|acc], m, indent)
  end
  defp to_iodata({:backtick, m, value}, false, _case, _errors, indent, acc) do
    indention([?`, value,?`|acc], m, indent)
  end
  defp to_iodata({tag, m, []}, color, case, errors, indent, acc) do
    indention(to_iodata(tag, color, case, errors, indent, acc), m, indent)
  end
  defp to_iodata({:paren, m, [{t, _, _}|_]=values}, color, case, errors, indent, acc) when t in unquote(newline++~w[group order union except intersect]a) do
    indention([?(|to_iodata(values, color, case, errors, indent+1, [?\n,?)|acc])], m, indent)
  end
  defp to_iodata({:case=tag, m, values}, color, case, errors, indent, acc) do
    indention([to_iodata(tag, color, case, errors, indent, [])|to_iodata(values, color, case, errors, indent+1, newline(to_iodata(:end, color, case, errors, indent, acc), indent))], m, indent)
  end
  defp to_iodata({:paren, m, values}, color, case, errors, indent, acc) do
    indention([?(|to_iodata(values, color, case, errors, 0, [?)|acc])], m, indent)
  end
  defp to_iodata({:bracket, m, values}, color, case, errors, indent, acc) do
    indention([?[|to_iodata(values, color, case, errors, 0, [?]|acc])], m, indent)
  end
  defp to_iodata({:brace, m, values}, color, case, errors, indent, acc) do
    indention([?{|to_iodata(values, color, case, errors, 0, [?}|acc])], m, indent)
  end
  defp to_iodata({_, [], values}, color, case, errors, indent, acc) do
    indention(to_iodata(values, color, case, errors, 0, acc), 0, indent)
  end
  defp to_iodata({:ident, [_,_,{:tag, tag}|_]=m, [{:paren, _, _}]=values},color,  case, errors, indent, acc) do
    indention(to_iodata(tag, color, case, errors, indent, to_iodata(values, color, case, errors, indent, acc)), m, indent)
  end
  defp to_iodata({tag, [{_, {l,c,_,_,_,_}}|_]=m, [{_, [{_, {l,lc,_,_,_,_}}|_], _}=left, {_, [{_, {l,rc,_,_,_,_}}|_], _}=right]}, color, case, errors, indent, acc) when (c > lc and c < rc) do
    to_iodata(left, color, case, errors, indent, indention(to_iodata(tag, color, case, errors, 0, to_iodata(right, color, case, errors, 0, acc)), m, 0))
  end
  defp to_iodata({tag, [{_, {l,c,_,_,_,_}}|_]=m, [{_, [{_, {l,lc,_,_,_,_,_,_}}|_], _}=left, {_, [{_, {l,rc,_,_,_,_,_,_}}|_], _}=right]}, color, case, errors, indent, acc) when (c > lc and c < rc) do
    to_iodata(left, color, case, errors, indent, indention(to_iodata(tag, color, case, errors, 0, to_iodata(right, color, case, errors, 0, acc)), m, 0))
  end
  defp to_iodata({tag, [{_, {l,c,_,_,_,_}}|_]=m, [{_, [{_, {l,lc,_,_,_,_}}|_], _}=left, {_, [{_, {l,rc,_,_,_,_,_,_}}|_], _}=right]}, color, case, errors, indent, acc) when (c > lc and c < rc) do
    to_iodata(left, color, case, errors, indent, indention(to_iodata(tag, color, case, errors, 0, to_iodata(right, color, case, errors, 0, acc)), m, 0))
  end
  defp to_iodata({tag, [{_, {l,c,_,_,_,_}}|_]=m, [{_, [{_, {l,lc,_,_,_,_,_,_}}|_], _}=left, {_, [{_, {l,rc,_,_,_,_}}|_], _}=right]}, color, case, errors, indent, acc) when (c > lc and c < rc) do
    to_iodata(left, color, case, errors, indent, indention(to_iodata(tag, color, case, errors, 0, to_iodata(right, color, case, errors, 0, acc)), m, 0))
  end
  # defp to_iodata({tag, [{_, {l,c,_,_,_,_}}|_]=m, [{_, [{_, {ll,cc,_,_,_,_}}|_], _}]=values}, color, case, errors, indent, acc) when (l == ll and c < cc and tag in ~w[desc asc not]a) do
  #   to_iodata(values, color, case, errors, indent, indention(to_iodata(tag, color, case, errors, indent, acc), m, 0))
  # end
  # defp to_iodata({tag, [{_, {l,c,_,_,_,_}}|_]=m, [{_, [{_, {ll,cc,_,_,_,_,_,_}}|_], _}]=values}, color, case, errors, indent, acc) when (l == ll and c < cc and tag in ~w[desc asc not]a) do
  #   to_iodata(values, color, case, errors, indent, indention(to_iodata(tag, color, case, errors, indent, acc), m, 0))
  # end
  defp to_iodata({tag, m, values}, color, case, errors, indent, acc) when tag in ~w[desc asc not]a do
    to_iodata(values, color, case, errors, indent, indention(to_iodata(tag, color, case, errors, indent, acc), m, 0))
  end
  defp to_iodata({tag, _m, [left, right]}, color, case, errors, indent, acc) when tag in ~w[union except intersect]a do
    to_iodata(left, color, case, errors, indent, newline(to_iodata(tag, color, case, errors, indent, to_iodata(right, color, case, errors, indent, acc)), indent))
  end
  defp to_iodata({tag, _m, [left, right]}, color, case, errors, indent, acc) when tag in ~w[as and]a do
    to_iodata(left, color, case, errors, indent, [?\s|to_iodata(tag, color, case, errors, indent, to_iodata(right, color, case, errors, indent, acc))])
  end
  defp to_iodata({tag, [_,{_, :operator}|_], [left, right]}, color, case, errors, indent, acc) do
    to_iodata(left, color, case, errors, indent, to_iodata(tag, color, case, errors, indent, to_iodata(right, color, case, errors, indent, acc)))
  end

  defp to_iodata({tag, m, [{_,_,_}|_]=values}, color, case, errors, indent, acc) do
    indention(to_iodata(tag, color, case, errors, indent, to_iodata(values, color, case, errors, indent, acc)), m, 0)
  end
  defp to_iodata({tag, m, value}=node, true, _case, errors, indent, acc) when tag in ~w[ident numeric special]a do
    case node in errors do
      true -> indention([@error, value, @reset|acc], m, indent)
      false -> indention([@literal, value, @reset|acc], m, indent)
    end
  end
  defp to_iodata({tag, m, value}=node, false, _case, errors, indent, acc) when tag in ~w[ident numeric special]a do
    case node in errors do
      true -> indention([value|acc], m, indent)
      false -> indention([value|acc], m, indent)
    end
  end
  defp to_iodata({:double_quote, m, value}=node, true, _case, errors, indent, acc) do
    case node in errors do
      true -> indention([?",@error,value, @reset, ?"|acc], m, indent)
      false -> indention([?", @enclosed , value, @reset, ?"|acc], m, indent)
    end
  end
  defp to_iodata({:double_quote, m, value}=node, false, _case, errors, indent, acc) do
    case node in errors do
      true -> indention([?",value, ?"|acc], m, indent)
      false -> indention([?", value, ?"|acc], m, indent)
    end
  end
  defp to_iodata(atom, _color, :lower, _errors, _indent, acc) when is_atom(atom) do
    ["#{atom}"|acc]
  end
  defp to_iodata(atom, _color, :upper, _errors, _indent, acc) when is_atom(atom) do
   [String.upcase("#{atom}")|acc]
  end
  defp to_iodata([token|tokens], color, case, errors, indent, acc) do
    to_iodata(token, color, case, errors, indent, to_iodata(tokens, color, case, errors, indent, acc))
  end
  defp to_iodata([], _color, _case, _errors, _indent, acc) do
    acc
  end
end
