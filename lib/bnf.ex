# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor
# https://standards.iso.org/iso-iec/9075/-2/ed-6/en/
# https://standards.iso.org/ittf/PubliclyAvailableStandards/ISO_IEC_9075-1_2023_ed_6_-_id_76583_Publication_PDF_(en).zip
# "standard/ISO_IEC_9075-2(E)_Foundation.bnf.txt"


defmodule SQL.BNF do
  @moduledoc false

  def parse(opts \\ %{}) do
    case opts do
      %{path: path} ->
          File.cwd!()
          |> Path.join(path)
          |> File.read!()
          |> parse(opts)
      %{download: true} ->
          {:ok, {_, _, body}} = :httpc.request(:get, {~c"https://standards.iso.org/iso-iec/9075/-2/ed-6/en/ISO_IEC_9075-2(E)_Foundation.bnf.txt", []}, [], [body_format: :binary])
          parse(body, opts)
      opts when is_binary(opts) ->
        parse(opts, %{})
    end
  end

  defp parse(binary, opts, type \\ :symbol, data \\ [], acc \\ [], symbol \\ [], expr \\ [], rules \\ {[], []})
  defp parse(<<>>, opts, type, data, acc, symbol, expr, rules) do
    {terminals, non_terminals} = merge(type, rules, symbol, [expr | [acc | data]])
    {terminals, non_terminals} = Enum.reduce(non_terminals, {terminals, []}, fn
      {r, [v]} = rule, {terminals, non_terminals} ->
        value = Enum.find(terminals, &(elem(&1, 0) == v))
        if value do
          {[{r, elem(value, 1)} | terminals], non_terminals}
        else
          {terminals, [rule | non_terminals]}
        end
      rule, {terminals, non_terminals} -> {terminals, [rule | non_terminals]}
    end)
    exprs = Enum.flat_map(non_terminals, &elem(&1, 1))
    %{true: non_terminals, false: root} = Enum.group_by(non_terminals, &(elem(&1, 0) in exprs))
    {keywords, operators, letters, digits, terminals} = Enum.reduce(terminals, {[], [], [], [], []}, fn
      {r, e} = rule, {keywords, operators, letters, digits, terminals} ->
        cond do
          String.ends_with?(r, "word>") == true ->
            e = if is_map_key(opts, r), do: e ++ opts[r], else: e
            {[{r, (for v <- e, v != "|", do: {atom(v), match(v), guard(v)})} | keywords], operators, letters, digits, terminals}
          String.ends_with?(r, "letter>") == true -> {keywords, operators, [{r, Enum.reject(e, &(&1 == "|"))}|letters], digits, terminals}
          String.ends_with?(r, "digit>") == true -> {keywords, operators, letters, [{r, Enum.reject(e, &(&1 == "|"))}|digits], terminals}
          String.ends_with?(r, "operator>") == true -> {keywords, [rule | operators], letters, digits, terminals}
          r in ~w[<asterisk> <solidus>] -> {keywords, [rule | operators], letters, digits, terminals}
          true -> {keywords, operators, letters, digits, [rule | terminals]}
        end
    end)

    symbols = terminals ++ operators
    operators = opts
    |> Map.get(:operators, [])
    |> Kernel.++(operators)
    |> Enum.sort_by(fn
      {_, [b]} ->  byte_size(b)
      {_, _, [b |_]} ->  byte_size(b)
    end, :desc)
    |> Enum.map(fn
      {r, e} -> {r, (for v <- e, do: {String.to_atom(v), inline_match(v)})}
      {r, _, e} -> {r, (for v <- e, do: {String.to_atom(v), inline_match(v)})}
    end)
    special_characters = Enum.filter(non_terminals ++ root, &(String.ends_with?(elem(&1, 0), "special character>") || String.ends_with?(elem(&1, 0), "special symbol>")))
    special_characters = for {_, e} <- special_characters, v <- e, v != "|", do: {String.to_atom(v), elem(Enum.find(symbols, {v, v}, &elem(&1, 0) == v), 1)}
    special_characters = special_characters ++ [tilde: ["~"], number_sign: ["#"]]
    special_characters = Enum.filter(special_characters, &byte_size(hd(elem(&1, 1))) == 1)
    %{count: {length(terminals), length(non_terminals), length(root)}, letters: letters, digits: Map.new(digits), special_characters: special_characters, keywords: Map.new(keywords), operators: operators, root: root, terminals: Map.new(terminals), non_terminals: Map.new(non_terminals)}
  end
  defp parse(<<?*, rest::binary>>, opts, :symbol = type, symbol, _acc, _data, _expr, rules) do
    parse(rest, opts, type, [], [], symbol, [], rules)
  end
  defp parse(<<?\n, ?\n, ?<, b, rest::binary>>, opts, type, data, acc, symbol, expr, rules) when type in [:non_terminal, :terminal] and (b in ?a..?z or b in ?A..?Z) do
    parse(<<?<, b, rest::binary>>, opts, :symbol, [], [], [], [], merge(type, rules, symbol, [expr | [acc | data]]))
  end
  defp parse(<<b, ?:, ?:, ?=, rest::binary>>, opts, type, data, acc, symbol, expr, rules) when b in [?\s, ?\t, ?\r, ?\n, ?\f] do
    parse(rest, opts, :terminal, [], [], "#{data}", [], merge(type, rules, symbol, [expr | acc]))
  end
  defp parse(<<?., rest::binary>>, opts, type, [?!, ?! | _] = data, acc, symbol, expr, rules) do
    parse(rest, opts, type, [], [acc, [data |  ~c"."]], symbol, expr, rules)
  end
  defp parse(<<?., ?., ?., rest::binary>>, opts, type, data, acc, symbol, expr, rules) do
    parse(rest, opts, type, [data | ~c" ..."], acc, symbol, expr, rules)
  end
  defp parse(<<?|, rest::binary>>, opts, type, data, acc, symbol, expr, rules) do
    parse(rest, opts, type, [data | ~c"|"], acc, symbol, expr, rules)
  end
  defp parse(<<b, ?<, c, rest::binary>>, opts, type, data, acc, symbol, expr, rules) when b in [?\s, ?\t, ?\r, ?\f] and type != :symbol and (c in ?a..?z or c in ?A..?Z) do
    parse(rest, opts, :non_terminal, [data | [?<, c]], acc, symbol, expr, rules)
  end
  defp parse(<<b, c, rest::binary>>, opts, type, data, acc, symbol, expr, rules) when b in [?\s, ?\t, ?\r, ?\f] and c not in [?\s, ?\t, ?\r, ?\f, ?\n] do
    parse(rest, opts, type, [data | [b, c]], acc, symbol, expr, rules)
  end
  defp parse(<<b, rest::binary>>, opts, type, data, acc, symbol, expr, rules) when b in [?\n, ?\s, ?\t, ?\r, ?\n, ?\f] do
    parse(rest, opts, type, data, acc, symbol, expr, rules)
  end
  defp parse(<<b, rest::binary>>, opts, type, data, acc, symbol, expr, rules) do
    parse(rest, opts, type, [data | [b]], acc, symbol, expr, rules)
  end

  @syntax_rules "!! See the Syntax Rules."
  defp merge(_type, rules, [], expr) when expr in [[], ""], do: rules
  defp merge(type, rules, rule, expr) when is_list(expr), do: merge(type, rules, rule, String.trim("#{expr}"))
  defp merge(_type, {terminals, non_terminals}, "<space>" = symbol, @syntax_rules), do: {[{symbol, ["\u0020"]} | terminals], non_terminals} # 32 \u0020
  defp merge(_type, {terminals, non_terminals}, "<identifier start>" = symbol, @syntax_rules), do: {[{symbol, ["[[:Lu:], [:Ll:], [:Lt:], [:Lm:], [:Lo:], [:Nl:]]"]} | terminals], non_terminals} # "Lu", "Ll", "Lt", "Lm", "Lo", or "Nl" Unicode.Set.match?(<<b::utf8>>, "[[:Lu:], [:Ll:], [:Lt:], [:Lm:], [:Lo:], [:Nl:]]")
  defp merge(_type, {terminals, non_terminals}, "<identifier extend>" = symbol, @syntax_rules), do: {[{symbol, ["[[:Mn:], [:Mc:], [:Nd:], [:Pc:], [:Cf:]]"]} | terminals], non_terminals} # 183 \u00B7 or "Mn", "Mc", "Nd", "Pc", or "Cf" Unicode.Set.match?(<<b::utf8>>, "[[:Mn:], [:Mc:], [:Nd:], [:Pc:], [:Cf:]]")
  defp merge(_type, {terminals, non_terminals}, "<Unicode escape character>" = symbol, @syntax_rules), do: {[{symbol, ["\\u"]} | terminals], non_terminals}
  defp merge(_type, {terminals, non_terminals}, "<non-double quote character>" = symbol, @syntax_rules), do: {[{symbol, [{:non_double_quote_character, [], "b != ?\""}]} | terminals], non_terminals}
  defp merge(_type, {terminals, non_terminals}, "<whitespace>" = symbol, @syntax_rules), do: {[{symbol, ["\u0009", "\u000D", "\u00A0", "\u00A0", "\u1680", "\u2000", "\u2001", "\u2002", "\u2003", "\u2004", "\u2005", "\u2006", "\u2007", "\u2008", "\u2009", "\u200A", "\u202F", "\u205F", "\u3000", "\u180E", "\u200B", "\u200C", "\u200D", "\u2060", "\uFEFF"]} | terminals], non_terminals}
  defp merge(_type, {terminals, non_terminals}, "<truncating whitespace>" = symbol, @syntax_rules), do: {terminals, [{symbol, [:ignore]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<bracketed comment contents>" = symbol, expr), do: {terminals, [map(symbol, String.replace(expr, @syntax_rules, "")) | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<newline>" = symbol, @syntax_rules), do: {[{symbol, ["\u000A", "\u000B", "\u000C", "\u000D", "\u0085", "\u2028", "\u2029"]} | terminals], non_terminals}
  defp merge(_type, {terminals, non_terminals}, "<non-quote character>" = symbol, @syntax_rules), do: {terminals, [{symbol, [{:not_qoute, "b != ?'", ""}]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<non-escaped character>" = symbol, @syntax_rules), do: {terminals, [{symbol, [{:not_escape, "b != ?\\", ""}]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<escaped character>" = symbol, @syntax_rules), do: {terminals, [{symbol, [{:escape, "b == ?\\", ""}]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<JSON path literal>" = symbol, @syntax_rules), do: {terminals, [{symbol, ["<left bracket>", "<literal>", "<right bracket>"]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<JSON path string literal>" = symbol, @syntax_rules), do: {terminals, [{symbol, ["<left bracket>", "<character string literal>", "<right bracket>"]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<JSON path numeric literal>" = symbol, @syntax_rules), do: {terminals, [{symbol, ["<left bracket>","<unsigned numeric literal>", "<right bracket>"]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<JSON path identifier>" = symbol, @syntax_rules), do: {terminals, [{symbol, ["<left bracket>","<identifier>", "<right bracket>"]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<JSON path key name>" = symbol, @syntax_rules), do: {terminals, [{symbol, ["<regular identifier>"]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<implementation-defined JSON representation option>" = symbol, @syntax_rules), do: {terminals, [{symbol, [:ignore]} | non_terminals]} # would be dialect specific
  defp merge(_type, {terminals, non_terminals}, symbol, expr) when symbol in ["<SQLSTATE class code>", "<SQLSTATE subclass code>"], do: {terminals, [map(symbol, String.replace(expr, @syntax_rules, "")) | non_terminals]} # no <separator> between <SQLSTATE char>s
  defp merge(_type, {terminals, non_terminals}, "<host label identifier>" = symbol, @syntax_rules), do: {terminals, [{symbol, [:ignore]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<host PL/I label variable>" = symbol, @syntax_rules), do: {terminals, [{symbol, [:ignore]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<embedded SQL Ada program>" = symbol, @syntax_rules), do: {terminals, [{symbol, [:ignore]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<embedded SQL C program>" = symbol, @syntax_rules), do: {terminals, [{symbol, [:ignore]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<embedded SQL COBOL program>" = symbol, @syntax_rules), do: {terminals, [{symbol, [:ignore]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<embedded SQL Fortran program>" = symbol, @syntax_rules), do: {terminals, [{symbol, [:ignore]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<embedded SQL MUMPS program>" = symbol, @syntax_rules), do: {terminals, [{symbol, [:ignore]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<embedded SQL Pascal program>" = symbol, @syntax_rules), do: {terminals, [{symbol, [:ignore]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<embedded SQL PL/I program>" = symbol, @syntax_rules), do: {terminals, [{symbol, [:ignore]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<Ada host identifier>" = symbol, @syntax_rules), do: {terminals, [{symbol, [:ignore]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<C host identifier>" = symbol, @syntax_rules), do: {terminals, [{symbol, [:ignore]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<COBOL host identifier>" = symbol, @syntax_rules), do: {terminals, [{symbol, [:ignore]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<Fortran host identifier>" = symbol, @syntax_rules), do: {terminals, [{symbol, [:ignore]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<MUMPS host identifier>" = symbol, @syntax_rules), do: {terminals, [{symbol, [:ignore]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<Pascal host identifier>" = symbol, @syntax_rules), do: {terminals, [{symbol, [:ignore]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<PL/I host identifier>" = symbol, @syntax_rules), do: {terminals, [{symbol, [:ignore]} | non_terminals]}
  defp merge(_type, {terminals, non_terminals}, "<preparable implementation-defined statement>" = symbol, @syntax_rules), do: {terminals, [{symbol, [:ignore]} | non_terminals]} # would be dialect specific
  defp merge(_type, {terminals, non_terminals}, "<direct implementation-defined statement>" = symbol, @syntax_rules), do: {terminals, [{symbol, [:ignore]} | non_terminals]} # would be dialect specific
  defp merge(_type, _rules, symbol, @syntax_rules), do: raise "Please apply rules for #{symbol} by referencing the PDF or https://github.com/ronsavage/SQL/blob/master/Syntax.rules.txt"
  defp merge(:terminal, {terminals, non_terminals}, symbol, expr), do: {[map(symbol, expr) | terminals], non_terminals}
  defp merge(:non_terminal, {terminals, non_terminals}, symbol, expr), do: {terminals, [map(symbol, expr) | non_terminals]}

  def choice(value, group \\ [], acc \\ [])
  def choice([], group, []), do: Enum.reverse(group)
  def choice([], [], acc), do: Enum.reverse(acc)
  def choice([], group, acc), do: Enum.reverse([Enum.reverse(group) | acc])
  def choice(["|" | rest], [] = group, acc), do: choice(rest, group, acc)
  def choice(["|" | rest], group, acc), do: choice(rest, [], [Enum.reverse(group) | acc])
  def choice([k | rest], group, acc), do: choice(rest, [k | group], acc)

  def optional(value, acc \\ [])
  def optional([], acc), do: choice(Enum.reverse(acc))
  def optional(["]" | rest], acc), do: {rest, optional([], acc)}
  def optional(["[" | rest], acc) do
    case optional(rest, []) do
      {rest, optional} -> optional(rest, [{:optional, optional} | acc])
      optional -> optional(rest, [{:optional, optional} | acc])
    end
  end
  def optional([node | rest], acc), do: optional(rest, [node | acc])

  def group(value, acc \\ [])
  def group([], acc), do: optional(repeat(Enum.reverse(acc)))
  def group(["}" | rest], acc), do: {rest, {:group, group([], acc)}}
  def group(["{" | rest], acc) do
    case group(rest, []) do
      {rest, group} -> group(rest, [group | acc])
      group -> group(rest, [group | acc])
    end
  end
  def group([node | rest], acc), do: group(rest, [node | acc])
  def group(expr, acc), do: group([], [expr | acc])

  def repeat(value, acc \\ [])
  def repeat([], acc), do: Enum.reverse(acc)
  def repeat([node, "..." | rest], acc), do: repeat(rest, [{:repeat, node} | acc])
  def repeat([node | rest], acc), do: repeat(rest, [node | acc])

  defp map(symbol, [v] = expr) when is_tuple(v), do: {symbol, expr}
  defp map(symbol, expr) when expr in ["|", "[", "]", [:ignore], ["\u0020"], ["\u0009", "\u000D", "\u00A0", "\u00A0", "\u1680", "\u2000", "\u2001", "\u2002", "\u2003", "\u2004", "\u2005", "\u2006", "\u2007", "\u2008", "\u2009", "\u200A", "\u202F", "\u205F", "\u3000", "\u180E", "\u200B", "\u200C", "\u200D", "\u2060", "\uFEFF"], ["\u000A", "\u000B", "\u000C", "\u000D", "\u0085", "\u2028", "\u2029"]], do: {symbol, List.wrap(expr)}
  defp map(symbol, expr) when is_list(expr), do: {symbol, expr}
  defp map(symbol, expr) when is_binary(expr) do
    {symbol, ~r"<[^>]*>"
    |> Regex.split(expr, include_captures: true, trim: true)
    |> Enum.reject(&(&1 == " "))
    |> Enum.flat_map(fn
      <<?<, _::binary>> = nt -> [nt]
      expr -> String.split(String.trim(expr), " ", trim: true)
    end)}
  end

  def cast(<<?<, b, _::binary>> = expr) when b in ?a..?z or b in ?A..?Z, do: expr
  def cast(expr) when expr in ["|", "{", "}", "[", "]", :ignore, :self, "\u0020", "\u0009", "\u000D", "\u00A0", "\u00A0", "\u1680", "\u2000", "\u2001", "\u2002", "\u2003", "\u2004", "\u2005", "\u2006", "\u2007", "\u2008", "\u2009", "\u200A", "\u202F", "\u205F", "\u3000", "\u180E", "\u200B", "\u200C", "\u200D", "\u2060", "\uFEFF", "\u000A", "\u000B", "\u000C", "\u000D", "\u0085", "\u2028", "\u2029"], do: expr
  def cast(expr) when is_binary(expr), do: {atom(expr), match(expr), guard(expr)}
  def cast(expr) when is_tuple(expr) or is_list(expr) or is_atom(expr), do: expr

  def atom(value), do: String.to_atom(String.replace(String.replace(String.downcase(value), ["<", ">"], ""), ["/", " "], "_"))
  def match(value), do: Enum.reduce(1..byte_size(value), "[]", fn n, acc -> "[#{acc}, b#{n}]" end)
  def inline_match(value) do
    for <<k <- value>>, reduce: "[]" do
      acc -> "[#{acc}, ?#{<<k>>}]"
    end
  end
  def guard(value) do
    {value, _n} = for <<k <- String.downcase(value)>>, reduce: {"", 1} do
      {"", n} -> {guard(k, n), n+1}
      {acc, n} -> {"#{acc} and #{guard(k, n)}", n+1}
    end
    value
  end
  def guard(k, n) when k in ?a..?z, do: "is_#{<<k>>}(b#{n})"
  def guard(k, n), do: "b#{n} in #{inspect(Enum.uniq(~c"#{<<k>>}#{String.upcase(<<k>>)}"))}"
end
