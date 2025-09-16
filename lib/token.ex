# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Token do
  @moduledoc false

  @doc """
  Returns a SQL iodata for a given token.
  """
  @doc since: "0.3.0"
  @callback to_iodata(token :: {atom(), keyword(), list()}, context :: map(), indent :: non_neg_integer(), acc :: iodata()) :: iodata()

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @compile {:inline, to_iodata: 4, indention: 4, indention: 5}
      @doc false
      @behaviour SQL.Token
      def to_iodata(token, context, indent, acc), do: SQL.Adapters.ANSI.module.to_iodata(token, context, indent, acc)

      def indention([?)|_]=acc, context, [_,_,{:offset, {_,_,l,c}}|_], level) do
        indention(acc, context.format, l, c, level)
      end
      def indention([?(|_]=acc, context, [_,_,{:offset, {l,c,_,_}}|_], level) do
        indention(acc, context.format, l, c, level)
      end
      def indention(acc, context, [{:preset, {l,c}}|_], level) do
        indention(acc, context.format, l, c, level)
      end
      def indention(acc, context, [_,{:offset, {l,c}}|_], level) do
        indention(acc, context.format, l, c, level)
      end

      def indention(acc, :block, line, column, level), do: indention(acc, :dynamic, line, column*2, level)
      def indention(acc, context, line, column, level) when column < 0, do: indention(acc, context, line, 0, level)
      def indention([?\s|_]=acc, :dynamic, line, _column, _level) when line > 1, do: acc
      def indention([?\n|_]=acc, :dynamic, line, column, _level) when line > 1, do: [:lists.duplicate(column, ?\s)|acc]
      def indention([<<_::binary>>|_]=acc, :dynamic, line, column, _level) when line <= 1 and column <= 1, do: [?\s|acc]
      def indention(acc, _context, 0, 0, _level), do: acc
      def indention(acc, _context, 0, 1, _level), do: [?\s|acc]
      def indention(acc, _context, 1, 0, _level), do: [?\n|acc]
      def indention(acc, _context, 0, column, _level), do: [:lists.duplicate(column, ?\s)|acc]
      def indention(acc, _context, line, 0, _level), do: [:lists.duplicate(line, ?\n)|acc]
      def indention(acc, _context, line, column, _level), do: [:lists.duplicate(line, ?\n), :lists.duplicate(column, ?\s)|acc]

      defoverridable to_iodata: 4
    end
  end
end
