# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.FormatterTest do
  use ExUnit.Case, async: true

  test "features/1" do
    assert [{:sigils, [:SQL]}, {:extensions, nil}]  == SQL.MixFormatter.features([])
  end

  test "format/2 preserve interpolation" do
    assert "with recursive temp(n, fact) as (\n  select\n    0, \n    1\n  union all\n  select\n    n + {{one}}, \n    (n + {{one}}) * fact\n  from\n    temp\n  where\n    n < 9\n)" == SQL.MixFormatter.format("with recursive temp(n, fact) as (select 0, 1 union all select n + {{one}}, (n + {{one}}) * fact from temp where n < 9)", [])
  end
end
