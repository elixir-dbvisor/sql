# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.MixFormatter do
  @moduledoc false
  @behaviour Mix.Tasks.Format

  @impl Mix.Tasks.Format
  def features(opts), do: [sigils: [:SQL], extensions: get_in(opts, [:sql, :extensions])]

  @impl Mix.Tasks.Format
  def format(source, _opts), do: SQL.parse(source)
end
