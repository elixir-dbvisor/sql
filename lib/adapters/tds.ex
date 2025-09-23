# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Adapters.TDS do
  @moduledoc """
    A SQL adapter for [TDS](https://www.microsoft.com/en-ca/sql-server).
  """
  @moduledoc since: "0.2.0"
  use SQL.Token

  defp to_iodata({:binding, m, [idx]}, format, _case, acc) when is_integer(idx), do: indention(["@#{idx}"|acc], format, m)
  defp to_iodata(token, format, case, acc), do: __to_iodata__(token, format, case, acc)
end
