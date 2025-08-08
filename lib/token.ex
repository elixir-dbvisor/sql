# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Token do
  @moduledoc false

  @type token :: {atom, keyword, list}
  @type tokens :: [{atom, keyword, list}]

  @doc """
  Returns a SQL string for a given token.
  """
  @doc since: "0.2.0"
  @doc deprecated: "Use SQL.Token.to_iodata/3 instead"
  @callback token_to_string(tokens | token) :: String.t()

  @doc """
  Returns a SQL string for a given token.
  """
  @doc since: "0.3.0"
  @callback to_iodata(token :: {atom(), keyword(), list()}, context :: map(), indent :: non_neg_integer()) :: iodata()

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @compile {:inline, to_iodata: 3, to_iodata: 4}
      @doc false
      @behaviour SQL.Token
      def token_to_string(token), do: SQL.Adapters.ANSI.token_to_string(token, __MODULE__)
      def to_iodata(token, context, indent), do: SQL.Adapters.ANSI.module.to_iodata(token, context, indent)

      def to_iodata([], _context, _indent, acc), do: acc
      def to_iodata([[]|tokens], context, indent, acc), do: to_iodata(tokens, context, indent, acc)
      def to_iodata([token|tokens], context, indent, acc), do: to_iodata(tokens, context, indent, [acc|context.module.to_iodata(token, context, indent)])

      def indention(indent, acc \\ [])
      def indention(0, acc), do: acc
      def indention(indent, acc), do: indention(indent-1, [?\s, ?\s|acc])
      defoverridable token_to_string: 1, to_iodata: 3
    end
  end
end
