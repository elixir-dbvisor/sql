# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Token do
  @moduledoc false

  @doc """
  Returns a SQL iodata for a given token.
  """
  @doc since: "0.3.0"
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @compile {:inline, to_iodata: 4, __to_iodata__: 4, indention: 3, indention: 4}

      def to_iodata(token, %{format: format, case: case}), do: to_iodata(token, format, case, [])

      defp to_iodata(token, format, case, acc), do: __to_iodata__(token, format, case, acc)

      defp indention(acc, format, [{:preset, {l,c}}|_]) do
        indention(acc, format, l, c)
      end
      defp indention(acc, format, [_,{:offset, {l,c}}|_]) do
        indention(acc, format, l, c)
      end
      defp indention(acc, format, line, column) when column < 0, do: indention(acc, format, line, 0)
      defp indention([?\s|_]=acc, :dynamic, line, _column) when line > 1, do: acc
      defp indention([?\n|_]=acc, :dynamic, line, column) when line > 1, do: [:lists.duplicate(column, ?\s)|acc]
      defp indention([<<_::binary>>|_]=acc, :dynamic, line, column) when line <= 1 and column <= 1, do: [?\s|acc]
      defp indention(acc, _format, 0, 0), do: acc
      defp indention(acc, _format, 0, 1), do: [?\s|acc]
      defp indention(acc, _format, 1, 0), do: [?\n|acc]
      defp indention(acc, _format, 0, column), do: [:lists.duplicate(column, ?\s)|acc]
      defp indention(acc, _format, line, 0), do: [:lists.duplicate(line, ?\n)|acc]
      defp indention(acc, _format, line, column), do: [:lists.duplicate(line, ?\n), :lists.duplicate(column, ?\s)|acc]

      {reserved, non_reserved, operators} = SQL.BNF.get_rules()
      for atom <- Enum.uniq(Enum.map(reserved++non_reserved++operators,&elem(&1, 0))) do
        defp __to_iodata__(unquote(atom), _format, :lower, acc) do
          [unquote("#{atom}")|acc]
        end
        defp __to_iodata__(unquote(atom), _format, :upper, acc) do
          [unquote(String.upcase("#{atom}"))|acc]
        end
      end
      defp __to_iodata__(:comma, _format, _case, acc) do
        [?,|acc]
      end
      defp __to_iodata__(:dot, _format, _case, acc) do
        [?.|acc]
      end
      defp __to_iodata__(:paren, _format, _case, acc) do
        [?(,?)|acc]
      end
      defp __to_iodata__({:colon, m, values}, format, case, acc) do
        to_iodata(values, format, case, indention([?;|acc], format, m))
      end
      defp __to_iodata__({:binding, m, _}, format, _case, acc) do
        indention([??|acc], format, m)
      end
      defp __to_iodata__({:comment, m, value}, format, _case, acc) do
        indention([?-,?-,value|acc], format, m)
      end
      defp __to_iodata__({:comments, m, value}, format, _case, acc) do
        indention([?\\,?*,value,?*,?\\|acc], format, m)
      end
      defp __to_iodata__({:quote, m, value}, format, _case, acc) do
        indention([?',value,?'|acc], format, m)
      end
      defp __to_iodata__({:backtick, m, value}, format, _case, acc) do
        indention([?`,value,?`|acc], format, m)
      end
      defp __to_iodata__({tag, m, []}, format, case, acc) do
        indention(to_iodata(tag, format, case, acc), format, m)
      end
      defp __to_iodata__({:paren, [_,_,{:offset, {l,c,el,ec}}|_]=m, values}, format, case, acc) do
        indention([?(|indention(to_iodata(values, format, case, indention([?)|acc], format, el, ec)), format, m)], format, l, c)
      end
      defp __to_iodata__({:bracket, m, values}, format, case, acc) do
        indention([?[|to_iodata(values, format, case, indention([?]|acc], format, m))], format, m)
      end
      defp __to_iodata__({_, [], values}, format, case, acc) do
        to_iodata(values, format, case, acc)
      end
      defp __to_iodata__({:ident, [_,_,_,{:tag, tag}|_]=m, [{:paren, _, _}]=values}, format, case, acc) do
        indention(to_iodata(tag, format, case, to_iodata(values, format, case, acc)), format, m)
      end
      defp __to_iodata__({tag, [{:span, {l, c, _, _}}|_]=m, [{_, [{:span, {ll, cc, _, _}}|_], _}]=values}, format, case, acc) when l >= ll and c >= cc do
        to_iodata(values, format, case, indention(to_iodata(tag, format, case, acc), format, m))
      end
      defp __to_iodata__({tag, [_,_,{:type, type}|_]=m, [left, right]}, format, case, acc) when type == :operator or tag in ~w[between cursor for to union except intersect]a do
        to_iodata(left, format, case, indention(to_iodata(tag, format, case, to_iodata(right, format, case, acc)), format, m))
      end
      defp __to_iodata__({:ident, m, value}=node, format, :upper, acc) do
        indention([:string.uppercase(value)|acc], format, m)
      end
      defp __to_iodata__({tag, m, value}=node, format, _case, acc) when tag in ~w[ident numeric special]a do
        indention([value|acc], format, m)
      end
      defp __to_iodata__({:double_quote, m, value}=node, format, _case, acc) do
        indention([?", value, ?"|acc], format, m)
      end
      defp __to_iodata__({tag, m, values}, format, case, acc) do
        indention(to_iodata(tag, format, case, to_iodata(values, format, case, acc)), format, m)
      end
      defp __to_iodata__([token|tokens], format, case, acc) do
        to_iodata(token, format, case, to_iodata(tokens, format, case, acc))
      end
      defp __to_iodata__([], _format, _case, acc) do
        acc
      end

      defoverridable to_iodata: 4
    end
  end
end
