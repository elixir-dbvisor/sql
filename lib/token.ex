# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Token do
  @moduledoc false

  @doc """
  Returns a SQL string for a given token.
  """
  @doc since: "0.2.0"
  @callback token_to_string(token :: {atom, keyword, list}) :: String.t()

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @doc false
      @behaviour SQL.Token
      def token_to_string(token), do: SQL.Adapters.ANSI.token_to_string(token, __MODULE__)
      defoverridable token_to_string: 1
    end
  end
end
