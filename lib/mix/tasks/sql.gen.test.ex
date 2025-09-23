# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor
if Code.ensure_loaded?(:yamerl) do
  defmodule Mix.Tasks.Sql.Gen.Test do
    use Mix.Task
    import Mix.Generator
    @moduledoc since: "0.2.0"

    @shortdoc "Generates test from the BNF rules"
    def run([base]) do
      for mod <- ~w[E F S T], do: create_file("test/conformance/#{String.downcase(mod)}_test.exs", test_template([mod: mod, dir: Path.join(base, mod)]), force: true)
    end

    def generate_test(dir) do
      for path <- File.ls!(dir), path =~ ".tests.yml", [{~c"feature", feature}, {~c"id", id}, {~c"sql", sql}] <- :yamerl.decode_file(to_charlist(Path.join(dir, path))) do
        statements = if is_list(hd(sql)), do: sql, else: [sql]
        statements = Enum.map(statements, &String.trim(String.replace(to_string(&1), ~r{(VARING)}, "VARYING")))
        {"#{feature} #{id}", statements}
      end
    end

    embed_template(:test, """
    # SPDX-License-Identifier: Apache-2.0
    # SPDX-FileCopyrightText: 2025 DBVisor
    defmodule SQL.Conformance.<%= @mod %>Test do
      use ExUnit.Case, async: true
      use SQL, case: :upper
      <%= for {name, statements} <- generate_test(@dir) do %>
      test <%= inspect name %> do
      <%= for statement <- statements do %>  assert ~s{<%= statement %>} == to_string(~SQL[<%= statement %>])
      <% end %>end
    <% end %>end
    """)
  end
end
