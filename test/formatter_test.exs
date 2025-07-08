# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.FormatterTest do
  use ExUnit.Case, async: true

  test "features/1" do
    assert [{:sigils, [:SQL]}, {:extensions, nil}]  == SQL.MixFormatter.features([])
  end

  test "format/2 preserve interpolation" do
    assert "with recursive temp(n, fact) as (select 0, 1 union all select n + {{one}}, (n + {{one}}) * fact from temp where n < 9)" == SQL.MixFormatter.format("with recursive temp(n, fact) as (select 0, 1 union all select n + {{one}}, (n + {{one}}) * fact from temp where n < 9)", [])
  end
end
