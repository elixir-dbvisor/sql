# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Adapters.ANSI do
  @moduledoc """
    A SQL adapter for [ANSI](https://blog.ansi.org/sql-standard-iso-iec-9075-2023-ansi-x3-135/).
  """
  @moduledoc since: "0.2.0"
  use SQL.Token

  defp to_iodata({:binding, m, _}, format, _case, acc) do
    indention([??|acc], format, m)
  end
  defp to_iodata(token, format, case, acc), do: __to_iodata__(token, format, case, acc)
end
