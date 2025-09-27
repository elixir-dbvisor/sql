# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.FormatterTest do
  use ExUnit.Case, async: true

  test "features/1" do
    assert [{:sigils, [:SQL]}, {:extensions, nil}]  == SQL.MixFormatter.features([])
  end

  test "format/2 preserve interpolation" do
    assert "\n\e[35mwith\e[0m \e[35mrecursive\e[0m \e[33mtemp\e[0m(\e[33mn\e[0m, \e[33mfact\e[0m) \e[35mas\e[0m (\n  \e[35mselect\e[0m\n    \e[33m0\e[0m,\n    \e[33m1\e[0m\n  \e[35munion\e[0m \e[35mall\e[0m\n  \e[35mselect\e[0m\n    \e[33mn\e[0m \e[35m+\e[0m {{one}},\n    (\e[33mn\e[0m \e[35m+\e[0m {{one}}) \e[35m*\e[0m \e[33mfact\e[0m\n  \e[35mfrom\e[0m\n    \e[33mtemp\e[0m\n  \e[35mwhere\e[0m\n    \e[33mn\e[0m \e[35m<\e[0m \e[33m9\e[0m\n)" == SQL.MixFormatter.format("with recursive temp(n, fact) as (select 0, 1 union all select n + {{one}}, (n + {{one}}) * fact from temp where n < 9)", [])
  end
end
