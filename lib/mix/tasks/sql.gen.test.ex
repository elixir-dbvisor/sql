# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule Mix.Tasks.Sql.Gen.Test do
  use Mix.Task
  import Mix.Generator
  @moduledoc since: "0.2.0"

  @shortdoc "Generates test from the BNF rules"
  def run([base]) do
    create_file("test/conformance/e_test.exs", test_template([mod: SQL.Conformance.ETest, dir: Path.join(base, "E")]))
    create_file("test/conformance/f_test.exs", test_template([mod: SQL.Conformance.FTest, dir: Path.join(base, "F")]))
    create_file("test/conformance/s_test.exs", test_template([mod: SQL.Conformance.STest, dir: Path.join(base, "S")]))
    create_file("test/conformance/t_test.exs", test_template([mod: SQL.Conformance.TTest, dir: Path.join(base, "T")]))
  end

  def generate_test(dir) do
    for path <- File.ls!(dir), path =~ ".tests.yml", [{~c"feature", feature}, {~c"id", id}, {~c"sql", sql}] <- :yamerl.decode_file(to_charlist(Path.join(dir, path))) do
      statements = if is_list(hd(sql)), do: sql, else: [sql]
      statements = Enum.map(statements, &String.replace(to_string(&1), ~r{(VARING)}, "VARYING"))
      {"#{feature} #{id}", Enum.map(statements, &{trim(&1), &1})}
    end
  end

  def trim(value) do
    value
    |> String.replace(~r{\(\s+\b}, &String.replace(&1, " ", ""))
    |> String.replace(~r{\(\s+'}, &String.replace(&1, " ", ""))
    |> String.replace(~r{\(\s+"}, &String.replace(&1, " ", ""))
    |> String.replace(~r{\(\s+\*}, &String.replace(&1, " ", ""))
    |> String.replace(~r{\b\s+\,}, &String.replace(&1, " ", ""))
    |> String.replace(~r{\)\s+\,}, &String.replace(&1, " ", ""))
    |> String.replace(~r{\'\s+\,}, &String.replace(&1, " ", ""))
    |> String.replace(~r{\b\s+\)}, &String.replace(&1, " ", ""))
    |> String.replace(~r{'\s+\)}, &String.replace(&1, " ", ""))
    |> String.replace(~r{\*\s+\)}, &String.replace(&1, " ", ""))
    |> String.replace(~r{\)\s+\)}, &String.replace(&1, " ", ""))
    |> String.replace(~r{(A)\s\+\d}, &Enum.join(Regex.split(~r{\d}, &1, include_captures: true, trim: true), " "))
    |> String.replace(~r{\W(SELECT|REFERENCES|INSERT|UPDATE|IN|MYTEMP)\(}, &Enum.join(Regex.split(~r{\(}, &1, include_captures: true, trim: true), " "))
    |> String.replace(~r{^(SELECT)\(}, &Enum.join(Regex.split(~r{\(}, &1, include_captures: true, trim: true), " "))
    |> String.replace(~r{\s+\.\s+}, &String.replace(&1, " ", ""))
    |> String.replace(~r{\d\s(\+|\-)\d}, &Enum.join(Enum.map(Regex.split(~r{\+|\-}, &1, include_captures: true, trim: true), fn x -> String.trim(x) end), " "))
    |> String.trim()
 end

  embed_template(:test, """
  # SPDX-License-Identifier: Apache-2.0
  # SPDX-FileCopyrightText: 2025 DBVisor

  defmodule <%= inspect @mod %>.Adapter do
    use SQL.Token

    def token_to_string(value, mod \\\\ __MODULE__)
    def token_to_string(value, _mod) when is_atom(value), do: String.upcase(Atom.to_string(value))
    def token_to_string(token, mod), do: SQL.Adapters.ANSI.token_to_string(token, mod)
  end
  defmodule <%= inspect @mod %> do
    use ExUnit.Case, async: true
    use SQL, adapter: <%= inspect @mod %>.Adapter

    <%= for {name, statements} <- generate_test(@dir) do %>
    test <%= inspect name %> do
      <%= for {left, right} <- statements do %>
      assert ~s{<%= left %>} == to_string(~SQL[<%= right %>])
      <% end %>
    end
    <% end %>
  end
  """)
end
