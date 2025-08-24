# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Lexer do
  @moduledoc false
  require Unicode.Set
  @context %{idx: 0, file: "nofile", binding: [], aliases: [], errors: []}
  def lex(binary), do: lex(binary, @context)
  def lex(binary, <<file::binary>>), do: lex(binary, %{@context | file: file})
  def lex(binary, %{}=context) do
    case lex(binary, context, 0, 0, []) do
      {:error, error} -> raise TokenMissingError, [{:snippet, binary} | error]
      {_, _, context, acc} -> {:ok, context, acc}
    end
  end
  def lex(binary, <<file::binary>>, idx), do: lex(binary, %{@context | file: file, idx: idx})

  def lex(<<?-, ?-, rest::binary>>, %{file: file}=context, line, column, acc) do
    {rest, data, l, c} = comment(rest, [], line, column+2)
    lex(rest, context, l, c, [{:comment, [type: :literal, line: line, column: column, end_line: l, end_column: c, file: file], data}|acc])
  end
  def lex(<<?/, ?*, rest::binary>>, %{file: file}=context, line, column, acc) do
    case comments(rest, [], line, column+2) do
      {:error, l, c} ->
        {:error, file: file, end_line: l, end_column: c, line: line, column: column, opening_delimiter: :"/*", expected_delimiter: :"*/"}

      {rest, data, l, c} ->
        lex(rest, context, l, c, [{:comments, [type: :literal, line: line, column: column, end_line: l, end_column: c, file: file], data}|acc])
    end
  end
  def lex(<<?{, ?{, rest::binary>>, %{idx: idx, binding: binding, file: file}=context, line, column, acc) do
    case double_brace(rest, [], line, column+2, 0) do
      {:error, l, c} ->
        {:error, file: file, end_line: l, end_column: c, line: line, column: column, opening_delimiter: :"{", expected_delimiter: :"}"}

      {rest, data, l, c} ->
        idx = idx+1
        value = Code.string_to_quoted!(:lists.flatten(data), file: file, line: line, column: column, columns: true, token_metadata: true, existing_atoms_only: true)
        binding = :lists.append([binding, [value]])
        lex(rest, %{context|idx: idx, binding: binding}, l, c, [{:binding, [type: :literal, line: line, column: column, end_line: l, end_column: c, file: file], [idx]}|acc])
    end
  end
  def lex(<<?., rest::binary>>, %{file: file}=context, line, column, [{t, _, _}|_]=acc) when t in ~w[ident double_quote bracket]a do
    end_column = column+1
    lex(rest, context, line, end_column, [{:dot, [type: :operator, line: line, column: column, end_column: end_column, file: file], []}|acc])
  end
  def lex(<<?;, rest::binary>>, %{file: file}=context, line, column, acc) do
    end_column = column+1
    lex(rest, context, line, end_column, [{:colon, [type: :delimiter, line: line, column: column, end_column: end_column, file: file], acc}])
  end
  def lex(<<?,, rest::binary>>, %{file: file}=context, line, column, acc) do
    end_column = column+1
    lex(rest, context, line, end_column, [{:comma, [type: :delimiter, line: line, column: column, end_column: end_column, file: file], []}|acc])
  end
  def lex(<<?(, rest::binary>>, %{file: file}=context, line, column, acc) do
    case lex(rest, context, line, column+1, []) do
      {rest, context, l, c, data} ->
        lex(rest, context, l, c, [{:paren, [type: :expression, line: line, column: column, end_line: l, end_column: c, file: file], data}|acc])
      {end_line, end_column, _context, _acc} ->
        {:error, file: file, end_line: end_line, end_column: end_column, line: line, column: column, opening_delimiter: :"(", expected_delimiter: :")"}
    end
  end
  def lex(<<?[, rest::binary>>, %{file: file}=context, line, column, acc) do
    case lex(rest, context, line, column+1, []) do
      {rest, context, l, c, data} ->
        lex(rest, context, l, c, [{:bracket, [type: :expression, line: line, column: column, end_line: l, end_column: c, file: file], data}|acc])
      {end_line, end_column, _context, _acc} ->
        {:error, file: file, end_line: end_line, end_column: end_column, line: line, column: column, opening_delimiter: :"[", expected_delimiter: :"]"}
    end
  end
  def lex(<<?{, rest::binary>>, %{file: file}=context, line, column, acc) do
    case lex(rest, context, line, column+1, []) do
      {rest, context, l, c, data} ->
        lex(rest, context, l, c, [{:brace, [type: :expression, line: line, column: column, end_line: l, end_column: c, file: file], data}|acc])
      {end_line, end_column, _context, _acc} ->
        {:error, file: file, end_line: end_line, end_column: end_column, line: line, column: column, opening_delimiter: :"{", expected_delimiter: :"}"}
    end
  end
  def lex(<<?", rest::binary>>, %{file: file}=context, line, column, acc) do
    case double_quote(rest, [], line, column+1) do
      {:error, l, c} ->
        {:error, file: file, end_line: l, end_column: c, line: line, column: column, opening_delimiter: :"\"", expected_delimiter: :"\""}

      {rest, data, l, c} ->
        lex(rest, context, l, c, [{:double_quote, [type: :literal, line: line, column: column, end_line: l, end_column: c, file: file], data}|acc])
    end
  end
  def lex(<<?', rest::binary>>, %{file: file}=context, line, column, acc) do
    case quote(rest, [], line, column+1) do
      {:error, l, c} ->
        {:error, file: file, end_line: l, end_column: c, line: line, column: column, opening_delimiter: :"'", expected_delimiter: :"'"}

      {rest, data, l, c} ->
        lex(rest, context, l, c, [{:quote, [type: :literal, line: line, column: column, end_line: l, end_column: c, file: file], data}|acc])
    end
  end
  def lex(<<?`, rest::binary>>, %{file: file}=context, line, column, acc) do
    case backtick(rest, [], line, column+1) do
      {:error, l, c} ->
        {:error, file: file, end_line: l, end_column: c, line: line, column: column, opening_delimiter: :"`", expected_delimiter: :"`"}

      {rest, data, l, c} ->
        lex(rest, context, l, c, [{:backtick, [type: :literal, line: line, column: column, end_line: l, end_column: c, file: file], data}|acc])
    end
  end
  def lex(<<?0, b, rest::binary>>, %{file: file}=context, line, column, acc) when b in ~c"Xx" do
    {rest, data, c} = hex(rest, [?0,b], column+2)
    lex(rest, context, line, c, [{:numeric, [type: :hexadecimal, line: line, column: column, end_column: c, file: file], data}|acc])
  end
  def lex(<<?0, b, rest::binary>>, %{file: file}=context, line, column, acc) when b in ~c"Bb" do
    {rest, data, c} = bin(rest, [?0,b], column+2)
    lex(rest, context, line, c, [{:numeric, [type: :binary, line: line, column: column, end_column: c, file: file], data}|acc])
  end
  def lex(<<?0, b, rest::binary>>, %{file: file}=context, line, column, acc) when b in ~c"Oo" do
    {rest, data, c} = oct(rest, [?0,b], column+2)
    lex(rest, context, line, c, [{:numeric, [type: :octal, line: line, column: column, end_column: c, file: file], data}|acc])
  end
  def lex(<<s, ?., b, rest::binary>>, %{file: file}=context, line, column, [{t,_,_}|_]=acc) when b in ?0..?9 and s in ~c"+-Ee" and t not in ~w[ident numeric]a do
    {rest, data, c} = num(rest, [s,?., b], column+3)
    lex(rest, context, line, c, [{:numeric, [type: :float, line: line, column: column, end_column: c, file: file], data}|acc])
  end
  def lex(<<b, n, rest::binary>>, %{file: file}=context, line, column, [{t,_,_}|_]=acc) when n in ?0..?9 and b in ~c"+-.Ee" and t not in ~w[ident numeric]a do
    {rest, data, c} = num(rest, [b,n], column+2)
    lex(rest, context, line, c, [{:numeric, [type: :literal, line: line, column: column, end_column: c, file: file], data}|acc])
  end
  def lex(<<b, rest::binary>>, %{file: file}=context, line, column, acc) when b in ?0..?9 do
    {rest, data, c} = num(rest, [b], column+1)
    lex(rest, context, line, c, [{:numeric, [type: :literal, line: line, column: column, end_column: c, file: file], data}|acc])
  end
  def lex(<<b, rest::binary>>, %{file: file}=context, line, column, acc) when b in ~c"!#$%&*+-/:<=>?@^|~" do
    case special(rest, [[]|[b]], column+1) do
      {rest, [_|_]=data, c} ->
        node = {:special, [type: :literal, line: line, column: column, end_column: c, file: file], data}
        lex(rest, Map.update!(context, :errors, &:lists.append([[node],&1])), line, c, [node|acc])
      {rest, tag, c} ->
        lex(rest, context, line, c, [{tag, [type: :operator, line: line, column: column, end_column: c, file: file], []}|acc])
    end
  end
  def lex(<<b, rest::binary>>, %{file: file}=context, line, column, acc) when Unicode.Set.match?(b, "[[:Lu:], [:Ll:], [:Lt:], [:Lm:], [:Lo:], [:Nl:]]") or b == ?_ do
    case ident(rest, [[]|[b]], line, column+1) do
      {rest, :operator, tag, l, c} ->
        lex(rest, context, l, c, [{tag, [type: :operator, line: line, column: column, end_line: l, end_column: c, file: file], []}|acc])
      {rest, tag, prefix, data, l, c} ->
        lex(rest, context, l, c, [{tag, [prefix: prefix, type: :literal, line: line, column: column, end_line: l, end_column: c, file: file], data}|acc])
      {rest, [_|_]=data, l, c} ->
        lex(rest, context, l, c, [{:ident, [type: :literal, line: line, column: column, end_line: l, end_column: c, file: file], data}|acc])
      {rest, tag, l, c} ->
        lex(rest, context, l, c, [{tag, [type: :reserved, line: line, column: column, end_line: l, end_column: c, file: file], []}|acc])
      {rest, tag, data, l, c} ->
        lex(rest, context, l, c, [{:ident, [tag: tag, type: :non_reserved, line: line, column: column, end_line: l, end_column: c, file: file], data}|acc])
    end
  end
  def lex(<<b, rest::binary>>, context, line, column, acc) when b == 32 or b in 8192..8205 or b in [9, 13, 160, 5760, 6158, 8239, 8287, 8288, 12288, 65279] do
    lex(rest, context, line, column+1, acc)
  end
  def lex(<<b, rest::binary>>, context, line, column, acc) when b in 10..13 or b in [133, 8232, 8233] do
    lex(rest, context, line+1, column, acc)
  end
  def lex(<<?), rest::binary>>, context, line, column, acc) do
    {rest, context, line, column+1, acc}
  end
  def lex(<<?], rest::binary>>, context, line, column, acc) do
    {rest, context, line, column+1, acc}
  end
  def lex(<<?}, rest::binary>>, context, line, column, acc) do
    {rest, context, line, column+1, acc}
  end
  def lex("", context, line, column, acc) do
    {line, column, context, acc}
  end

  operators = [
    {:asterisk, [type: :mysql], ["*"]},
    {:solidus, [type: :mysql], ["/"]},
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
    {:as, [type: :postgres], ["as"]},
    {:ilike, [type: :postgres], ["ilike"]},
    {:like, [type: :postgres], ["like"]},
    {:in, [type: :postgres], ["in"]},
  ]
  rules = SQL.BNF.parse(%{
  "<reserved word>" => ~w[| LIMIT | ILIKE | BACKWARD | FORWARD | ISNULL | NOTNULL],
  operators: operators,
  download: true
  })
 reserved = rules.keywords["<reserved word>"] ++ rules.keywords["<SQL/JSON key word>"]
 operators = Enum.uniq(Enum.flat_map(rules.operators, &elem(&1, 1)))

  suggestions = Enum.map(operators, &to_string(elem(&1, 0)))
  def suggest_operator(value) do
      Enum.sort(Enum.filter(unquote(suggestions), &(String.jaro_distance("#{value}", &1) > 0)), &(String.jaro_distance(value, &1) >= String.jaro_distance(value, &2)))
  end

  def ident(<<?', rest::binary>>, prefix, l, c) do
    {rest, data, l, c} = quote(rest, [], l, c+1)
    {rest, :quote, prefix, data, l, c}
  end
  def ident(<<?", rest::binary>>, prefix, l, c) do
    {rest, data, l, c} = double_quote(rest, [], l, c+1)
    {rest, :double_quote, prefix, data, l, c}
  end
  def ident(<<?`, rest::binary>>, prefix, l, c) do
    {rest, data, l, c} = backtick(rest, [], l, c+1)
    {rest, :backtick, prefix, data, l, c}
  end
  def ident(<<b, rest::binary>>, data, l, c) when (Unicode.Set.match?(b, "[[:Lu:], [:Ll:], [:Lt:], [:Lm:], [:Lo:], [:Nl:], [:Mn:], [:Mc:], [:Nd:], [:Pc:], [:Cf:]]") and b != ?,) or b == ?& do
    ident(rest, [data|[b]], l, c+1)
  end
  for {atom, match} <- operators do
    def ident(rest, unquote(match), l, c), do: {rest, :operator, unquote(atom), l, c}
  end
  for {atom, match, guard} <- Enum.uniq(reserved) do
    def ident(rest, unquote(match), l, c) when unquote(guard), do: {rest, unquote(atom), l, c}
  end
  for {atom, match, guard} <- Enum.uniq(rules.keywords["<non-reserved word>"]) do
    def ident(rest, unquote(match)=data, l, c) when unquote(guard), do: {rest, unquote(atom), data, l, c}
  end
  def ident(rest, data, l, c), do: {rest, data, l, c}

  def comment(<<b, rest::binary>>, data, l, c) when b in 10..13 or b in [133, 8232, 8233], do: {rest, data, l+1, c}
  def comment(<<b, rest::binary>>, data, l, c) when b == 32 or b in 8192..8205 or b in [9, 13, 160, 5760, 6158, 8239, 8287, 8288, 12288, 65279], do: {rest, data, l, c+1}
  def comment(<<b, rest::binary>>, data, l, c), do: comment(rest, [data|[b]], l, c+1)

  def comments(<<?*, ?/, rest::binary>>, data, l, c), do: {rest, data, l, c+2}
  def comments(<<b, rest::binary>>, data, l, c) when b in 10..13 or b in [133, 8232, 8233] do
    comments(rest, [data|[b]], l+1, c)
  end
  def comments(<<b, rest::binary>>, data, l, c), do: comments(rest, [data|[b]], l, c+1)
  def comments("", _data, l, c), do: {:error, l, c}

  def special(<<b, rest::binary>>, data, length) when b in ~c"%&*+-/:<=>?^_|$@!~#" do
    special(rest, [data|[b]], length+1)
  end
  for {atom, match} <- operators do
    def special(rest, unquote(match), length), do: {rest, unquote(atom), length}
  end
  def special(rest, data, length), do: {rest, data, length}

  def num(<<?., e, s, b, rest::binary>>, data, length) when b in ?0..?9 and e in ~c"Ee" and s in ~c"-+" do
    num(rest, [data|[?.,e,s,b]], length+4)
  end
  def num(<<?., b, e, s, rest::binary>>, data, length) when b in ?0..?9 and e in ~c"Ee" and s in ~c"-+" do
    num(rest, [data|[?.,b,e,s]], length+4)
  end
  def num(<<e, b, rest::binary>>, data, length) when b in ?0..?9 and e in ~c"Ee" do
    num(rest, [data|[e,b]], length+2)
  end
  def num(<<b, rest::binary>>, data, length) when b in ?0..?9 or b in ~c"._Ee-+" do
    num(rest, [data|[b]], length+1)
  end
  def num(rest, data, length), do: {rest, data, length}

  def hex(<<b, rest::binary>>, data, length) when b in ?0..?9 or b in ?A..?F or b in ?a..?f or b == ?_ do
    hex(rest, [data|[b]], length+1)
  end
  def hex(rest, data, length), do: {rest, data, length}

  def bin(<<b, rest::binary>>, data, length) when b in ?0..?1 or b == ?_ do
    bin(rest, [data|[b]], length+1)
  end
  def bin(rest, data, length), do: {rest, data, length}

  def oct(<<b, rest::binary>>, data, length) when b in ?0..?7 or b == ?_ do
    oct(rest, [data|[b]], length+1)
  end
  def oct(rest, data, length), do: {rest, data, length}

  def backtick(<<?`, rest::binary>>, data, l, c), do: {rest, data, l, c+1}
  def backtick(<<b, rest::binary>>, data, l, c) when b in 10..13 or b in [133, 8232, 8233] do
    backtick(rest, [data|[b]], l+1, c)
  end
  def backtick(<<b, rest::binary>>, data, l, c) do
    backtick(rest, [data|[b]], l, c+1)
  end
  def backtick("", _data, l, c), do: {:error, l, c}

  def double_quote(<<?", rest::binary>>, data, l, c), do: {rest, data, l, c+1}
  def double_quote(<<b, rest::binary>>, data, l, c) when b in 10..13 or b in [133, 8232, 8233] do
    double_quote(rest, [data|[b]], l+1, c)
  end
  def double_quote(<<b, rest::binary>>, data, l, c) do
    double_quote(rest, [data|[b]], l, c+1)
  end
  def double_quote("", _data, l, c), do: {:error, l, c}

  def double_brace(<<?},?}, rest::binary>>, data, l, c, 0), do: {rest, data, l, c+2}
  def double_brace(<<b, rest::binary>>, data, l, c, n) when b in 10..13 or b in [133, 8232, 8233] do
    double_brace(rest, [data|[b]], l+1, c, n)
  end
  def double_brace(<<?{, rest::binary>>, data, l, c, n) do
    double_brace(rest, [data|[?{]], l, c+1, n+1)
  end
  def double_brace(<<?}, rest::binary>>, data, l, c, n) do
    double_brace(rest, [data|[?}]], l, c+1, n-1)
  end
  def double_brace(<<b, rest::binary>>, data, l, c, n) do
    double_brace(rest, [data|[b]], l, c+1, n)
  end
  def double_brace("", _data, l, c, _n), do: {:error, l, c}

  def quote(<<?', rest::binary>>, data, l, c), do: {rest, data, l, c+1}
  def quote(<<b, rest::binary>>, data, l, c) when b in 10..13 or b in [133, 8232, 8233] do
    quote(rest, [data|[b]], l+1, c)
  end
  def quote(<<b, rest::binary>>, data, l, c) do
    quote(rest, [data|[b]], l, c+1)
  end
  def quote("", _data, l, c), do: {:error, l, c}
end
