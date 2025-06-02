# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule Mix.Tasks.Sql.Gen.Parser do
  use Mix.Task
  import Mix.Generator
  @moduledoc since: "0.2.0"

  @shortdoc "Generates a lexer and parser from the BNF rules"
  def run(_args) do
    rules = SQL.BNF.parse()
    space = Enum.map(rules["<space>"], fn <<c::utf8>> -> c end)
    whitespace = Enum.map(rules["<whitespace>"], fn <<c::utf8>> -> c end)
    newline = Enum.map(rules["<newline>"], fn <<c::utf8>> -> c end)

    keywords = String.split(rules["<reserved word>"], "|") ++ String.split(rules["<non-reserved word>"], "|") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
    keywords = keywords ++ ~w[LIMIT ILIKE BACKWARD FORWARD ISNULL NOTNULL]
    create_file("lib/lexer.ex", lexer_template([mod: SQL.Lexer, keywords: keywords, space: space, whitespace: whitespace, newline: newline]))
    create_file("lib/parser.ex", parser_template([mod: SQL.Parser, keywords: Enum.map(keywords, &String.to_atom(String.downcase(&1)))]))
  end

  def guard(keyword) do
    {value, _n} = for <<k <- String.downcase(keyword)>>, reduce: {[], 1} do
      {[], n} -> {{:in, [context: Elixir, imports: [{2, Kernel}]], [{:"b#{n}", [], Elixir}, Enum.uniq(~c"#{<<k>>}#{String.upcase(<<k>>)}")]}, n+1}
      {left, n} -> {{:and, [context: Elixir, imports: [{2, Kernel}]], [left, {:in, [context: Elixir, imports: [{2, Kernel}]], [{:"b#{n}", [], Elixir}, Enum.uniq(~c"#{<<k>>}#{String.upcase(<<k>>)}")]}]}, n+1}
    end
    Macro.to_string(value)
  end

  embed_template(:parser, """
  # SPDX-License-Identifier: Apache-2.0
  # SPDX-FileCopyrightText: 2025 DBVisor

  defmodule <%= inspect @mod %> do
    @moduledoc false
    @compile {:inline, parse: 1, parse: 5, predicate: 1, insert_node: 5}

    import Kernel, except: [is_boolean: 1]

    defguard is_and(node) when elem(node, 0) == :and
    defguard is_between(node) when elem(node, 0) == :between
    defguard is_boolean(node) when elem(node, 0) in ~w[and or <> <= >= != < > !< !> = true false unknown like ilike in all any is isnull notnull between]a
    defguard is_combinator(node) when elem(node, 0) in ~w[except intersect union]a and elem(node, 2) == []
    defguard is_comma(node) when elem(node, 0) == :comma
    defguard is_comment(node) when elem(node, 0) in ~w[comment comments]a
    defguard is_conditional(node) when elem(node, 0) in ~w[and or]a and elem(node, 2) == []
    defguard is_colon(node) when elem(node, 0) == :colon
    defguard is_distinct(node) when elem(node, 0) == :distinct
    defguard is_declare(node) when elem(node, 0) == :declare
    defguard is_data_type(node) when elem(node, 0) in ~w[integer float ident quote double_quote backtick bracket parens . binding]a
    defguard is_fetch(node) when elem(node, 0) == :fetch
    defguard is_fetch_dir(node) when elem(node, 0) in ~w[absolute backward forward relative]a
    defguard is_from(node) when elem(node, 0) == :from
    defguard is_for(node) when elem(node, 0) == :for
    defguard is_grant(node) when elem(node, 0) == :grant
    defguard is_revoke(node) when elem(node, 0) == :revoke
    defguard is_keyword(node) when elem(node, 0) in <%= inspect(@keywords, limit: :infinity) %>
    defguard is_not(node) when elem(node, 0) == :not and elem(node, 2) == []
    defguard is_join(node) when elem(node, 0) == :join
    defguard is_parens(node) when elem(node, 0) == :parens
    defguard is_operator(node) when elem(node, 0) in ~w[operator :: + - * / ^ % & += -= *= /= %= &= ^-= |*= <=> || as <> <= >= != < > !< !> = like ilike in all any is isnull notnull between]a
    defguard is_of(node) when elem(node, 0) == :of
    defguard is_is(node) when elem(node, 0) == :is
    defguard is_on(node) when elem(node, 0) == :on
    defguard is_select(node) when elem(node, 0) == :select

    def predicate([l, c, r]) when is_boolean(l) and is_conditional(c) and is_boolean(r) do
      {elem(c, 0), elem(c, 1), [l, r]}
    end
    def predicate([l, b]) when is_boolean(b) do
      [{elem(b, 0), elem(b, 1), [l | elem(b, 2)]}]
    end
    def predicate([l, b, r | rest]) when is_boolean(b) or is_operator(b) do
      predicate([{elem(b, 0), elem(b, 1), [l, r]} | rest])
    end
    def predicate([{_, _, _}, node | _] =  unit) when is_comma(node) do
      unit
    end
    def predicate([l, b, r, c | rest]) when is_comma(c) and (is_boolean(b) or is_operator(b)) do
      [{elem(b, 0), elem(b, 1), [l, r]}, c | rest]
    end
    def predicate([l, c, r, c2 | rest]) when is_boolean(l) and is_conditional(c) and is_boolean(r) and is_conditional(c2) do
      predicate([{elem(c, 0), elem(c, 1), [l, r]}, c2 | rest])
    end
    def predicate([f, c, l, b, r, c2 | rest]) when is_boolean(b) and is_conditional(c) and is_conditional(c2) do
      predicate([f, c, {elem(b, 0), elem(b, 1), [l, r]}, c2 | rest])
    end
    def predicate([f, c, l, b, r]) when is_boolean(b) and is_conditional(c) do
      predicate([f, c, {elem(b, 0), elem(b, 1), [l, r]}])
    end
    def predicate([l, b, r, c | rest]) when is_boolean(b) and is_conditional(c) do
      predicate([{elem(b, 0), elem(b, 1), [l, r]}, c | rest])
    end
    def predicate(unit) do
      unit
    end


    def insert_node(node, unit, acc, context, root) when is_parens(node) do
      {[{elem(node, 0), elem(node, 1), parse(elem(node, 2))} | unit], acc, context, root}
    end
    def insert_node(node, [{:in = tag, meta, []}, right, {:using, _, _} = using | unit], acc, context, root) do
      {[{tag, meta, [node, [right, using | unit]]}], acc, context, root}
    end
    def insert_node({:in, _, _} = node, [_, {:using, _, _}|_] = unit, acc, context, root) do
      {[node | unit], acc, context, root}
    end
    def insert_node({:into = tag, meta, _}, [_] = unit, acc, context, root) do
      {[{tag, meta, unit}], acc, context, root}
    end
    def insert_node(node, [n, b, r, c, l | unit], acc, context, root) when is_between(b) and is_and(c) and is_not(n) and is_data_type(r) and is_data_type(l) and is_data_type(node) do
      {[{elem(b, 0), elem(b, 1), [{elem(n, 0), elem(n, 1), [node]}, {elem(c, 0), elem(c, 1), [r, l]}]} | unit], acc, context, root}
    end
    def insert_node(node, [n, b, s, r, c, l | unit], acc, context, root) when is_between(b) and is_and(c) and is_not(n) and is_data_type(r) and is_data_type(l) and is_data_type(node) do
      {[{elem(b, 0), elem(b, 1), [{elem(n, 0), elem(n, 1), [node]}, {elem(s, 0), elem(s, 1), [{elem(c, 0), elem(c, 1), [r, l]}]}]} | unit], acc, context, root}
    end
    def insert_node(node, [b, s, r, c, l | unit], acc, context, root) when is_between(b) and is_and(c) and is_data_type(r) and is_data_type(l) and is_data_type(node) do
      {[{elem(b, 0), elem(b, 1), [node, {elem(s, 0), elem(s, 1), [{elem(c, 0), elem(c, 1), [r, l]}]}]} | unit], acc, context, root}
    end
    def insert_node(node, [b, r, c, l | unit], acc, context, root) when is_between(b) and is_and(c) and is_data_type(r) and is_data_type(l) and is_data_type(node) do
      {[{elem(b, 0), elem(b, 1), [node, {elem(c, 0), elem(c, 1), [r, l]}]} | unit], acc, context, root}
    end
    def insert_node(node, [b, l, c | unit], acc, context, root) when is_data_type(node) and is_operator(b) and is_data_type(l) and is_conditional(c) do
      {[{elem(b, 0), elem(b, 1), [node, l]}, c | unit], acc, context, root}
    end
    def insert_node(node, [r, b, l | unit], acc, context, root) when is_conditional(node) and is_data_type(r) and is_operator(b) and is_data_type(l) do
      {[node, {elem(b, 0), elem(b, 1), [r, l]} | unit], acc, context, root}
    end
    def insert_node(node, [o, l], acc, context, root) when is_data_type(node) and is_operator(o) and is_data_type(l) do
      {[{elem(o, 0), elem(o, 1), [node, l]}], acc, context, root}
    end
    def insert_node(node, [u | unit], acc, context, root) when is_not(node) and elem(u, 0) in ~w[false true unknown null]a do
      {[{elem(node, 0), elem(node, 1), [u]} | unit], acc, context, root}
    end
    def insert_node(node, [u | unit], acc, context, root) when is_not(u) and is_data_type(node) do
      {[{elem(u, 0), elem(u, 1), [node | unit]}], acc, context, root}
    end
    def insert_node({:into = tag, meta, []}, [ident, parens, values], acc, context, root) do
      {[], [{tag, meta, [ident, parens, values]} | acc], context, root}
    end
    def insert_node({tag, meta, []}, [ident, parens], acc, context, root) when tag in ~w[into table]a do
      {[], [{tag, meta, [ident, parens]} | acc], context, root}
    end
    def insert_node({:add = tag, meta, []}, [ident, type], acc, context, root) do
      {[], [{tag, meta, [ident, type]} | acc], context, root}
    end
    def insert_node({:type = tag, meta, []}, [ident, as, type], acc, context, root) do
      {[], [{tag, meta, [{elem(as, 0), elem(as, 1), [ident, type]}]} | acc], context, root}
    end
    def insert_node({tag, meta, []}, [ident], acc, context, root) when tag in ~w[type table]a do
      {[], [{tag, meta, [ident]} | acc], context, root}
    end
    def insert_node({:with = tag, meta, []}, [{:recursive = t,  m, []}, {:ident, _, _} = l, {:parens, _, _} = r, {:as = t2, m2, a}], [], context, root) do
      {[], [], context, root ++ [{tag, meta, [{t2, m2, [{t, m, [l, r]} | a]}]}]}
    end
    def insert_node({:with = tag, meta, []}, [{:ident, _, _} = l, {:parens, _, _} = r, {:as = t2, m2, a}], [], context, root) do
      {[], [], context, root ++ [{tag, meta, [{t2, m2, [[l, r] | a]}]}]}
    end
    def insert_node({:with = tag, meta, []}, [{:ident, _, _}, {:as, _, _}] = unit, acc, context, root) do
      {[], [], context, root ++ [{tag, meta, unit ++ acc}]}
    end
    def insert_node({tag, meta, []}, unit, acc, context, root) when tag in ~w[by in references]a do
      {[{tag, meta, predicate(unit ++ acc)}], [], context, root}
    end
    def insert_node(node, [n|_] = unit, acc, context, root) when (is_on(n) or is_of(n)) and elem(node, 0) in ~w[select insert update delete truncate references trigger create connect temporary execute usage set alter system maintain]a do
      {[node|unit], acc, context, root}
    end
    def insert_node(node, [_, n|_] = unit, acc, context, root) when is_for(n) and is_from(node) do
      {[node|unit], acc, context, root}
    end
    def insert_node(node, [_, _, _, n|_] = unit, acc, context, root) when is_for(n) and is_select(node) do
      {[node|unit], acc, context, root}
    end
    def insert_node(node, [] = unit, [] = acc, [] = context, root) when elem(node, 0) in ~w[create drop insert alter update delete start set open close commit rollback]a do
      {[node | unit], acc, context, root}
    end
    def insert_node({tag, meta, []}, unit, acc, context, root) when tag in ~w[create drop insert alter update delete start set open close commit rollback]a do
      {[], [], context, [{tag, meta, List.wrap(predicate(unit ++ acc))} | root]}
    end
    def insert_node(node, [n |_] = unit, acc, context, root) when is_grant(node) and elem(n, 0) == :option do
      {[node | unit], acc, context, root}
    end
    def insert_node(node, unit, acc, context, root) when is_grant(node) or is_revoke(node) or is_declare(node) do
      {[], [], context, [{elem(node, 0), elem(node, 1), unit ++ acc ++ root}]}
    end
    def insert_node({:distinct = tag, meta, []}, [{:on, _, _} = on | unit], acc, context, root) do
      {[{tag, meta, [on]} | unit], acc, context, root}
    end
    def insert_node(node, [u | unit], acc, context, root) when is_fetch_dir(node) and elem(u, 0) != :in do
      {[{elem(node, 0), elem(node, 1), [u]}], unit++acc, context, root}
    end
    def insert_node(node, [u | unit], acc, context, root) when is_fetch(node) do
      {[], [], context, [{elem(node, 0), elem(node, 1), [u]} | unit ++ acc ++ root]}
    end
    def insert_node(node, [on], [], context, root) when is_join(node) and is_on(on) do
      {[], [], context, [{elem(node, 0), elem(node, 1), elem(node, 2) ++ [on]} | root]}
    end
    def insert_node(node, [ident, on], [] = acc, context, root) when is_join(node) and is_on(on) do
      {[], acc, context, [{elem(node, 0), elem(node, 1), elem(node, 2) ++ [{elem(on, 0), elem(on, 1), [ident | elem(on, 2)]}]} | root]}
    end
    def insert_node(node, [ident, as, on | unit], [] = acc, context, root) when is_join(node) and is_on(on) do
      {[], acc, context, [{elem(node, 0), elem(node, 1), elem(node, 2) ++ [{elem(on, 0), elem(on, 1), [[ident, as]] ++ elem(on, 2) ++ unit}]} | root]}
    end
    def insert_node(node, [ident, on | unit], [] = acc, context, root) when is_join(node) and is_on(on) do
      {[], acc, context, [{elem(node, 0), elem(node, 1), elem(node, 2) ++ [{elem(on, 0), elem(on, 1), [ident] ++ elem(on, 2) ++ unit}]} | root]}
    end
    def insert_node(node, unit, acc, context, root) when is_join(node) do
      a = elem(node, 2)
      acc = unit ++ acc
      acc = if a == [], do: acc, else: a ++ [acc]
      {[], [], context, [{elem(node, 0), elem(node, 1), acc} | root]}
    end
    def insert_node({tag, meta, []}, unit, acc, context, root) when tag in ~w[select from where group having order limit offset]a do
      {[], [], context, [{tag, meta, List.wrap(predicate(unit ++ acc))} | root]}
    end
    def insert_node(node, unit, acc, context, {:colon, meta, []}) do
      {unit, acc, context, {:colon, meta, [node]}}
    end
    def insert_node(node, [parens | unit], acc, context, root) when is_parens(parens) and is_keyword(node) do
      {[{elem(node, 0), elem(node, 1), [parens]} | unit], acc, context, root}
    end
    def insert_node(node, unit, acc, context, root)  do
      {[node | unit], acc, context, root}
    end

    def parse(tokens) do
      parse(tokens, [], [], [], [])
    end
    def parse([], [], [], [], root) do
      root
    end
    def parse([], unit, acc, [], []) do
      predicate(unit ++ acc)
    end
    def parse([], unit, acc, [], root) do
      predicate(unit ++ acc) ++ root
    end
    def parse([], unit, acc, context, root) when is_tuple(context) do
      [{elem(context, 0), elem(context, 1), [unit ++ acc ++ root, elem(context, 2)]}]
    end
    def parse([node | rest], unit, acc, context, root) when is_comment(node) do
      parse(rest, unit, acc, context, [node | root])
    end
    def parse([{:all, m, _}, node | rest], unit, acc, [], root) when is_combinator(node) do
      parse(rest, [], [], {elem(node, 0), elem(node, 1), [{:all, m, unit ++ acc ++ root}]}, [])
    end
    def parse([node | rest], unit, acc, [], root) when is_combinator(node) do
      parse(rest, [], [], {elem(node, 0), elem(node, 1), unit ++ acc ++ root}, [])
    end
    def parse([node | rest], unit, acc, context, root) when is_colon(node) do
      parse(rest, [], [], context, [{elem(node, 0), elem(node, 1), unit ++ acc ++ root}])
    end
    def parse([ident, from, distinct, n, is, left | rest], unit, acc, context, root) when is_is(is) and is_from(from) and is_distinct(distinct) do
      node = {elem(is, 0), elem(is, 1), [left, {elem(n, 0), elem(n, 1), [{elem(distinct, 0), elem(distinct, 1), [{elem(from, 0), elem(from, 1), [ident]}]}]}]}
      {unit, acc, context, root} = insert_node(node, unit, acc, context, root)
      parse(rest, unit, acc, context, root)
    end
    def parse([ident, from, distinct, is, left | rest], unit, acc, context, root) when is_is(is) and is_from(from) and is_distinct(distinct) do
      node = {elem(is, 0), elem(is, 1), [left, {elem(distinct, 0), elem(distinct, 1), [{elem(from, 0), elem(from, 1), [ident]}]}]}
      {unit, acc, context, root} = insert_node(node, unit, acc, context, root)
      parse(rest, unit, acc, context, root)
    end
    def parse([node | rest], unit, acc, context, root) when is_colon(node) do
      parse(rest, [], [], context, [{elem(node, 0), elem(node, 1), unit ++ acc ++ root}])
    end
    def parse([parens, node | rest], unit, acc, [], root) when is_parens(parens) and is_combinator(node) do
      parse(rest, unit, acc, {elem(node, 0), elem(node, 1), [{elem(parens, 0), elem(parens, 1), parse(elem(parens, 2))}]}, root)
    end
    def parse([node | rest], unit, acc, context, root) when is_comma(node) do
      parse(rest, [], [{elem(node, 0), elem(node, 1), predicate(unit)} | acc], context, root)
    end
    def parse([node | rest], unit, acc, context, root) do
      {unit, acc, context, root} = insert_node(node, unit, acc, context, root)
      parse(rest, unit, acc, context, root)
    end
  end
  """)


  embed_template(:lexer, """
  # SPDX-License-Identifier: Apache-2.0
  # SPDX-FileCopyrightText: 2025 DBVisor

  defmodule <%= inspect @mod %> do
    @moduledoc false
    @compile {:inline, lex: 9, lex: 4, meta: 3, merge: 3, type: 2, node: 5}

    defguard is_data_type(node) when elem(node, 0) in ~w[integer float ident quote double_quote backtick bracket parens .]a
    defguard is_newline(b) when b in <%= inspect(@newline) %>
    defguard is_space(b) when b in <%= inspect(@space) %>
    defguard is_whitespace(b) when b in <%= inspect(@whitespace) %>

    def opening_delimiter(:parens), do: :"("
    def opening_delimiter(:bracket), do: :"["
    def opening_delimiter(:double_quote), do: :"\\""
    def opening_delimiter(:quote), do: :"'"
    def opening_delimiter(:backtick), do: :"`"
    def opening_delimiter(type) when type in ~w[var code braces]a, do: :"{"

    def expected_delimiter(:parens), do: :")"
    def expected_delimiter(:bracket), do: :"]"
    def expected_delimiter(:double_quote), do: :"\\""
    def expected_delimiter(:quote), do: :"'"
    def expected_delimiter(:backtick), do: :"`"
    def expected_delimiter(type) when type in ~w[var code braces]a, do: :"}"

    def lex(binary, file, params \\\\ 0, opts \\\\ [metadata: true]) do
      case lex(binary, binary, [{:binding, []}, {:params, params}, {:file, file} | opts], 0, 0, nil, [], [], 0) do
        {"", _binary, opts, line, column, nil = type, data, acc, _n} ->
          {:ok, opts, line, column, type, data, acc}

        {"", binary, _opts, end_line, end_column, type, _data, [{_, [line: line, column: column, file: file], _}|_], _n} when type in ~w[parens bracket double_quote quote backtick var code]a ->
          raise TokenMissingError, file: file, snippet: binary, end_line: end_line, end_column: end_column, line: line, column: column, opening_delimiter: opening_delimiter(type), expected_delimiter: expected_delimiter(type)

        {"", _binary, opts, line, column, type, data, acc, _n} ->
          {:ok, opts, line, column, type, data, insert_node(node(ident(type, data), line, column, data, opts), acc)}
      end
    end
    def lex("" = rest, binary, opts, line, column, type, data, acc, n) do
      {rest, binary, opts, line, column, type, data, acc, n}
    end
    def lex(<<?-, ?-, rest::binary>>, binary, opts, line, column, type, data, acc, n) do
      lex(rest, binary, opts, line, column+2, :comment, [], insert_node(type, line, column, data, opts, acc), n)
    end
    def lex(<<?/, ?*, rest::binary>>, binary, opts, line, column, _type, data, acc, n) do
      lex(rest, binary, opts, line, column+2, :comments, data, acc, n)
    end
    def lex(<<?*, ?/, rest::binary>>, binary, opts, line, column, :comments, data, acc, n) do
      lex(rest, binary, opts, line, column+2, nil, [], insert_node(node(:comments, line, column, data, opts), acc), n)
    end
    def lex(<<b, rest::binary>>, binary, opts, line, column, :comments, data, acc, n) do
      lex(rest, binary, opts, line, column+1, :comments, [data | [b]], acc, n)
    end
    def lex(<<?{, ?{, rest::binary>>, binary, opts, line, column, nil, data, acc, n) do
      lex(rest, binary, opts, line, column+2, :var, data, acc, n)
    end
    def lex(<<?}, ?}, rest::binary>>, binary, [_, _, _, {:format, true}] = opts, line, column, _type, data, acc, 0 = n), do: lex(rest, binary, opts, line, column+2, nil, [], insert_node(node(:binding, line, column, data, opts), acc), n)
    def lex(<<?}, ?}, rest::binary>>, binary, opts, line, column, type, data, acc, 0 = n) when type in ~w[code var]a do
      opts = opts
             |> Keyword.update!(:binding, &(&1 ++ [{type, IO.iodata_to_binary(data)}]))
             |> Keyword.update!(:params, &(&1+1))
      lex(rest, binary, opts, line, column+2, nil, [], insert_node(node(:binding, line, column, Keyword.get(opts, :params), opts), acc), n)
    end
    def lex(<<?}, rest::binary>>, binary, opts, line, column, :code = type, data, acc, n) do
      lex(rest, binary, opts, line, column+1, type, [data | [?}]], acc, n-1)
    end
    def lex(<<b, rest::binary>>, binary, opts, line, column, type, data, acc, n) when type in ~w[var code]a and b in [?{] do
      lex(rest, binary, opts, line, column+1, :code, [data | [b]], acc, n+1)
    end
    def lex(<<b, rest::binary>>, binary, opts, line, column, :var = type, data, acc, n) when b in ?0..?9 and data != [] do
      lex(rest, binary, opts, line, column+1, type, [data | [b]], acc, n)
    end
    def lex(<<b, rest::binary>>, binary, opts, line, column, :var = type, data, acc, n) when b in ?a..?z or b in ?A..?Z or (b == ?_ and data != []) do
      lex(rest, binary, opts, line, column+1, type, [data | [b]], acc, n)
    end
    def lex(<<b, rest::binary>>, binary, opts, line, column, type, data, acc, n) when type in ~w[var code]a do
      lex(rest, binary, opts, line, column+1, :code, [data | [b]], acc, n)
    end
    def lex(<<b, rest::binary>>, binary, opts, line, column, type, data, acc, n) when b in [?(, ?[] do
      acc = case ident(type, data) do
        nil -> acc
        :ident -> insert_node(node(type, line, column, data, opts), acc)
        tag -> insert_node(node(tag, line, column, [], opts), acc)
      end
      case lex(rest, binary, opts, line, column+1, nil, [], [], n) do
        {rest, opts, line, column, value} ->
        lex(rest, binary, opts, line, column, nil, [], insert_node(node(ident(type, [b]), line, column, value, opts), acc), n)
        {rest, binary, o, l, c, t, d, a, _n} ->
        value = if t, do: insert_node(node(t, l, c, d, o), a), else: a
        lex(rest, binary, opts, l, c, (if b == ?(, do: :parens, else: :bracket), [], insert_node(node(ident(type, [b]), line, column, value, opts), acc), n)
      end
    end
    def lex(<<b, rest::binary>>, _binary, opts, line, column, type, data, acc, _n) when b in [?), ?]] do
      acc =  if type, do: insert_node(node(type, line, column, data, opts), acc), else: acc
      {rest, opts, line, column+1, acc}
    end
    def lex(<<?", rest::binary>>, binary, opts, line, column, :double_quote = type, data, acc, n) do
      lex(rest, binary, opts, line, column+1, nil, [], insert_node(node(type, line, column, data, opts), acc), n)
    end
    def lex(<<?`, rest::binary>>, binary, opts, line, column, :backtick = type, data, acc, n) do
      lex(rest, binary, opts, line, column+1, nil, [], insert_node(node(type, line, column, data, opts), acc), n)
    end
    def lex(<<?', rest::binary>>, binary, opts, line, column, :quote = type, data, acc, n) do
      lex(rest, binary, opts, line, column+1, nil, [], insert_node(node(type, line, column, data, opts), acc), n)
    end
    def lex(<<b, rest::binary>>, binary, opts, line, column, type, data, acc, n) when type in ~w[double_quote quote backtick]a do
      lex(rest, binary, opts, line, column+1, type, [data | [b]], acc, n)
    end
    def lex(<<b::utf8, rest::binary>>, binary, opts, line, column, type, data, acc, n) when is_newline(b) do
      if data == [] do
        lex(rest, binary, opts, line+1, column, type, data, acc, n)
      else
        tag = ident(type, data)
        lex(rest, binary, opts, line+1, column, nil, [], insert_node(node(tag, line, column, data, opts), acc), n)
      end
    end
    def lex(<<b::utf8, rest::binary>>, binary, opts, line, column, type, data, acc, n) when is_space(b) do
      if data == [] do
        lex(rest, binary, opts, line, column+1, type, data, acc, n)
      else
        tag = ident(type, data)
        lex(rest, binary, opts, line, column+1, nil, [], insert_node(node(tag, line, column, data, opts), acc), n)
      end
    end
    def lex(<<b::utf8, rest::binary>>, binary, opts, line, column, type, data, acc, n) when is_whitespace(b) do
      if data == [] do
        lex(rest, binary, opts, line, column+1, type, data, acc, n)
      else
        tag = ident(type, data)
        lex(rest, binary, opts, line, column+1, nil, [], insert_node(node(tag, line, column, data, opts), acc), n)
      end
    end
    def lex(<<b, rest::binary>>, binary, opts, line, column, type, data, acc, n) when b in [?,, ?;] do
      acc = if type, do: insert_node(node(ident(type, data), line, column, data, opts), acc), else: acc
      lex(rest, binary, opts, line, column, nil, [], insert_node(node(type(b), line, column+1, [], opts), acc), n)
    end
    def lex(<<b::binary-size(3), rest::binary>>, binary, opts, line, column, type, data, acc, n) when b in ~w[^-= |*= <=>] do
      node = node(String.to_atom(b), line, column+3, [], opts)
      if data == [] do
        lex(rest, binary, opts, line, column+3, type, data, insert_node(node, acc), n)
      else
        lex(rest, binary, opts, line, column+3, nil, [], insert_node(node, insert_node(node(ident(type, data), line, column, data, opts), acc)), n)
      end
    end
    def lex(<<b::binary-size(2), rest::binary>>, binary, opts, line, column, type, data, acc, n) when b in ~w[:: <> != !< !> <= >= += -= *= /= %= &= ||] do
      node = node(String.to_atom(b), line, column+2, [], opts)
      if data == [] do
        lex(rest, binary, opts, line, column+2, type, data, insert_node(node, acc), n)
      else
        lex(rest, binary, opts, line, column+2, nil, [], insert_node(node, insert_node(node(ident(type, data), line, column, data, opts), acc)), n)
      end
    end
    def lex(<<b, e, rest::binary>>, binary, opts, line, column, type, data, acc, n) when type in ~w[integer float]a and b in [?E, ?e] and (e in [?-, ?+] or e in ?0..?9) do
      type = :float
      lex(rest, binary, opts, line, column+2, type, merge(merge(data, b, type), e, type), acc, n)
    end
    def lex(<<b, e, rest::binary>>, binary, opts, line, column, nil, [], acc, n) when b == ?. and e in ?0..?9 do
      lex(rest, binary, opts, line, column+2, :float, [b, e], acc, n)
    end
    def lex(<<b, e, rest::binary>>, binary, opts, line, column, nil, [], acc, n) when b in [?-, ?+] and e == ?. do
      lex(rest, binary, opts, line, column+2, :float, [b,e], acc, n)
    end
    def lex(<<b, rest::binary>>, binary, opts, line, column, :integer, data, acc, n) when b == ?. do
      type = :float
      lex(rest, binary, opts, line, column+1, type, merge(data, b, type), acc, n)
    end
    def lex(<<b, rest::binary>>, binary, opts, line, column, type, data, acc, n) when b == ?. do
      node = node(List.to_atom([b]), line, column+1, [], opts)
      if data == [] do
        lex(rest, binary, opts, line, column+1, type, data, insert_node(node, acc), n)
      else
        lex(rest, binary, opts, line, column+1, nil, [], insert_node(node, insert_node(node(ident(type, data), line, column, data, opts), acc)), n)
      end
    end
    def lex(<<b, rest::binary>>, binary, opts, line, column, _type, [] = data, [node | _] = acc, n) when b in [?+, ?-, ?^, ?*, ?/, ?%, ?&, ?<, ?>, ?=] and is_data_type(node) do
      node = node(List.to_atom([b]), line, column+1, data, opts)
      lex(rest, binary, opts, line, column+1, nil, data, insert_node(node, acc), n)
    end
    def lex(<<b, c, rest::binary>>, binary, opts, line, column, nil, [], acc, n) when b in [?+, ?-] and c in ?0..?9 do
      lex(rest, binary, opts, line, column+2, :integer, [b, c], acc, n)
    end
    def lex(<<b, rest::binary>>, binary, opts, line, column, nil = type, data, acc, n) when b in [?+, ?-, ?^, ?*, ?/, ?%, ?&, ?<, ?>, ?=] do
      node = node(List.to_atom([b]), line, column+1, data, opts)
      lex(rest, binary, opts, line, column+1, type, data, insert_node(node, acc), n)
    end
    def lex(<<b, rest::binary>>, binary, opts, line, column, type, data, acc, n) when b in [?+, ?-, ?^, ?*, ?/, ?%, ?&, ?<, ?>, ?=] and type in ~w[integer float ident quote double_quote backtick bracket parens nil]a do
      node = node(List.to_atom([b]), line, column+1, [], opts)
      lex(rest, binary, opts, line, column+1, nil, [], insert_node(node, insert_node(node(ident(type, data), line, column, data, opts), acc)), n)
    end
    def lex(<<b, rest::binary>>, binary, opts, line, column, type, data, acc, n) do
      type = type(b, type)
      lex(rest, binary, opts, line, column+1, type, merge(data, b, type), acc, n)
    end

    def insert_node(nil, _line, _column, _data, _opts, acc) do
      acc
    end
    def insert_node(type, line, column, data, opts, acc) do
        insert_node(node(type, line, column, data, opts), acc)
    end
    def insert_node(right, [{:. = tag, m, a}, {:., _, [_, _]} = left | acc]) do
      [{tag, m, [left, right | a]} | acc]
    end
    def insert_node(right, [{:. = tag, meta, [left]} | acc]) do
      [{tag, meta, [left, right]} | acc]
    end
    def insert_node({:., _, _} = node, [right, {:. = tag, m, []}, left | acc]) do
      [node, {tag, m, [left, right]} | acc]
    end
    def insert_node({:. = t, m, a}, [left | acc]) do
      [{t, m, [left|a]} | acc]
    end
    def insert_node({:join = t, m, a} = node, acc) do
      case join(acc) do
        {qualified, rest} -> [{t, m, [qualified|a]} | rest]
        rest -> [node | rest]
      end
    end
    def insert_node(node, acc) do
      [node | acc]
    end

    def join([{:outer, _} = r, {tag, _} = l, {:natural, _} = n | rest]) when tag in ~w[left right full]a do
      {[n, l, r], rest}
    end
    def join([{:outer, _} = r, {tag, _} = l | rest]) when tag in ~w[left right full]a do
      {[l, r], rest}
    end
    def join([{:inner, _} = r, {:natural, _} = l| rest]) do
      {[l, r], rest}
    end
    def join([{tag, _} = l | rest]) when tag in ~w[inner left right full natural cross]a do
      {[l], rest}
    end
    def join(acc) do
      acc
    end

    def merge([] = data, _b, type) when type in ~w[double_quote quote backtick]a, do: data
    def merge(data, b, _type), do: [data | [b]]

    def type(?;), do: :colon
    def type(?,), do: :comma
    def type(?"), do: :double_quote
    def type(?'), do: :quote
    def type(?`), do: :backtick
    def type(?(), do: :left_paren
    def type(?)), do: :right_paren
    def type(?[), do: :left_bracket
    def type(?]), do: :right_bracket

    def type(%param{}), do: param
    def type(param) when is_float(param), do: :float
    def type(param) when is_integer(param), do: :integer
    def type(param) when is_map(param), do: :map
    def type(param) when is_list(param), do: {:list, Enum.uniq(Enum.map(param, &type/1))}
    def type(param) when is_binary(param), do: :string
    def type(_param), do: nil

    def type(_, type) when type in ~w[double_quote quote backtick comment comments]a, do: type
    def type(?", _type), do: :double_quote
    def type(?', _type), do: :quote
    def type(?`, _type), do: :backtick
    def type(b, type) when b in ?0..?9 and type in ~w[nil integer float]a, do: type || :integer
    def type(?., :integer), do: :float
    def type(_b, _type), do: :ident

    def meta(_line, _column, [_,_,_,{_,false}|_]), do: []
    def meta(line, column, [_, _, {_, file} |_]), do: [line: line, column: column, file: file]

    def node(:binding = tag, line, column, [idx], [{:binding, false}, {:params, params}|_] = opts) do
      {tag, meta(line, column, opts), Enum.at(params, idx)}
    end
    def node(:binding = tag, line, column, data, opts) when is_integer(data), do: {tag, meta(line, column, opts), [data]}
    def node(tag, line, column, data, opts) when tag in ~w[ident float integer double_quote quote backtick binding parens bracket . comment comments]a do
      data = case data do
                [] -> data
                [{_, _, _} | _] -> data
                _ -> [IO.iodata_to_binary(data)]
              end
      {tag, meta(line, column, opts), data}
    end
    def node(tag, line, column, _data, opts) when tag in ~w[asterisk inner left right full natural cross outer]a do
      {tag, meta(line, column, opts)}
    end
    def node(tag, line, column, _data, opts) do
      {tag, meta(line, column, opts), []}
    end

    def ident(_type, [?*]), do: :asterisk
    def ident(_type, [?(]), do: :parens
    def ident(_type, [?[]), do: :bracket
    <%= for keyword <- @keywords do %>
      def ident(:ident, <%= Enum.reduce(1..byte_size(keyword), "[]", fn n, acc -> "[\#{acc}, b\#{n}]" end) %>) when <%= guard(keyword) %>, do: <%= inspect(String.to_atom(String.downcase(keyword))) %>
    <% end %>
      def ident(type, _), do: type
  end
  """)
end
