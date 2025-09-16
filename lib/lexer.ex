# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Lexer do
  @moduledoc false
  require Unicode.Set
  # @compile {:inline, lex: 5}

  @context %{idx: 0, file: "nofile", binding: [], aliases: [], errors: [], module: nil, format: :static, case: :lower, sql_lock: nil}
  def lex(binary, <<file::binary>> \\ "nofile", idx \\ 0) do
    case lex(binary, %{@context | file: file, idx: idx}, 0, 0, []) do
      {:error, error} -> raise TokenMissingError, [{:snippet, binary} | error]
      {:error, :zero_width, l, c} -> raise SyntaxError, [description: "illegal zero width character", file: file, line: l, column: c]
      {:error, :bidi, l, c} -> raise SyntaxError, [description: "illegal bidi character", file: file, line: l, column: c]
      {:error, :cgj, l, c} -> raise SyntaxError, [description: "illegal cgj character", file: file, line: l, column: c]
      {_, _, context, acc} -> {:ok, context, acc}
    end
  end

  def lex(<<239, 187, 191, _::binary>>, _context, l, c, _acc) do
    error(:zero_width, l, c)
  end
  def lex(<<226, 128, b, _::binary>>, _context, l, c, _acc) when b in 139..141 do
    error(:zero_width, l, c)
  end
  def lex(<<226, 129, 160, _::binary>>, _context, l, c, _acc) do
    error(:zero_width, l, c)
  end
  def lex(<<226, 128, b, _::binary>>, _context, l, c, _acc) when b in 170..174 do
    error(:bidi, l, c)
  end
  def lex(<<226, 129, b, _::binary>>, _context, l, c, _acc) when b in 166..169 do
    error(:bidi, l, c)
  end
  def lex(<<225, 158, b, _::binary>>, _context, l, c, _acc) when b in 180..181 do
    error(:zero_width, l, c)
  end
  def lex(<<225, 160, 142, _::binary>>, _context, l, c, _acc) do
    error(:zero_width, l, c)
  end
  def lex(<<205, 143, _::binary>>, _context, l, c, _acc) do
    error(:cgj, l, c)
  end
  def lex(<<b, rest::binary>>, context, line, column, acc) when b in [9, 13, 32] do
    lex(rest, context, line, column+1, acc)
  end
  def lex(<<194, 160, rest::binary>>, context, line, column, acc) do
    lex(rest, context, line, column+1, acc)
  end
  def lex(<<225, 154, 128, rest::binary>>, context, line, column, acc) do
    lex(rest, context, line, column+1, acc)
  end
  def lex(<<226, 128, b, rest::binary>>, context, line, column, acc) when b in [130, 131, 137, 175] do
    lex(rest, context, line, column+1, acc)
  end
  def lex(<<226, 129, 159, rest::binary>>, context, line, column, acc) do
    lex(rest, context, line, column+1, acc)
  end
  def lex(<<227, 128, 128, rest::binary>>, context, line, column, acc) do
    lex(rest, context, line, column+1, acc)
  end
  def lex(<<194, 133, rest::binary>>, context, line, _column, acc) do
    lex(rest, context, line+1, 0, acc)
  end
  def lex(<<226, 128, b, rest::binary>>, context, line, _column, acc) when b in 168..169 do
    lex(rest, context, line+1, 0, acc)
  end
  def lex(<<b, rest::binary>>, context, line, _column, acc) when b in 10..13 do
    lex(rest, context, line+1, 0, acc)
  end
  def lex(<<?-, ?-, rest::binary>>, context, line, column, acc) do
    comment(rest, [], line, column+2, context, line, column, acc)
  end
  def lex(<<?/, ?*, rest::binary>>, context, line, column, acc) do
    comments(rest, [], line, column+2, context, line, column, acc)
  end
  def lex(<<?{, ?{, rest::binary>>, context, line, column, acc) do
    double_brace(rest, [], line, column+1, 0, context, 0, 1, acc)
  end
  def lex(<<?., rest::binary>>, context, line, column, [{t, [{:span, {_, _, el, ec}}|_], _}|_]=acc) when t in ~w[ident double_quote bracket]a do
    column = column+1
    lex(rest, context, line, column, [{:dot, [span: {line, column, line, column}, offset: {line-el, (column-ec)-1}, type: :operator, file: context.file], []}|acc])
  end
  def lex(<<?;, rest::binary>>, context, line, column, [{_, [{:span, {_, _, el, ec}}|_], _}|_]=acc) do
    column = column+1
    lex(rest, context, line, column, [{:colon, [span: {line, column, line, column}, offset: {line-el, (column-ec)-1}, type: :delimiter, file: context.file], acc}])
  end
  def lex(<<?,, rest::binary>>, context, line, column, [{_, [{:span, {_, _, el, ec}}|_], _}|_]=acc) do
    column = column+1
    lex(rest, context, line, column, [{:comma, [span: {line, column, line, column}, offset: {line-el, (column-ec)-1}, type: :delimiter, file: context.file], []}|acc])
  end
  def lex(<<?(, rest::binary>>, context, line, column, acc) do
    column = column+1
    case lex(rest, context, line, column, []) do
      {rest, context, l, c, []=data} ->
        offset = case acc do
          [{_, [{:span, {_, _, el, ec}}|_], _}|_] -> {line-el, (column-ec)-1, 0, 0}
          [] -> {0, 0, 0, 0}
        end
        lex(rest, context, l, c, [{:paren, [span: {line, column, l, c}, offset: offset, type: :expression, file: context.file], data}|acc])
      {rest, context, l, c, [{_, [{:span, {_, _, eel, eec}}|_], _}|_]=data} ->
        offset = case acc do
          [{_, [{:span, {_, _, el, ec}}|_], _}|_] -> {line-el, (column-ec)-1, l-eel, (c-eec)-1}
          [] -> {0, 0, l-eel, (c-eec)-1}
        end
        lex(rest, context, l, c, [{:paren, [span: {line, column, l, c}, offset: offset, type: :expression, file: context.file], data}|acc])
      {end_line, end_column, _context, _acc} ->
        {:error, file: context.file, end_line: end_line, end_column: end_column, line: line, column: column, opening_delimiter: :"(", expected_delimiter: :")"}
    end
  end
  def lex(<<?[, rest::binary>>, context, line, column, acc) do
    column = column+1
    case lex(rest, context, line, column, []) do
      {rest, context, l, c, []=data} ->
        offset = case acc do
          [{_, [{:span, {_, _, el, ec}}|_], _}|_] -> {line-el, (column-ec)-1, 0, 0}
          [] -> {0, 0, 0, 0}
        end

        lex(rest, context, l, c, [{:bracket, [span: {line, column, l, c}, offset: offset, type: :expression, file: context.file], data}|acc])
      {rest, context, l, c, [{_, [{:span, {_, _, eel, eec}}|_], _}|_]=data} ->
        offset = case acc do
          [{_, [{:span, {_, _, el, ec}}|_], _}|_] -> {line-el, (column-ec)-1, l-eel, (c-eec)-1}
          [] -> {0, 0, l-eel, (c-eec)-1}
        end

        lex(rest, context, l, c, [{:bracket, [span: {line, column, l, c}, offset: offset, type: :expression, file: context.file], data}|acc])
      {end_line, end_column, _context, _acc} ->
        {:error, file: context.file, end_line: end_line, end_column: end_column, line: line, column: column, opening_delimiter: :"[", expected_delimiter: :"]"}
    end
  end
  def lex(<<?{, rest::binary>>, context, line, column, acc) do
    column = column+1
    case lex(rest, context, line, column, []) do
      {rest, context, l, c, []=data} ->
        offset = case acc do
          [{_, [{:span, {_, _, el, ec}}|_], _}|_] -> {line-el, (column-ec)-1, 0, 0}
          [] -> {0, 0, 0, 0}
        end
        lex(rest, context, l, c, [{:brace, [span: {line, column, l, c}, offset: offset, type: :expression, file: context.file], data}|acc])

      {rest, context, l, c, [{_, [{:span, {_, _, eel, eec}}|_], _}|_]=data} ->
        offset = case acc do
          [{_, [{:span, {_, _, el, ec}}|_], _}|_] -> {line-el, (column-ec)-1, l-eel, (c-eec)-1}
          [] -> {0, 0, l-eel, (c-eec)-1}
        end

        lex(rest, context, l, c, [{:brace, [span: {line, column, l, c}, offset: offset, type: :expression, file: context.file], data}|acc])
      {end_line, end_column, _context, _acc} ->
        {:error, file: context.file, end_line: end_line, end_column: end_column, line: line, column: column, opening_delimiter: :"{", expected_delimiter: :"}"}
    end
  end
  def lex(<<?", rest::binary>>, context, line, column, acc) do
    double_quote(rest, [], line, column+1, context, line, column, acc)
  end
  def lex(<<?', rest::binary>>, context, line, column, acc) do
    quote(rest, [], line, column+1, context, line, column, acc)
  end
  def lex(<<?`, rest::binary>>, context, line, column, acc) do
    backtick(rest, [], line, column+1, context, line, column, acc)
  end
  def lex(<<?0, b, rest::binary>>, context, line, column, acc) when b in ~c"Xx" do
    hex(rest, [b, ?0], line, column+1, context, 1, acc)
  end
  def lex(<<?0, b, rest::binary>>, context, line, column, acc) when b in ~c"Bb" do
    bin(rest, [b, ?0], line, column+1, context, 1, acc)
  end
  def lex(<<?0, b, rest::binary>>, context, line, column, acc) when b in ~c"Oo" do
    oct(rest, [b, ?0], line, column+1, context, 1, acc)
  end
  def lex(<<s, ?., b, rest::binary>>, context, line, column, [{t,_,_}|_]=acc) when b in ?0..?9 and s in ~c"+-Ee" and t not in ~w[ident numeric]a do
    num(rest, [b,?.,s], line, column+1, context, 2, acc)
  end
  def lex(<<b, n, rest::binary>>, context, line, column, [{t,_,_}|_]=acc) when n in ?0..?9 and b in ~c"+-.Ee" and t not in ~w[ident numeric]a do
    num(rest, [n,b], line, column+1, context, 1, acc)
  end
  def lex(<<b, rest::binary>>, context, line, column, acc) when b in ?0..?9 do
    num(rest, [b], line, column+1, context, 0, acc)
  end
  def lex(<<b, rest::binary>>, context, line, column, acc) when b in ~c"!#$%&*+-/:<=>?@^|~" do
    special(rest, [b], context, line, column+1, 0, acc)
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
  def lex(<<b, rest::binary>>, context, line, column, acc) when b in ?a..?z or b in ?A..?Z or b == ?_ do
    ident(rest, [b], line, column+1, context, 0, acc)
  end
  def lex(<<b::utf8, rest::binary>>, context, line, column, acc) when Unicode.Set.match?(b, "[[:Lu:], [:Ll:], [:Lt:], [:Lm:], [:Lo:], [:Nl:]]") do
    ident(rest, [b], line, column+1, context, 0, acc)
  end
  def lex("", context, line, column, acc) do
    {line, column, context, acc}
  end

  {reserved, non_reserved, operators} = SQL.BNF.get_rules()
  suggestions = Enum.map(operators, &to_string(elem(&1, 0)))
  def suggest_operator(value) do
    Enum.sort(Enum.filter(unquote(suggestions), &(String.jaro_distance("#{value}", &1) > 0)), &(String.jaro_distance(value, &1) >= String.jaro_distance(value, &2)))
  end

  def ident(<<239, 187, 191, _::binary>>, _, line, column, _context, _length, _acc) do
    error(:zero_width, line, column)
  end
  def ident(<<226, 128, b, _::binary>>, _, line, column, _context, _length, _acc) when b in 139..141 do
    error(:zero_width, line, column)
  end
  def ident(<<226, 129, 160, _::binary>>, _, line, column, _context, _length, _acc) do
    error(:zero_width, line, column)
  end
  def ident(<<226, 128, b, _::binary>>, _, line, column, _context, _length, _acc) when b in 170..174 do
    error(:bidi, line, column)
  end
  def ident(<<226, 129, b, _::binary>>, _, line, column, _context, _length, _acc) when b in 166..169 do
    error(:bidi, line, column)
  end
  def ident(<<225, 158, b, _::binary>>, _, line, column, _context, _length, _acc)  when b in 180..181 do
    error(:zero_width, line, column)
  end
  def ident(<<225, 160, 142, _::binary>>, _, line, column, _context, _length, _acc) do
    error(:zero_width, line, column)
  end
  def ident(<<205, 143, _::binary>>, _, line, column, _context, _length, _acc) do
    error(:cgj, line, column)
  end
  def ident(<<?', rest::binary>>, data, line, column, context, length, acc) do
    end_column = column+length+1
    case acc do
      [{_, [{:span, {_, _, el, ec}}|_], _}|_] ->
        quote(rest, [], line, end_column, context, 0, 0, [{:ident, [span: {line, column, line, end_column}, offset: {line-el, (column-ec)-1}, type: :literal, file: context.file], :lists.reverse(data)}|acc])

      [] ->
        quote(rest, [], line, end_column, context, 0, 0, [{:ident, [span: {line, column, line, end_column}, offset: {0, 0}, type: :literal, file: context.file], :lists.reverse(data)}|acc])
    end
  end
  def ident(<<?", rest::binary>>, data, line, column, context, length, acc) do
    end_column = column+length+1
    case acc do
      [{_, [{:span, {_, _, el, ec}}|_], _}|_] ->
        double_quote(rest, [], line, end_column, context, 0, 0, [{:ident, [span: {line, column, line, end_column}, offset: {line-el, (column-ec)-1}, type: :literal, file: context.file], :lists.reverse(data)}|acc])

      [] ->
        double_quote(rest, [], line, end_column, context, 0, 0, [{:ident, [span: {line, column, line, end_column}, offset: {0, 0}, type: :literal, file: context.file], :lists.reverse(data)}|acc])
    end
  end
  def ident(<<?`, rest::binary>>, data, line, column, context, length, acc) do
    end_column = column+length+1
    case acc do
      [{_, [{:span, {_, _, el, ec}}|_], _}|_] ->
        backtick(rest, [], line, end_column, context, 0, 0, [{:ident, [span: {line, column, line, end_column}, offset: {line-el, (column-ec)-1}, type: :literal, file: context.file], :lists.reverse(data)}|acc])

      [] ->
        backtick(rest, [], line, end_column, context, 0, 0, [{:ident, [span: {line, column, line, end_column}, offset: {0, 0}, type: :literal, file: context.file], :lists.reverse(data)}|acc])
    end
  end
  def ident(<<b, rest::binary>>, data, line, column, context, length, acc) when b in ?a..?z or b in ?A..?Z or b == ?_ or b == ?& or ?0..?9 do
    ident(rest, [b|data], line, column, context, length+1, acc)
  end
  def ident(<<b::utf8, rest::binary>>, data, line, column, context, length, acc) when Unicode.Set.match?(b, "[[:Lu:], [:Ll:], [:Lt:], [:Lm:], [:Lo:], [:Nl:], [:Mn:], [:Mc:], [:Nd:], [:Pc:], [:Cf:]]") and b != ?, do
    ident(rest, [b|data], line, column, context, length+1, acc)
  end
  for {atom, match} <- operators do
    def ident(rest, unquote(match), line, column, context, length, acc) do
      end_column = column+length
      case acc do
        [{_, [{:span, {_, _, el, ec}}|_], _}|_] ->
          lex(rest, context, line, end_column, [{unquote(atom), [span: {line, column, line, end_column}, offset: {line-el, (column-ec)-1}, type: :operator, file: context.file], []}|acc])

        [] ->
          lex(rest, context, line, end_column, [{unquote(atom), [span: {line, column, line, end_column}, offset: {0, 0}, type: :operator, file: context.file], []}|acc])
      end
    end
  end
  for {atom, match, guard} <- reserved do
    def ident(rest, unquote(match), line, column, context, length, acc) when unquote(guard) do
      end_column = column+length
      case acc do
        [{_, [{:span, {_, _, el, ec}}|_], _}|_] ->
          lex(rest, context, line, end_column, [{unquote(atom), [span: {line, column, line, end_column}, offset: {line-el, (column-ec)-1}, type: :reserved, file: context.file], []}|acc])

        [] ->
          lex(rest, context, line, end_column, [{unquote(atom), [span: {line, column, line, end_column}, offset: {0, 0}, type: :reserved, file: context.file], []}|acc])
      end
    end
  end
  for {atom, match, guard} <- non_reserved do
    def ident(rest, unquote(match)=data, line, column, context, length, acc) when unquote(guard) do
      end_column = column+length
      case acc do
        [{_, [{:span, {_, _, el, ec}}|_], _}|_] ->
          lex(rest, context, line, end_column, [{:ident, [span: {line, column, line, end_column}, offset: {line-el, (column-ec)-1}, type: :non_reserved, tag: unquote(atom), file: context.file], :lists.reverse(data)}|acc])
        [] ->
          lex(rest, context, line, end_column, [{:ident, [span: {line, column, line, end_column}, offset: {0, 0}, type: :non_reserved, tag: unquote(atom), file: context.file], :lists.reverse(data)}|acc])
      end
    end
  end
  def ident(rest, data, line, column, context, length, acc) do
    end_column = column+length
    case acc do
      [{_, [{:span, {_, _, el, ec}}|_], _}|_] ->
        lex(rest, context, line, end_column, [{:ident, [span: {line, column, line, end_column}, offset: {line-el, (column-ec)-1}, type: :literal, file: context.file], :lists.reverse(data)}|acc])
      [] ->
        lex(rest, context, line, end_column, [{:ident, [span: {line, column, line, end_column}, offset: {0, 0}, type: :literal, file: context.file], :lists.reverse(data)}|acc])
    end
  end

  def comment(<<194, 133, rest::binary>>, data, l, c, context, line, column, acc) do
    l=l+1
    case acc do
      [{_, [{:span, {_, _, el, ec}}|_], _}|_] ->
        lex(rest, context, l, c, [{:comment, [span: {line, column, l, c}, offset: {line-el, (c-ec)-1},type: :literal, file: context.file], :lists.reverse(data)}|acc])
      [] ->
        lex(rest, context, l, c, [{:comment, [span: {line, column, l, c}, offset: {0, 0},type: :literal, file: context.file], :lists.reverse(data)}|acc])
    end
  end
  def comment(<<226, 128, b, rest::binary>>, data, l, c, context, line, column, acc) when b in 168..169 do
    l=l+1
    case acc do
      [{_, [{:span, {_, _, el, ec}}|_], _}|_] ->
        lex(rest, context, l, c, [{:comment, [span: {line, column, l, c}, offset: {line-el, (c-ec)-1},type: :literal, file: context.file], :lists.reverse(data)}|acc])
      [] ->
        lex(rest, context, l, c, [{:comment, [span: {line, column, l, c}, offset: {0, 0},type: :literal, file: context.file], :lists.reverse(data)}|acc])
    end
  end
  def comment(<<b, rest::binary>>, data, l, c, context, line, column, acc) when b in 10..13 do
    l=l+1
    case acc do
      [{_, [{:span, {_, _, el, ec}}|_], _}|_] ->
        lex(rest, context, l, c, [{:comment, [span: {line, column, l, c}, offset: {line-el, (c-ec)-1},type: :literal, file: context.file], :lists.reverse(data)}|acc])
      [] ->
        lex(rest, context, l, c, [{:comment, [span: {line, column, l, c}, offset: {0, 0},type: :literal, file: context.file], :lists.reverse(data)}|acc])
    end
  end
  def comment(<<194, 160, rest::binary>>, data, l, c, context, line, column, acc) do
    comment(rest, [?\s|data], l, c+1, context, line, column, acc)
  end
  def comment(<<225, 154, 128, rest::binary>>, data, l, c, context, line, column, acc) do
    comment(rest, [?\s|data], l, c+1, context, line, column, acc)
  end
  def comment(<<226, 128, b, rest::binary>>, data, l, c, context, line, column, acc) when b in [130, 131, 137, 175] do
    comment(rest, [?\s|data], l, c+1, context, line, column, acc)
  end
  def comment(<<226, 129, 159, rest::binary>>, data, l, c, context, line, column, acc) do
    comment(rest, [?\s|data], l, c+1, context, line, column, acc)
  end
  def comment(<<227, 128, 128, rest::binary>>, data, l, c, context, line, column, acc) do
    comment(rest, [?\s|data], l, c+1, context, line, column, acc)
  end
  def comment(<<b, rest::binary>>, data, l, c, context, line, column, acc), do: comment(rest, [b|data], l, c+1, context, line, column, acc)
  def comment(""=rest, data, l, c, context, line, column, acc) do
    case acc do
      [{_, [{:span, {_, _, el, ec}}|_], _}|_] ->
        lex(rest, context, l, c, [{:comment, [span: {line, column, l, c}, offset: {line-el, (column-ec)-1}, type: :literal, file: context.file], :lists.reverse(data)}|acc])
      [] ->
        lex(rest, context, l, c, [{:comment, [span: {line, column, l, c}, offset: {0, 0}, type: :literal, file: context.file], :lists.reverse(data)}|acc])
    end
  end

  def comments(<<?*, ?/, rest::binary>>, data, l, c, context, line, column, acc) do
    c=c+2
    case acc do
      [{_, [{:span, {_, _, el, ec}}|_], _}|_] ->
        lex(rest, context, l, c, [{:comments, [span: {line, column, l, c}, offset: {line-el, (column-ec)-1}, type: :literal, file: context.file], :lists.reverse(data)}|acc])
      [] ->
        lex(rest, context, l, c, [{:comments, [span: {line, column, l, c}, offset: {0, 0}, type: :literal, file: context.file], :lists.reverse(data)}|acc])
    end
  end
  def comments(<<194, 133, rest::binary>>, data, l, c, context, line, column, acc) do
    comments(rest, [?\n|data], l+1, c, context, line, column, acc)
  end
  def comments(<<226, 128, b, rest::binary>>, data, l, c, context, line, column, acc) when b in 168..169 do
    comments(rest, [?\n|data], l+1, c, context, line, column, acc)
  end
  def comments(<<b, rest::binary>>, data, l, c, context, line, column, acc) when b in 10..13 do
    comments(rest, [?\n|data], l+1, c, context, line, column, acc)
  end
  def comments(<<194, 160, rest::binary>>, data, l, c, context, line, column, acc) do
    comments(rest, [?\s|data], l, c+1, context, line, column, acc)
  end
  def comments(<<225, 154, 128, rest::binary>>, data, l, c, context, line, column, acc) do
    comments(rest, [?\s|data], l, c+1, context, line, column, acc)
  end
  def comments(<<226, 128, b, rest::binary>>, data, l, c, context, line, column, acc) when b in [130, 131, 137, 175] do
    comments(rest, [?\s|data], l, c+1, context, line, column, acc)
  end
  def comments(<<226, 129, 159, rest::binary>>, data, l, c, context, line, column, acc) do
    comments(rest, [?\s|data], l, c+1, context, line, column, acc)
  end
  def comments(<<227, 128, 128, rest::binary>>, data, l, c, context, line, column, acc) do
    comments(rest, [?\s|data], l, c+1, context, line, column, acc)
  end
  def comments(<<b, rest::binary>>, data, l, c, context, line, column, acc), do: comments(rest, [b|data], l, c+1, context, line, column, acc)
  def comments("", _data, l, c, context, line, column, _acc), do: {:error, file: context.file, end_line: l, end_column: c, line: line, column: column, opening_delimiter: :"/*", expected_delimiter: :"*/"}

  def special(<<239, 187, 191, _::binary>>, _, _context, line, column, _length, _acc) do
    error(:zero_width, line, column)
  end
  def special(<<226, 128, b, _::binary>>, _, _context, line, column, _length, _acc) when b in 139..141 do
    error(:zero_width, line, column)
  end
  def special(<<226, 129, 160, _::binary>>, _, _context, line, column, _length, _acc) do
    error(:zero_width, line, column)
  end
  def special(<<226, 128, b, _::binary>>, _, _context, line, column, _length, _acc) when b in 170..174 do
    error(:bidi, line, column)
  end
  def special(<<226, 129, b, _::binary>>, _, _context, line, column, _length, _acc) when b in 166..169 do
    error(:bidi, line, column)
  end
  def special(<<225, 158, b, _::binary>>, _, _context, line, column, _length, _acc)  when b in 180..181 do
    error(:zero_width, line, column)
  end
  def special(<<225, 160, 142, _::binary>>, _, _context, line, column, _length, _acc) do
    error(:zero_width, line, column)
  end
  def special(<<205, 143, _::binary>>, _, _context, line, column, _length, _acc) do
    error(:cgj, line, column)
  end
  def special(<<b, rest::binary>>, data, context, line, column, length, acc) when b in ~c"%&*+-/:<=>?^_|$@!~#" do
    special(rest, [b|data], context, line, column, length+1, acc)
  end
  for {atom, match} <- operators do
    def special(rest, unquote(match), context, line, column, length, acc) do
      end_column = column+length
      case acc do
        [{_, [{:span, {_, _, el, ec}}|_], _}|_] ->
          lex(rest, context, line, end_column, [{unquote(atom), [span: {line, column, line, end_column}, offset: {line-el, (column-ec)-1}, type: :operator, file: context.file], []}|acc])
        [] ->
          lex(rest, context, line, end_column, [{unquote(atom), [span: {line, column, line, end_column}, offset: {0, 0}, type: :operator, file: context.file], []}|acc])
      end
    end
  end
  def special(rest, data, context, line, column, length, acc) do
    end_column = column+length
    node = case acc do
      [{_, [{:span, {_, _, el, ec}}|_], _}|_] ->
        {:special, [span: {line, column, line, end_column}, offset: {line-el, (column-ec)-1}, type: :literal, file: context.file], :lists.reverse(data)}
      [] ->
        {:special, [span: {line, column, line, end_column}, offset: {0, 0}, type: :literal, file: context.file], :lists.reverse(data)}
    end
    lex(rest, Map.update!(context, :errors, &[node|&1]), line, end_column, [node|acc])
  end

  def num(<<239, 187, 191, _::binary>>, _, line, column, _context, _length, _acc) do
    error(:zero_width, line, column)
  end
  def num(<<226, 128, b, _::binary>>, _, line, column, _context, _length, _acc) when b in 139..141 do
    error(:zero_width, line, column)
  end
  def num(<<226, 129, 160, _::binary>>, _, line, column, _context, _length, _acc) do
    error(:zero_width, line, column)
  end
  def num(<<226, 128, b, _::binary>>, _, line, column, _context, _length, _acc) when b in 170..174 do
    error(:bidi, line, column)
  end
  def num(<<226, 129, b, _::binary>>, _, line, column, _context, _length, _acc) when b in 166..169 do
    error(:bidi, line, column)
  end
  def num(<<225, 158, b, _::binary>>, _, line, column, _context, _length, _acc)  when b in 180..181 do
    error(:zero_width, line, column)
  end
  def num(<<225, 160, 142, _::binary>>, _, line, column, _context, _length, _acc) do
    error(:zero_width, line, column)
  end
  def num(<<205, 143, _::binary>>, _, line, column, _context, _length, _acc) do
    error(:cgj, line, column)
  end
  def num(<<?., e, s, b, rest::binary>>, data, line, column, context, length, acc) when b in ?0..?9 and e in ~c"Ee" and s in ~c"-+" do
    num(rest, [b,s,e,?.|data], line, column, context, length+4, acc)
  end
  def num(<<?., b, e, s, rest::binary>>, data, line, column, context, length, acc) when b in ?0..?9 and e in ~c"Ee" and s in ~c"-+" do
    num(rest, [s,e,b,?.|data], line, column, context, length+4, acc)
  end
  def num(<<e, b, rest::binary>>, data, line, column, context, length, acc) when b in ?0..?9 and e in ~c"Ee" do
    num(rest, [b,e|data], line, column, context, length+2, acc)
  end
  def num(<<b, rest::binary>>, data, line, column, context, length, acc) when b in ?0..?9 or b in ~c"._Ee-+" do
    num(rest, [b|data], line, column, context, length+1, acc)
  end
  def num(rest, data, line, column, context, length, acc) do
    end_column = column+length
    case acc do
      [{_, [{:span, {_, _, el, ec}}|_], _}|_] ->
        lex(rest, context, line, end_column, [{:numeric, [span: {line, column, line, end_column}, offset: {line-el, (column-ec)-1}, type: :literal, file: context.file], :lists.reverse(data)}|acc])
      [] ->
        lex(rest, context, line, end_column, [{:numeric, [span: {line, column, line, end_column}, offset: {0, 0}, type: :literal, file: context.file], :lists.reverse(data)}|acc])
    end
  end

  def hex(<<239, 187, 191, _::binary>>, _, line, column, _context, _length, _acc) do
    error(:zero_width, line, column)
  end
  def hex(<<226, 128, b, _::binary>>, _, line, column, _context, _length, _acc) when b in 139..141 do
    error(:zero_width, line, column)
  end
  def hex(<<226, 129, 160, _::binary>>, _, line, column, _context, _length, _acc) do
    error(:zero_width, line, column)
  end
  def hex(<<226, 128, b, _::binary>>, _, line, column, _context, _length, _acc) when b in 170..174 do
    error(:bidi, line, column)
  end
  def hex(<<226, 129, b, _::binary>>, _, line, column, _context, _length, _acc) when b in 166..169 do
    error(:bidi, line, column)
  end
  def hex(<<225, 158, b, _::binary>>, _, line, column, _context, _length, _acc)  when b in 180..181 do
    error(:zero_width, line, column)
  end
  def hex(<<225, 160, 142, _::binary>>, _, line, column, _context, _length, _acc) do
    error(:zero_width, line, column)
  end
  def hex(<<205, 143, _::binary>>, _, line, column, _context, _length, _acc) do
    error(:cgj, line, column)
  end
  def hex(<<b, rest::binary>>, data, line, column, context, length, acc) when b in ?0..?9 or b in ?A..?F or b in ?a..?f or b == ?_ do
    hex(rest, [b|data], line, column, context, length+1, acc)
  end
  def hex(rest, data, line, column, context, length, acc) do
    end_column = column+length
    case acc do
      [{_, [{:span, {_, _, el, ec}}|_], _}|_] ->
        lex(rest, context, line, end_column, [{:numeric, [span: {line, column, line, end_column}, offset: {line-el, (column-ec)-1}, type: :hexadecimal, file: context.file], :lists.reverse(data)}|acc])
      [] ->
        lex(rest, context, line, end_column, [{:numeric, [span: {line, column, line, end_column}, offset: {0, 0}, type: :hexadecimal, file: context.file], :lists.reverse(data)}|acc])
    end
  end

  def bin(<<239, 187, 191, _::binary>>, _, line, column, _context, _length, _acc) do
    error(:zero_width, line, column)
  end
  def bin(<<226, 128, b, _::binary>>, _, line, column, _context, _length, _acc) when b in 139..141 do
    error(:zero_width, line, column)
  end
  def bin(<<226, 129, 160, _::binary>>, _, line, column, _context, _length, _acc) do
    error(:zero_width, line, column)
  end
  def bin(<<226, 128, b, _::binary>>, _, line, column, _context, _length, _acc) when b in 170..174 do
    error(:bidi, line, column)
  end
  def bin(<<226, 129, b, _::binary>>, _, line, column, _context, _length, _acc) when b in 166..169 do
    error(:bidi, line, column)
  end
  def bin(<<225, 158, b, _::binary>>, _, line, column, _context, _length, _acc)  when b in 180..181 do
    error(:zero_width, line, column)
  end
  def bin(<<225, 160, 142, _::binary>>, _, line, column, _context, _length, _acc) do
    error(:zero_width, line, column)
  end
  def bin(<<205, 143, _::binary>>, _, line, column, _context, _length, _acc) do
    error(:cgj, line, column)
  end
  def bin(<<b, rest::binary>>, data, line, column, context, length, acc) when b in ?0..?1 or b == ?_ do
    bin(rest, [b|data], line, column, context, length+1, acc)
  end
  def bin(rest, data, line, column, context, length, acc) do
    end_column = column+length
    case acc do
      [{_, [{:span, {_, _, el, ec}}|_], _}|_] ->
        lex(rest, context, line, end_column, [{:numeric, [span: {line, column, line, end_column}, offset: {line-el, (column-ec)-1}, type: :binary, file: context.file], :lists.reverse(data)}|acc])
      [] ->
        lex(rest, context, line, end_column, [{:numeric, [span: {line, column, line, end_column}, offset: {0, 0}, type: :binary, file: context.file], :lists.reverse(data)}|acc])
    end
  end

  def oct(<<239, 187, 191, _::binary>>, _, line, column, _context, _length, _acc) do
    error(:zero_width, line, column)
  end
  def oct(<<226, 128, b, _::binary>>, _, line, column, _context, _length, _acc) when b in 139..141 do
    error(:zero_width, line, column)
  end
  def oct(<<226, 129, 160, _::binary>>, _, line, column, _context, _length, _acc) do
    error(:zero_width, line, column)
  end
  def oct(<<226, 128, b, _::binary>>, _, line, column, _context, _length, _acc) when b in 170..174 do
    error(:bidi, line, column)
  end
  def oct(<<226, 129, b, _::binary>>, _, line, column, _context, _length, _acc) when b in 166..169 do
    error(:bidi, line, column)
  end
  def oct(<<225, 158, b, _::binary>>, _, line, column, _context, _length, _acc)  when b in 180..181 do
    error(:zero_width, line, column)
  end
  def oct(<<225, 160, 142, _::binary>>, _, line, column, _context, _length, _acc) do
    error(:zero_width, line, column)
  end
  def oct(<<205, 143, _::binary>>, _, line, column, _context, _length, _acc) do
    error(:cgj, line, column)
  end
  def oct(<<b, rest::binary>>, data, line, column, context, length, acc) when b in ?0..?7 or b == ?_ do
    oct(rest, [b|data], line, column, context, length+1, acc)
  end
  def oct(rest, data, line, column, context, length, acc) do
    end_column = column+length
    case acc do
      [{_, [{:span, {_, _, el, ec}}|_], _}|_] ->
        lex(rest, context, line, end_column, [{:numeric, [span: {line, column, line, end_column}, offset: {line-el, (column-ec)-1}, type: :octal, file: context.file], :lists.reverse(data)}|acc])
      [] ->
        lex(rest, context, line, end_column, [{:numeric, [span: {line, column, line, end_column}, offset: {0, 0}, type: :octal, file: context.file], :lists.reverse(data)}|acc])
    end
  end

  def backtick(<<239, 187, 191, _::binary>>, _, l, c, _context, _line, _column, _acc) do
    error(:zero_width, l, c)
  end
  def backtick(<<226, 128, b, _::binary>>, _, l, c, _context, _line, _column, _acc) when b in 139..141 do
    error(:zero_width, l, c)
  end
  def backtick(<<226, 129, 160, _::binary>>, _, l, c, _context, _line, _column, _acc) do
    error(:zero_width, l, c)
  end
  def backtick(<<225, 158, b, _::binary>>, _, l, c, _context, _line, _column, _acc)  when b in 180..181 do
    error(:zero_width, l, c)
  end
  def backtick(<<225, 160, 142, _::binary>>, _, l, c, _context, _line, _column, _acc) do
    error(:zero_width, l, c)
  end
  def backtick(<<?`, rest::binary>>, data, l, c, context, line, column, acc) do
    end_line = l+line
    end_column = c+column+1
    case acc do
      [{_, [{:span, {_, _, el, ec}}|_], _}|_] ->
        lex(rest, context, end_line, end_column, [{:backtick, [span: {l, c, end_line, end_column}, offset: {l-el, (c-ec)-1}, type: :literal, file: context.file], :lists.reverse(data)}|acc])
      [] ->
        lex(rest, context, end_line, end_column, [{:backtick, [span: {l, c, end_line, end_column}, offset: {0, 0}, type: :literal, file: context.file], :lists.reverse(data)}|acc])
    end
  end
  def backtick(<<194, 160, rest::binary>>, data, l, c, context, line, column, acc) do
    backtick(rest, [?\s|data], l, c, context, line, column+1, acc)
  end
  def backtick(<<225, 154, 128, rest::binary>>, data, l, c, context, line, column, acc) do
    backtick(rest, [?\s|data], l, c, context, line, column+1, acc)
  end
  def backtick(<<226, 128, b, rest::binary>>, data, l, c, context, line, column, acc) when b in [130, 131, 137, 175] do
    backtick(rest, [?\s|data], l, c, context, line, column+1, acc)
  end
  def backtick(<<226, 129, 159, rest::binary>>, data, l, c, context, line, column, acc) do
    backtick(rest, [?\s|data], l, c, context, line, column+1, acc)
  end
  def backtick(<<227, 128, 128, rest::binary>>, data, l, c, context, line, column, acc) do
    backtick(rest, [?\s|data], l, c, context, line, column+1, acc)
  end
  def backtick(<<194, 133, rest::binary>>, data, l, c, context, line, column, acc) do
    backtick(rest, [?\n|data], l, c, context, line+1, column, acc)
  end
  def backtick(<<226, 128, b, rest::binary>>, data, l, c, context, line, column, acc) when b in 168..169 do
    backtick(rest, [?\n|data], l, c, context, line+1, column, acc)
  end
  def backtick(<<b, rest::binary>>, data, l, c, context, line, column, acc) when b in 10..13 do
    backtick(rest, [?\n|data], l, c, context, line+1, column, acc)
  end
  def backtick(<<b, rest::binary>>, data, l, c, context, line, column, acc) do
    backtick(rest, [b|data], l, c, context, line, column+1, acc)
  end
  def backtick("", _data, l, c, context, line, column, _acc), do: {:error, file: context.file, line: l, column: c, end_line: l+line, end_column: c+column, opening_delimiter: :"`", expected_delimiter: :"`"}

  def double_quote(<<239, 187, 191, _::binary>>, _,  l, c, _context, _line, _column, _acc) do
    error(:zero_width, l, c)
  end
  def double_quote(<<226, 128, b, _::binary>>, _,  l, c, _context, _line, _column, _acc) when b in 139..141 do
    error(:zero_width, l, c)
  end
  def double_quote(<<226, 129, 160, _::binary>>, _, l, c, _context, _line, _column, _acc) do
    error(:zero_width, l, c)
  end
  def double_quote(<<225, 158, b, _::binary>>, _, l, c, _context, _line, _column, _acc)  when b in 180..181 do
    error(:zero_width, l, c)
  end
  def double_quote(<<225, 160, 142, _::binary>>, _, l, c, _context, _line, _column, _acc) do
    error(:zero_width, l, c)
  end
  def double_quote(<<?", rest::binary>>, data, l, c, context, line, column, acc) do
    end_line = l+line
    end_column = c+column+1
    case acc do
      [{_, [{:span, {_, _, el, ec}}|_], _}|_] ->
        lex(rest, context, end_line, end_column, [{:double_quote, [span: {l, c, end_line, end_column}, offset: {l-el, (c-ec)-1}, type: :literal, file: context.file], :lists.reverse(data)}|acc])
      [] ->
        lex(rest, context, end_line, end_column, [{:double_quote, [span: {l, c, end_line, end_column}, offset: {0, 0}, type: :literal, file: context.file], :lists.reverse(data)}|acc])
    end
  end
  def double_quote(<<194, 160, rest::binary>>, data, l, c, context, line, column, acc) do
    double_quote(rest, [?\s|data], l, c, context, line, column+1, acc)
  end
  def double_quote(<<225, 154, 128, rest::binary>>, data, l, c, context, line, column, acc) do
    double_quote(rest, [?\s|data], l, c, context, line, column+1, acc)
  end
  def double_quote(<<226, 128, b, rest::binary>>, data, l, c, context, line, column, acc) when b in [130, 131, 137, 175] do
    double_quote(rest, [?\s|data], l, c, context, line, column+1, acc)
  end
  def double_quote(<<226, 129, 159, rest::binary>>, data, l, c, context, line, column, acc) do
    double_quote(rest, [?\s|data], l, c, context, line, column+1, acc)
  end
  def double_quote(<<227, 128, 128, rest::binary>>, data, l, c, context, line, column, acc) do
    double_quote(rest, [?\s|data], l, c, context, line, column+1, acc)
  end
  def double_quote(<<194, 133, rest::binary>>, data, l, c, context, line, column, acc) do
    double_quote(rest, [?\n|data], l, c, context, line+1, column, acc)
  end
  def double_quote(<<226, 128, b, rest::binary>>, data, l, c, context, line, column, acc) when b in 168..169 do
    double_quote(rest, [?\n|data], l, c, context, line+1, column, acc)
  end
  def double_quote(<<b, rest::binary>>, data, l, c, context, line, column, acc) when b in 10..13 do
    double_quote(rest, [?\n|data], l, c, context, line+1, column, acc)
  end
  def double_quote(<<b, rest::binary>>, data, l, c, context, line, column, acc) do
    double_quote(rest, [b|data], l, c, context, line, column+1, acc)
  end
  def double_quote("", _data, l, c, context, line, column, _acc), do: {:error, file: context.file, line: l, column: c, end_line: l+line, end_column: c+column, opening_delimiter: :"\"", expected_delimiter: :"\""}

  def double_brace(<<239, 187, 191, _::binary>>, _, l, c,_, _context, _line, _column, _acc) do
    error(:zero_width, l, c)
  end
  def double_brace(<<226, 128, b, _::binary>>, _, l, c,_, _context, _line, _column, _acc) when b in 139..141 do
    error(:zero_width, l, c)
  end
  def double_brace(<<226, 129, 160, _::binary>>, _, l, c,_, _context, _line, _column, _acc) do
    error(:zero_width, l, c)
  end
  def double_brace(<<225, 158, b, _::binary>>, _, l, c, _, _context, _line, _column, _acc)  when b in 180..181 do
    error(:zero_width, l, c)
  end
  def double_brace(<<225, 160, 142, _::binary>>, _, l, c, _, _context, _line, _column, _acc) do
    error(:zero_width, l, c)
  end
  def double_brace(<<205, 143, _::binary>>, _, l, c, _, _context, _line, _column, _acc) do
    error(:cgj, l, c)
  end
  def double_brace(<<?},?}, rest::binary>>, data, l, c, 0, context, line, column, acc) do
    end_line = l+line
    end_column = c+column+2
    idx = context.idx+1
    value = Code.string_to_quoted!(:lists.reverse(data), file: context.file, line: line, column: column, columns: true, token_metadata: true, existing_atoms_only: true)
    case acc do
      [{_, [{:span, {_, _, el, ec}}|_], _}|_] ->
        lex(rest, %{context|idx: idx, binding: [value|context.binding]}, end_line, end_column, [{:binding, [span: {l, c, end_line, end_column}, offset: {l-el, (c-ec)-1}, type: :binding, file: context.file], [idx]}|acc])
      [] ->
        lex(rest, %{context|idx: idx, binding: [value|context.binding]}, end_line, end_column, [{:binding, [span: {l, c, end_line, end_column}, offset: {0, 0}, type: :binding, file: context.file], [idx]}|acc])
    end
  end
  def double_brace(<<194, 160, rest::binary>>, data, l, c, n, context, line, column, acc) do
    double_brace(rest, [?\s|data], l, c, n, context, line, column+1, acc)
  end
  def double_brace(<<225, 154, 128, rest::binary>>, data, l, c, n, context, line, column, acc) do
    double_brace(rest, [?\s|data], l, c, n, context, line, column+1, acc)
  end
  def double_brace(<<226, 128, b, rest::binary>>, data, l, c, n, context, line, column, acc) when b in [130, 131, 137, 175] do
    double_brace(rest, [?\s|data], l, c, n, context, line, column+1, acc)
  end
  def double_brace(<<226, 129, 159, rest::binary>>, data, l, c, n, context, line, column, acc) do
    double_brace(rest, [?\s|data], l, c, n, context, line, column+1, acc)
  end
  def double_brace(<<227, 128, 128, rest::binary>>, data, l, c, n, context, line, column, acc) do
    double_brace(rest, [?\s|data], l, c, n, context, line, column+1, acc)
  end
  def double_brace(<<194, 133, rest::binary>>, data, l, c, n, context, line, column, acc) do
    double_brace(rest, [?\n|data], l, c, n, context, line+1, column, acc)
  end
  def double_brace(<<226, 128, b, rest::binary>>, data, l, c, n, context, line, column, acc) when b in 168..169 do
    double_brace(rest, [?\n|data], l, c, n, context, line+1, column, acc)
  end
  def double_brace(<<b, rest::binary>>, data, l, c, n, context, line, column, acc) when b in 10..13 do
    double_brace(rest, [?\n|data], l, c, n, context, line+1, column, acc)
  end
  def double_brace(<<?{, rest::binary>>, data, l, c, n, context, line, column, acc) do
    double_brace(rest, [?{|data], l, c, n+1, context, line, column+1, acc)
  end
  def double_brace(<<?}, rest::binary>>, data, l, c, n, context, line, column, acc) do
    double_brace(rest, [?}|data], l, c, n-1, context, line, column+1, acc)
  end
  def double_brace(<<b, rest::binary>>, data, l, c, n, context, line, column, acc) do
    double_brace(rest, [b|data], l, c, n, context, line, column+1, acc)
  end
  def double_brace("", _data, l, c, _n, context, line, column, _acc), do: {:error, file: context.file, end_line: l, end_column: c, line: l+line, column: c+column, opening_delimiter: :"{", expected_delimiter: :"}"}

  def quote(<<239, 187, 191, _::binary>>, _, l, c, _context, _line, _column, _acc) do
    error(:zero_width, l, c)
  end
  def quote(<<226, 128, b, _::binary>>, _, l, c, _context, _line, _column, _acc) when b in 139..141 do
    error(:zero_width, l, c)
  end
  def quote(<<226, 129, 160, _::binary>>, _, l, c, _context, _line, _column, _acc) do
    error(:zero_width, l, c)
  end
  def quote(<<225, 158, b, _::binary>>, _, l, c, _context, _line, _column, _acc)  when b in 180..181 do
    error(:zero_width, l, c)
  end
  def quote(<<225, 160, 142, _::binary>>, _, l, c, _context, _line, _column, _acc) do
    error(:zero_width, l, c)
  end
  def quote(<<?', rest::binary>>, data, l, c, context, line, column, acc) do
    end_line = l+line
    end_column = c+column+1
    case acc do
      [{_, [{:span, {_, _, el, ec}}|_], _}|_] ->
        lex(rest, context, end_line, end_column, [{:quote, [span: {l, c, end_line, end_column}, offset: {l-el, (c-ec)-1}, type: :literal, file: context.file], :lists.reverse(data)}|acc])
      [] ->
        lex(rest, context, end_line, end_column, [{:quote, [span: {l, c, end_line, end_column}, offset: {0,0}, type: :literal, file: context.file], :lists.reverse(data)}|acc])
    end
  end
  def quote(<<194, 160, rest::binary>>, data, l, c, context, line, column, acc) do
    quote(rest, [?\s|data], l, c, context, line, column+1, acc)
  end
  def quote(<<225, 154, 128, rest::binary>>, data, l, c, context, line, column, acc) do
    quote(rest, [?\s|data], l, c, context, line, column+1, acc)
  end
  def quote(<<226, 128, b, rest::binary>>, data, l, c, context, line, column, acc) when b in [130, 131, 137, 175] do
    quote(rest, [?\s|data], l, c, context, line, column+1, acc)
  end
  def quote(<<226, 129, 159, rest::binary>>, data, l, c, context, line, column, acc) do
    quote(rest, [?\s|data], l, c, context, line, column+1, acc)
  end
  def quote(<<227, 128, 128, rest::binary>>, data, l, c, context, line, column, acc) do
    quote(rest, [?\s|data], l, c, context, line, column+1, acc)
  end
  def quote(<<194, 133, rest::binary>>, data, l, c, context, line, column, acc) do
    quote(rest, [?\n|data], l, c, context, line+1, column, acc)
  end
  def quote(<<226, 128, b, rest::binary>>, data, l, c, context, line, column, acc) when b in 168..169 do
    quote(rest, [?\n|data], l, c, context, line+1, column, acc)
  end
  def quote(<<b, rest::binary>>, data, l, c, context, line, column, acc) when b in 10..13 do
    quote(rest, [?\n|data], l, c, context, line+1, column, acc)
  end
  def quote(<<b, rest::binary>>, data, l, c, context, line, column, acc) do
    quote(rest, [b|data], l, c, context, line, column+1, acc)
  end
  def quote("", _data, l, c, context, line, column, _acc), do: {:error, file: context.file, line: l, column: c, end_line: l+line, end_column: c+column, opening_delimiter: :"'", expected_delimiter: :"'"}

  def error(type, l, c), do: {:error, type, l, c}
end
