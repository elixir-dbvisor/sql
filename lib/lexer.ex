# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Lexer do
  @moduledoc false
  import SQL.Helpers, only: [is_comment: 1, is_delimiter: 1, is_digit: 1, is_dot: 1, is_e: 1, is_literal: 1, is_nested_end: 1, is_nested_start: 1, is_newline: 1, is_sign: 1, is_space: 1, is_special_character: 1, is_whitespace: 1, tag: 1]
  @compile {:inline, lex: 12, update_state: 17, node: 6, type: 2, type: 1}
  require Unicode.Set
  def lex(binary, file \\ "nofile", params \\ 0, binding \\ [], aliases \\ []) do
    case lex(binary, file, params, binding, aliases, 0, 0, nil, [], nil, [], 0) do
      {:error, error} -> raise TokenMissingError, [{:snippet, binary} | error]
      {"", ^file, params, binding, aliases, _line, _column, nil, [], nil, acc, 0} -> {:ok, %{params: params, binding: binding, aliases: aliases}, acc}
    end
  end
  def lex("", file, _params, _binding, _aliases, line, column, type, _data, _meta, _acc, _n) when type in ~w[backtick quote double_quote double_braces]a do
    {:error, file: file, end_line: column, end_column: line, line: line, column: column, opening_delimiter: opening_delimiter(type), expected_delimiter: expected_delimiter(type)}
  end
  def lex(""=rest, file, params, binding, aliases, line, column, nil=type, data, meta, acc, n) do
    {rest, file, params, binding, aliases, line, column, type, data, meta, acc, n}
  end
  def lex(""=rest, file, params, binding, aliases, line, column, type, data, meta, acc, n) do
    update_state(rest, file, params, binding, aliases, line, column, type, data, meta, acc, n, line, column, nil, [], nil)
  end
  def lex(<<b::binary-size(2), rest::binary>>, file, params, binding, aliases, line, column, type, data, meta, acc, n) when is_comment(b) do
    update_state(rest, file, params, binding, aliases, line, column, type, data, meta, acc, n, line, column+2, type(b), [], nil)
  end
  def lex(<<b, rest::binary>>, file, params, binding, aliases, line, column, :comment=type, data, meta, acc, n) when is_newline(b) do
    update_state(rest, file, params, binding, aliases, line, column, type, data, meta, acc, n, line, column+1, nil, [], nil)
  end
  def lex(<<"*/", rest::binary>>, file, params, binding, aliases, line, column, :comments=type, data, meta, acc, n) do
    update_state(rest, file, params, binding, aliases, line, column, type, data, meta, acc, n, line, column+2, nil, [], nil)
  end
  def lex(<<b, rest::binary>>, file, params, binding, aliases, line, column, type, data, meta, acc, n) when type in ~w[comment comments]a do
      lex(rest, file, params, binding, aliases, line, column+1, type, [data|[b]], meta, acc, n)
  end
  def lex(<<"{{", rest::binary>>, file, params, binding, aliases, line, column, type, data, meta, acc, n) when type != :double_braces do
    update_state(rest, file, params, binding, aliases, line, column, type, data, meta, acc, n, line, column+2, :double_braces, [], nil)
  end
  def lex(<<"}}", rest::binary>>, file, params, binding, aliases, line, column, :double_braces=type, data, meta, acc, 0=n) do
    update_state(rest, file, params, binding, aliases, line, column, type, data, meta, acc, n, line, column+2, nil, [], nil)
  end
  def lex(<<b, rest::binary>>, file, params, binding, aliases, line, column, :double_braces=type, data, meta, acc, n) do
    n = case b do
      ?{ -> n+1
      ?} -> n-1
      _ -> n
    end
    lex(rest, file, params, binding, aliases, line, column+1, type, [data|[b]], meta, acc, n)
  end
  def lex(<<?&, c, rest::binary>>, file, params, binding, aliases, line, column, type, data, meta, acc, n) when is_literal(c) do
    lex(<<c, rest::binary>>, file, params, binding, aliases, line, column, type, [data | [?&]], meta, acc, n)
  end
  def lex(<<b, rest::binary>>, file, params, binding, aliases, line, column, type, data, meta, acc, n) when is_literal(b) do
    column = column+1
    t = type(b)
    cond do
      type == t ->
        update_state(rest, file, params, binding, aliases, line, column, type, data, meta, acc, n, line, column, nil, [], nil)
      type == :ident ->
        lex(rest, file, params, binding, aliases, line, column, t, [], data, acc, n)
      true ->
        lex(rest, file, params, binding, aliases, line, column, t, data, meta, acc, n)
    end
  end
  def lex(<<b, rest::binary>>, file, params, binding, aliases, line, column, type, data, meta, acc, n) when type in ~w[quote double_quote]a do
    lex(rest, file, params, binding, aliases, line, column, type, [data|[b]], meta, acc, n)
  end
  def lex(<<b, rest::binary>>, file, params, binding, aliases, line, column, nil=_type, data, meta, acc, n) when is_delimiter(b) do
    column = column+1
    update_state(rest, file, params, binding, aliases, line, column, type(b), data, meta, acc, n, line, column, nil, [], nil)
  end
  def lex(<<b, _::binary>>=rest, file, params, binding, aliases, line, column, type, data, meta, acc, n) when is_delimiter(b) do
    update_state(rest, file, params, binding, aliases, line, column, type, data, meta, acc, n, line, column, nil, [], nil)
  end
  def lex(<<b, rest::binary>>, file, params, binding, aliases, line, column, type, data, meta, acc, n) when is_nested_start(b) do
    tag = type(b)
    column = column+1
    case lex(rest, file, params, binding, aliases, line, column, nil, [], nil, [], n) do
      {rest, f, p, b, a, l, c, value} when type == nil -> update_state(rest, f, p, b, a, l, c, tag, value, meta, acc, n, l, c, nil, [], nil)

      {rest, f, p, b, a, l, c, value} when type == :ident ->
        case node(type, line, column, data, meta, file) do
          {:ident, _, _} = node ->
            update_state(rest, f, p, b, a, line, column, :fun, [node, node(tag, l, c, value, nil, f)], nil, acc, n, l, c, nil, [], nil)

          {t, m, []=a2} ->
            lex(rest, f, params, binding, aliases, l, c, nil, [], nil, [{t, m, [node(tag, l, c, value, nil, f)|a2]}|acc], n)
        end

      {rest, f, p, b, a, l, c, value} -> update_state(rest, f, p, b, a, l, c, tag, value, meta, acc, n, l, c, nil, [], nil)

      {_, _, _, _, _, end_line, end_column, _, _, _, _, _} -> {:error, file: file, end_line: end_line, end_column: end_column, line: line, column: column, opening_delimiter: opening_delimiter(tag), expected_delimiter: expected_delimiter(tag)}
    end
  end
  def lex(<<b, rest::binary>>, file, params, binding, aliases, line, column, nil=_type, _data, _meta, acc, _n) when is_nested_end(b) do
    {rest, file, params, binding, aliases, line, column, acc}
  end
  def lex(<<b, _::binary>>=rest, file, params, binding, aliases, line, column, type, data, meta, acc, n) when is_nested_end(b) do
    column = column+1
    update_state(rest, file, params, binding, aliases, line, column, type, data, meta, acc, n, line, column, nil, [], nil)
  end
  def lex(<<b, e, c, rest::binary>>, file, params, binding, aliases, line, column, :numeric=type, data, {s, w, f}, acc, n) when is_dot(b) and is_e(e) and is_sign(c) do
    lex(rest, file, params, binding, aliases, line, column+3, type, [[[data|[b]]|[e]]|[c]], {s, w, f+1}, acc, n)
  end
  def lex(<<b, rest::binary>>, file, params, binding, aliases, line, column, :numeric=type, data, {s, w, f}, acc, n) when is_dot(b) do
    lex(rest, file, params, binding, aliases, line, column+1, type, [data|[b]], {s, w, f+1}, acc, n)
  end
  def lex(<<b, e, rest::binary>>, file, params, binding, aliases, line, column, :numeric=type, data, meta, acc, n) when is_e(b) and (is_sign(e) or is_digit(e)) do
    lex(rest, file, params, binding, aliases, line, column+2, type, [[data|[b]]|[e]], meta, acc, n)
  end
  def lex(<<b, e, rest::binary>>, file, params, binding, aliases, line, column, nil, []=data, nil, acc, n) when is_dot(b) and is_digit(e) do
    lex(rest, file, params, binding, aliases, line, column+2, :numeric, [[data|[b]]|[e]], {0, 0, 1}, acc, n)
  end
  def lex(<<b, e, rest::binary>>, file, params, binding, aliases, line, column, nil, []=data, nil, acc, n) when is_sign(b) and is_dot(e) do
    lex(rest, file, params, binding, aliases, line, column+2, :numeric, [[data|[b]]|[e]], {1, 0, 0}, acc, n)
  end
  def lex(<<b, e, rest::binary>>, file, params, binding, aliases, line, column, :numeric=type, data, {s, w, f}, acc, n) when is_dot(b) and is_digit(e) do
    lex(rest, file, params, binding, aliases, line, column+2, type, [[data|[b]]|[e]], {s, w, f+1}, acc, n)
  end
  def lex(<<b, c, rest::binary>>, file, params, binding, aliases, line, column, nil, []=data, nil, [{t, [{:type, tm}|_], _}|_]=acc, n) when is_sign(b) and is_digit(c) and t not in ~w[ident numeric dot]a and tm in ~w[reserved non_reserved]a  do
    lex(rest, file, params, binding, aliases, line, column+2, :numeric, [[data|[b]]|[c]], {1, 1, 0}, acc, n)
  end
  def lex(<<b, rest::binary>>, file, params, binding, aliases, line, column, type, data, meta, acc, n) when type in ~w[nil numeric]a and is_digit(b) do
    lex(rest, file, params, binding, aliases, line, column+1, :numeric, [data|[b]], update_meta(meta, :numeric), acc, n)
  end
  def lex(<<b, rest::binary>>, file, params, binding, aliases, line, column, :special=type, data, meta, acc, n) when is_digit(b) do
    update_state(rest, file, params, binding, aliases, line, column, type, data, meta, acc, n, line, column+1, :numeric, [[]|[b]], {0, 1, 0})
  end
  def lex(<<b, rest::binary>>, file, params, binding, aliases, line, column, nil=_type, data, meta, acc, n) when is_dot(b) do
    column = column+1
    update_state(rest, file, params, binding, aliases, line, column, :dot, data, meta, acc, n, line, column, nil, [], nil)
  end
  def lex(<<b, _::binary>>=rest, file, params, binding, aliases, line, column, type, data, meta, acc, n) when is_dot(b) do
    update_state(rest, file, params, binding, aliases, line, column, type, data, meta, acc, n, line, column, nil, [], nil)
  end
  def lex(<<b, rest::binary>>, file, params, binding, aliases, line, column, type, data, meta, acc, n) when type != :ident and (Unicode.Set.match?(b, "[[:Lu:], [:Ll:], [:Lt:], [:Lm:], [:Lo:], [:Nl:]]") or b == ?_) do
    update_state(rest, file, params, binding, aliases, line, column, type, data, meta, acc, n, line, column+1, :ident, [[]|[b]], meta)
  end
  def lex(<<b, rest::binary>>, file, params, binding, aliases, line, column, :ident=type, data, meta, acc, n) when Unicode.Set.match?(b, "[[:Mn:], [:Mc:], [:Nd:], [:Pc:], [:Cf:]]") do
    lex(rest, file, params, binding, aliases, line, column+1, type, [data|[b]], meta, acc, n)
  end
  def lex(<<b, rest::binary>>, file, params, binding, aliases, line, column, type, data, meta, acc, n) when is_special_character(b) and type in ~w[nil special]a and not is_space(b) do
    lex(rest, file, params, binding, aliases, line, column+1, :special, [data|[b]], meta, acc, n)
  end
  def lex(<<b, rest::binary>>, file, params, binding, aliases, line, column, type, data, meta, acc, n) when is_special_character(b) and not is_space(b) do
    update_state(rest, file, params, binding, aliases, line, column, type, data, meta, acc, n, line, column+1, :special, [[]|[b]], nil)
  end
  def lex(<<b::utf8, rest::binary>>, file, params, binding, aliases, line, column, type, []=data, meta, acc, n) when is_newline(b) do
    update_state(rest, file, params, binding, aliases, line, column, type, data, meta, acc, n, line+1, column, type, data, meta)
  end
  def lex(<<b::utf8, rest::binary>>, file, params, binding, aliases, line, column, type, []=data, meta, acc, n) when is_whitespace(b) or is_space(b) do
    update_state(rest, file, params, binding, aliases, line, column, type, data, meta, acc, n, line, column+1, type, data, meta)
  end
  def lex(<<b::utf8, rest::binary>>, file, params, binding, aliases, line, column, type, data, meta, acc, n) when is_newline(b) do
    update_state(rest, file, params, binding, aliases, line, column, type, data, meta, acc, n, line+1, column, nil, [], nil)
  end
  def lex(<<b::utf8, rest::binary>>, file, params, binding, aliases, line, column, type, data, meta, acc, n) when is_whitespace(b) or is_space(b) do
    update_state(rest, file, params, binding, aliases, line, column, type, data, meta, acc, n, line, column+1, nil, [], nil)
  end
  def lex(<<b, rest::binary>>, file, params, binding, aliases, line, column, type, data, meta, acc, n) do
    lex(rest, file, params, binding, aliases, line, column+1, type(b, type), [data|[b]], meta, acc, n)
  end

  def opening_delimiter(:paren), do: :"("
  def opening_delimiter(:bracket), do: :"["
  def opening_delimiter(:double_quote), do: :"\""
  def opening_delimiter(:quote), do: :"'"
  def opening_delimiter(:backtick), do: :"`"
  def opening_delimiter(type) when type in ~w[brace double_braces]a, do: :"{"

  def expected_delimiter(:paren), do: :")"
  def expected_delimiter(:bracket), do: :"]"
  def expected_delimiter(type) when type in ~w[backtick quote double_quote]a, do: opening_delimiter(type)
  def expected_delimiter(type) when type in ~w[brace double_braces]a, do: :"}"


  def update_state(rest, file, params, binding, aliases, _line, _column, nil=_type, _data, _meta, acc, n, l, c, t, d, m) do
    lex(rest, file, params, binding, aliases, l, c, t, d, m, acc, n)
  end
  def update_state(rest, file, params, binding, aliases, line, column, :colon=type, []=_data, meta, acc, n, l, c, t, d, m) do
    lex(rest, file, params, binding, aliases, l, c, t, d, m, [node(type, line, column, acc, meta, file)], n)
  end
  def update_state(rest, file, params, binding, aliases, line, column, :ident=type, data, meta, [{:as=tt, mm, []=aa}, {:ident, _, a}=right|acc]=ac, n, l, c, t, d, m) do
    case node(type, line, column, data, meta, file) do
      {:ident, _, as} = node -> lex(rest, file, params, binding, [{as, a}|aliases], l, c, t, d, m, [{tt, mm, [right, node|aa]}|acc], n)
      node -> lex(rest, file, params, binding, aliases, l, c, t, d, m, [node|ac], n)
    end
  end
  def update_state(rest, file, params, binding, aliases, line, column, type, data, meta, [{:dot=t2, m2, []=a}, {tag, _, _}=right|acc], n, l, c, t, d, m) when (type in ~w[ident double_quote bracket dot]a or data==[[], ?*]) and tag in ~w[ident double_quote bracket dot]a do
    lex(rest, file, params, binding, aliases, l, c, t, d, m, [{t2, m2, [right, node(type, line, column, data, meta, file)|a]}|acc], n)
  end
  def update_state(rest, file, params, [format: true]=binding, aliases, line, column, :double_braces=type, data, meta, acc, n, l, c, t, d, m) do
    lex(rest, file, params, binding, aliases, l, c, t, d, m, [node(type, line, column, data, meta, file)|acc], n)
  end
  def update_state(rest, file, params, binding, aliases, line, column, :double_braces=type, data, meta, acc, n, l, c, t, d, m) do
    params=params+1
    lex(rest, file, params, :lists.flatten(binding, [Code.string_to_quoted!(IO.iodata_to_binary(data), file: file, line: line, column: column, columns: true, token_metadata: true, existing_atoms_only: true)]), aliases, l, c,  t, d, m, [node(type, line, column, [params], meta, file)|acc], n)
  end
  def update_state(rest, file, params, binding, aliases, line, column, type, data, meta, acc, n, l, c, t, d, m) do
    lex(rest, file, params, binding, aliases, l, c, t, d, m, [node(type, line, column, data, meta, file)|acc], n)
  end

  def update_meta(nil, :numeric), do: {0, 1, 0}
  def update_meta({s, w, 0 = f}, :numeric), do: {s, w+1, f}
  def update_meta({s, w, f}, :numeric), do: {s, w, f+1}


  def node(:double_braces=_tag, line, column, data, _meta, file), do: {:binding, [type: :literal, line: line, column: column, file: file], data}
  def node(:numeric=tag, line, column, data, {s, w, f}, file), do: {tag, [type: :literal, sign: s, whole: w, fractional: f, line: line, column: column, file: file], data}
  def node(:special, line, column, data, _meta, file) do
    case tag(data) do
      nil -> {:ident, [type: :literal, line: line, column: column, file: file], data}
      tag -> {tag, [type: :operator, line: line, column: column, file: file], []}
    end
  end
  def node(:quote = tag, line, column, data, prefix, file) when is_list(prefix), do: {tag, [prefix: prefix, type: :literal, line: line, column: column, file: file], data}
  def node(tag, line, column, data, _meta, file) when tag in ~w[bracket paren brace]a, do: {tag, [type: :expression, line: line, column: column, file: file], data}
  def node(tag, line, column, data, _meta, file) when tag in ~w[quote double_quote backtick]a, do: {tag, [type: :literal, line: line, column: column, file: file], data}
  def node(tag, line, column, []=data, _meta, file), do: {tag, [line: line, column: column, file: file], data}
  def node(tag, line, column, [{_, _, _} | _]=data, _meta, file), do: {tag, [type: :expression, line: line, column: column, file: file], data}
  def node(tag, line, column, data, nil, file) do
    case tag(data) do
      {:reserved = k, tag} -> {tag, [type: k, line: line, column: column, file: file], []}
      {k, t} -> {tag, [type: k, tag: t, line: line, column: column, file: file], data}
      _ -> {tag, [type: :literal, line: line, column: column, file: file], data}
    end
  end
  def node(tag, line, column, data, _meta, file), do: {tag, [type: :literal, line: line, column: column, file: file], data}

  def type(?"), do: :double_quote
  def type(?'), do: :quote
  def type(?`), do: :backtick
  def type(?,), do: :comma
  def type(?;), do: :colon
  def type(?*), do: :special
  def type("--"), do: :comment
  def type("\\*"), do: :comments
  def type(b) when b in [?(, ?)], do: :paren
  def type(b) when b in [?{, ?}], do: :brace
  def type(b) when b in [?[, ?]], do: :bracket
  def type(_, type) when type in ~w[comment comments double_quote quote backtick]a, do: type
  def type(b, type) when is_digit(b) and type in ~w[nil numeric]a or is_dot(b) and type == :numeric, do: :numeric
  def type(?*, _type), do: :special
  def type(_b, _type), do: :ident
end
