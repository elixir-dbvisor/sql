# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Lexer do
  @moduledoc false
  require Unicode.Set
  @zero "illegal zero width character"
  @bidi "illegal bidi character"
  @cgj "illegal cgj character"
  @context %{idx: 0, file: "nofile", binding: [], aliases: [], errors: [], module: nil, format: :static, case: :lower, validate: nil}
  def lex(binary, <<file::binary>> \\ "nofile", idx \\ 0) do
    case lex(binary, %{@context | file: file, idx: idx}, 0, 0, []) do
      {:error, error} -> raise TokenMissingError, [{:snippet, binary} | error]
      {:error, :zero_width, l, c} -> raise SyntaxError, [description: @zero, file: file, line: l, column: c]
      {:error, :bidi, l, c} -> raise SyntaxError, [description: @bidi, file: file, line: l, column: c]
      {:error, :cgj, l, c} -> raise SyntaxError, [description: @cgj, file: file, line: l, column: c]
      {_, _, context, acc} -> {:ok, context, acc}
    end
  end

  defp lex(rest, context, line, column, acc) do
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
      <<9, rest::binary>> -> lex(rest, context, line, column+1, acc)
      <<32, rest::binary>> -> lex(rest, context, line, column+1, acc)
      <<194, 160, rest::binary>> -> lex(rest, context, line, column+1, acc)
      <<225, 154, 128, rest::binary>> -> lex(rest, context, line, column+1, acc)
      <<226, 128, 130, rest::binary>> -> lex(rest, context, line, column+1, acc)
      <<226, 128, 131, rest::binary>> -> lex(rest, context, line, column+1, acc)
      <<226, 128, 137, rest::binary>> -> lex(rest, context, line, column+1, acc)
      <<226, 128, 175, rest::binary>> -> lex(rest, context, line, column+1, acc)
      <<226, 129, 159, rest::binary>> -> lex(rest, context, line, column+1, acc)
      <<227, 128, 128, rest::binary>> -> lex(rest, context, line, column+1, acc)
      <<194, 133, rest::binary>> -> lex(rest, context, line+1, 0, acc)
      <<226, 128, 168, rest::binary>> -> lex(rest, context, line+1, 0, acc)
      <<226, 128, 169, rest::binary>> -> lex(rest, context, line+1, 0, acc)
      <<10, rest::binary>> -> lex(rest, context, line+1, 0, acc)
      <<11, rest::binary>> -> lex(rest, context, line+1, 0, acc)
      <<12, rest::binary>> -> lex(rest, context, line+1, 0, acc)
      <<13, rest::binary>> -> lex(rest, context, line+1, 0, acc)
      <<?., rest::binary>> ->
        column = column+1
        case acc do
          [{t, _, _}|_] when t in ~w[ident double_quote bracket]a ->
            lex(rest, context, line, column, node(:dot, :operator, line, column, line, column, context, [], acc))
          _ ->
            num(rest, [?.], context, line, column, 0, acc)
        end
      <<?;, rest::binary>> ->
        column = column+1
        lex(rest, context, line, column, node(:colon, :delimiter, line, column, line, column, context, [], acc))
      <<?,, rest::binary>> ->
        column = column+1
        lex(rest, context, line, column, node(:comma, :delimiter, line, column, line, column, context, [], acc))
      <<?-, ?-, rest::binary>> -> comment(rest, [], line, column+1, context, line, column+1, acc)
      <<?/, ?*, rest::binary>> -> comments(rest, [], line, column+1, context, line, column+1, acc)
      <<?{, ?{, rest::binary>> -> double_brace(rest, [], line, column+1, 0, context, 0, 1, acc)
      <<?`, rest::binary>> -> backtick(rest, [], line, column+1, context, line, column, acc)
      <<?', rest::binary>> -> quote(rest, [], line, column+1, context, line, column, acc)
      <<?", rest::binary>> -> double_quote(rest, [], line, column+1, context, line, column, acc)
      <<?0, ?x, rest::binary>> -> hex(rest, [?x, ?0], context, line, column+1, 1, acc)
      <<?0, ?X, rest::binary>> -> hex(rest, [?X, ?0], context, line, column+1, 1, acc)
      <<?0, ?b, rest::binary>> -> bin(rest, [?b, ?0], context, line, column+1, 1, acc)
      <<?0, ?B, rest::binary>> -> bin(rest, [?B, ?0], context, line, column+1, 1, acc)
      <<?0, ?o, rest::binary>> -> oct(rest, [?o, ?0], context, line, column+1, 1, acc)
      <<?0, ?O, rest::binary>> -> oct(rest, [?O, ?0], context, line, column+1, 1, acc)
      <<?!, rest::binary>> -> special(rest, [?!], context, line, column+1, 0, acc)
      <<?#, rest::binary>> -> special(rest, [?#], context, line, column+1, 0, acc)
      <<?$, rest::binary>> -> special(rest, [?$], context, line, column+1, 0, acc)
      <<?%, rest::binary>> -> special(rest, [?%], context, line, column+1, 0, acc)
      <<?&, rest::binary>> -> special(rest, [?&], context, line, column+1, 0, acc)
      <<?*, rest::binary>> -> special(rest, [?*], context, line, column+1, 0, acc)
      <<?+, rest::binary>> -> special(rest, [?+], context, line, column+1, 0, acc)
      <<?-, rest::binary>> -> special(rest, [?-], context, line, column+1, 0, acc)
      <<?/, rest::binary>> -> special(rest, [?/], context, line, column+1, 0, acc)
      <<?:, rest::binary>> -> special(rest, [?:], context, line, column+1, 0, acc)
      <<?<, rest::binary>> -> special(rest, [?<], context, line, column+1, 0, acc)
      <<?=, rest::binary>> -> special(rest, [?=], context, line, column+1, 0, acc)
      <<?>, rest::binary>> -> special(rest, [?>], context, line, column+1, 0, acc)
      <<??, rest::binary>> -> special(rest, [??], context, line, column+1, 0, acc)
      <<?@, rest::binary>> -> special(rest, [?@], context, line, column+1, 0, acc)
      <<?^, rest::binary>> -> special(rest, [?^], context, line, column+1, 0, acc)
      <<?|, rest::binary>> -> special(rest, [?|], context, line, column+1, 0, acc)
      <<?~, rest::binary>> -> special(rest, [?~], context, line, column+1, 0, acc)
      <<?_, rest::binary>> -> ident(rest, [?_], context, line, column+1, 0, acc)
      <<?0, rest::binary>> -> num(rest, [?0], context, line, column+1, 0, acc)
      <<?1, rest::binary>> -> num(rest, [?1], context, line, column+1, 0, acc)
      <<?2, rest::binary>> -> num(rest, [?2], context, line, column+1, 0, acc)
      <<?3, rest::binary>> -> num(rest, [?3], context, line, column+1, 0, acc)
      <<?4, rest::binary>> -> num(rest, [?4], context, line, column+1, 0, acc)
      <<?5, rest::binary>> -> num(rest, [?5], context, line, column+1, 0, acc)
      <<?6, rest::binary>> -> num(rest, [?6], context, line, column+1, 0, acc)
      <<?7, rest::binary>> -> num(rest, [?7], context, line, column+1, 0, acc)
      <<?8, rest::binary>> -> num(rest, [?8], context, line, column+1, 0, acc)
      <<?9, rest::binary>> -> num(rest, [?9], context, line, column+1, 0, acc)
      <<?A, rest::binary>> -> ident(rest, [?a], context, line, column+1, 0, acc)
      <<?B, rest::binary>> -> ident(rest, [?b], context, line, column+1, 0, acc)
      <<?C, rest::binary>> -> ident(rest, [?c], context, line, column+1, 0, acc)
      <<?D, rest::binary>> -> ident(rest, [?d], context, line, column+1, 0, acc)
      <<?E, rest::binary>> -> ident(rest, [?e], context, line, column+1, 0, acc)
      <<?F, rest::binary>> -> ident(rest, [?f], context, line, column+1, 0, acc)
      <<?G, rest::binary>> -> ident(rest, [?g], context, line, column+1, 0, acc)
      <<?H, rest::binary>> -> ident(rest, [?h], context, line, column+1, 0, acc)
      <<?I, rest::binary>> -> ident(rest, [?i], context, line, column+1, 0, acc)
      <<?J, rest::binary>> -> ident(rest, [?j], context, line, column+1, 0, acc)
      <<?K, rest::binary>> -> ident(rest, [?k], context, line, column+1, 0, acc)
      <<?L, rest::binary>> -> ident(rest, [?l], context, line, column+1, 0, acc)
      <<?M, rest::binary>> -> ident(rest, [?m], context, line, column+1, 0, acc)
      <<?N, rest::binary>> -> ident(rest, [?n], context, line, column+1, 0, acc)
      <<?O, rest::binary>> -> ident(rest, [?o], context, line, column+1, 0, acc)
      <<?P, rest::binary>> -> ident(rest, [?p], context, line, column+1, 0, acc)
      <<?Q, rest::binary>> -> ident(rest, [?q], context, line, column+1, 0, acc)
      <<?R, rest::binary>> -> ident(rest, [?r], context, line, column+1, 0, acc)
      <<?S, rest::binary>> -> ident(rest, [?s], context, line, column+1, 0, acc)
      <<?T, rest::binary>> -> ident(rest, [?t], context, line, column+1, 0, acc)
      <<?U, rest::binary>> -> ident(rest, [?u], context, line, column+1, 0, acc)
      <<?V, rest::binary>> -> ident(rest, [?v], context, line, column+1, 0, acc)
      <<?W, rest::binary>> -> ident(rest, [?w], context, line, column+1, 0, acc)
      <<?X, rest::binary>> -> ident(rest, [?x], context, line, column+1, 0, acc)
      <<?Y, rest::binary>> -> ident(rest, [?y], context, line, column+1, 0, acc)
      <<?Z, rest::binary>> -> ident(rest, [?z], context, line, column+1, 0, acc)
      <<?a, rest::binary>> -> ident(rest, [?a], context, line, column+1, 0, acc)
      <<?b, rest::binary>> -> ident(rest, [?b], context, line, column+1, 0, acc)
      <<?c, rest::binary>> -> ident(rest, [?c], context, line, column+1, 0, acc)
      <<?d, rest::binary>> -> ident(rest, [?d], context, line, column+1, 0, acc)
      <<?e, rest::binary>> -> ident(rest, [?e], context, line, column+1, 0, acc)
      <<?f, rest::binary>> -> ident(rest, [?f], context, line, column+1, 0, acc)
      <<?g, rest::binary>> -> ident(rest, [?g], context, line, column+1, 0, acc)
      <<?h, rest::binary>> -> ident(rest, [?h], context, line, column+1, 0, acc)
      <<?i, rest::binary>> -> ident(rest, [?i], context, line, column+1, 0, acc)
      <<?j, rest::binary>> -> ident(rest, [?j], context, line, column+1, 0, acc)
      <<?k, rest::binary>> -> ident(rest, [?k], context, line, column+1, 0, acc)
      <<?l, rest::binary>> -> ident(rest, [?l], context, line, column+1, 0, acc)
      <<?m, rest::binary>> -> ident(rest, [?m], context, line, column+1, 0, acc)
      <<?n, rest::binary>> -> ident(rest, [?n], context, line, column+1, 0, acc)
      <<?o, rest::binary>> -> ident(rest, [?o], context, line, column+1, 0, acc)
      <<?p, rest::binary>> -> ident(rest, [?p], context, line, column+1, 0, acc)
      <<?q, rest::binary>> -> ident(rest, [?q], context, line, column+1, 0, acc)
      <<?r, rest::binary>> -> ident(rest, [?r], context, line, column+1, 0, acc)
      <<?s, rest::binary>> -> ident(rest, [?s], context, line, column+1, 0, acc)
      <<?t, rest::binary>> -> ident(rest, [?t], context, line, column+1, 0, acc)
      <<?u, rest::binary>> -> ident(rest, [?u], context, line, column+1, 0, acc)
      <<?v, rest::binary>> -> ident(rest, [?v], context, line, column+1, 0, acc)
      <<?w, rest::binary>> -> ident(rest, [?w], context, line, column+1, 0, acc)
      <<?x, rest::binary>> -> ident(rest, [?x], context, line, column+1, 0, acc)
      <<?y, rest::binary>> -> ident(rest, [?y], context, line, column+1, 0, acc)
      <<?(, rest::binary>> ->
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
      <<?[, rest::binary>> ->
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
      <<?{, rest::binary>> ->
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
      <<?}, rest::binary>> -> {rest, context, line, column+1, acc}
      <<?), rest::binary>> -> {rest, context, line, column+1, acc}
      <<?], rest::binary>> -> {rest, context, line, column+1, acc}
      <<b::utf8, rest::binary>> when Unicode.Set.match?(b, "[[:Lu:], [:Ll:], [:Lt:], [:Lm:], [:Lo:], [:Nl:]]") ->
        ident(rest, [b], context, line, column+1, 0, acc)
      "" -> {line, column, context, acc}
      # rest -> ident_start(rest, context, line, column, acc)
    end
  end

  # case_ast =
  #   for b <- tl(Unicode.Set.to_pattern!("[[:Lu:], [:Ll:], [:Lt:], [:Lm:], [:Lo:], [:Nl:]]")) do
  #     hd(
  #       quote do
  #         <<unquote(b), rest::binary>> -> ident(rest, [unquote(b)], var!(context), var!(line), var!(column)+1, 0, var!(acc))
  #         # <<unquote(b), rest::binary>> -> true
  #       end
  #     )
  #   end

  #   defp ident_start(rest, context, line, column, acc) do
  #     case rest do
  #       unquote(case_ast)
  #     end
  #   end



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
            lex(var!(rest), var!(context), var!(line), var!(end_column), node(unquote(atom), unquote(type), var!(line), var!(column), var!(line), var!(end_column), var!(context), [], var!(acc)))
        end
      )
    end ++ for {atom, match} <- non_reserved do
      hd(
        quote do
          unquote(match) ->
            lex(var!(rest), var!(context), var!(line), var!(end_column), node(unquote(atom), :non_reserved, var!(line), var!(column), var!(line), var!(end_column), var!(context), :lists.reverse(var!(data)), var!(acc)))
        end
      )
    end ++ quote do
      data -> lex(var!(rest), var!(context), var!(line), var!(end_column), node(:ident, :literal, var!(line), var!(column), var!(line), var!(end_column), var!(context), :lists.reverse(data), var!(acc)))
    end

  defp ident(rest, data, context, line, column, length, acc) do
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
        end_column = column+length+1
        backtick(rest, [], line, end_column, context, 0, 0, node(:ident, :literal, line, column, line, end_column, context, :lists.reverse(data), acc))
      <<?', rest::binary>> ->
        end_column = column+length+1
        quote(rest, [], line, end_column, context, 0, 0, node(:ident, :literal, line, column, line, end_column, context, :lists.reverse(data), acc))
      <<?", rest::binary>> ->
        end_column = column+length+1
        double_quote(rest, [], line, end_column, context, 0, 0, node(:ident, :literal, line, column, line, end_column, context, :lists.reverse(data), acc))
      <<?_, rest::binary>> -> ident(rest, [?_|data], context, line, column, length+1, acc)
      <<?&, rest::binary>> -> ident(rest, [?&|data], context, line, column, length+1, acc)
      <<?0, rest::binary>> -> ident(rest, [?0|data], context, line, column, length+1, acc)
      <<?1, rest::binary>> -> ident(rest, [?1|data], context, line, column, length+1, acc)
      <<?2, rest::binary>> -> ident(rest, [?2|data], context, line, column, length+1, acc)
      <<?3, rest::binary>> -> ident(rest, [?3|data], context, line, column, length+1, acc)
      <<?4, rest::binary>> -> ident(rest, [?4|data], context, line, column, length+1, acc)
      <<?5, rest::binary>> -> ident(rest, [?5|data], context, line, column, length+1, acc)
      <<?6, rest::binary>> -> ident(rest, [?6|data], context, line, column, length+1, acc)
      <<?7, rest::binary>> -> ident(rest, [?7|data], context, line, column, length+1, acc)
      <<?8, rest::binary>> -> ident(rest, [?8|data], context, line, column, length+1, acc)
      <<?9, rest::binary>> -> ident(rest, [?9|data], context, line, column, length+1, acc)
      <<?A, rest::binary>> -> ident(rest, [?a|data], context, line, column, length+1, acc)
      <<?B, rest::binary>> -> ident(rest, [?b|data], context, line, column, length+1, acc)
      <<?C, rest::binary>> -> ident(rest, [?c|data], context, line, column, length+1, acc)
      <<?D, rest::binary>> -> ident(rest, [?d|data], context, line, column, length+1, acc)
      <<?E, rest::binary>> -> ident(rest, [?e|data], context, line, column, length+1, acc)
      <<?F, rest::binary>> -> ident(rest, [?f|data], context, line, column, length+1, acc)
      <<?G, rest::binary>> -> ident(rest, [?g|data], context, line, column, length+1, acc)
      <<?H, rest::binary>> -> ident(rest, [?h|data], context, line, column, length+1, acc)
      <<?I, rest::binary>> -> ident(rest, [?i|data], context, line, column, length+1, acc)
      <<?J, rest::binary>> -> ident(rest, [?j|data], context, line, column, length+1, acc)
      <<?K, rest::binary>> -> ident(rest, [?k|data], context, line, column, length+1, acc)
      <<?L, rest::binary>> -> ident(rest, [?l|data], context, line, column, length+1, acc)
      <<?M, rest::binary>> -> ident(rest, [?m|data], context, line, column, length+1, acc)
      <<?N, rest::binary>> -> ident(rest, [?n|data], context, line, column, length+1, acc)
      <<?O, rest::binary>> -> ident(rest, [?o|data], context, line, column, length+1, acc)
      <<?P, rest::binary>> -> ident(rest, [?p|data], context, line, column, length+1, acc)
      <<?Q, rest::binary>> -> ident(rest, [?q|data], context, line, column, length+1, acc)
      <<?R, rest::binary>> -> ident(rest, [?r|data], context, line, column, length+1, acc)
      <<?S, rest::binary>> -> ident(rest, [?s|data], context, line, column, length+1, acc)
      <<?T, rest::binary>> -> ident(rest, [?t|data], context, line, column, length+1, acc)
      <<?U, rest::binary>> -> ident(rest, [?u|data], context, line, column, length+1, acc)
      <<?V, rest::binary>> -> ident(rest, [?v|data], context, line, column, length+1, acc)
      <<?W, rest::binary>> -> ident(rest, [?w|data], context, line, column, length+1, acc)
      <<?X, rest::binary>> -> ident(rest, [?x|data], context, line, column, length+1, acc)
      <<?Y, rest::binary>> -> ident(rest, [?y|data], context, line, column, length+1, acc)
      <<?Z, rest::binary>> -> ident(rest, [?z|data], context, line, column, length+1, acc)
      <<?a, rest::binary>> -> ident(rest, [?a|data], context, line, column, length+1, acc)
      <<?b, rest::binary>> -> ident(rest, [?b|data], context, line, column, length+1, acc)
      <<?c, rest::binary>> -> ident(rest, [?c|data], context, line, column, length+1, acc)
      <<?d, rest::binary>> -> ident(rest, [?d|data], context, line, column, length+1, acc)
      <<?e, rest::binary>> -> ident(rest, [?e|data], context, line, column, length+1, acc)
      <<?f, rest::binary>> -> ident(rest, [?f|data], context, line, column, length+1, acc)
      <<?g, rest::binary>> -> ident(rest, [?g|data], context, line, column, length+1, acc)
      <<?h, rest::binary>> -> ident(rest, [?h|data], context, line, column, length+1, acc)
      <<?i, rest::binary>> -> ident(rest, [?i|data], context, line, column, length+1, acc)
      <<?j, rest::binary>> -> ident(rest, [?j|data], context, line, column, length+1, acc)
      <<?k, rest::binary>> -> ident(rest, [?k|data], context, line, column, length+1, acc)
      <<?l, rest::binary>> -> ident(rest, [?l|data], context, line, column, length+1, acc)
      <<?m, rest::binary>> -> ident(rest, [?m|data], context, line, column, length+1, acc)
      <<?n, rest::binary>> -> ident(rest, [?n|data], context, line, column, length+1, acc)
      <<?o, rest::binary>> -> ident(rest, [?o|data], context, line, column, length+1, acc)
      <<?p, rest::binary>> -> ident(rest, [?p|data], context, line, column, length+1, acc)
      <<?q, rest::binary>> -> ident(rest, [?q|data], context, line, column, length+1, acc)
      <<?r, rest::binary>> -> ident(rest, [?r|data], context, line, column, length+1, acc)
      <<?s, rest::binary>> -> ident(rest, [?s|data], context, line, column, length+1, acc)
      <<?t, rest::binary>> -> ident(rest, [?t|data], context, line, column, length+1, acc)
      <<?u, rest::binary>> -> ident(rest, [?u|data], context, line, column, length+1, acc)
      <<?v, rest::binary>> -> ident(rest, [?v|data], context, line, column, length+1, acc)
      <<?w, rest::binary>> -> ident(rest, [?w|data], context, line, column, length+1, acc)
      <<?x, rest::binary>> -> ident(rest, [?x|data], context, line, column, length+1, acc)
      <<?y, rest::binary>> -> ident(rest, [?y|data], context, line, column, length+1, acc)
      <<b::utf8, rest::binary>> when Unicode.Set.match?(b, "[[:Lu:], [:Ll:], [:Lt:], [:Lm:], [:Lo:], [:Nl:], [:Mn:], [:Mc:], [:Nd:], [:Pc:], [:Cf:]]") and b != ?, ->
        ident(rest, [b|data], context, line, column, length+1, acc)
      rest ->
        end_column = column+length
        case data do
          unquote(case_ast)
        end
    end
  end

  defp comment(rest, data, l, c, context, line, column, acc) do
    case rest do
      <<194, 133, rest::binary>> ->
        l=l+1
        lex(rest, context, l, c, node(:comment, :literal, line, column, l, c, context, :lists.reverse(data), acc))
      <<226, 128, 168, rest::binary>> ->
        l=l+1
        lex(rest, context, l, c, node(:comment, :literal, line, column, l, c, context, :lists.reverse(data), acc))
      <<226, 128, 169, rest::binary>> ->
        l=l+1
        lex(rest, context, l, c, node(:comment, :literal, line, column, l, c, context, :lists.reverse(data), acc))
      <<10, rest::binary>> ->
        l=l+1
        lex(rest, context, l, c, node(:comment, :literal, line, column, l, c, context, :lists.reverse(data), acc))
      <<11, rest::binary>> ->
        l=l+1
        lex(rest, context, l, c, node(:comment, :literal, line, column, l, c, context, :lists.reverse(data), acc))
      <<12, rest::binary>> ->
        l=l+1
        lex(rest, context, l, c, node(:comment, :literal, line, column, l, c, context, :lists.reverse(data), acc))
      <<13, rest::binary>> ->
        l=l+1
        lex(rest, context, l, c, node(:comment, :literal, line, column, l, c, context, :lists.reverse(data), acc))
      <<194, 160, rest::binary>> -> comment(rest, [?\s|data], l, c+1, context, line, column, acc)
      <<225, 154, 128, rest::binary>> -> comment(rest, [?\s|data], l, c+1, context, line, column, acc)
      <<226, 128, 130, rest::binary>> -> comment(rest, [?\s|data], l, c+1, context, line, column, acc)
      <<226, 128, 131, rest::binary>> -> comment(rest, [?\s|data], l, c+1, context, line, column, acc)
      <<226, 128, 137, rest::binary>> -> comment(rest, [?\s|data], l, c+1, context, line, column, acc)
      <<226, 128, 175, rest::binary>> -> comment(rest, [?\s|data], l, c+1, context, line, column, acc)
      <<226, 129, 159, rest::binary>> -> comment(rest, [?\s|data], l, c+1, context, line, column, acc)
      <<227, 128, 128, rest::binary>> -> comment(rest, [?\s|data], l, c+1, context, line, column, acc)
      <<b, rest::binary>> -> comment(rest, [b|data], l, c+1, context, line, column, acc)
      "" -> lex(rest, context, l, c, node(:comment, :literal, line, column, l, c, context, :lists.reverse(data), acc))
    end
  end

  defp comments(rest, data, l, c, context, line, column, acc) do
    case rest do
      <<194, 133, rest::binary>> -> comments(rest, [?\n|data], l+1, c, context, line, column, acc)
      <<226, 128, 168, rest::binary>> -> comments(rest, [?\n|data], l+1, c, context, line, column, acc)
      <<226, 128, 169, rest::binary>> -> comments(rest, [?\n|data], l+1, c, context, line, column, acc)
      <<10, rest::binary>> -> comments(rest, [?\n|data], l+1, c, context, line, column, acc)
      <<11, rest::binary>> -> comments(rest, [?\n|data], l+1, c, context, line, column, acc)
      <<12, rest::binary>> -> comments(rest, [?\n|data], l+1, c, context, line, column, acc)
      <<13, rest::binary>> -> comments(rest, [?\n|data], l+1, c, context, line, column, acc)
      <<194, 160, rest::binary>> -> comments(rest, [?\s|data], l, c+1, context, line, column, acc)
      <<225, 154, 128, rest::binary>> -> comments(rest, [?\s|data], l, c+1, context, line, column, acc)
      <<226, 128, 130, rest::binary>> -> comments(rest, [?\s|data], l, c+1, context, line, column, acc)
      <<226, 128, 131, rest::binary>> -> comments(rest, [?\s|data], l, c+1, context, line, column, acc)
      <<226, 128, 137, rest::binary>> -> comments(rest, [?\s|data], l, c+1, context, line, column, acc)
      <<226, 128, 175, rest::binary>> -> comments(rest, [?\s|data], l, c+1, context, line, column, acc)
      <<226, 129, 159, rest::binary>> -> comments(rest, [?\s|data], l, c+1, context, line, column, acc)
      <<227, 128, 128, rest::binary>> -> comments(rest, [?\s|data], l, c+1, context, line, column, acc)
      <<?*, ?/, rest::binary>> ->
        c=c+2
        lex(rest, context, l, c, node(:comments, :literal, line, column, l, c, context, :lists.reverse(data), acc))
      <<b, rest::binary>> -> comments(rest, [b|data], l, c+1, context, line, column, acc)
      "" -> {:error, file: context.file, end_line: l, end_column: c, line: line, column: column, opening_delimiter: :"/*", expected_delimiter: :"*/"}
    end
  end

  case_ast =
    for {atom, match} <- operators, hd(match) not in ?a..?z do
      hd(
        quote do
          unquote(match) -> lex(var!(rest), var!(context), var!(line), var!(end_column), node(unquote(atom), :operator, var!(line), var!(column), var!(line), var!(end_column), var!(context), [], var!(acc)))
        end
      )
    end ++ quote do
      data ->
        case var!(acc) do
          [] ->
            node = node(:special, :operator, var!(line), var!(column), var!(line), var!(end_column), 0, 0, var!(context), data)
            lex(var!(rest), %{var!(context) | errors: [node|var!(context).errors]}, var!(line), var!(end_column), [node|var!(acc)])
          [{_, [{:span, {_, _, el, ec}}|_], _}|_] ->
            node = node(:special, :operator, var!(line), var!(column), var!(line), var!(end_column), var!(line)-el, (var!(column)-ec)-1, var!(context), data)
            lex(var!(rest), %{var!(context) | errors: [node|var!(context).errors]}, var!(line), var!(end_column), [node|var!(acc)])
        end
    end

  defp special(rest, data, context, line, column, length, acc) do
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
      <<?!, rest::binary>> -> special(rest, [?!|data], context, line, column, length+1, acc)
      <<?#, rest::binary>> -> special(rest, [?#|data], context, line, column, length+1, acc)
      <<?$, rest::binary>> -> special(rest, [?$|data], context, line, column, length+1, acc)
      <<?%, rest::binary>> -> special(rest, [?%|data], context, line, column, length+1, acc)
      <<?&, rest::binary>> -> special(rest, [?&|data], context, line, column, length+1, acc)
      <<?*, rest::binary>> -> special(rest, [?*|data], context, line, column, length+1, acc)
      <<?+, rest::binary>> -> special(rest, [?+|data], context, line, column, length+1, acc)
      <<?-, rest::binary>> -> special(rest, [?-|data], context, line, column, length+1, acc)
      <<?/, rest::binary>> -> special(rest, [?/|data], context, line, column, length+1, acc)
      <<?:, rest::binary>> -> special(rest, [?:|data], context, line, column, length+1, acc)
      <<?<, rest::binary>> -> special(rest, [?<|data], context, line, column, length+1, acc)
      <<?=, rest::binary>> -> special(rest, [?=|data], context, line, column, length+1, acc)
      <<?>, rest::binary>> -> special(rest, [?>|data], context, line, column, length+1, acc)
      <<??, rest::binary>> -> special(rest, [??|data], context, line, column, length+1, acc)
      <<?@, rest::binary>> -> special(rest, [?@|data], context, line, column, length+1, acc)
      <<?^, rest::binary>> -> special(rest, [?^|data], context, line, column, length+1, acc)
      <<?_, rest::binary>> -> special(rest, [?_|data], context, line, column, length+1, acc)
      <<?|, rest::binary>> -> special(rest, [?||data], context, line, column, length+1, acc)
      <<?~, rest::binary>> -> special(rest, [?~|data], context, line, column, length+1, acc)
      rest ->
        end_column = column+length
        case data do
          unquote(case_ast)
        end
    end
  end

  defp num(rest, data, context, line, column, length, acc) do
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
      # <<?., e, s, b, rest::binary>> when b in ?0..?9 and e in ~c"Ee" and s in ~c"-+"  -> num(rest, [b,s,e,?.|data], line, column, context, length+4, acc)
      # <<?., b, e, s, rest::binary>> when b in ?0..?9 and e in ~c"Ee" and s in ~c"-+" -> num(rest, [s,e,b,?.|data], line, column, context, length+4, acc)
      <<?_, rest::binary>> -> num(rest, [?_|data], context, line, column, length+1, acc)
      <<?., rest::binary>> -> num(rest, [?.|data], context, line, column, length+1, acc)
      <<?-, rest::binary>> -> num(rest, [?-|data], context, line, column, length+1, acc)
      <<?+, rest::binary>> -> num(rest, [?+|data], context, line, column, length+1, acc)
      <<?e, rest::binary>> -> num(rest, [?e|data], context, line, column, length+1, acc)
      <<?E, rest::binary>> -> num(rest, [?E|data], context, line, column, length+1, acc)
      <<?0, rest::binary>> -> num(rest, [?0|data], context, line, column, length+1, acc)
      <<?1, rest::binary>> -> num(rest, [?1|data], context, line, column, length+1, acc)
      <<?2, rest::binary>> -> num(rest, [?2|data], context, line, column, length+1, acc)
      <<?3, rest::binary>> -> num(rest, [?3|data], context, line, column, length+1, acc)
      <<?4, rest::binary>> -> num(rest, [?4|data], context, line, column, length+1, acc)
      <<?5, rest::binary>> -> num(rest, [?5|data], context, line, column, length+1, acc)
      <<?6, rest::binary>> -> num(rest, [?6|data], context, line, column, length+1, acc)
      <<?7, rest::binary>> -> num(rest, [?7|data], context, line, column, length+1, acc)
      <<?8, rest::binary>> -> num(rest, [?8|data], context, line, column, length+1, acc)
      <<?9, rest::binary>> -> num(rest, [?9|data], context, line, column, length+1, acc)
      # <<e, b, rest::binary>> when b in ?0..?9 and e in ~c"Ee" -> num(rest, [?9|data], l, c, context, line, column+1, acc)
      rest ->
        end_column = column+length
        lex(rest, context, line, end_column, node(:numeric, :literal, line, column, line, end_column, context, :lists.reverse(data), acc))
    end
  end

  defp hex(rest, data, context, line, column, length, acc) do
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
      <<?_, rest::binary>> -> hex(rest, [?_|data], context, line, column, length+1, acc)
      <<?0, rest::binary>> -> hex(rest, [?0|data], context, line, column, length+1, acc)
      <<?1, rest::binary>> -> hex(rest, [?1|data], context, line, column, length+1, acc)
      <<?2, rest::binary>> -> hex(rest, [?2|data], context, line, column, length+1, acc)
      <<?3, rest::binary>> -> hex(rest, [?3|data], context, line, column, length+1, acc)
      <<?4, rest::binary>> -> hex(rest, [?4|data], context, line, column, length+1, acc)
      <<?5, rest::binary>> -> hex(rest, [?5|data], context, line, column, length+1, acc)
      <<?6, rest::binary>> -> hex(rest, [?6|data], context, line, column, length+1, acc)
      <<?7, rest::binary>> -> hex(rest, [?7|data], context, line, column, length+1, acc)
      <<?8, rest::binary>> -> hex(rest, [?8|data], context, line, column, length+1, acc)
      <<?9, rest::binary>> -> hex(rest, [?9|data], context, line, column, length+1, acc)
      <<?A, rest::binary>> -> hex(rest, [?A|data], context, line, column, length+1, acc)
      <<?B, rest::binary>> -> hex(rest, [?B|data], context, line, column, length+1, acc)
      <<?C, rest::binary>> -> hex(rest, [?C|data], context, line, column, length+1, acc)
      <<?D, rest::binary>> -> hex(rest, [?D|data], context, line, column, length+1, acc)
      <<?E, rest::binary>> -> hex(rest, [?E|data], context, line, column, length+1, acc)
      <<?F, rest::binary>> -> hex(rest, [?F|data], context, line, column, length+1, acc)
      <<?a, rest::binary>> -> hex(rest, [?a|data], context, line, column, length+1, acc)
      <<?b, rest::binary>> -> hex(rest, [?b|data], context, line, column, length+1, acc)
      <<?c, rest::binary>> -> hex(rest, [?c|data], context, line, column, length+1, acc)
      <<?d, rest::binary>> -> hex(rest, [?d|data], context, line, column, length+1, acc)
      <<?e, rest::binary>> -> hex(rest, [?e|data], context, line, column, length+1, acc)
      <<?f, rest::binary>> -> hex(rest, [?f|data], context, line, column, length+1, acc)
      rest ->
        end_column = column+length
        lex(rest, context, line, end_column, node(:numeric, :hexadecimal, line, column, line, end_column, context, :lists.reverse(data), acc))
    end
  end

  defp bin(rest, data, context, line, column, length, acc) do
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
      <<?_, rest::binary>> -> bin(rest, [?_|data], context, line, column, length+1, acc)
      <<?0, rest::binary>> -> bin(rest, [?0|data], context, line, column, length+1, acc)
      <<?1, rest::binary>> -> bin(rest, [?1|data], context, line, column, length+1, acc)
      rest ->
        end_column = column+length
        lex(rest, context, line, end_column, node(:numeric, :binary, line, column, line, end_column, context, :lists.reverse(data), acc))
    end
  end

  defp oct(rest, data, context, line, column, length, acc) do
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
      <<?_, rest::binary>> -> oct(rest, [?_|data], context, line, column, length+1, acc)
      <<?0, rest::binary>> -> oct(rest, [?0|data], context, line, column, length+1, acc)
      <<?1, rest::binary>> -> oct(rest, [?1|data], context, line, column, length+1, acc)
      <<?2, rest::binary>> -> oct(rest, [?2|data], context, line, column, length+1, acc)
      <<?3, rest::binary>> -> oct(rest, [?3|data], context, line, column, length+1, acc)
      <<?4, rest::binary>> -> oct(rest, [?4|data], context, line, column, length+1, acc)
      <<?5, rest::binary>> -> oct(rest, [?5|data], context, line, column, length+1, acc)
      <<?6, rest::binary>> -> oct(rest, [?6|data], context, line, column, length+1, acc)
      <<?7, rest::binary>> -> oct(rest, [?7|data], context, line, column, length+1, acc)
      rest ->
        end_column = column+length
        lex(rest, context, line, end_column, node(:numeric, :octal, line, column, line, end_column, context, :lists.reverse(data), acc))
    end
  end

  defp backtick(rest, data, l, c, context, line, column, acc) do
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
        lex(rest, context, end_line, end_column, node(:backtick, :literal, l, c, end_line, end_column, context, :lists.reverse(data), acc))
      <<194, 160, rest::binary>> -> backtick(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<225, 154, 128, rest::binary>> -> backtick(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<226, 128, 175, rest::binary>> -> backtick(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<226, 128, 137, rest::binary>> -> backtick(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<226, 128, 131, rest::binary>> -> backtick(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<226, 128, 130, rest::binary>> -> backtick(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<226, 129, 159, rest::binary>> -> backtick(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<227, 128, 128, rest::binary>> -> backtick(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<194, 133, rest::binary>> -> backtick(rest, [?\n|data], l, c, context, line+1, column, acc)
      <<226, 128, 168, rest::binary>> -> backtick(rest, [?\n|data], l, c, context, line+1, column, acc)
      <<226, 128, 169, rest::binary>> -> backtick(rest, [?\n|data], l, c, context, line+1, column, acc)
      <<10, rest::binary>> -> backtick(rest, [?\n|data], l, c, context, line+1, column, acc)
      <<11, rest::binary>> -> backtick(rest, [?\n|data], l, c, context, line+1, column, acc)
      <<12, rest::binary>> -> backtick(rest, [?\n|data], l, c, context, line+1, column, acc)
      <<13, rest::binary>> -> backtick(rest, [?\n|data], l, c, context, line+1, column, acc)
      <<b, rest::binary>> -> backtick(rest, [b|data], l, c, context, line, column+1, acc)
      "" -> {:error, file: context.file, line: l, column: c, end_line: l+line, end_column: c+column, opening_delimiter: :"`", expected_delimiter: :"`"}
    end
  end

  defp double_quote(rest, data, l, c, context, line, column, acc) do
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
        lex(rest, context, end_line, end_column, node(:double_quote, :literal, l, c, end_line, end_column, context, :lists.reverse(data), acc))
      <<194, 160, rest::binary>> -> double_quote(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<225, 154, 128, rest::binary>> -> double_quote(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<226, 128, 175, rest::binary>> -> double_quote(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<226, 128, 137, rest::binary>> -> double_quote(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<226, 128, 131, rest::binary>> -> double_quote(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<226, 128, 130, rest::binary>> -> double_quote(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<226, 129, 159, rest::binary>> -> double_quote(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<227, 128, 128, rest::binary>> -> double_quote(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<194, 133, rest::binary>> -> double_quote(rest, [?\n|data], l, c, context, line+1, column, acc)
      <<226, 128, 168, rest::binary>> -> double_quote(rest, [?\n|data], l, c, context, line+1, column, acc)
      <<226, 128, 169, rest::binary>> -> double_quote(rest, [?\n|data], l, c, context, line+1, column, acc)
      <<10, rest::binary>> -> double_quote(rest, [?\n|data], l, c, context, line+1, column, acc)
      <<11, rest::binary>> -> double_quote(rest, [?\n|data], l, c, context, line+1, column, acc)
      <<12, rest::binary>> -> double_quote(rest, [?\n|data], l, c, context, line+1, column, acc)
      <<13, rest::binary>> -> double_quote(rest, [?\n|data], l, c, context, line+1, column, acc)
      <<b, rest::binary>> -> double_quote(rest, [b|data], l, c, context, line, column+1, acc)
      "" -> {:error, file: context.file, line: l, column: c, end_line: l+line, end_column: c+column, opening_delimiter: :"\"", expected_delimiter: :"\""}
    end
  end

  defp double_brace(rest, data, l, c, n, context, line, column, acc) do
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
      <<194, 160, rest::binary>> -> double_brace(rest, [?\s|data], l, c, n, context, line, column+1, acc)
      <<225, 154, 128, rest::binary>> -> double_brace(rest, [?\s|data], l, c, n, context, line, column+1, acc)
      <<226, 128, 175, rest::binary>> -> double_brace(rest, [?\s|data], l, c, n, context, line, column+1, acc)
      <<226, 128, 137, rest::binary>> -> double_brace(rest, [?\s|data], l, c, n, context, line, column+1, acc)
      <<226, 128, 131, rest::binary>> -> double_brace(rest, [?\s|data], l, c, n, context, line, column+1, acc)
      <<226, 128, 130, rest::binary>> -> double_brace(rest, [?\s|data], l, c, n, context, line, column+1, acc)
      <<226, 129, 159, rest::binary>> -> double_brace(rest, [?\s|data], l, c, n, context, line, column+1, acc)
      <<227, 128, 128, rest::binary>> -> double_brace(rest, [?\s|data], l, c, n, context, line, column+1, acc)
      <<194, 133, rest::binary>> -> double_brace(rest, [?\n|data], l, c, n, context, line, column+1, acc)
      <<226, 128, 168, rest::binary>> -> double_brace(rest, [?\n|data], l, c, n, context, line, column+1, acc)
      <<226, 128, 169, rest::binary>> -> double_brace(rest, [?\n|data], l, c, n, context, line, column+1, acc)
      <<10, rest::binary>> -> double_brace(rest, [?\n|data], l, c, n, context, line, column+1, acc)
      <<11, rest::binary>> -> double_brace(rest, [?\n|data], l, c, n, context, line, column+1, acc)
      <<12, rest::binary>> -> double_brace(rest, [?\n|data], l, c, n, context, line, column+1, acc)
      <<13, rest::binary>> -> double_brace(rest, [?\n|data], l, c, n, context, line, column+1, acc)
      <<?{, rest::binary>> -> double_brace(rest, [?{|data], l, c, n+1, context, line, column+1, acc)
      <<?}, ?}, rest::binary>> when n == 0 ->
        end_line = l+line
        end_column = c+column+2
        idx = context.idx+1
        value = Code.string_to_quoted!(:lists.reverse(data), file: context.file, line: line, column: column, columns: true, token_metadata: true, existing_atoms_only: true)
        lex(rest, %{context|idx: idx, binding: [value|context.binding]}, end_line, end_column, node(:binding, :binding, l, c, end_line, end_column, context, [idx], acc))
      <<?}, rest::binary>> -> double_brace(rest, [?}|data], l, c, n-1, context, line, column+1, acc)
      <<b, rest::binary>> -> double_brace(rest, [b|data], l, c, n, context, line, column+1, acc)
      "" -> {:error, file: context.file, end_line: l, end_column: c, line: l+line, column: c+column, opening_delimiter: :"{", expected_delimiter: :"}"}
    end
  end

  defp quote(rest, data, l, c, context, line, column, acc) do
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
        lex(rest, context, end_line, end_column, node(:quote, :literal, l, c, end_line, end_column, context, :lists.reverse(data), acc))
      <<194, 160, rest::binary>> -> quote(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<225, 154, 128, rest::binary>> -> quote(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<226, 128, 175, rest::binary>> -> quote(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<226, 128, 137, rest::binary>> -> quote(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<226, 128, 131, rest::binary>> -> quote(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<226, 128, 130, rest::binary>> -> quote(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<226, 129, 159, rest::binary>> -> quote(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<227, 128, 128, rest::binary>> -> quote(rest, [?\s|data], l, c, context, line, column+1, acc)
      <<194, 133, rest::binary>> -> quote(rest, [?\n|data], l, c, context, line+1, column, acc)
      <<226, 128, 168, rest::binary>> -> quote(rest, [?\n|data], l, c, context, line+1, column, acc)
      <<226, 128, 169, rest::binary>> -> quote(rest, [?\n|data], l, c, context, line+1, column, acc)
      <<10, rest::binary>> -> quote(rest, [?\n|data], l, c, context, line+1, column, acc)
      <<11, rest::binary>> -> quote(rest, [?\n|data], l, c, context, line+1, column, acc)
      <<12, rest::binary>> -> quote(rest, [?\n|data], l, c, context, line+1, column, acc)
      <<13, rest::binary>> -> quote(rest, [?\n|data], l, c, context, line+1, column, acc)
      <<b, rest::binary>> -> quote(rest, [b|data], l, c, context, line, column+1, acc)
      "" -> {:error, file: context.file, line: l, column: c, end_line: l+line, end_column: c+column, opening_delimiter: :"'", expected_delimiter: :"'"}
    end
  end

  defp node(tag, type, line, column, end_line, end_column, context, data, acc) do
    case acc do
      [] -> [node(tag, type, line, column, end_line, end_column, 0, 0, context, data)|acc]
      [{_, [{:span, {_, _, el, ec}}|_], _}|_] -> [node(tag, type, line, column, end_line, end_column, line-el, (column-ec)-1, context, data)|acc]
    end
  end

  defp node(tag, type, line, column, end_line, end_column, el, ec, context, data) do
    case type do
      :non_reserved -> {:ident, [span: {line, column, end_line, end_column}, offset: {el,ec}, type: type, tag: tag, file: context.file], data}
      _ -> {tag, [span: {line, column, end_line, end_column}, offset: {el,ec}, type: type, file: context.file], data}
    end
  end
end
