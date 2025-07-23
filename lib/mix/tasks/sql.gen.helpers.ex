# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule Mix.Tasks.Sql.Gen.Helpers do
  use Mix.Task
  import Mix.Generator
  @moduledoc since: "0.2.0"

  @shortdoc "Generates a helpers from the BNF rules"
  def run(_args) do
    operators = [
      {:plus, [type: :mysql], ["+"]},
      {:minus, [type: :mysql], ["-"]},
      {:not, [type: :mysql], ["!"]},
      {:logical_and, [type: :mysql], ["&&"]},
      {:logical_or, [type: :mysql], ["||"]},
      {:bitwise_and, [type: :mysql], ["&"]},
      {:bitwise_and_assignment, [type: :tds], ["&="]},
      {:bitwise_xor, [type: :mysql], ["^"]},
      {:bitwise_xor_assignment, [type: :tds], ["^="]},
      {:bitwise_or, [type: :mysql], ["|"]},
      {:bitwise_or_assignment, [type: :tds], ["|=", "|*="]},
      {:bitwise_exclusive_assignment, [type: :sql], ["^-="]},
      {:bitwise_invasion, [type: :mysql], ["~"]},
      {:right_shift, [type: :mysql], [">>"]},
      {:left_shift, [type: :mysql], ["<<"]},
      {:null_safe_equals_operator, [type: :mysql], ["<=>"]},
      {:mod, [type: :mysql], ["%"]},
      {:json_extract, [type: :mysql], ["->"]},
      {:json_unquote_json_extract, [type: :mysql], ["->>"]},
      {:assign_value, [type: :mysql], [":="]},
      {:add_assignment, [type: :tds], ["+="]},
      {:subtract_assignment, [type: :tds], ["-="]},
      {:multiply_assignment, [type: :tds], ["*="]},
      {:divide_assignment, [type: :tds], ["/="]},
      {:mod_assignment, [type: :tds], ["%="]},
      {:not_greater_then, [type: :tds], ["!>"]},
      {:not_less_then, [type: :tds], ["!<"]},
      {:right_containment, [type: :postgres], ["@>"]},
      {:left_containment, [type: :postgres], ["<@"]},
      {:sqaure_root, [type: :postgres], ["|/"]},
      {:cube_root, [type: :postgres], ["||/"]},
      {:abs, [type: :postgres], ["@"]},
      {:bitwise_exclusive_or, [type: :postgres], ["#"]},
      {:starts_with, [type: :postgres], ["^@"]},
      {:regex_match, [type: :postgres], ["~*"]},
      {:not_regex_match_case, [type: :postgres], ["!~"]},
      {:not_regex_match, [type: :postgres], ["!~*"]},
      {:bitwise_exclusive_or, [type: :postgres], ["##"]},
      {:right_extend, [type: :postgres], ["&<"]},
      {:left_extend, [type: :postgres], ["&>"]},
      {:right_below, [type: :postgres], ["<<|"]},
      {:left_below, [type: :postgres], ["|>>"]},
      {:not_right_extend, [type: :postgres], ["&<|"]},
      {:not_left_extend, [type: :postgres], ["|&>"]},
      {:right_below, [type: :postgres], ["<^"]},
      {:left_below, [type: :postgres], [">^"]},
      {:object_intersect, [type: :postgres], ["?#"]},
      {:horizontal_line, [type: :postgres], ["?-"]},
      {:vertical_line, [type: :postgres], ["?|"]},
      {:perpendicular_line, [type: :postgres], ["?-|"]},
      {:parallel_line, [type: :postgres], ["?||"]},
      {:regex_match, [type: :postgres], ["~="]},
      {:right_containment, [type: :postgres], ["<<="]},
      {:left_containment, [type: :postgres], [">>="]},
      {:tsvector_match, [type: :postgres], ["@@"]},
      {:negate_tsquery, [type: :postgres], ["!!"]},
      {:json_extract, [type: :postgres], ["#>"]},
      {:json_extract_text, [type: :postgres], ["#>>"]},
      {:json_array_containment, [type: :postgres], ["?&"]},
      {:json_delete, [type: :postgres], ["#-"]},
      {:json_path_return, [type: :postgres], ["@?"]},
      {:ranges_adjacent, [type: :postgres], ["-|-"]},
      {:cast, [type: :postgres], ["::"]},
    ]
    rules = SQL.BNF.parse(%{
    "<reserved word>" => ~w[| LIMIT | ILIKE | BACKWARD | FORWARD | ISNULL | NOTNULL],
    operators: operators,
    download: true
    })
    enclosed = [
      {:double_quote, [type: :literal], ["\"", "\""]},
      {:quote, [type: :literal], ["'", "'"]},
      # {:double_dollar, [type: :literal], ["$$", "$$"]},
      # {:dollar, [type: :literal], ["$", "$"]},
      # {:unicode_escape, [type: :literal], ["U&'", "'"]},
      {:backtick, [type: :literal], ["`", "`"]},
      # {:bit_string, [type: :literal], ["B'", "'"]},
      {:brace, [type: :expr], ["{", "}"]},
      {:bracket, [type: :expr], ["[", "]"]},
      {:paren, [type: :expr], ["(", ")"]},
      # {:comment, [type: :literal], ["--", "\n"]},
      # {:comments, [type: :literal], ["/*", "*/"]},
    ]
    exprs = for {n, [type: :expr], [f, l]} <- enclosed, reduce: {[], [], []} do
              {name, first, last} -> {[n|name], [f|first], [l|last]}
            end
    space = Enum.map(rules.terminals["<space>"], fn <<c::utf8>> -> c end)
    whitespace = Enum.map(rules.terminals["<whitespace>"], fn <<c::utf8>> -> c end)
    newline = Enum.map(rules.terminals["<newline>"], fn <<c::utf8>> -> c end)
    reserved = rules.keywords["<reserved word>"] ++ rules.keywords["<SQL/JSON key word>"]
    create_file("lib/helpers.ex", helpers_template([mod: SQL.Lexer, reserved: Enum.uniq(reserved), non_reserved: Enum.uniq(rules.keywords["<non-reserved word>"]), nested_start: ~c"#{elem(exprs, 1)}", nested_end: ~c"#{elem(exprs, 2)}", special_characters: ~c"#{Enum.uniq(Enum.map(rules.special_characters, &elem(&1, 1)))}", operators: Enum.uniq(Enum.flat_map(rules.operators, &elem(&1, 1))), digits: ~c"#{rules.digits["<digit>"]}", exprs: exprs, space: space, whitespace: whitespace, newline: newline]))
  end

  embed_template(:helpers, """
  # SPDX-License-Identifier: Apache-2.0
  # SPDX-FileCopyrightText: 2025 DBVisor

  defmodule SQL.Helpers do
    @moduledoc false

    defguard is_newline(b) when b in <%= inspect @newline %>
    defguard is_space(b) when b in <%= inspect @space %>
    defguard is_whitespace(b) when b in <%= inspect @whitespace %>
    defguard is_literal(b) when b in ~c{"'`}
    defguard is_expr(b) when b in <%= inspect elem(@exprs, 0) %>
    defguard is_nested_start(b) when b in <%= inspect @nested_start %>
    defguard is_nested_end(b) when b in <%= inspect @nested_end %>
    defguard is_special_character(b) when b in <%= inspect @special_characters %>
    defguard is_digit(b) when b in <%= inspect @digits %>
    defguard is_comment(b) when b in ["--", "/*"]
    defguard is_sign(b) when b in ~c"-+"
    defguard is_dot(b) when b == ?.
    defguard is_delimiter(b) when b in ~c";,"
    <%= for letter <- Enum.to_list(?a..?z) do %>
    defguard is_<%= [letter] %>(b) when b in <%= inspect [letter | :string.uppercase([letter])] %>
    <% end %>

    <%= for {atom, match, guard} <- @reserved do %>
    def tag(<%= match %>) when <%= guard %>, do: {:reserved, <%= inspect(atom) %>}
    <% end %>
    <%= for {atom, match, guard} <- @non_reserved do %>
    def tag(<%= match %>) when <%= guard %>, do: {:non_reserved, <%= inspect(atom) %>}
    <% end %>
    <%= for {atom, match} <- @operators do %>
    def tag(<%= match %>), do: <%= inspect(atom) %>
    <% end %>
    def tag(_), do: nil
  end
  """)
end
