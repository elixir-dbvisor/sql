# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Adapters.MySQL do
  @moduledoc """
    A SQL adapter for [MySQL](https://www.mysql.com).
  """
  @moduledoc since: "0.2.0"
  use SQL.Token

  @doc false
  def to_iodata(token, context, indent, acc), do: SQL.Adapters.ANSI.to_iodata(token, context, indent, acc)
end
