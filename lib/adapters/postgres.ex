# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Adapters.Postgres do
  @moduledoc """
    A SQL adapter for [PostgreSQL](https://www.postgresql.org).
  """
  @moduledoc since: "0.2.0"
  use SQL.Token

  defp to_iodata({:in, m, [{:not, _, left}, {:binding, _, [idx]}]}, format, case, acc) do
    to_iodata(left, format, case, indention(["!= ANY($#{idx})"|acc], format, m))
  end
  defp to_iodata({:in, m, [left, {:binding, _, [idx]} ]}, format, case, acc) do
    to_iodata(left, format, case, indention(["= ANY($#{idx})"|acc], format, m))
  end
  defp to_iodata({:binding, m, [idx]}, format, _case, acc) do
    indention(["$#{idx}"|acc], format, m)
  end
  defp to_iodata(token, format, case, acc), do: __to_iodata__(token, format, case, acc)
end
