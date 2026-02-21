# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Lexer do
  @moduledoc false
  require Unicode.Set
  @zero "illegal zero width character"
  @bidi "illegal bidi character"
  @cgj "illegal cgj character"
  @context %{idx: 0, file: "nofile", binding: [], types: [], aliases: [], errors: [], module: nil, format: :static, case: :lower, validate: nil, description: nil, columns: nil}
  def lex(binary, <<file::binary>> \\ "nofile", idx \\ 0) do
    case lex(binary, %{@context | file: file, idx: idx}, 0, 0, 0, 0, []) do
      {:error, error} -> raise TokenMissingError, [{:snippet, binary} | error]
      {:error, :zero_width, l, c} -> raise SyntaxError, [description: @zero, file: file, line: l, column: c]
      {:error, :bidi, l, c} -> raise SyntaxError, [description: @bidi, file: file, line: l, column: c]
      {:error, :cgj, l, c} -> raise SyntaxError, [description: @cgj, file: file, line: l, column: c]
      {_, _, context, acc} -> {:ok, context, acc}
    end
  end

  defp lex(rest, context, line, column, ol, oc, acc) do
    case rest do
      <<226, 129, 166, _::binary>> -> {:error, :bidi, line, column}
      <<226, 129, 167, _::binary>> -> {:error, :bidi, line, column}
      <<226, 129, 168, _::binary>> -> {:error, :bidi, line, column}
      <<226, 129, 169, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 170, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 171, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 172, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 173, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 174, _::binary>> -> {:error, :bidi, line, column}
      <<239, 187, 191, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 128, 141, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 128, 140, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 128, 139, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 129, 160, _::binary>> -> {:error, :zero_width, line, column}
      <<225, 158, 181, _::binary>> -> {:error, :zero_width, line, column}
      <<225, 158, 180, _::binary>> -> {:error, :zero_width, line, column}
      <<225, 160, 142, _::binary>> -> {:error, :zero_width, line, column}
      <<205, 143, _::binary>> -> {:error, :cgj, line, column}
      <<9, rest::binary>> -> lex(rest, context, line, column+1, ol, oc, acc)
      <<32, rest::binary>> -> lex(rest, context, line, column+1, ol, oc, acc)
      <<194, 160, rest::binary>> -> lex(rest, context, line, column+1, ol, oc, acc)
      <<225, 154, 128, rest::binary>> -> lex(rest, context, line, column+1, ol, oc, acc)
      <<226, 128, 130, rest::binary>> -> lex(rest, context, line, column+1, ol, oc, acc)
      <<226, 128, 131, rest::binary>> -> lex(rest, context, line, column+1, ol, oc, acc)
      <<226, 128, 137, rest::binary>> -> lex(rest, context, line, column+1, ol, oc, acc)
      <<226, 128, 175, rest::binary>> -> lex(rest, context, line, column+1, ol, oc, acc)
      <<226, 129, 159, rest::binary>> -> lex(rest, context, line, column+1, ol, oc, acc)
      <<227, 128, 128, rest::binary>> -> lex(rest, context, line, column+1, ol, oc, acc)
      <<194, 133, rest::binary>> -> lex(rest, context, line+1, 0, ol, oc, acc)
      <<226, 128, 168, rest::binary>> -> lex(rest, context, line+1, 0, ol, oc, acc)
      <<226, 128, 169, rest::binary>> -> lex(rest, context, line+1, 0, ol, oc, acc)
      <<10, rest::binary>> -> lex(rest, context, line+1, 0, ol, oc, acc)
      <<11, rest::binary>> -> lex(rest, context, line+1, 0, ol, oc, acc)
      <<12, rest::binary>> -> lex(rest, context, line+1, 0, ol, oc, acc)
      <<13, rest::binary>> -> lex(rest, context, line+1, 0, ol, oc, acc)
      <<?., rest::binary>> ->
        case acc do
          [{t, _, _}|_] when t in ~w[ident double_quote bracket]a ->
            end_column=column+1
            lex(rest, context, line, end_column, line, end_column, node(:dot, :operator, line, column, line, end_column, ol, oc, context, [], acc))
          _ ->
            num(rest, [?.], context, line, column, 1, ol, oc, acc)
        end
      <<?;, rest::binary>> ->
        end_column=column+1
        lex(rest, context, line, end_column, line, end_column, node(:colon, :delimiter, line, column, line, column, ol, oc, context, [], acc))
      <<?,, rest::binary>> ->
        end_column=column+1
        lex(rest, context, line, end_column, line, end_column, node(:comma, :delimiter, line, column, line, end_column, ol, oc, context, [], acc))
      <<?-, ?-, rest::binary>> -> comment(rest, [], line, column+2, context, line, column, ol, oc, acc)
      <<?/, ?*, rest::binary>> -> comments(rest, [], line, column+2, context, line, column, ol, oc, acc)
      <<?{, ?{, rest::binary>> -> double_brace(rest, [], line, column, 0, context, 0, 2, ol, oc, acc)
      <<c, a, s, e, rest::binary>> when c in ~c"cC" and a in ~c"aA" and s in ~c"sS" and e in ~c"eE" ->
        case lex(rest, context, line, column, line, column, []) do
          {rest, context, end_line, end_column, ool, ooc, data} ->
            lex(rest, context, end_line, end_column, end_line, end_column, [{:case, [span: span(line, column, end_line, end_column, ol, oc, ool, ooc), type: :expression, file: context.file], data}|acc])
          {end_line, end_column, _context, _acc} ->
            {:error, file: context.file, end_line: end_line, end_column: end_column, line: line, column: column, opening_delimiter: :case, expected_delimiter: :end}
        end
      <<e, n, d, rest::binary>> when e in ~c"eE" and n in ~c"nN" and d in ~c"dD" -> {rest, context, line, column, ol, oc, acc}
      <<?`, rest::binary>> -> backtick(rest, [], line, column, context, 0, 1, ol, oc, acc)
      <<?', rest::binary>> -> quote(rest, [], line, column, context, 0, 1, ol, oc, acc)
      <<?", rest::binary>> -> double_quote(rest, [], line, column, context, 0, 1, ol, oc, acc)
      <<?0, ?x, rest::binary>> -> hex(rest, [?x, ?0], context, line, column, 2, ol, oc, acc)
      <<?0, ?X, rest::binary>> -> hex(rest, [?X, ?0], context, line, column, 2, ol, oc, acc)
      <<?0, ?b, rest::binary>> -> bin(rest, [?b, ?0], context, line, column, 2, ol, oc, acc)
      <<?0, ?B, rest::binary>> -> bin(rest, [?B, ?0], context, line, column, 2, ol, oc, acc)
      <<?0, ?o, rest::binary>> -> oct(rest, [?o, ?0], context, line, column, 2, ol, oc, acc)
      <<?0, ?O, rest::binary>> -> oct(rest, [?O, ?0], context, line, column, 2, ol, oc, acc)
      <<?!, rest::binary>> -> special(rest, [?!], context, line, column, 1, ol, oc, acc)
      <<?#, rest::binary>> -> special(rest, [?#], context, line, column, 1, ol, oc, acc)
      <<?$, rest::binary>> -> special(rest, [?$], context, line, column, 1, ol, oc, acc)
      <<?%, rest::binary>> -> special(rest, [?%], context, line, column, 1, ol, oc, acc)
      <<?&, rest::binary>> -> special(rest, [?&], context, line, column, 1, ol, oc, acc)
      <<?*, rest::binary>> -> special(rest, [?*], context, line, column, 1, ol, oc, acc)
      <<?+, rest::binary>> -> special(rest, [?+], context, line, column, 1, ol, oc, acc)
      <<?-, rest::binary>> -> special(rest, [?-], context, line, column, 1, ol, oc, acc)
      <<?/, rest::binary>> -> special(rest, [?/], context, line, column, 1, ol, oc, acc)
      <<?:, rest::binary>> -> special(rest, [?:], context, line, column, 1, ol, oc, acc)
      <<?<, rest::binary>> -> special(rest, [?<], context, line, column, 1, ol, oc, acc)
      <<?=, rest::binary>> -> special(rest, [?=], context, line, column, 1, ol, oc, acc)
      <<?>, rest::binary>> -> special(rest, [?>], context, line, column, 1, ol, oc, acc)
      <<??, rest::binary>> -> special(rest, [??], context, line, column, 1, ol, oc, acc)
      <<?@, rest::binary>> -> special(rest, [?@], context, line, column, 1, ol, oc, acc)
      <<?^, rest::binary>> -> special(rest, [?^], context, line, column, 1, ol, oc, acc)
      <<?|, rest::binary>> -> special(rest, [?|], context, line, column, 1, ol, oc, acc)
      <<?~, rest::binary>> -> special(rest, [?~], context, line, column, 1, ol, oc, acc)
      <<?_, rest::binary>> -> ident(rest, [?_], context, line, column, 1, ol, oc, acc)
      <<?0, rest::binary>> -> num(rest, [?0], context, line, column, 1, ol, oc, acc)
      <<?1, rest::binary>> -> num(rest, [?1], context, line, column, 1, ol, oc, acc)
      <<?2, rest::binary>> -> num(rest, [?2], context, line, column, 1, ol, oc, acc)
      <<?3, rest::binary>> -> num(rest, [?3], context, line, column, 1, ol, oc, acc)
      <<?4, rest::binary>> -> num(rest, [?4], context, line, column, 1, ol, oc, acc)
      <<?5, rest::binary>> -> num(rest, [?5], context, line, column, 1, ol, oc, acc)
      <<?6, rest::binary>> -> num(rest, [?6], context, line, column, 1, ol, oc, acc)
      <<?7, rest::binary>> -> num(rest, [?7], context, line, column, 1, ol, oc, acc)
      <<?8, rest::binary>> -> num(rest, [?8], context, line, column, 1, ol, oc, acc)
      <<?9, rest::binary>> -> num(rest, [?9], context, line, column, 1, ol, oc, acc)
      <<?A, rest::binary>> -> ident(rest, [?a], context, line, column, 1, ol, oc, acc)
      <<?B, rest::binary>> -> ident(rest, [?b], context, line, column, 1, ol, oc, acc)
      <<?C, rest::binary>> -> ident(rest, [?c], context, line, column, 1, ol, oc, acc)
      <<?D, rest::binary>> -> ident(rest, [?d], context, line, column, 1, ol, oc, acc)
      <<?E, rest::binary>> -> ident(rest, [?e], context, line, column, 1, ol, oc, acc)
      <<?F, rest::binary>> -> ident(rest, [?f], context, line, column, 1, ol, oc, acc)
      <<?G, rest::binary>> -> ident(rest, [?g], context, line, column, 1, ol, oc, acc)
      <<?H, rest::binary>> -> ident(rest, [?h], context, line, column, 1, ol, oc, acc)
      <<?I, rest::binary>> -> ident(rest, [?i], context, line, column, 1, ol, oc, acc)
      <<?J, rest::binary>> -> ident(rest, [?j], context, line, column, 1, ol, oc, acc)
      <<?K, rest::binary>> -> ident(rest, [?k], context, line, column, 1, ol, oc, acc)
      <<?L, rest::binary>> -> ident(rest, [?l], context, line, column, 1, ol, oc, acc)
      <<?M, rest::binary>> -> ident(rest, [?m], context, line, column, 1, ol, oc, acc)
      <<?N, rest::binary>> -> ident(rest, [?n], context, line, column, 1, ol, oc, acc)
      <<?O, rest::binary>> -> ident(rest, [?o], context, line, column, 1, ol, oc, acc)
      <<?P, rest::binary>> -> ident(rest, [?p], context, line, column, 1, ol, oc, acc)
      <<?Q, rest::binary>> -> ident(rest, [?q], context, line, column, 1, ol, oc, acc)
      <<?R, rest::binary>> -> ident(rest, [?r], context, line, column, 1, ol, oc, acc)
      <<?S, rest::binary>> -> ident(rest, [?s], context, line, column, 1, ol, oc, acc)
      <<?T, rest::binary>> -> ident(rest, [?t], context, line, column, 1, ol, oc, acc)
      <<?U, rest::binary>> -> ident(rest, [?u], context, line, column, 1, ol, oc, acc)
      <<?V, rest::binary>> -> ident(rest, [?v], context, line, column, 1, ol, oc, acc)
      <<?W, rest::binary>> -> ident(rest, [?w], context, line, column, 1, ol, oc, acc)
      <<?X, rest::binary>> -> ident(rest, [?x], context, line, column, 1, ol, oc, acc)
      <<?Y, rest::binary>> -> ident(rest, [?y], context, line, column, 1, ol, oc, acc)
      <<?Z, rest::binary>> -> ident(rest, [?z], context, line, column, 1, ol, oc, acc)
      <<?a, rest::binary>> -> ident(rest, [?a], context, line, column, 1, ol, oc, acc)
      <<?b, rest::binary>> -> ident(rest, [?b], context, line, column, 1, ol, oc, acc)
      <<?c, rest::binary>> -> ident(rest, [?c], context, line, column, 1, ol, oc, acc)
      <<?d, rest::binary>> -> ident(rest, [?d], context, line, column, 1, ol, oc, acc)
      <<?e, rest::binary>> -> ident(rest, [?e], context, line, column, 1, ol, oc, acc)
      <<?f, rest::binary>> -> ident(rest, [?f], context, line, column, 1, ol, oc, acc)
      <<?g, rest::binary>> -> ident(rest, [?g], context, line, column, 1, ol, oc, acc)
      <<?h, rest::binary>> -> ident(rest, [?h], context, line, column, 1, ol, oc, acc)
      <<?i, rest::binary>> -> ident(rest, [?i], context, line, column, 1, ol, oc, acc)
      <<?j, rest::binary>> -> ident(rest, [?j], context, line, column, 1, ol, oc, acc)
      <<?k, rest::binary>> -> ident(rest, [?k], context, line, column, 1, ol, oc, acc)
      <<?l, rest::binary>> -> ident(rest, [?l], context, line, column, 1, ol, oc, acc)
      <<?m, rest::binary>> -> ident(rest, [?m], context, line, column, 1, ol, oc, acc)
      <<?n, rest::binary>> -> ident(rest, [?n], context, line, column, 1, ol, oc, acc)
      <<?o, rest::binary>> -> ident(rest, [?o], context, line, column, 1, ol, oc, acc)
      <<?p, rest::binary>> -> ident(rest, [?p], context, line, column, 1, ol, oc, acc)
      <<?q, rest::binary>> -> ident(rest, [?q], context, line, column, 1, ol, oc, acc)
      <<?r, rest::binary>> -> ident(rest, [?r], context, line, column, 1, ol, oc, acc)
      <<?s, rest::binary>> -> ident(rest, [?s], context, line, column, 1, ol, oc, acc)
      <<?t, rest::binary>> -> ident(rest, [?t], context, line, column, 1, ol, oc, acc)
      <<?u, rest::binary>> -> ident(rest, [?u], context, line, column, 1, ol, oc, acc)
      <<?v, rest::binary>> -> ident(rest, [?v], context, line, column, 1, ol, oc, acc)
      <<?w, rest::binary>> -> ident(rest, [?w], context, line, column, 1, ol, oc, acc)
      <<?x, rest::binary>> -> ident(rest, [?x], context, line, column, 1, ol, oc, acc)
      <<?y, rest::binary>> -> ident(rest, [?y], context, line, column, 1, ol, oc, acc)
      <<?(, rest::binary>> ->
        case lex(rest, context, line, column, line, column, []) do
          {rest, context, end_line, end_column, ool, ooc, data} ->
            lex(rest, context, end_line, end_column, end_line, end_column, [{:paren, [span: span(line, column, end_line, end_column, ol, oc, ool, ooc), type: :expression, file: context.file], data}|acc])
          {end_line, end_column, _context, _acc} ->
            {:error, file: context.file, end_line: end_line, end_column: end_column, line: line, column: column, opening_delimiter: :"(", expected_delimiter: :")"}
        end
      <<?[, rest::binary>> ->
        case lex(rest, context, line, column, line, column, []) do
          {rest, context, end_line, end_column, ool, ooc, data} ->
            lex(rest, context, end_line, end_column, end_line, end_column, [{:bracket, [span: span(line, column, end_line, end_column, ol, oc, ool, ooc), type: :expression, file: context.file], data}|acc])
          {end_line, end_column, _context, _acc} ->
            {:error, file: context.file, end_line: end_line, end_column: end_column, line: line, column: column, opening_delimiter: :"[", expected_delimiter: :"]"}
        end
      <<?{, rest::binary>> ->
        ol = line-ol
        oc = column-oc
        case lex(rest, context, line, column, line, column, []) do
          {rest, context, end_line, end_column, ool, ooc, data} ->
            lex(rest, context, end_line, end_column, end_line, end_column, [{:brace, [span: span(line, column, end_line, end_column, ol, oc, ool, ooc), type: :expression, file: context.file], data}|acc])
          {end_line, end_column, _context, _acc} ->
            {:error, file: context.file, end_line: end_line, end_column: end_column, line: line, column: column, opening_delimiter: :"{", expected_delimiter: :"}"}
        end
      <<?}, rest::binary>> -> {rest, context, line, column, ol, oc, acc}
      <<?), rest::binary>> -> {rest, context, line, column, ol, oc, acc}
      <<?], rest::binary>> -> {rest, context, line, column, ol, oc, acc}
      <<b::utf8, rest::binary>> when Unicode.Set.match?(b, "[[:Lu:], [:Ll:], [:Lt:], [:Lm:], [:Lo:], [:Nl:]]") ->
        ident(rest, [b], context, line, column, 1, ol, oc, acc)
      "" -> {line, column, context, acc}
    end
  end

  {reserved, non_reserved, operators} = SQL.BNF.get_rules()
  suggestions = Enum.map(operators, &to_string(elem(&1, 0)))
  def suggest_operator(value) do
    Enum.sort(Enum.filter(unquote(suggestions), &(String.jaro_distance("#{value}", &1) > 0)), &(String.jaro_distance(value, &1) >= String.jaro_distance(value, &2)))
  end

  reserved = Enum.reject(reserved, &(&1 in operators))
  non_reserved = Enum.reject(non_reserved, &(&1 in operators or &1 in reserved))
  case_ast =
    for {type, values} <- [operator: operators, reserved: reserved],  {atom, match} <- values, hd(match) in ?a..?z do
      hd(
        quote do
          unquote(match) ->
            lex(var!(rest), var!(context), var!(line), var!(end_column), var!(line), var!(end_column), node(unquote(atom), unquote(type), var!(line), var!(column), var!(line), var!(end_column), var!(ol), var!(oc), var!(context), [], var!(acc)))
        end
      )
    end ++ for {atom, match} <- non_reserved do
      hd(
        quote do
          unquote(match) ->
            lex(var!(rest), var!(context), var!(line), var!(end_column), var!(line), var!(end_column), node(unquote(atom), :non_reserved, var!(line), var!(column), var!(line), var!(end_column), var!(ol), var!(oc), var!(context), :lists.reverse(var!(data)), var!(acc)))
        end
      )
    end ++ quote do
      data -> lex(var!(rest), var!(context), var!(line), var!(end_column), var!(line), var!(end_column), node(:ident, :literal, var!(line), var!(column), var!(line), var!(end_column), var!(ol), var!(oc), var!(context), :lists.reverse(data), var!(acc)))
    end

  defp ident(rest, data, context, line, column, length, ol, oc, acc) do
    case rest do
      <<226, 129, 166, _::binary>> -> {:error, :bidi, line, column}
      <<226, 129, 167, _::binary>> -> {:error, :bidi, line, column}
      <<226, 129, 168, _::binary>> -> {:error, :bidi, line, column}
      <<226, 129, 169, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 170, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 171, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 172, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 173, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 174, _::binary>> -> {:error, :bidi, line, column}
      <<239, 187, 191, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 128, 141, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 128, 140, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 128, 139, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 129, 160, _::binary>> -> {:error, :zero_width, line, column}
      <<225, 158, 181, _::binary>> -> {:error, :zero_width, line, column}
      <<225, 158, 180, _::binary>> -> {:error, :zero_width, line, column}
      <<225, 160, 142, _::binary>> -> {:error, :zero_width, line, column}
      <<205, 143, _::binary>> -> {:error, :cgj, line, column}
      <<?`, rest::binary>> ->
        end_column = column+length
        backtick(rest, [], line, end_column, context, 0, 1, line, end_column, node(:ident, :literal, line, column, line, end_column, ol, oc, context, :lists.reverse(data), acc))
      <<?', rest::binary>> ->
        end_column = column+length
        quote(rest, [], line, end_column, context, 0, 1, line, end_column, node(:ident, :literal, line, column, line, end_column, ol, oc, context, :lists.reverse(data), acc))
      <<?", rest::binary>> ->
        end_column = column+length
        double_quote(rest, [], line, end_column, context, 0, 1, line, end_column, node(:ident, :literal, line, column, line, end_column, ol, oc, context, :lists.reverse(data), acc))
      <<?_, rest::binary>> -> ident(rest, [?_|data], context, line, column, length+1, ol, oc, acc)
      <<?&, rest::binary>> -> ident(rest, [?&|data], context, line, column, length+1, ol, oc, acc)
      <<?0, rest::binary>> -> ident(rest, [?0|data], context, line, column, length+1, ol, oc, acc)
      <<?1, rest::binary>> -> ident(rest, [?1|data], context, line, column, length+1, ol, oc, acc)
      <<?2, rest::binary>> -> ident(rest, [?2|data], context, line, column, length+1, ol, oc, acc)
      <<?3, rest::binary>> -> ident(rest, [?3|data], context, line, column, length+1, ol, oc, acc)
      <<?4, rest::binary>> -> ident(rest, [?4|data], context, line, column, length+1, ol, oc, acc)
      <<?5, rest::binary>> -> ident(rest, [?5|data], context, line, column, length+1, ol, oc, acc)
      <<?6, rest::binary>> -> ident(rest, [?6|data], context, line, column, length+1, ol, oc, acc)
      <<?7, rest::binary>> -> ident(rest, [?7|data], context, line, column, length+1, ol, oc, acc)
      <<?8, rest::binary>> -> ident(rest, [?8|data], context, line, column, length+1, ol, oc, acc)
      <<?9, rest::binary>> -> ident(rest, [?9|data], context, line, column, length+1, ol, oc, acc)
      <<?A, rest::binary>> -> ident(rest, [?a|data], context, line, column, length+1, ol, oc, acc)
      <<?B, rest::binary>> -> ident(rest, [?b|data], context, line, column, length+1, ol, oc, acc)
      <<?C, rest::binary>> -> ident(rest, [?c|data], context, line, column, length+1, ol, oc, acc)
      <<?D, rest::binary>> -> ident(rest, [?d|data], context, line, column, length+1, ol, oc, acc)
      <<?E, rest::binary>> -> ident(rest, [?e|data], context, line, column, length+1, ol, oc, acc)
      <<?F, rest::binary>> -> ident(rest, [?f|data], context, line, column, length+1, ol, oc, acc)
      <<?G, rest::binary>> -> ident(rest, [?g|data], context, line, column, length+1, ol, oc, acc)
      <<?H, rest::binary>> -> ident(rest, [?h|data], context, line, column, length+1, ol, oc, acc)
      <<?I, rest::binary>> -> ident(rest, [?i|data], context, line, column, length+1, ol, oc, acc)
      <<?J, rest::binary>> -> ident(rest, [?j|data], context, line, column, length+1, ol, oc, acc)
      <<?K, rest::binary>> -> ident(rest, [?k|data], context, line, column, length+1, ol, oc, acc)
      <<?L, rest::binary>> -> ident(rest, [?l|data], context, line, column, length+1, ol, oc, acc)
      <<?M, rest::binary>> -> ident(rest, [?m|data], context, line, column, length+1, ol, oc, acc)
      <<?N, rest::binary>> -> ident(rest, [?n|data], context, line, column, length+1, ol, oc, acc)
      <<?O, rest::binary>> -> ident(rest, [?o|data], context, line, column, length+1, ol, oc, acc)
      <<?P, rest::binary>> -> ident(rest, [?p|data], context, line, column, length+1, ol, oc, acc)
      <<?Q, rest::binary>> -> ident(rest, [?q|data], context, line, column, length+1, ol, oc, acc)
      <<?R, rest::binary>> -> ident(rest, [?r|data], context, line, column, length+1, ol, oc, acc)
      <<?S, rest::binary>> -> ident(rest, [?s|data], context, line, column, length+1, ol, oc, acc)
      <<?T, rest::binary>> -> ident(rest, [?t|data], context, line, column, length+1, ol, oc, acc)
      <<?U, rest::binary>> -> ident(rest, [?u|data], context, line, column, length+1, ol, oc, acc)
      <<?V, rest::binary>> -> ident(rest, [?v|data], context, line, column, length+1, ol, oc, acc)
      <<?W, rest::binary>> -> ident(rest, [?w|data], context, line, column, length+1, ol, oc, acc)
      <<?X, rest::binary>> -> ident(rest, [?x|data], context, line, column, length+1, ol, oc, acc)
      <<?Y, rest::binary>> -> ident(rest, [?y|data], context, line, column, length+1, ol, oc, acc)
      <<?Z, rest::binary>> -> ident(rest, [?z|data], context, line, column, length+1, ol, oc, acc)
      <<?a, rest::binary>> -> ident(rest, [?a|data], context, line, column, length+1, ol, oc, acc)
      <<?b, rest::binary>> -> ident(rest, [?b|data], context, line, column, length+1, ol, oc, acc)
      <<?c, rest::binary>> -> ident(rest, [?c|data], context, line, column, length+1, ol, oc, acc)
      <<?d, rest::binary>> -> ident(rest, [?d|data], context, line, column, length+1, ol, oc, acc)
      <<?e, rest::binary>> -> ident(rest, [?e|data], context, line, column, length+1, ol, oc, acc)
      <<?f, rest::binary>> -> ident(rest, [?f|data], context, line, column, length+1, ol, oc, acc)
      <<?g, rest::binary>> -> ident(rest, [?g|data], context, line, column, length+1, ol, oc, acc)
      <<?h, rest::binary>> -> ident(rest, [?h|data], context, line, column, length+1, ol, oc, acc)
      <<?i, rest::binary>> -> ident(rest, [?i|data], context, line, column, length+1, ol, oc, acc)
      <<?j, rest::binary>> -> ident(rest, [?j|data], context, line, column, length+1, ol, oc, acc)
      <<?k, rest::binary>> -> ident(rest, [?k|data], context, line, column, length+1, ol, oc, acc)
      <<?l, rest::binary>> -> ident(rest, [?l|data], context, line, column, length+1, ol, oc, acc)
      <<?m, rest::binary>> -> ident(rest, [?m|data], context, line, column, length+1, ol, oc, acc)
      <<?n, rest::binary>> -> ident(rest, [?n|data], context, line, column, length+1, ol, oc, acc)
      <<?o, rest::binary>> -> ident(rest, [?o|data], context, line, column, length+1, ol, oc, acc)
      <<?p, rest::binary>> -> ident(rest, [?p|data], context, line, column, length+1, ol, oc, acc)
      <<?q, rest::binary>> -> ident(rest, [?q|data], context, line, column, length+1, ol, oc, acc)
      <<?r, rest::binary>> -> ident(rest, [?r|data], context, line, column, length+1, ol, oc, acc)
      <<?s, rest::binary>> -> ident(rest, [?s|data], context, line, column, length+1, ol, oc, acc)
      <<?t, rest::binary>> -> ident(rest, [?t|data], context, line, column, length+1, ol, oc, acc)
      <<?u, rest::binary>> -> ident(rest, [?u|data], context, line, column, length+1, ol, oc, acc)
      <<?v, rest::binary>> -> ident(rest, [?v|data], context, line, column, length+1, ol, oc, acc)
      <<?w, rest::binary>> -> ident(rest, [?w|data], context, line, column, length+1, ol, oc, acc)
      <<?x, rest::binary>> -> ident(rest, [?x|data], context, line, column, length+1, ol, oc, acc)
      <<?y, rest::binary>> -> ident(rest, [?y|data], context, line, column, length+1, ol, oc, acc)
      <<b::utf8, rest::binary>> when Unicode.Set.match?(b, "[[:Lu:], [:Ll:], [:Lt:], [:Lm:], [:Lo:], [:Nl:], [:Mn:], [:Mc:], [:Nd:], [:Pc:], [:Cf:]]") and b != ?, ->
        ident(rest, [b|data], context, line, column, length+1, ol, oc, acc)
      rest ->
        end_column = column+length
        case data do
          unquote(case_ast)
        end
    end
  end

  defp comment(rest, data, l, c, context, line, column, ol, oc, acc) do
    case rest do
      <<194, 133, rest::binary>> ->
        l=l+1
        lex(rest, context, l, c, l, c, node(:comment, :literal, line, column, l, c, ol, oc, context, :lists.reverse(data), acc))
      <<226, 128, 168, rest::binary>> ->
        l=l+1
        lex(rest, context, l, c, l, c, node(:comment, :literal, line, column, l, c, ol, oc, context, :lists.reverse(data), acc))
      <<226, 128, 169, rest::binary>> ->
        l=l+1
        lex(rest, context, l, c, l, c, node(:comment, :literal, line, column, l, c, ol, oc, context, :lists.reverse(data), acc))
      <<10, rest::binary>> ->
        l=l+1
        lex(rest, context, l, c, l, c, node(:comment, :literal, line, column, l, c, ol, oc, context, :lists.reverse(data), acc))
      <<11, rest::binary>> ->
        l=l+1
        lex(rest, context, l, c, l, c, node(:comment, :literal, line, column, l, c, ol, oc, context, :lists.reverse(data), acc))
      <<12, rest::binary>> ->
        l=l+1
        lex(rest, context, l, c, l, c, node(:comment, :literal, line, column, l, c, ol, oc, context, :lists.reverse(data), acc))
      <<13, rest::binary>> ->
        l=l+1
        lex(rest, context, l, c, l, c, node(:comment, :literal, line, column, l, c,ol, oc,  context, :lists.reverse(data), acc))
      <<194, 160, rest::binary>> -> comment(rest, [?\s|data], l, c+1, context, line, column, ol, oc, acc)
      <<225, 154, 128, rest::binary>> -> comment(rest, [?\s|data], l, c+1, context, line, column, ol, oc, acc)
      <<226, 128, 130, rest::binary>> -> comment(rest, [?\s|data], l, c+1, context, line, column, ol, oc, acc)
      <<226, 128, 131, rest::binary>> -> comment(rest, [?\s|data], l, c+1, context, line, column, ol, oc, acc)
      <<226, 128, 137, rest::binary>> -> comment(rest, [?\s|data], l, c+1, context, line, column, ol, oc, acc)
      <<226, 128, 175, rest::binary>> -> comment(rest, [?\s|data], l, c+1, context, line, column, ol, oc, acc)
      <<226, 129, 159, rest::binary>> -> comment(rest, [?\s|data], l, c+1, context, line, column, ol, oc, acc)
      <<227, 128, 128, rest::binary>> -> comment(rest, [?\s|data], l, c+1, context, line, column, ol, oc, acc)
      <<b, rest::binary>> -> comment(rest, [b|data], l, c+1, context, line, column, ol, oc, acc)
      "" -> lex(rest, context, l, c, l, c, node(:comment, :literal, line, column, l, c, ol, oc, context, :lists.reverse(data), acc))
    end
  end

  defp comments(rest, data, l, c, context, line, column, ol, oc, acc) do
    case rest do
      <<194, 133, rest::binary>> -> comments(rest, [?\n|data], l+1, c, context, line, column, ol, oc, acc)
      <<226, 128, 168, rest::binary>> -> comments(rest, [?\n|data], l+1, c, context, line, column, ol, oc, acc)
      <<226, 128, 169, rest::binary>> -> comments(rest, [?\n|data], l+1, c, context, line, column, ol, oc, acc)
      <<10, rest::binary>> -> comments(rest, [?\n|data], l+1, c, context, line, column, ol, oc, acc)
      <<11, rest::binary>> -> comments(rest, [?\n|data], l+1, c, context, line, column, ol, oc, acc)
      <<12, rest::binary>> -> comments(rest, [?\n|data], l+1, c, context, line, column, ol, oc, acc)
      <<13, rest::binary>> -> comments(rest, [?\n|data], l+1, c, context, line, column, ol, oc, acc)
      <<194, 160, rest::binary>> -> comments(rest, [?\s|data], l, c+1, context, line, column, ol, oc, acc)
      <<225, 154, 128, rest::binary>> -> comments(rest, [?\s|data], l, c+1, context, line, column, ol, oc, acc)
      <<226, 128, 130, rest::binary>> -> comments(rest, [?\s|data], l, c+1, context, line, column, ol, oc, acc)
      <<226, 128, 131, rest::binary>> -> comments(rest, [?\s|data], l, c+1, context, line, column, ol, oc, acc)
      <<226, 128, 137, rest::binary>> -> comments(rest, [?\s|data], l, c+1, context, line, column, ol, oc, acc)
      <<226, 128, 175, rest::binary>> -> comments(rest, [?\s|data], l, c+1, context, line, column, ol, oc, acc)
      <<226, 129, 159, rest::binary>> -> comments(rest, [?\s|data], l, c+1, context, line, column, ol, oc, acc)
      <<227, 128, 128, rest::binary>> -> comments(rest, [?\s|data], l, c+1, context, line, column, ol, oc, acc)
      <<?*, ?/, rest::binary>> ->
        c=c+2
        lex(rest, context, l, c, l, c, node(:comments, :literal, line, column, l, c, ol, oc, context, :lists.reverse(data), acc))
      <<b, rest::binary>> -> comments(rest, [b|data], l, c+1, context, line, column, ol, oc, acc)
      "" -> {:error, file: context.file, end_line: l, end_column: c, line: line, column: column, opening_delimiter: :"/*", expected_delimiter: :"*/"}
    end
  end

  case_ast =
    for {atom, match} <- operators, hd(match) not in ?a..?z do
      hd(
        quote do
          unquote(match) -> lex(var!(rest), var!(context), var!(line), var!(end_column), var!(line), var!(end_column), node(unquote(atom), :operator, var!(line), var!(column), var!(line), var!(end_column), var!(ol), var!(oc), var!(context), [], var!(acc)))
        end
      )
    end ++ quote do
      data ->
        node = node(:special, :operator, var!(line), var!(column), var!(line), var!(end_column), var!(ol), var!(oc), var!(context), data)
        lex(var!(rest), %{var!(context) | errors: [node|var!(context).errors]}, var!(line), var!(end_column), var!(line), var!(end_column), [node|var!(acc)])
    end

  defp special(rest, data, context, line, column, length, ol, oc, acc) do
    case rest do
      <<226, 129, 166, _::binary>> -> {:error, :bidi, line, column}
      <<226, 129, 167, _::binary>> -> {:error, :bidi, line, column}
      <<226, 129, 168, _::binary>> -> {:error, :bidi, line, column}
      <<226, 129, 169, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 170, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 171, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 172, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 173, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 174, _::binary>> -> {:error, :bidi, line, column}
      <<239, 187, 191, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 128, 141, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 128, 140, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 128, 139, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 129, 160, _::binary>> -> {:error, :zero_width, line, column}
      <<225, 158, 181, _::binary>> -> {:error, :zero_width, line, column}
      <<225, 158, 180, _::binary>> -> {:error, :zero_width, line, column}
      <<225, 160, 142, _::binary>> -> {:error, :zero_width, line, column}
      <<205, 143, _::binary>> -> {:error, :cgj, line, column}
      <<?!, rest::binary>> -> special(rest, [?!|data], context, line, column, length+1, ol, oc, acc)
      <<?#, rest::binary>> -> special(rest, [?#|data], context, line, column, length+1, ol, oc, acc)
      <<?$, rest::binary>> -> special(rest, [?$|data], context, line, column, length+1, ol, oc, acc)
      <<?%, rest::binary>> -> special(rest, [?%|data], context, line, column, length+1, ol, oc, acc)
      <<?&, rest::binary>> -> special(rest, [?&|data], context, line, column, length+1, ol, oc, acc)
      <<?*, rest::binary>> -> special(rest, [?*|data], context, line, column, length+1, ol, oc, acc)
      <<?+, rest::binary>> -> special(rest, [?+|data], context, line, column, length+1, ol, oc, acc)
      <<?-, rest::binary>> -> special(rest, [?-|data], context, line, column, length+1, ol, oc, acc)
      <<?/, rest::binary>> -> special(rest, [?/|data], context, line, column, length+1, ol, oc, acc)
      <<?:, rest::binary>> -> special(rest, [?:|data], context, line, column, length+1, ol, oc, acc)
      <<?<, rest::binary>> -> special(rest, [?<|data], context, line, column, length+1, ol, oc, acc)
      <<?=, rest::binary>> -> special(rest, [?=|data], context, line, column, length+1, ol, oc, acc)
      <<?>, rest::binary>> -> special(rest, [?>|data], context, line, column, length+1, ol, oc, acc)
      <<??, rest::binary>> -> special(rest, [??|data], context, line, column, length+1, ol, oc, acc)
      <<?@, rest::binary>> -> special(rest, [?@|data], context, line, column, length+1, ol, oc, acc)
      <<?^, rest::binary>> -> special(rest, [?^|data], context, line, column, length+1, ol, oc, acc)
      <<?_, rest::binary>> -> special(rest, [?_|data], context, line, column, length+1, ol, oc, acc)
      <<?|, rest::binary>> -> special(rest, [?||data], context, line, column, length+1, ol, oc, acc)
      <<?~, rest::binary>> -> special(rest, [?~|data], context, line, column, length+1, ol, oc, acc)
      rest ->
        end_column = column+length
        case data do
          unquote(case_ast)
        end
    end
  end

  defp num(rest, data, context, line, column, length, ol, oc, acc) do
    case rest do
      <<226, 129, 166, _::binary>> -> {:error, :bidi, line, column}
      <<226, 129, 167, _::binary>> -> {:error, :bidi, line, column}
      <<226, 129, 168, _::binary>> -> {:error, :bidi, line, column}
      <<226, 129, 169, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 170, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 171, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 172, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 173, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 174, _::binary>> -> {:error, :bidi, line, column}
      <<239, 187, 191, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 128, 141, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 128, 140, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 128, 139, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 129, 160, _::binary>> -> {:error, :zero_width, line, column}
      <<225, 158, 181, _::binary>> -> {:error, :zero_width, line, column}
      <<225, 158, 180, _::binary>> -> {:error, :zero_width, line, column}
      <<225, 160, 142, _::binary>> -> {:error, :zero_width, line, column}
      <<205, 143, _::binary>> -> {:error, :cgj, line, column}
      <<?_, rest::binary>> -> num(rest, [?_|data], context, line, column, length+1, ol, oc, acc)
      <<?., rest::binary>> -> num(rest, [?.|data], context, line, column, length+1, ol, oc, acc)
      <<?-, rest::binary>> -> num(rest, [?-|data], context, line, column, length+1, ol, oc, acc)
      <<?+, rest::binary>> -> num(rest, [?+|data], context, line, column, length+1, ol, oc, acc)
      <<?e, rest::binary>> -> num(rest, [?e|data], context, line, column, length+1, ol, oc, acc)
      <<?E, rest::binary>> -> num(rest, [?E|data], context, line, column, length+1, ol, oc, acc)
      <<?0, rest::binary>> -> num(rest, [?0|data], context, line, column, length+1, ol, oc, acc)
      <<?1, rest::binary>> -> num(rest, [?1|data], context, line, column, length+1, ol, oc, acc)
      <<?2, rest::binary>> -> num(rest, [?2|data], context, line, column, length+1, ol, oc, acc)
      <<?3, rest::binary>> -> num(rest, [?3|data], context, line, column, length+1, ol, oc, acc)
      <<?4, rest::binary>> -> num(rest, [?4|data], context, line, column, length+1, ol, oc, acc)
      <<?5, rest::binary>> -> num(rest, [?5|data], context, line, column, length+1, ol, oc, acc)
      <<?6, rest::binary>> -> num(rest, [?6|data], context, line, column, length+1, ol, oc, acc)
      <<?7, rest::binary>> -> num(rest, [?7|data], context, line, column, length+1, ol, oc, acc)
      <<?8, rest::binary>> -> num(rest, [?8|data], context, line, column, length+1, ol, oc, acc)
      <<?9, rest::binary>> -> num(rest, [?9|data], context, line, column, length+1, ol, oc, acc)
      rest ->
        end_column = column+length
        lex(rest, context, line, end_column, line, end_column, node(:numeric, :literal, line, column, line, end_column, ol, oc, context, :lists.reverse(data), acc))
    end
  end

  defp hex(rest, data, context, line, column, length, ol, oc, acc) do
    case rest do
      <<226, 129, 166, _::binary>> -> {:error, :bidi, line, column}
      <<226, 129, 167, _::binary>> -> {:error, :bidi, line, column}
      <<226, 129, 168, _::binary>> -> {:error, :bidi, line, column}
      <<226, 129, 169, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 170, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 171, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 172, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 173, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 174, _::binary>> -> {:error, :bidi, line, column}
      <<239, 187, 191, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 128, 141, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 128, 140, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 128, 139, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 129, 160, _::binary>> -> {:error, :zero_width, line, column}
      <<225, 158, 181, _::binary>> -> {:error, :zero_width, line, column}
      <<225, 158, 180, _::binary>> -> {:error, :zero_width, line, column}
      <<225, 160, 142, _::binary>> -> {:error, :zero_width, line, column}
      <<205, 143, _::binary>> -> {:error, :cgj, line, column}
      <<?_, rest::binary>> -> hex(rest, [?_|data], context, line, column, length+1, ol, oc, acc)
      <<?0, rest::binary>> -> hex(rest, [?0|data], context, line, column, length+1, ol, oc, acc)
      <<?1, rest::binary>> -> hex(rest, [?1|data], context, line, column, length+1, ol, oc, acc)
      <<?2, rest::binary>> -> hex(rest, [?2|data], context, line, column, length+1, ol, oc, acc)
      <<?3, rest::binary>> -> hex(rest, [?3|data], context, line, column, length+1, ol, oc, acc)
      <<?4, rest::binary>> -> hex(rest, [?4|data], context, line, column, length+1, ol, oc, acc)
      <<?5, rest::binary>> -> hex(rest, [?5|data], context, line, column, length+1, ol, oc, acc)
      <<?6, rest::binary>> -> hex(rest, [?6|data], context, line, column, length+1, ol, oc, acc)
      <<?7, rest::binary>> -> hex(rest, [?7|data], context, line, column, length+1, ol, oc, acc)
      <<?8, rest::binary>> -> hex(rest, [?8|data], context, line, column, length+1, ol, oc, acc)
      <<?9, rest::binary>> -> hex(rest, [?9|data], context, line, column, length+1, ol, oc, acc)
      <<?A, rest::binary>> -> hex(rest, [?A|data], context, line, column, length+1, ol, oc, acc)
      <<?B, rest::binary>> -> hex(rest, [?B|data], context, line, column, length+1, ol, oc, acc)
      <<?C, rest::binary>> -> hex(rest, [?C|data], context, line, column, length+1, ol, oc, acc)
      <<?D, rest::binary>> -> hex(rest, [?D|data], context, line, column, length+1, ol, oc, acc)
      <<?E, rest::binary>> -> hex(rest, [?E|data], context, line, column, length+1, ol, oc, acc)
      <<?F, rest::binary>> -> hex(rest, [?F|data], context, line, column, length+1, ol, oc, acc)
      <<?a, rest::binary>> -> hex(rest, [?a|data], context, line, column, length+1, ol, oc, acc)
      <<?b, rest::binary>> -> hex(rest, [?b|data], context, line, column, length+1, ol, oc, acc)
      <<?c, rest::binary>> -> hex(rest, [?c|data], context, line, column, length+1, ol, oc, acc)
      <<?d, rest::binary>> -> hex(rest, [?d|data], context, line, column, length+1, ol, oc, acc)
      <<?e, rest::binary>> -> hex(rest, [?e|data], context, line, column, length+1, ol, oc, acc)
      <<?f, rest::binary>> -> hex(rest, [?f|data], context, line, column, length+1, ol, oc, acc)
      rest ->
        end_column = column+length
        lex(rest, context, line, end_column, line, end_column, node(:numeric, :hexadecimal, line, column, line, end_column, ol, oc, context, :lists.reverse(data), acc))
    end
  end

  defp bin(rest, data, context, line, column, length, ol, oc, acc) do
    case rest do
      <<226, 129, 166, _::binary>> -> {:error, :bidi, line, column}
      <<226, 129, 167, _::binary>> -> {:error, :bidi, line, column}
      <<226, 129, 168, _::binary>> -> {:error, :bidi, line, column}
      <<226, 129, 169, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 170, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 171, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 172, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 173, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 174, _::binary>> -> {:error, :bidi, line, column}
      <<239, 187, 191, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 128, 141, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 128, 140, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 128, 139, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 129, 160, _::binary>> -> {:error, :zero_width, line, column}
      <<225, 158, 181, _::binary>> -> {:error, :zero_width, line, column}
      <<225, 158, 180, _::binary>> -> {:error, :zero_width, line, column}
      <<225, 160, 142, _::binary>> -> {:error, :zero_width, line, column}
      <<205, 143, _::binary>> -> {:error, :cgj, line, column}
      <<?_, rest::binary>> -> bin(rest, [?_|data], context, line, column, length+1, ol, oc, acc)
      <<?0, rest::binary>> -> bin(rest, [?0|data], context, line, column, length+1, ol, oc, acc)
      <<?1, rest::binary>> -> bin(rest, [?1|data], context, line, column, length+1, ol, oc, acc)
      rest ->
        end_column = column+length
        lex(rest, context, line, end_column, line, end_column, node(:numeric, :binary, line, column, line, end_column, ol, oc, context, :lists.reverse(data), acc))
    end
  end

  defp oct(rest, data, context, line, column, length, ol, oc, acc) do
    case rest do
      <<226, 129, 166, _::binary>> -> {:error, :bidi, line, column}
      <<226, 129, 167, _::binary>> -> {:error, :bidi, line, column}
      <<226, 129, 168, _::binary>> -> {:error, :bidi, line, column}
      <<226, 129, 169, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 170, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 171, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 172, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 173, _::binary>> -> {:error, :bidi, line, column}
      <<226, 128, 174, _::binary>> -> {:error, :bidi, line, column}
      <<239, 187, 191, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 128, 141, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 128, 140, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 128, 139, _::binary>> -> {:error, :zero_width, line, column}
      <<226, 129, 160, _::binary>> -> {:error, :zero_width, line, column}
      <<225, 158, 181, _::binary>> -> {:error, :zero_width, line, column}
      <<225, 158, 180, _::binary>> -> {:error, :zero_width, line, column}
      <<225, 160, 142, _::binary>> -> {:error, :zero_width, line, column}
      <<205, 143, _::binary>> -> {:error, :cgj, line, column}
      <<?_, rest::binary>> -> oct(rest, [?_|data], context, line, column, length+1, ol, oc, acc)
      <<?0, rest::binary>> -> oct(rest, [?0|data], context, line, column, length+1, ol, oc, acc)
      <<?1, rest::binary>> -> oct(rest, [?1|data], context, line, column, length+1, ol, oc, acc)
      <<?2, rest::binary>> -> oct(rest, [?2|data], context, line, column, length+1, ol, oc, acc)
      <<?3, rest::binary>> -> oct(rest, [?3|data], context, line, column, length+1, ol, oc, acc)
      <<?4, rest::binary>> -> oct(rest, [?4|data], context, line, column, length+1, ol, oc, acc)
      <<?5, rest::binary>> -> oct(rest, [?5|data], context, line, column, length+1, ol, oc, acc)
      <<?6, rest::binary>> -> oct(rest, [?6|data], context, line, column, length+1, ol, oc, acc)
      <<?7, rest::binary>> -> oct(rest, [?7|data], context, line, column, length+1, ol, oc, acc)
      rest ->
        end_column = column+length
        lex(rest, context, line, end_column, line, end_column, node(:numeric, :octal, line, column, line, end_column, ol, oc, context, :lists.reverse(data), acc))
    end
  end

  defp backtick(rest, data, l, c, context, line, column, ol, oc, acc) do
    case rest do
      <<239, 187, 191, _::binary>> -> {:error, :zero_width, l, c}
      <<226, 128, 141, _::binary>> -> {:error, :zero_width, l, c}
      <<226, 128, 140, _::binary>> -> {:error, :zero_width, l, c}
      <<226, 128, 139, _::binary>> -> {:error, :zero_width, l, c}
      <<226, 129, 160, _::binary>> -> {:error, :zero_width, l, c}
      <<225, 158, 181, _::binary>> -> {:error, :zero_width, l, c}
      <<225, 158, 180, _::binary>> -> {:error, :zero_width, l, c}
      <<225, 160, 142, _::binary>> -> {:error, :zero_width, l, c}
      <<?`, rest::binary>> ->
        end_line = l+line
        end_column = c+column+1
        lex(rest, context, end_line, end_column, end_line, end_column, node(:backtick, :literal, l, c, end_line, end_column, ol, oc, context, :lists.reverse(data), acc))
      <<194, 160, rest::binary>> -> backtick(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<225, 154, 128, rest::binary>> -> backtick(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<226, 128, 175, rest::binary>> -> backtick(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<226, 128, 137, rest::binary>> -> backtick(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<226, 128, 131, rest::binary>> -> backtick(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<226, 128, 130, rest::binary>> -> backtick(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<226, 129, 159, rest::binary>> -> backtick(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<227, 128, 128, rest::binary>> -> backtick(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<194, 133, rest::binary>> -> backtick(rest, [?\n|data], l, c, context, line+1, column, ol, oc, acc)
      <<226, 128, 168, rest::binary>> -> backtick(rest, [?\n|data], l, c, context, line+1, column, ol, oc, acc)
      <<226, 128, 169, rest::binary>> -> backtick(rest, [?\n|data], l, c, context, line+1, column, ol, oc, acc)
      <<10, rest::binary>> -> backtick(rest, [?\n|data], l, c, context, line+1, column, ol, oc, acc)
      <<11, rest::binary>> -> backtick(rest, [?\n|data], l, c, context, line+1, column, ol, oc, acc)
      <<12, rest::binary>> -> backtick(rest, [?\n|data], l, c, context, line+1, column, ol, oc, acc)
      <<13, rest::binary>> -> backtick(rest, [?\n|data], l, c, context, line+1, column, ol, oc, acc)
      <<b, rest::binary>> -> backtick(rest, [b|data], l, c, context, line, column+1, ol, oc, acc)
      "" -> {:error, file: context.file, line: l, column: c, end_line: l+line, end_column: c+column, opening_delimiter: :"`", expected_delimiter: :"`"}
    end
  end

  defp double_quote(rest, data, l, c, context, line, column, ol, oc, acc) do
    case rest do
      <<239, 187, 191, _::binary>> -> {:error, :zero_width, l, c}
      <<226, 128, 141, _::binary>> -> {:error, :zero_width, l, c}
      <<226, 128, 140, _::binary>> -> {:error, :zero_width, l, c}
      <<226, 128, 139, _::binary>> -> {:error, :zero_width, l, c}
      <<226, 129, 160, _::binary>> -> {:error, :zero_width, l, c}
      <<225, 158, 181, _::binary>> -> {:error, :zero_width, l, c}
      <<225, 158, 180, _::binary>> -> {:error, :zero_width, l, c}
      <<225, 160, 142, _::binary>> -> {:error, :zero_width, l, c}
      <<?", rest::binary>> ->
        end_line = l+line
        end_column = c+column+1
        lex(rest, context, end_line, end_column, end_line, end_column, node(:double_quote, :literal, l, c, end_line, end_column, ol, oc, context, :lists.reverse(data), acc))
      <<194, 160, rest::binary>> -> double_quote(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<225, 154, 128, rest::binary>> -> double_quote(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<226, 128, 175, rest::binary>> -> double_quote(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<226, 128, 137, rest::binary>> -> double_quote(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<226, 128, 131, rest::binary>> -> double_quote(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<226, 128, 130, rest::binary>> -> double_quote(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<226, 129, 159, rest::binary>> -> double_quote(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<227, 128, 128, rest::binary>> -> double_quote(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<194, 133, rest::binary>> -> double_quote(rest, [?\n|data], l, c, context, line+1, column, ol, oc, acc)
      <<226, 128, 168, rest::binary>> -> double_quote(rest, [?\n|data], l, c, context, line+1, column, ol, oc, acc)
      <<226, 128, 169, rest::binary>> -> double_quote(rest, [?\n|data], l, c, context, line+1, column, ol, oc, acc)
      <<10, rest::binary>> -> double_quote(rest, [?\n|data], l, c, context, line+1, column, ol, oc, acc)
      <<11, rest::binary>> -> double_quote(rest, [?\n|data], l, c, context, line+1, column, ol, oc, acc)
      <<12, rest::binary>> -> double_quote(rest, [?\n|data], l, c, context, line+1, column, ol, oc, acc)
      <<13, rest::binary>> -> double_quote(rest, [?\n|data], l, c, context, line+1, column, ol, oc, acc)
      <<b, rest::binary>> -> double_quote(rest, [b|data], l, c, context, line, column+1, ol, oc, acc)
      "" -> {:error, file: context.file, line: l, column: c, end_line: l+line, end_column: c+column, opening_delimiter: :"\"", expected_delimiter: :"\""}
    end
  end

  defp double_brace(rest, data, l, c, n, context, line, column, ol, oc, acc) do
    case rest do
      <<239, 187, 191, _::binary>> -> {:error, :zero_width, l, c}
      <<226, 128, 141, _::binary>> -> {:error, :zero_width, l, c}
      <<226, 128, 140, _::binary>> -> {:error, :zero_width, l, c}
      <<226, 128, 139, _::binary>> -> {:error, :zero_width, l, c}
      <<226, 129, 160, _::binary>> -> {:error, :zero_width, l, c}
      <<225, 158, 181, _::binary>> -> {:error, :zero_width, l, c}
      <<225, 158, 180, _::binary>> -> {:error, :zero_width, l, c}
      <<225, 160, 142, _::binary>> -> {:error, :zero_width, l, c}
      <<205, 143, _::binary>> -> {:cgj, :zero_width, l, c}
      <<194, 160, rest::binary>> -> double_brace(rest, [?\s|data], l, c, n, context, line, column+1, ol, oc, acc)
      <<225, 154, 128, rest::binary>> -> double_brace(rest, [?\s|data], l, c, n, context, line, column+1, ol, oc, acc)
      <<226, 128, 175, rest::binary>> -> double_brace(rest, [?\s|data], l, c, n, context, line, column+1, ol, oc, acc)
      <<226, 128, 137, rest::binary>> -> double_brace(rest, [?\s|data], l, c, n, context, line, column+1, ol, oc, acc)
      <<226, 128, 131, rest::binary>> -> double_brace(rest, [?\s|data], l, c, n, context, line, column+1, ol, oc, acc)
      <<226, 128, 130, rest::binary>> -> double_brace(rest, [?\s|data], l, c, n, context, line, column+1, ol, oc, acc)
      <<226, 129, 159, rest::binary>> -> double_brace(rest, [?\s|data], l, c, n, context, line, column+1, ol, oc, acc)
      <<227, 128, 128, rest::binary>> -> double_brace(rest, [?\s|data], l, c, n, context, line, column+1, ol, oc, acc)
      <<194, 133, rest::binary>> -> double_brace(rest, [?\n|data], l, c, n, context, line, column+1, ol, oc, acc)
      <<226, 128, 168, rest::binary>> -> double_brace(rest, [?\n|data], l, c, n, context, line, column+1, ol, oc, acc)
      <<226, 128, 169, rest::binary>> -> double_brace(rest, [?\n|data], l, c, n, context, line, column+1, ol, oc, acc)
      <<10, rest::binary>> -> double_brace(rest, [?\n|data], l, c, n, context, line, column+1, ol, oc, acc)
      <<11, rest::binary>> -> double_brace(rest, [?\n|data], l, c, n, context, line, column+1, ol, oc, acc)
      <<12, rest::binary>> -> double_brace(rest, [?\n|data], l, c, n, context, line, column+1, ol, oc, acc)
      <<13, rest::binary>> -> double_brace(rest, [?\n|data], l, c, n, context, line, column+1, ol, oc, acc)
      <<?{, rest::binary>> -> double_brace(rest, [?{|data], l, c, n+1, context, line, column+1, ol, oc, acc)
      <<?}, ?}, rest::binary>> when n == 0 ->
        end_line = l+line
        end_column = c+column+2
        idx = context.idx+1
        value = Code.string_to_quoted!(:lists.reverse(data), file: context.file, line: line, column: column, columns: true, token_metadata: true, existing_atoms_only: true)
        lex(rest, %{context|idx: idx, binding: [value|context.binding]}, end_line, end_column, end_line, end_column, node(:binding, :binding, l, c, end_line, end_column, ol, oc, context, [idx], acc))
      <<?}, rest::binary>> -> double_brace(rest, [?}|data], l, c, n-1, context, line, column+1, ol, oc, acc)
      <<b, rest::binary>> -> double_brace(rest, [b|data], l, c, n, context, line, column+1, ol, oc, acc)
      "" -> {:error, file: context.file, end_line: l, end_column: c, line: l+line, column: c+column, opening_delimiter: :"{", expected_delimiter: :"}"}
    end
  end

  defp quote(rest, data, l, c, context, line, column, ol, oc, acc) do
    case rest do
      <<239, 187, 191, _::binary>> -> {:error, :zero_width, l, c}
      <<226, 128, 141, _::binary>> -> {:error, :zero_width, l, c}
      <<226, 128, 140, _::binary>> -> {:error, :zero_width, l, c}
      <<226, 128, 139, _::binary>> -> {:error, :zero_width, l, c}
      <<226, 129, 160, _::binary>> -> {:error, :zero_width, l, c}
      <<225, 158, 181, _::binary>> -> {:error, :zero_width, l, c}
      <<225, 158, 180, _::binary>> -> {:error, :zero_width, l, c}
      <<225, 160, 142, _::binary>> -> {:error, :zero_width, l, c}
      <<?', rest::binary>> ->
        end_line = l+line
        end_column = c+column+1
        lex(rest, context, end_line, end_column, end_line, end_column, node(:quote, :literal, l, c, end_line, end_column, ol, oc, context, :lists.reverse(data), acc))
      <<194, 160, rest::binary>> -> quote(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<225, 154, 128, rest::binary>> -> quote(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<226, 128, 175, rest::binary>> -> quote(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<226, 128, 137, rest::binary>> -> quote(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<226, 128, 131, rest::binary>> -> quote(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<226, 128, 130, rest::binary>> -> quote(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<226, 129, 159, rest::binary>> -> quote(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<227, 128, 128, rest::binary>> -> quote(rest, [?\s|data], l, c, context, line, column+1, ol, oc, acc)
      <<194, 133, rest::binary>> -> quote(rest, [?\n|data], l, c, context, line+1, column, ol, oc, acc)
      <<226, 128, 168, rest::binary>> -> quote(rest, [?\n|data], l, c, context, line+1, column, ol, oc, acc)
      <<226, 128, 169, rest::binary>> -> quote(rest, [?\n|data], l, c, context, line+1, column, ol, oc, acc)
      <<10, rest::binary>> -> quote(rest, [?\n|data], l, c, context, line+1, column, ol, oc, acc)
      <<11, rest::binary>> -> quote(rest, [?\n|data], l, c, context, line+1, column, ol, oc, acc)
      <<12, rest::binary>> -> quote(rest, [?\n|data], l, c, context, line+1, column, ol, oc, acc)
      <<13, rest::binary>> -> quote(rest, [?\n|data], l, c, context, line+1, column, ol, oc, acc)
      <<b, rest::binary>> -> quote(rest, [b|data], l, c, context, line, column+1, ol, oc, acc)
      "" -> {:error, file: context.file, line: l, column: c, end_line: l+line, end_column: c+column, opening_delimiter: :"'", expected_delimiter: :"'"}
    end
  end

  defp node(tag, type, line, column, end_line, end_column, ol, oc, context, data) do
    case type do
      :non_reserved -> {:ident, [span: span(line, column, end_line, end_column, ol, oc), type: type, tag: tag, file: context.file], data}
      _ -> {tag, [span: span(line, column, end_line, end_column, ol, oc), type: type, file: context.file], data}
    end
  end

  defp node(tag, type, line, column, end_line, end_column, ol, oc, context, data, acc) do
    [node(tag, type, line, column, end_line, end_column, ol, oc, context, data)|acc]
  end

  defp span(line, column, end_line, end_column, ol, oc, end_line, ooc), do: {line, column, end_line, end_column, line-ol, column-oc, 0, end_column-ooc}
  defp span(line, column, end_line, end_column, line, oc, ool, _ooc), do: {line, column, end_line, end_column, 0, column-oc, end_line-ool, end_column}
  defp span(line, column, end_line, end_column, ol, _oc, ool, _ooc), do: {line, column, end_line, end_column, line-ol, end_column, end_line-ool, end_column}

  defp span(line, column, end_line, end_column, end_line, oc), do: {line, column, end_line, end_column, 0, column-oc}
  defp span(line, column, end_line, end_column, ol, _oc), do: {line, column, end_line, end_column, line-ol, column}
end
