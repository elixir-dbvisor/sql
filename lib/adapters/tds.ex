# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Adapters.TDS do
  @moduledoc """
    A SQL adapter for [TDS](https://www.microsoft.com/en-ca/sql-server).
  """
  @moduledoc since: "0.2.0"
  use SQL.Token

  defp to_iodata({:binding, m, _}, format, _case, acc) do
    idx = Process.get(:sql_binding)
    Process.put(:sql_binding, idx-1)
    indention(["@#{idx}"|acc], format, m)
  end
  defp to_iodata(token, format, case, acc), do: __to_iodata__(token, format, case, acc)
end
