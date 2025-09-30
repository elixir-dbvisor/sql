# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.MixFormatter do
  @moduledoc false
  @behaviour Mix.Tasks.Format

  @impl Mix.Tasks.Format
  def features(opts), do: [sigils: [:SQL], extensions: get_in(opts, [:sql, :extensions])]

  @impl Mix.Tasks.Format
  def format(source, opts) do
    opts = Map.new(Keyword.merge([validate: nil], opts))
    {:ok, context, tokens} = SQL.Lexer.lex(source)
    {:ok, context, tokens} = SQL.Parser.parse(tokens, Map.merge(context, opts))
    if context.errors != [], do: IO.warn([?\n,SQL.format_error(context.errors),"  \n  ",SQL.Format.to_iodata(tokens, context, 1),?\n])
    IO.iodata_to_binary(SQL.Format.to_iodata(tokens, context))
  end
end
