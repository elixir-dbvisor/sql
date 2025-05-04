# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Lexer do
  @moduledoc false
  @compile {:inline, lex: 9, lex: 4, meta: 3, merge: 3, type: 2, node: 5}

  defguard is_data_type(node) when elem(node, 0) in ~w[integer float ident quote double_quote backtick bracket parens .]a
  defguard is_newline(b) when b in [10, 11, 12, 13, 133, 8232, 8233]
  defguard is_space(b) when b in ~c" "
  defguard is_whitespace(b) when b in [9, 13, 160, 160, 5760, 8192, 8193, 8194, 8195, 8196, 8197, 8198, 8199, 8200, 8201, 8202, 8239, 8287, 12288, 6158, 8203, 8204, 8205, 8288, 65279]

  def opening_delimiter(:parens), do: :"("
  def opening_delimiter(:bracket), do: :"["
  def opening_delimiter(:double_quote), do: :"\""
  def opening_delimiter(:quote), do: :"'"
  def opening_delimiter(:backtick), do: :"`"
  def opening_delimiter(type) when type in ~w[var code braces]a, do: :"{"

  def expected_delimiter(:parens), do: :")"
  def expected_delimiter(:bracket), do: :"]"
  def expected_delimiter(:double_quote), do: :"\""
  def expected_delimiter(:quote), do: :"'"
  def expected_delimiter(:backtick), do: :"`"
  def expected_delimiter(type) when type in ~w[var code braces]a, do: :"}"

  def lex(binary, file, params \\ 0, opts \\ [metadata: true]) do
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
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"aA" and b2 in ~c"bB" and b3 in ~c"sS", do: :abs
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"aA" and b2 in ~c"bB" and b3 in ~c"sS" and b4 in ~c"eE" and b5 in ~c"nN" and b6 in ~c"tT", do: :absent
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"aA" and b2 in ~c"cC" and b3 in ~c"oO" and b4 in ~c"sS", do: :acos
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"aA" and b2 in ~c"lL" and b3 in ~c"lL", do: :all
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"aA" and b2 in ~c"lL" and b3 in ~c"lL" and b4 in ~c"oO" and b5 in ~c"cC" and b6 in ~c"aA" and
  b7 in ~c"tT" and b8 in ~c"eE", do: :allocate
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"aA" and b2 in ~c"lL" and b3 in ~c"tT" and b4 in ~c"eE" and b5 in ~c"rR", do: :alter
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"aA" and b2 in ~c"nN" and b3 in ~c"dD", do: :and
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"aA" and b2 in ~c"nN" and b3 in ~c"yY", do: :any
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"aA" and b2 in ~c"nN" and b3 in ~c"yY" and b4 in ~c"_" and b5 in ~c"vV" and b6 in ~c"aA" and
  b7 in ~c"lL" and b8 in ~c"uU" and b9 in ~c"eE", do: :any_value
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"aA" and b2 in ~c"rR" and b3 in ~c"eE", do: :are
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"aA" and b2 in ~c"rR" and b3 in ~c"rR" and b4 in ~c"aA" and b5 in ~c"yY", do: :array
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"aA" and b2 in ~c"rR" and b3 in ~c"rR" and b4 in ~c"aA" and b5 in ~c"yY" and b6 in ~c"_" and
  b7 in ~c"aA" and b8 in ~c"gG" and b9 in ~c"gG", do: :array_agg
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21]) when b1 in ~c"aA" and b2 in ~c"rR" and b3 in ~c"rR" and b4 in ~c"aA" and b5 in ~c"yY" and b6 in ~c"_" and
  b7 in ~c"mM" and b8 in ~c"aA" and b9 in ~c"xX" and b10 in ~c"_" and b11 in ~c"cC" and
  b12 in ~c"aA" and b13 in ~c"rR" and b14 in ~c"dD" and b15 in ~c"iI" and b16 in ~c"nN" and
  b17 in ~c"aA" and b18 in ~c"lL" and b19 in ~c"iI" and b20 in ~c"tT" and b21 in ~c"yY", do: :array_max_cardinality
  
    def ident(:ident, [[[], b1], b2]) when b1 in ~c"aA" and b2 in ~c"sS", do: :as
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"aA" and b2 in ~c"sS" and b3 in ~c"eE" and b4 in ~c"nN" and b5 in ~c"sS" and b6 in ~c"iI" and
  b7 in ~c"tT" and b8 in ~c"iI" and b9 in ~c"vV" and b10 in ~c"eE", do: :asensitive
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"aA" and b2 in ~c"sS" and b3 in ~c"iI" and b4 in ~c"nN", do: :asin
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"aA" and b2 in ~c"sS" and b3 in ~c"yY" and b4 in ~c"mM" and b5 in ~c"mM" and b6 in ~c"eE" and
  b7 in ~c"tT" and b8 in ~c"rR" and b9 in ~c"iI" and b10 in ~c"cC", do: :asymmetric
  
    def ident(:ident, [[[], b1], b2]) when b1 in ~c"aA" and b2 in ~c"tT", do: :at
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"aA" and b2 in ~c"tT" and b3 in ~c"aA" and b4 in ~c"nN", do: :atan
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"aA" and b2 in ~c"tT" and b3 in ~c"oO" and b4 in ~c"mM" and b5 in ~c"iI" and b6 in ~c"cC", do: :atomic
  
    def ident(:ident, [[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13]) when b1 in ~c"aA" and b2 in ~c"uU" and b3 in ~c"tT" and b4 in ~c"hH" and b5 in ~c"oO" and b6 in ~c"rR" and
  b7 in ~c"iI" and b8 in ~c"zZ" and b9 in ~c"aA" and b10 in ~c"tT" and b11 in ~c"iI" and
  b12 in ~c"oO" and b13 in ~c"nN", do: :authorization
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"aA" and b2 in ~c"vV" and b3 in ~c"gG", do: :avg
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"bB" and b2 in ~c"eE" and b3 in ~c"gG" and b4 in ~c"iI" and b5 in ~c"nN", do: :begin
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"bB" and b2 in ~c"eE" and b3 in ~c"gG" and b4 in ~c"iI" and b5 in ~c"nN" and b6 in ~c"_" and
  b7 in ~c"fF" and b8 in ~c"rR" and b9 in ~c"aA" and b10 in ~c"mM" and b11 in ~c"eE", do: :begin_frame
  
    def ident(:ident, [[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when b1 in ~c"bB" and b2 in ~c"eE" and b3 in ~c"gG" and b4 in ~c"iI" and b5 in ~c"nN" and b6 in ~c"_" and
  b7 in ~c"pP" and b8 in ~c"aA" and b9 in ~c"rR" and b10 in ~c"tT" and b11 in ~c"iI" and
  b12 in ~c"tT" and b13 in ~c"iI" and b14 in ~c"oO" and b15 in ~c"nN", do: :begin_partition
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"bB" and b2 in ~c"eE" and b3 in ~c"tT" and b4 in ~c"wW" and b5 in ~c"eE" and b6 in ~c"eE" and
  b7 in ~c"nN", do: :between
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"bB" and b2 in ~c"iI" and b3 in ~c"gG" and b4 in ~c"iI" and b5 in ~c"nN" and b6 in ~c"tT", do: :bigint
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"bB" and b2 in ~c"iI" and b3 in ~c"nN" and b4 in ~c"aA" and b5 in ~c"rR" and b6 in ~c"yY", do: :binary
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"bB" and b2 in ~c"lL" and b3 in ~c"oO" and b4 in ~c"bB", do: :blob
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"bB" and b2 in ~c"oO" and b3 in ~c"oO" and b4 in ~c"lL" and b5 in ~c"eE" and b6 in ~c"aA" and
  b7 in ~c"nN", do: :boolean
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"bB" and b2 in ~c"oO" and b3 in ~c"tT" and b4 in ~c"hH", do: :both
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"bB" and b2 in ~c"tT" and b3 in ~c"rR" and b4 in ~c"iI" and b5 in ~c"mM", do: :btrim
  
    def ident(:ident, [[[], b1], b2]) when b1 in ~c"bB" and b2 in ~c"yY", do: :by
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"cC" and b2 in ~c"aA" and b3 in ~c"lL" and b4 in ~c"lL", do: :call
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"cC" and b2 in ~c"aA" and b3 in ~c"lL" and b4 in ~c"lL" and b5 in ~c"eE" and b6 in ~c"dD", do: :called
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"cC" and b2 in ~c"aA" and b3 in ~c"rR" and b4 in ~c"dD" and b5 in ~c"iI" and b6 in ~c"nN" and
  b7 in ~c"aA" and b8 in ~c"lL" and b9 in ~c"iI" and b10 in ~c"tT" and b11 in ~c"yY", do: :cardinality
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"cC" and b2 in ~c"aA" and b3 in ~c"sS" and b4 in ~c"cC" and b5 in ~c"aA" and b6 in ~c"dD" and
  b7 in ~c"eE" and b8 in ~c"dD", do: :cascaded
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"cC" and b2 in ~c"aA" and b3 in ~c"sS" and b4 in ~c"eE", do: :case
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"cC" and b2 in ~c"aA" and b3 in ~c"sS" and b4 in ~c"tT", do: :cast
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"cC" and b2 in ~c"eE" and b3 in ~c"iI" and b4 in ~c"lL", do: :ceil
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"cC" and b2 in ~c"eE" and b3 in ~c"iI" and b4 in ~c"lL" and b5 in ~c"iI" and b6 in ~c"nN" and
  b7 in ~c"gG", do: :ceiling
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"cC" and b2 in ~c"hH" and b3 in ~c"aA" and b4 in ~c"rR", do: :char
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"cC" and b2 in ~c"hH" and b3 in ~c"aA" and b4 in ~c"rR" and b5 in ~c"_" and b6 in ~c"lL" and
  b7 in ~c"eE" and b8 in ~c"nN" and b9 in ~c"gG" and b10 in ~c"tT" and b11 in ~c"hH", do: :char_length
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"cC" and b2 in ~c"hH" and b3 in ~c"aA" and b4 in ~c"rR" and b5 in ~c"aA" and b6 in ~c"cC" and
  b7 in ~c"tT" and b8 in ~c"eE" and b9 in ~c"rR", do: :character
  
    def ident(:ident, [[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16]) when b1 in ~c"cC" and b2 in ~c"hH" and b3 in ~c"aA" and b4 in ~c"rR" and b5 in ~c"aA" and b6 in ~c"cC" and
  b7 in ~c"tT" and b8 in ~c"eE" and b9 in ~c"rR" and b10 in ~c"_" and b11 in ~c"lL" and
  b12 in ~c"eE" and b13 in ~c"nN" and b14 in ~c"gG" and b15 in ~c"tT" and b16 in ~c"hH", do: :character_length
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"cC" and b2 in ~c"hH" and b3 in ~c"eE" and b4 in ~c"cC" and b5 in ~c"kK", do: :check
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"cC" and b2 in ~c"lL" and b3 in ~c"aA" and b4 in ~c"sS" and b5 in ~c"sS" and b6 in ~c"iI" and
  b7 in ~c"fF" and b8 in ~c"iI" and b9 in ~c"eE" and b10 in ~c"rR", do: :classifier
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"cC" and b2 in ~c"lL" and b3 in ~c"oO" and b4 in ~c"bB", do: :clob
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"cC" and b2 in ~c"lL" and b3 in ~c"oO" and b4 in ~c"sS" and b5 in ~c"eE", do: :close
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"aA" and b4 in ~c"lL" and b5 in ~c"eE" and b6 in ~c"sS" and
  b7 in ~c"cC" and b8 in ~c"eE", do: :coalesce
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"lL" and b4 in ~c"lL" and b5 in ~c"aA" and b6 in ~c"tT" and
  b7 in ~c"eE", do: :collate
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"lL" and b4 in ~c"lL" and b5 in ~c"eE" and b6 in ~c"cC" and
  b7 in ~c"tT", do: :collect
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"lL" and b4 in ~c"uU" and b5 in ~c"mM" and b6 in ~c"nN", do: :column
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"mM" and b4 in ~c"mM" and b5 in ~c"iI" and b6 in ~c"tT", do: :commit
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"nN" and b4 in ~c"dD" and b5 in ~c"iI" and b6 in ~c"tT" and
  b7 in ~c"iI" and b8 in ~c"oO" and b9 in ~c"nN", do: :condition
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"nN" and b4 in ~c"nN" and b5 in ~c"eE" and b6 in ~c"cC" and
  b7 in ~c"tT", do: :connect
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"nN" and b4 in ~c"sS" and b5 in ~c"tT" and b6 in ~c"rR" and
  b7 in ~c"aA" and b8 in ~c"iI" and b9 in ~c"nN" and b10 in ~c"tT", do: :constraint
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"nN" and b4 in ~c"tT" and b5 in ~c"aA" and b6 in ~c"iI" and
  b7 in ~c"nN" and b8 in ~c"sS", do: :contains
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"nN" and b4 in ~c"vV" and b5 in ~c"eE" and b6 in ~c"rR" and
  b7 in ~c"tT", do: :convert
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"pP" and b4 in ~c"yY", do: :copy
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"rR" and b4 in ~c"rR", do: :corr
  
    def ident(:ident, [[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"rR" and b4 in ~c"rR" and b5 in ~c"eE" and b6 in ~c"sS" and
  b7 in ~c"pP" and b8 in ~c"oO" and b9 in ~c"nN" and b10 in ~c"dD" and b11 in ~c"iI" and
  b12 in ~c"nN" and b13 in ~c"gG", do: :corresponding
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"sS", do: :cos
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"sS" and b4 in ~c"hH", do: :cosh
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"uU" and b4 in ~c"nN" and b5 in ~c"tT", do: :count
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"vV" and b4 in ~c"aA" and b5 in ~c"rR" and b6 in ~c"_" and
  b7 in ~c"pP" and b8 in ~c"oO" and b9 in ~c"pP", do: :covar_pop
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"vV" and b4 in ~c"aA" and b5 in ~c"rR" and b6 in ~c"_" and
  b7 in ~c"sS" and b8 in ~c"aA" and b9 in ~c"mM" and b10 in ~c"pP", do: :covar_samp
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"cC" and b2 in ~c"rR" and b3 in ~c"eE" and b4 in ~c"aA" and b5 in ~c"tT" and b6 in ~c"eE", do: :create
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"cC" and b2 in ~c"rR" and b3 in ~c"oO" and b4 in ~c"sS" and b5 in ~c"sS", do: :cross
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"cC" and b2 in ~c"uU" and b3 in ~c"bB" and b4 in ~c"eE", do: :cube
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"cC" and b2 in ~c"uU" and b3 in ~c"mM" and b4 in ~c"eE" and b5 in ~c"_" and b6 in ~c"dD" and
  b7 in ~c"iI" and b8 in ~c"sS" and b9 in ~c"tT", do: :cume_dist
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"cC" and b2 in ~c"uU" and b3 in ~c"rR" and b4 in ~c"rR" and b5 in ~c"eE" and b6 in ~c"nN" and
  b7 in ~c"tT", do: :current
  
    def ident(:ident, [[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when b1 in ~c"cC" and b2 in ~c"uU" and b3 in ~c"rR" and b4 in ~c"rR" and b5 in ~c"eE" and b6 in ~c"nN" and
  b7 in ~c"tT" and b8 in ~c"_" and b9 in ~c"cC" and b10 in ~c"aA" and b11 in ~c"tT" and
  b12 in ~c"aA" and b13 in ~c"lL" and b14 in ~c"oO" and b15 in ~c"gG", do: :current_catalog
  
    def ident(:ident, [[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when b1 in ~c"cC" and b2 in ~c"uU" and b3 in ~c"rR" and b4 in ~c"rR" and b5 in ~c"eE" and b6 in ~c"nN" and
  b7 in ~c"tT" and b8 in ~c"_" and b9 in ~c"dD" and b10 in ~c"aA" and b11 in ~c"tT" and
  b12 in ~c"eE", do: :current_date
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22], b23], b24], b25], b26], b27], b28], b29], b30], b31]) when b1 in ~c"cC" and b2 in ~c"uU" and b3 in ~c"rR" and b4 in ~c"rR" and b5 in ~c"eE" and b6 in ~c"nN" and
  b7 in ~c"tT" and b8 in ~c"_" and b9 in ~c"dD" and b10 in ~c"eE" and b11 in ~c"fF" and
  b12 in ~c"aA" and b13 in ~c"uU" and b14 in ~c"lL" and b15 in ~c"tT" and b16 in ~c"_" and
  b17 in ~c"tT" and b18 in ~c"rR" and b19 in ~c"aA" and b20 in ~c"nN" and b21 in ~c"sS" and
  b22 in ~c"fF" and b23 in ~c"oO" and b24 in ~c"rR" and b25 in ~c"mM" and b26 in ~c"_" and
  b27 in ~c"gG" and b28 in ~c"rR" and b29 in ~c"oO" and b30 in ~c"uU" and b31 in ~c"pP", do: :current_default_transform_group
  
    def ident(:ident, [[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when b1 in ~c"cC" and b2 in ~c"uU" and b3 in ~c"rR" and b4 in ~c"rR" and b5 in ~c"eE" and b6 in ~c"nN" and
  b7 in ~c"tT" and b8 in ~c"_" and b9 in ~c"pP" and b10 in ~c"aA" and b11 in ~c"tT" and
  b12 in ~c"hH", do: :current_path
  
    def ident(:ident, [[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when b1 in ~c"cC" and b2 in ~c"uU" and b3 in ~c"rR" and b4 in ~c"rR" and b5 in ~c"eE" and b6 in ~c"nN" and
  b7 in ~c"tT" and b8 in ~c"_" and b9 in ~c"rR" and b10 in ~c"oO" and b11 in ~c"lL" and
  b12 in ~c"eE", do: :current_role
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"cC" and b2 in ~c"uU" and b3 in ~c"rR" and b4 in ~c"rR" and b5 in ~c"eE" and b6 in ~c"nN" and
  b7 in ~c"tT" and b8 in ~c"_" and b9 in ~c"rR" and b10 in ~c"oO" and b11 in ~c"wW", do: :current_row
  
    def ident(:ident, [[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when b1 in ~c"cC" and b2 in ~c"uU" and b3 in ~c"rR" and b4 in ~c"rR" and b5 in ~c"eE" and b6 in ~c"nN" and
  b7 in ~c"tT" and b8 in ~c"_" and b9 in ~c"sS" and b10 in ~c"cC" and b11 in ~c"hH" and
  b12 in ~c"eE" and b13 in ~c"mM" and b14 in ~c"aA", do: :current_schema
  
    def ident(:ident, [[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when b1 in ~c"cC" and b2 in ~c"uU" and b3 in ~c"rR" and b4 in ~c"rR" and b5 in ~c"eE" and b6 in ~c"nN" and
  b7 in ~c"tT" and b8 in ~c"_" and b9 in ~c"tT" and b10 in ~c"iI" and b11 in ~c"mM" and
  b12 in ~c"eE", do: :current_time
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17]) when b1 in ~c"cC" and b2 in ~c"uU" and b3 in ~c"rR" and b4 in ~c"rR" and b5 in ~c"eE" and b6 in ~c"nN" and
  b7 in ~c"tT" and b8 in ~c"_" and b9 in ~c"tT" and b10 in ~c"iI" and b11 in ~c"mM" and
  b12 in ~c"eE" and b13 in ~c"sS" and b14 in ~c"tT" and b15 in ~c"aA" and b16 in ~c"mM" and
  b17 in ~c"pP", do: :current_timestamp
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22], b23], b24], b25], b26], b27], b28], b29], b30], b31], b32]) when b1 in ~c"cC" and b2 in ~c"uU" and b3 in ~c"rR" and b4 in ~c"rR" and b5 in ~c"eE" and b6 in ~c"nN" and
  b7 in ~c"tT" and b8 in ~c"_" and b9 in ~c"tT" and b10 in ~c"rR" and b11 in ~c"aA" and
  b12 in ~c"nN" and b13 in ~c"sS" and b14 in ~c"fF" and b15 in ~c"oO" and b16 in ~c"rR" and
  b17 in ~c"mM" and b18 in ~c"_" and b19 in ~c"gG" and b20 in ~c"rR" and b21 in ~c"oO" and
  b22 in ~c"uU" and b23 in ~c"pP" and b24 in ~c"_" and b25 in ~c"fF" and b26 in ~c"oO" and
  b27 in ~c"rR" and b28 in ~c"_" and b29 in ~c"tT" and b30 in ~c"yY" and b31 in ~c"pP" and
  b32 in ~c"eE", do: :current_transform_group_for_type
  
    def ident(:ident, [[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when b1 in ~c"cC" and b2 in ~c"uU" and b3 in ~c"rR" and b4 in ~c"rR" and b5 in ~c"eE" and b6 in ~c"nN" and
  b7 in ~c"tT" and b8 in ~c"_" and b9 in ~c"uU" and b10 in ~c"sS" and b11 in ~c"eE" and
  b12 in ~c"rR", do: :current_user
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"cC" and b2 in ~c"uU" and b3 in ~c"rR" and b4 in ~c"sS" and b5 in ~c"oO" and b6 in ~c"rR", do: :cursor
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"cC" and b2 in ~c"yY" and b3 in ~c"cC" and b4 in ~c"lL" and b5 in ~c"eE", do: :cycle
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"dD" and b2 in ~c"aA" and b3 in ~c"tT" and b4 in ~c"eE", do: :date
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"dD" and b2 in ~c"aA" and b3 in ~c"yY", do: :day
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"dD" and b2 in ~c"eE" and b3 in ~c"aA" and b4 in ~c"lL" and b5 in ~c"lL" and b6 in ~c"oO" and
  b7 in ~c"cC" and b8 in ~c"aA" and b9 in ~c"tT" and b10 in ~c"eE", do: :deallocate
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"dD" and b2 in ~c"eE" and b3 in ~c"cC", do: :dec
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"dD" and b2 in ~c"eE" and b3 in ~c"cC" and b4 in ~c"fF" and b5 in ~c"lL" and b6 in ~c"oO" and
  b7 in ~c"aA" and b8 in ~c"tT", do: :decfloat
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"dD" and b2 in ~c"eE" and b3 in ~c"cC" and b4 in ~c"iI" and b5 in ~c"mM" and b6 in ~c"aA" and
  b7 in ~c"lL", do: :decimal
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"dD" and b2 in ~c"eE" and b3 in ~c"cC" and b4 in ~c"lL" and b5 in ~c"aA" and b6 in ~c"rR" and
  b7 in ~c"eE", do: :declare
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"dD" and b2 in ~c"eE" and b3 in ~c"fF" and b4 in ~c"aA" and b5 in ~c"uU" and b6 in ~c"lL" and
  b7 in ~c"tT", do: :default
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"dD" and b2 in ~c"eE" and b3 in ~c"fF" and b4 in ~c"iI" and b5 in ~c"nN" and b6 in ~c"eE", do: :define
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"dD" and b2 in ~c"eE" and b3 in ~c"lL" and b4 in ~c"eE" and b5 in ~c"tT" and b6 in ~c"eE", do: :delete
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"dD" and b2 in ~c"eE" and b3 in ~c"nN" and b4 in ~c"sS" and b5 in ~c"eE" and b6 in ~c"_" and
  b7 in ~c"rR" and b8 in ~c"aA" and b9 in ~c"nN" and b10 in ~c"kK", do: :dense_rank
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"dD" and b2 in ~c"eE" and b3 in ~c"rR" and b4 in ~c"eE" and b5 in ~c"fF", do: :deref
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"dD" and b2 in ~c"eE" and b3 in ~c"sS" and b4 in ~c"cC" and b5 in ~c"rR" and b6 in ~c"iI" and
  b7 in ~c"bB" and b8 in ~c"eE", do: :describe
  
    def ident(:ident, [[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13]) when b1 in ~c"dD" and b2 in ~c"eE" and b3 in ~c"tT" and b4 in ~c"eE" and b5 in ~c"rR" and b6 in ~c"mM" and
  b7 in ~c"iI" and b8 in ~c"nN" and b9 in ~c"iI" and b10 in ~c"sS" and b11 in ~c"tT" and
  b12 in ~c"iI" and b13 in ~c"cC", do: :deterministic
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"dD" and b2 in ~c"iI" and b3 in ~c"sS" and b4 in ~c"cC" and b5 in ~c"oO" and b6 in ~c"nN" and
  b7 in ~c"nN" and b8 in ~c"eE" and b9 in ~c"cC" and b10 in ~c"tT", do: :disconnect
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"dD" and b2 in ~c"iI" and b3 in ~c"sS" and b4 in ~c"tT" and b5 in ~c"iI" and b6 in ~c"nN" and
  b7 in ~c"cC" and b8 in ~c"tT", do: :distinct
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"dD" and b2 in ~c"oO" and b3 in ~c"uU" and b4 in ~c"bB" and b5 in ~c"lL" and b6 in ~c"eE", do: :double
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"dD" and b2 in ~c"rR" and b3 in ~c"oO" and b4 in ~c"pP", do: :drop
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"dD" and b2 in ~c"yY" and b3 in ~c"nN" and b4 in ~c"aA" and b5 in ~c"mM" and b6 in ~c"iI" and
  b7 in ~c"cC", do: :dynamic
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"eE" and b2 in ~c"aA" and b3 in ~c"cC" and b4 in ~c"hH", do: :each
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"eE" and b2 in ~c"lL" and b3 in ~c"eE" and b4 in ~c"mM" and b5 in ~c"eE" and b6 in ~c"nN" and
  b7 in ~c"tT", do: :element
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"eE" and b2 in ~c"lL" and b3 in ~c"sS" and b4 in ~c"eE", do: :else
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"eE" and b2 in ~c"mM" and b3 in ~c"pP" and b4 in ~c"tT" and b5 in ~c"yY", do: :empty
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"eE" and b2 in ~c"nN" and b3 in ~c"dD", do: :end
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"eE" and b2 in ~c"nN" and b3 in ~c"dD" and b4 in ~c"_" and b5 in ~c"fF" and b6 in ~c"rR" and
  b7 in ~c"aA" and b8 in ~c"mM" and b9 in ~c"eE", do: :end_frame
  
    def ident(:ident, [[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13]) when b1 in ~c"eE" and b2 in ~c"nN" and b3 in ~c"dD" and b4 in ~c"_" and b5 in ~c"pP" and b6 in ~c"aA" and
  b7 in ~c"rR" and b8 in ~c"tT" and b9 in ~c"iI" and b10 in ~c"tT" and b11 in ~c"iI" and
  b12 in ~c"oO" and b13 in ~c"nN", do: :end_partition
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"eE" and b2 in ~c"nN" and b3 in ~c"dD" and b4 in ~c"-" and b5 in ~c"eE" and b6 in ~c"xX" and
  b7 in ~c"eE" and b8 in ~c"cC", do: :"end-exec"
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"eE" and b2 in ~c"qQ" and b3 in ~c"uU" and b4 in ~c"aA" and b5 in ~c"lL" and b6 in ~c"sS", do: :equals
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"eE" and b2 in ~c"sS" and b3 in ~c"cC" and b4 in ~c"aA" and b5 in ~c"pP" and b6 in ~c"eE", do: :escape
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"eE" and b2 in ~c"vV" and b3 in ~c"eE" and b4 in ~c"rR" and b5 in ~c"yY", do: :every
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"eE" and b2 in ~c"xX" and b3 in ~c"cC" and b4 in ~c"eE" and b5 in ~c"pP" and b6 in ~c"tT", do: :except
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"eE" and b2 in ~c"xX" and b3 in ~c"eE" and b4 in ~c"cC", do: :exec
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"eE" and b2 in ~c"xX" and b3 in ~c"eE" and b4 in ~c"cC" and b5 in ~c"uU" and b6 in ~c"tT" and
  b7 in ~c"eE", do: :execute
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"eE" and b2 in ~c"xX" and b3 in ~c"iI" and b4 in ~c"sS" and b5 in ~c"tT" and b6 in ~c"sS", do: :exists
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"eE" and b2 in ~c"xX" and b3 in ~c"pP", do: :exp
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"eE" and b2 in ~c"xX" and b3 in ~c"tT" and b4 in ~c"eE" and b5 in ~c"rR" and b6 in ~c"nN" and
  b7 in ~c"aA" and b8 in ~c"lL", do: :external
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"eE" and b2 in ~c"xX" and b3 in ~c"tT" and b4 in ~c"rR" and b5 in ~c"aA" and b6 in ~c"cC" and
  b7 in ~c"tT", do: :extract
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"fF" and b2 in ~c"aA" and b3 in ~c"lL" and b4 in ~c"sS" and b5 in ~c"eE", do: false
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"fF" and b2 in ~c"eE" and b3 in ~c"tT" and b4 in ~c"cC" and b5 in ~c"hH", do: :fetch
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"fF" and b2 in ~c"iI" and b3 in ~c"lL" and b4 in ~c"tT" and b5 in ~c"eE" and b6 in ~c"rR", do: :filter
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"fF" and b2 in ~c"iI" and b3 in ~c"rR" and b4 in ~c"sS" and b5 in ~c"tT" and b6 in ~c"_" and
  b7 in ~c"vV" and b8 in ~c"aA" and b9 in ~c"lL" and b10 in ~c"uU" and b11 in ~c"eE", do: :first_value
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"fF" and b2 in ~c"lL" and b3 in ~c"oO" and b4 in ~c"aA" and b5 in ~c"tT", do: :float
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"fF" and b2 in ~c"lL" and b3 in ~c"oO" and b4 in ~c"oO" and b5 in ~c"rR", do: :floor
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"fF" and b2 in ~c"oO" and b3 in ~c"rR", do: :for
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"fF" and b2 in ~c"oO" and b3 in ~c"rR" and b4 in ~c"eE" and b5 in ~c"iI" and b6 in ~c"gG" and
  b7 in ~c"nN", do: :foreign
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"fF" and b2 in ~c"rR" and b3 in ~c"aA" and b4 in ~c"mM" and b5 in ~c"eE" and b6 in ~c"_" and
  b7 in ~c"rR" and b8 in ~c"oO" and b9 in ~c"wW", do: :frame_row
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"fF" and b2 in ~c"rR" and b3 in ~c"eE" and b4 in ~c"eE", do: :free
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"fF" and b2 in ~c"rR" and b3 in ~c"oO" and b4 in ~c"mM", do: :from
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"fF" and b2 in ~c"uU" and b3 in ~c"lL" and b4 in ~c"lL", do: :full
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"fF" and b2 in ~c"uU" and b3 in ~c"nN" and b4 in ~c"cC" and b5 in ~c"tT" and b6 in ~c"iI" and
  b7 in ~c"oO" and b8 in ~c"nN", do: :function
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"fF" and b2 in ~c"uU" and b3 in ~c"sS" and b4 in ~c"iI" and b5 in ~c"oO" and b6 in ~c"nN", do: :fusion
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"gG" and b2 in ~c"eE" and b3 in ~c"tT", do: :get
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"gG" and b2 in ~c"lL" and b3 in ~c"oO" and b4 in ~c"bB" and b5 in ~c"aA" and b6 in ~c"lL", do: :global
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"gG" and b2 in ~c"rR" and b3 in ~c"aA" and b4 in ~c"nN" and b5 in ~c"tT", do: :grant
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"gG" and b2 in ~c"rR" and b3 in ~c"eE" and b4 in ~c"aA" and b5 in ~c"tT" and b6 in ~c"eE" and
  b7 in ~c"sS" and b8 in ~c"tT", do: :greatest
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"gG" and b2 in ~c"rR" and b3 in ~c"oO" and b4 in ~c"uU" and b5 in ~c"pP", do: :group
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"gG" and b2 in ~c"rR" and b3 in ~c"oO" and b4 in ~c"uU" and b5 in ~c"pP" and b6 in ~c"iI" and
  b7 in ~c"nN" and b8 in ~c"gG", do: :grouping
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"gG" and b2 in ~c"rR" and b3 in ~c"oO" and b4 in ~c"uU" and b5 in ~c"pP" and b6 in ~c"sS", do: :groups
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"hH" and b2 in ~c"aA" and b3 in ~c"vV" and b4 in ~c"iI" and b5 in ~c"nN" and b6 in ~c"gG", do: :having
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"hH" and b2 in ~c"oO" and b3 in ~c"lL" and b4 in ~c"dD", do: :hold
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"hH" and b2 in ~c"oO" and b3 in ~c"uU" and b4 in ~c"rR", do: :hour
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"iI" and b2 in ~c"dD" and b3 in ~c"eE" and b4 in ~c"nN" and b5 in ~c"tT" and b6 in ~c"iI" and
  b7 in ~c"tT" and b8 in ~c"yY", do: :identity
  
    def ident(:ident, [[[], b1], b2]) when b1 in ~c"iI" and b2 in ~c"nN", do: :in
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"iI" and b2 in ~c"nN" and b3 in ~c"dD" and b4 in ~c"iI" and b5 in ~c"cC" and b6 in ~c"aA" and
  b7 in ~c"tT" and b8 in ~c"oO" and b9 in ~c"rR", do: :indicator
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"iI" and b2 in ~c"nN" and b3 in ~c"iI" and b4 in ~c"tT" and b5 in ~c"iI" and b6 in ~c"aA" and
  b7 in ~c"lL", do: :initial
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"iI" and b2 in ~c"nN" and b3 in ~c"nN" and b4 in ~c"eE" and b5 in ~c"rR", do: :inner
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"iI" and b2 in ~c"nN" and b3 in ~c"oO" and b4 in ~c"uU" and b5 in ~c"tT", do: :inout
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"iI" and b2 in ~c"nN" and b3 in ~c"sS" and b4 in ~c"eE" and b5 in ~c"nN" and b6 in ~c"sS" and
  b7 in ~c"iI" and b8 in ~c"tT" and b9 in ~c"iI" and b10 in ~c"vV" and b11 in ~c"eE", do: :insensitive
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"iI" and b2 in ~c"nN" and b3 in ~c"sS" and b4 in ~c"eE" and b5 in ~c"rR" and b6 in ~c"tT", do: :insert
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"iI" and b2 in ~c"nN" and b3 in ~c"tT", do: :int
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"iI" and b2 in ~c"nN" and b3 in ~c"tT" and b4 in ~c"eE" and b5 in ~c"gG" and b6 in ~c"eE" and
  b7 in ~c"rR", do: :integer
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"iI" and b2 in ~c"nN" and b3 in ~c"tT" and b4 in ~c"eE" and b5 in ~c"rR" and b6 in ~c"sS" and
  b7 in ~c"eE" and b8 in ~c"cC" and b9 in ~c"tT", do: :intersect
  
    def ident(:ident, [[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when b1 in ~c"iI" and b2 in ~c"nN" and b3 in ~c"tT" and b4 in ~c"eE" and b5 in ~c"rR" and b6 in ~c"sS" and
  b7 in ~c"eE" and b8 in ~c"cC" and b9 in ~c"tT" and b10 in ~c"iI" and b11 in ~c"oO" and
  b12 in ~c"nN", do: :intersection
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"iI" and b2 in ~c"nN" and b3 in ~c"tT" and b4 in ~c"eE" and b5 in ~c"rR" and b6 in ~c"vV" and
  b7 in ~c"aA" and b8 in ~c"lL", do: :interval
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"iI" and b2 in ~c"nN" and b3 in ~c"tT" and b4 in ~c"oO", do: :into
  
    def ident(:ident, [[[], b1], b2]) when b1 in ~c"iI" and b2 in ~c"sS", do: :is
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"jJ" and b2 in ~c"oO" and b3 in ~c"iI" and b4 in ~c"nN", do: :join
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"jJ" and b2 in ~c"sS" and b3 in ~c"oO" and b4 in ~c"nN", do: :json
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"jJ" and b2 in ~c"sS" and b3 in ~c"oO" and b4 in ~c"nN" and b5 in ~c"_" and b6 in ~c"aA" and
  b7 in ~c"rR" and b8 in ~c"rR" and b9 in ~c"aA" and b10 in ~c"yY", do: :json_array
  
    def ident(:ident, [[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13]) when b1 in ~c"jJ" and b2 in ~c"sS" and b3 in ~c"oO" and b4 in ~c"nN" and b5 in ~c"_" and b6 in ~c"aA" and
  b7 in ~c"rR" and b8 in ~c"rR" and b9 in ~c"aA" and b10 in ~c"yY" and b11 in ~c"aA" and
  b12 in ~c"gG" and b13 in ~c"gG", do: :json_arrayagg
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"jJ" and b2 in ~c"sS" and b3 in ~c"oO" and b4 in ~c"nN" and b5 in ~c"_" and b6 in ~c"eE" and
  b7 in ~c"xX" and b8 in ~c"iI" and b9 in ~c"sS" and b10 in ~c"tT" and b11 in ~c"sS", do: :json_exists
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"jJ" and b2 in ~c"sS" and b3 in ~c"oO" and b4 in ~c"nN" and b5 in ~c"_" and b6 in ~c"oO" and
  b7 in ~c"bB" and b8 in ~c"jJ" and b9 in ~c"eE" and b10 in ~c"cC" and b11 in ~c"tT", do: :json_object
  
    def ident(:ident, [[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when b1 in ~c"jJ" and b2 in ~c"sS" and b3 in ~c"oO" and b4 in ~c"nN" and b5 in ~c"_" and b6 in ~c"oO" and
  b7 in ~c"bB" and b8 in ~c"jJ" and b9 in ~c"eE" and b10 in ~c"cC" and b11 in ~c"tT" and
  b12 in ~c"aA" and b13 in ~c"gG" and b14 in ~c"gG", do: :json_objectagg
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"jJ" and b2 in ~c"sS" and b3 in ~c"oO" and b4 in ~c"nN" and b5 in ~c"_" and b6 in ~c"qQ" and
  b7 in ~c"uU" and b8 in ~c"eE" and b9 in ~c"rR" and b10 in ~c"yY", do: :json_query
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"jJ" and b2 in ~c"sS" and b3 in ~c"oO" and b4 in ~c"nN" and b5 in ~c"_" and b6 in ~c"sS" and
  b7 in ~c"cC" and b8 in ~c"aA" and b9 in ~c"lL" and b10 in ~c"aA" and b11 in ~c"rR", do: :json_scalar
  
    def ident(:ident, [[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when b1 in ~c"jJ" and b2 in ~c"sS" and b3 in ~c"oO" and b4 in ~c"nN" and b5 in ~c"_" and b6 in ~c"sS" and
  b7 in ~c"eE" and b8 in ~c"rR" and b9 in ~c"iI" and b10 in ~c"aA" and b11 in ~c"lL" and
  b12 in ~c"iI" and b13 in ~c"zZ" and b14 in ~c"eE", do: :json_serialize
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"jJ" and b2 in ~c"sS" and b3 in ~c"oO" and b4 in ~c"nN" and b5 in ~c"_" and b6 in ~c"tT" and
  b7 in ~c"aA" and b8 in ~c"bB" and b9 in ~c"lL" and b10 in ~c"eE", do: :json_table
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20]) when b1 in ~c"jJ" and b2 in ~c"sS" and b3 in ~c"oO" and b4 in ~c"nN" and b5 in ~c"_" and b6 in ~c"tT" and
  b7 in ~c"aA" and b8 in ~c"bB" and b9 in ~c"lL" and b10 in ~c"eE" and b11 in ~c"_" and
  b12 in ~c"pP" and b13 in ~c"rR" and b14 in ~c"iI" and b15 in ~c"mM" and b16 in ~c"iI" and
  b17 in ~c"tT" and b18 in ~c"iI" and b19 in ~c"vV" and b20 in ~c"eE", do: :json_table_primitive
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"jJ" and b2 in ~c"sS" and b3 in ~c"oO" and b4 in ~c"nN" and b5 in ~c"_" and b6 in ~c"vV" and
  b7 in ~c"aA" and b8 in ~c"lL" and b9 in ~c"uU" and b10 in ~c"eE", do: :json_value
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"lL" and b2 in ~c"aA" and b3 in ~c"gG", do: :lag
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"lL" and b2 in ~c"aA" and b3 in ~c"nN" and b4 in ~c"gG" and b5 in ~c"uU" and b6 in ~c"aA" and
  b7 in ~c"gG" and b8 in ~c"eE", do: :language
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"lL" and b2 in ~c"aA" and b3 in ~c"rR" and b4 in ~c"gG" and b5 in ~c"eE", do: :large
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"lL" and b2 in ~c"aA" and b3 in ~c"sS" and b4 in ~c"tT" and b5 in ~c"_" and b6 in ~c"vV" and
  b7 in ~c"aA" and b8 in ~c"lL" and b9 in ~c"uU" and b10 in ~c"eE", do: :last_value
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"lL" and b2 in ~c"aA" and b3 in ~c"tT" and b4 in ~c"eE" and b5 in ~c"rR" and b6 in ~c"aA" and
  b7 in ~c"lL", do: :lateral
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"lL" and b2 in ~c"eE" and b3 in ~c"aA" and b4 in ~c"dD", do: :lead
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"lL" and b2 in ~c"eE" and b3 in ~c"aA" and b4 in ~c"dD" and b5 in ~c"iI" and b6 in ~c"nN" and
  b7 in ~c"gG", do: :leading
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"lL" and b2 in ~c"eE" and b3 in ~c"aA" and b4 in ~c"sS" and b5 in ~c"tT", do: :least
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"lL" and b2 in ~c"eE" and b3 in ~c"fF" and b4 in ~c"tT", do: :left
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"lL" and b2 in ~c"iI" and b3 in ~c"kK" and b4 in ~c"eE", do: :like
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"lL" and b2 in ~c"iI" and b3 in ~c"kK" and b4 in ~c"eE" and b5 in ~c"_" and b6 in ~c"rR" and
  b7 in ~c"eE" and b8 in ~c"gG" and b9 in ~c"eE" and b10 in ~c"xX", do: :like_regex
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"lL" and b2 in ~c"iI" and b3 in ~c"sS" and b4 in ~c"tT" and b5 in ~c"aA" and b6 in ~c"gG" and
  b7 in ~c"gG", do: :listagg
  
    def ident(:ident, [[[], b1], b2]) when b1 in ~c"lL" and b2 in ~c"nN", do: :ln
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"lL" and b2 in ~c"oO" and b3 in ~c"cC" and b4 in ~c"aA" and b5 in ~c"lL", do: :local
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"lL" and b2 in ~c"oO" and b3 in ~c"cC" and b4 in ~c"aA" and b5 in ~c"lL" and b6 in ~c"tT" and
  b7 in ~c"iI" and b8 in ~c"mM" and b9 in ~c"eE", do: :localtime
  
    def ident(:ident, [[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when b1 in ~c"lL" and b2 in ~c"oO" and b3 in ~c"cC" and b4 in ~c"aA" and b5 in ~c"lL" and b6 in ~c"tT" and
  b7 in ~c"iI" and b8 in ~c"mM" and b9 in ~c"eE" and b10 in ~c"sS" and b11 in ~c"tT" and
  b12 in ~c"aA" and b13 in ~c"mM" and b14 in ~c"pP", do: :localtimestamp
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"lL" and b2 in ~c"oO" and b3 in ~c"gG", do: :log
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"lL" and b2 in ~c"oO" and b3 in ~c"gG" and b4 in ~c"1" and b5 in ~c"0", do: :log10
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"lL" and b2 in ~c"oO" and b3 in ~c"wW" and b4 in ~c"eE" and b5 in ~c"rR", do: :lower
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"lL" and b2 in ~c"pP" and b3 in ~c"aA" and b4 in ~c"dD", do: :lpad
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"lL" and b2 in ~c"tT" and b3 in ~c"rR" and b4 in ~c"iI" and b5 in ~c"mM", do: :ltrim
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"mM" and b2 in ~c"aA" and b3 in ~c"tT" and b4 in ~c"cC" and b5 in ~c"hH", do: :match
  
    def ident(:ident, [[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when b1 in ~c"mM" and b2 in ~c"aA" and b3 in ~c"tT" and b4 in ~c"cC" and b5 in ~c"hH" and b6 in ~c"_" and
  b7 in ~c"nN" and b8 in ~c"uU" and b9 in ~c"mM" and b10 in ~c"bB" and b11 in ~c"eE" and
  b12 in ~c"rR", do: :match_number
  
    def ident(:ident, [[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when b1 in ~c"mM" and b2 in ~c"aA" and b3 in ~c"tT" and b4 in ~c"cC" and b5 in ~c"hH" and b6 in ~c"_" and
  b7 in ~c"rR" and b8 in ~c"eE" and b9 in ~c"cC" and b10 in ~c"oO" and b11 in ~c"gG" and
  b12 in ~c"nN" and b13 in ~c"iI" and b14 in ~c"zZ" and b15 in ~c"eE", do: :match_recognize
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"mM" and b2 in ~c"aA" and b3 in ~c"tT" and b4 in ~c"cC" and b5 in ~c"hH" and b6 in ~c"eE" and
  b7 in ~c"sS", do: :matches
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"mM" and b2 in ~c"aA" and b3 in ~c"xX", do: :max
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"mM" and b2 in ~c"eE" and b3 in ~c"mM" and b4 in ~c"bB" and b5 in ~c"eE" and b6 in ~c"rR", do: :member
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"mM" and b2 in ~c"eE" and b3 in ~c"rR" and b4 in ~c"gG" and b5 in ~c"eE", do: :merge
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"mM" and b2 in ~c"eE" and b3 in ~c"tT" and b4 in ~c"hH" and b5 in ~c"oO" and b6 in ~c"dD", do: :method
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"mM" and b2 in ~c"iI" and b3 in ~c"nN", do: :min
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"mM" and b2 in ~c"iI" and b3 in ~c"nN" and b4 in ~c"uU" and b5 in ~c"tT" and b6 in ~c"eE", do: :minute
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"mM" and b2 in ~c"oO" and b3 in ~c"dD", do: :mod
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"mM" and b2 in ~c"oO" and b3 in ~c"dD" and b4 in ~c"iI" and b5 in ~c"fF" and b6 in ~c"iI" and
  b7 in ~c"eE" and b8 in ~c"sS", do: :modifies
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"mM" and b2 in ~c"oO" and b3 in ~c"dD" and b4 in ~c"uU" and b5 in ~c"lL" and b6 in ~c"eE", do: :module
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"mM" and b2 in ~c"oO" and b3 in ~c"nN" and b4 in ~c"tT" and b5 in ~c"hH", do: :month
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"mM" and b2 in ~c"uU" and b3 in ~c"lL" and b4 in ~c"tT" and b5 in ~c"iI" and b6 in ~c"sS" and
  b7 in ~c"eE" and b8 in ~c"tT", do: :multiset
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"nN" and b2 in ~c"aA" and b3 in ~c"tT" and b4 in ~c"iI" and b5 in ~c"oO" and b6 in ~c"nN" and
  b7 in ~c"aA" and b8 in ~c"lL", do: :national
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"nN" and b2 in ~c"aA" and b3 in ~c"tT" and b4 in ~c"uU" and b5 in ~c"rR" and b6 in ~c"aA" and
  b7 in ~c"lL", do: :natural
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"nN" and b2 in ~c"cC" and b3 in ~c"hH" and b4 in ~c"aA" and b5 in ~c"rR", do: :nchar
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"nN" and b2 in ~c"cC" and b3 in ~c"lL" and b4 in ~c"oO" and b5 in ~c"bB", do: :nclob
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"nN" and b2 in ~c"eE" and b3 in ~c"wW", do: :new
  
    def ident(:ident, [[[], b1], b2]) when b1 in ~c"nN" and b2 in ~c"oO", do: :no
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"nN" and b2 in ~c"oO" and b3 in ~c"nN" and b4 in ~c"eE", do: :none
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"nN" and b2 in ~c"oO" and b3 in ~c"rR" and b4 in ~c"mM" and b5 in ~c"aA" and b6 in ~c"lL" and
  b7 in ~c"iI" and b8 in ~c"zZ" and b9 in ~c"eE", do: :normalize
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"nN" and b2 in ~c"oO" and b3 in ~c"tT", do: :not
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"nN" and b2 in ~c"tT" and b3 in ~c"hH" and b4 in ~c"_" and b5 in ~c"vV" and b6 in ~c"aA" and
  b7 in ~c"lL" and b8 in ~c"uU" and b9 in ~c"eE", do: :nth_value
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"nN" and b2 in ~c"tT" and b3 in ~c"iI" and b4 in ~c"lL" and b5 in ~c"eE", do: :ntile
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"nN" and b2 in ~c"uU" and b3 in ~c"lL" and b4 in ~c"lL", do: :null
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"nN" and b2 in ~c"uU" and b3 in ~c"lL" and b4 in ~c"lL" and b5 in ~c"iI" and b6 in ~c"fF", do: :nullif
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"nN" and b2 in ~c"uU" and b3 in ~c"mM" and b4 in ~c"eE" and b5 in ~c"rR" and b6 in ~c"iI" and
  b7 in ~c"cC", do: :numeric
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17]) when b1 in ~c"oO" and b2 in ~c"cC" and b3 in ~c"cC" and b4 in ~c"uU" and b5 in ~c"rR" and b6 in ~c"rR" and
  b7 in ~c"eE" and b8 in ~c"nN" and b9 in ~c"cC" and b10 in ~c"eE" and b11 in ~c"sS" and
  b12 in ~c"_" and b13 in ~c"rR" and b14 in ~c"eE" and b15 in ~c"gG" and b16 in ~c"eE" and
  b17 in ~c"xX", do: :occurrences_regex
  
    def ident(:ident, [[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when b1 in ~c"oO" and b2 in ~c"cC" and b3 in ~c"tT" and b4 in ~c"eE" and b5 in ~c"tT" and b6 in ~c"_" and
  b7 in ~c"lL" and b8 in ~c"eE" and b9 in ~c"nN" and b10 in ~c"gG" and b11 in ~c"tT" and
  b12 in ~c"hH", do: :octet_length
  
    def ident(:ident, [[[], b1], b2]) when b1 in ~c"oO" and b2 in ~c"fF", do: :of
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"oO" and b2 in ~c"fF" and b3 in ~c"fF" and b4 in ~c"sS" and b5 in ~c"eE" and b6 in ~c"tT", do: :offset
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"oO" and b2 in ~c"lL" and b3 in ~c"dD", do: :old
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"oO" and b2 in ~c"mM" and b3 in ~c"iI" and b4 in ~c"tT", do: :omit
  
    def ident(:ident, [[[], b1], b2]) when b1 in ~c"oO" and b2 in ~c"nN", do: :on
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"oO" and b2 in ~c"nN" and b3 in ~c"eE", do: :one
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"oO" and b2 in ~c"nN" and b3 in ~c"lL" and b4 in ~c"yY", do: :only
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"oO" and b2 in ~c"pP" and b3 in ~c"eE" and b4 in ~c"nN", do: :open
  
    def ident(:ident, [[[], b1], b2]) when b1 in ~c"oO" and b2 in ~c"rR", do: :or
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"oO" and b2 in ~c"rR" and b3 in ~c"dD" and b4 in ~c"eE" and b5 in ~c"rR", do: :order
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"oO" and b2 in ~c"uU" and b3 in ~c"tT", do: :out
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"oO" and b2 in ~c"uU" and b3 in ~c"tT" and b4 in ~c"eE" and b5 in ~c"rR", do: :outer
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"oO" and b2 in ~c"vV" and b3 in ~c"eE" and b4 in ~c"rR", do: :over
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"oO" and b2 in ~c"vV" and b3 in ~c"eE" and b4 in ~c"rR" and b5 in ~c"lL" and b6 in ~c"aA" and
  b7 in ~c"pP" and b8 in ~c"sS", do: :overlaps
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"oO" and b2 in ~c"vV" and b3 in ~c"eE" and b4 in ~c"rR" and b5 in ~c"lL" and b6 in ~c"aA" and
  b7 in ~c"yY", do: :overlay
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"pP" and b2 in ~c"aA" and b3 in ~c"rR" and b4 in ~c"aA" and b5 in ~c"mM" and b6 in ~c"eE" and
  b7 in ~c"tT" and b8 in ~c"eE" and b9 in ~c"rR", do: :parameter
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"pP" and b2 in ~c"aA" and b3 in ~c"rR" and b4 in ~c"tT" and b5 in ~c"iI" and b6 in ~c"tT" and
  b7 in ~c"iI" and b8 in ~c"oO" and b9 in ~c"nN", do: :partition
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"pP" and b2 in ~c"aA" and b3 in ~c"tT" and b4 in ~c"tT" and b5 in ~c"eE" and b6 in ~c"rR" and
  b7 in ~c"nN", do: :pattern
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"pP" and b2 in ~c"eE" and b3 in ~c"rR", do: :per
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"pP" and b2 in ~c"eE" and b3 in ~c"rR" and b4 in ~c"cC" and b5 in ~c"eE" and b6 in ~c"nN" and
  b7 in ~c"tT", do: :percent
  
    def ident(:ident, [[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when b1 in ~c"pP" and b2 in ~c"eE" and b3 in ~c"rR" and b4 in ~c"cC" and b5 in ~c"eE" and b6 in ~c"nN" and
  b7 in ~c"tT" and b8 in ~c"_" and b9 in ~c"rR" and b10 in ~c"aA" and b11 in ~c"nN" and
  b12 in ~c"kK", do: :percent_rank
  
    def ident(:ident, [[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when b1 in ~c"pP" and b2 in ~c"eE" and b3 in ~c"rR" and b4 in ~c"cC" and b5 in ~c"eE" and b6 in ~c"nN" and
  b7 in ~c"tT" and b8 in ~c"iI" and b9 in ~c"lL" and b10 in ~c"eE" and b11 in ~c"_" and
  b12 in ~c"cC" and b13 in ~c"oO" and b14 in ~c"nN" and b15 in ~c"tT", do: :percentile_cont
  
    def ident(:ident, [[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when b1 in ~c"pP" and b2 in ~c"eE" and b3 in ~c"rR" and b4 in ~c"cC" and b5 in ~c"eE" and b6 in ~c"nN" and
  b7 in ~c"tT" and b8 in ~c"iI" and b9 in ~c"lL" and b10 in ~c"eE" and b11 in ~c"_" and
  b12 in ~c"dD" and b13 in ~c"iI" and b14 in ~c"sS" and b15 in ~c"cC", do: :percentile_disc
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"pP" and b2 in ~c"eE" and b3 in ~c"rR" and b4 in ~c"iI" and b5 in ~c"oO" and b6 in ~c"dD", do: :period
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"pP" and b2 in ~c"oO" and b3 in ~c"rR" and b4 in ~c"tT" and b5 in ~c"iI" and b6 in ~c"oO" and
  b7 in ~c"nN", do: :portion
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"pP" and b2 in ~c"oO" and b3 in ~c"sS" and b4 in ~c"iI" and b5 in ~c"tT" and b6 in ~c"iI" and
  b7 in ~c"oO" and b8 in ~c"nN", do: :position
  
    def ident(:ident, [[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when b1 in ~c"pP" and b2 in ~c"oO" and b3 in ~c"sS" and b4 in ~c"iI" and b5 in ~c"tT" and b6 in ~c"iI" and
  b7 in ~c"oO" and b8 in ~c"nN" and b9 in ~c"_" and b10 in ~c"rR" and b11 in ~c"eE" and
  b12 in ~c"gG" and b13 in ~c"eE" and b14 in ~c"xX", do: :position_regex
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"pP" and b2 in ~c"oO" and b3 in ~c"wW" and b4 in ~c"eE" and b5 in ~c"rR", do: :power
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"pP" and b2 in ~c"rR" and b3 in ~c"eE" and b4 in ~c"cC" and b5 in ~c"eE" and b6 in ~c"dD" and
  b7 in ~c"eE" and b8 in ~c"sS", do: :precedes
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"pP" and b2 in ~c"rR" and b3 in ~c"eE" and b4 in ~c"cC" and b5 in ~c"iI" and b6 in ~c"sS" and
  b7 in ~c"iI" and b8 in ~c"oO" and b9 in ~c"nN", do: :precision
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"pP" and b2 in ~c"rR" and b3 in ~c"eE" and b4 in ~c"pP" and b5 in ~c"aA" and b6 in ~c"rR" and
  b7 in ~c"eE", do: :prepare
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"pP" and b2 in ~c"rR" and b3 in ~c"iI" and b4 in ~c"mM" and b5 in ~c"aA" and b6 in ~c"rR" and
  b7 in ~c"yY", do: :primary
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"pP" and b2 in ~c"rR" and b3 in ~c"oO" and b4 in ~c"cC" and b5 in ~c"eE" and b6 in ~c"dD" and
  b7 in ~c"uU" and b8 in ~c"rR" and b9 in ~c"eE", do: :procedure
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"pP" and b2 in ~c"tT" and b3 in ~c"fF", do: :ptf
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"rR" and b2 in ~c"aA" and b3 in ~c"nN" and b4 in ~c"gG" and b5 in ~c"eE", do: :range
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"rR" and b2 in ~c"aA" and b3 in ~c"nN" and b4 in ~c"kK", do: :rank
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"aA" and b4 in ~c"dD" and b5 in ~c"sS", do: :reads
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"aA" and b4 in ~c"lL", do: :real
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"cC" and b4 in ~c"uU" and b5 in ~c"rR" and b6 in ~c"sS" and
  b7 in ~c"iI" and b8 in ~c"vV" and b9 in ~c"eE", do: :recursive
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"fF", do: :ref
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"fF" and b4 in ~c"eE" and b5 in ~c"rR" and b6 in ~c"eE" and
  b7 in ~c"nN" and b8 in ~c"cC" and b9 in ~c"eE" and b10 in ~c"sS", do: :references
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"fF" and b4 in ~c"eE" and b5 in ~c"rR" and b6 in ~c"eE" and
  b7 in ~c"nN" and b8 in ~c"cC" and b9 in ~c"iI" and b10 in ~c"nN" and b11 in ~c"gG", do: :referencing
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"gG" and b4 in ~c"rR" and b5 in ~c"_" and b6 in ~c"aA" and
  b7 in ~c"vV" and b8 in ~c"gG" and b9 in ~c"xX", do: :regr_avgx
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"gG" and b4 in ~c"rR" and b5 in ~c"_" and b6 in ~c"aA" and
  b7 in ~c"vV" and b8 in ~c"gG" and b9 in ~c"yY", do: :regr_avgy
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"gG" and b4 in ~c"rR" and b5 in ~c"_" and b6 in ~c"cC" and
  b7 in ~c"oO" and b8 in ~c"uU" and b9 in ~c"nN" and b10 in ~c"tT", do: :regr_count
  
    def ident(:ident, [[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"gG" and b4 in ~c"rR" and b5 in ~c"_" and b6 in ~c"iI" and
  b7 in ~c"nN" and b8 in ~c"tT" and b9 in ~c"eE" and b10 in ~c"rR" and b11 in ~c"cC" and
  b12 in ~c"eE" and b13 in ~c"pP" and b14 in ~c"tT", do: :regr_intercept
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"gG" and b4 in ~c"rR" and b5 in ~c"_" and b6 in ~c"rR" and
  b7 in ~c"2", do: :regr_r2
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"gG" and b4 in ~c"rR" and b5 in ~c"_" and b6 in ~c"sS" and
  b7 in ~c"lL" and b8 in ~c"oO" and b9 in ~c"pP" and b10 in ~c"eE", do: :regr_slope
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"gG" and b4 in ~c"rR" and b5 in ~c"_" and b6 in ~c"sS" and
  b7 in ~c"xX" and b8 in ~c"xX", do: :regr_sxx
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"gG" and b4 in ~c"rR" and b5 in ~c"_" and b6 in ~c"sS" and
  b7 in ~c"xX" and b8 in ~c"yY", do: :regr_sxy
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"gG" and b4 in ~c"rR" and b5 in ~c"_" and b6 in ~c"sS" and
  b7 in ~c"yY" and b8 in ~c"yY", do: :regr_syy
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"lL" and b4 in ~c"eE" and b5 in ~c"aA" and b6 in ~c"sS" and
  b7 in ~c"eE", do: :release
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"sS" and b4 in ~c"uU" and b5 in ~c"lL" and b6 in ~c"tT", do: :result
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"tT" and b4 in ~c"uU" and b5 in ~c"rR" and b6 in ~c"nN", do: :return
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"tT" and b4 in ~c"uU" and b5 in ~c"rR" and b6 in ~c"nN" and
  b7 in ~c"sS", do: :returns
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"vV" and b4 in ~c"oO" and b5 in ~c"kK" and b6 in ~c"eE", do: :revoke
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"rR" and b2 in ~c"iI" and b3 in ~c"gG" and b4 in ~c"hH" and b5 in ~c"tT", do: :right
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"rR" and b2 in ~c"oO" and b3 in ~c"lL" and b4 in ~c"lL" and b5 in ~c"bB" and b6 in ~c"aA" and
  b7 in ~c"cC" and b8 in ~c"kK", do: :rollback
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"rR" and b2 in ~c"oO" and b3 in ~c"lL" and b4 in ~c"lL" and b5 in ~c"uU" and b6 in ~c"pP", do: :rollup
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"rR" and b2 in ~c"oO" and b3 in ~c"wW", do: :row
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"rR" and b2 in ~c"oO" and b3 in ~c"wW" and b4 in ~c"_" and b5 in ~c"nN" and b6 in ~c"uU" and
  b7 in ~c"mM" and b8 in ~c"bB" and b9 in ~c"eE" and b10 in ~c"rR", do: :row_number
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"rR" and b2 in ~c"oO" and b3 in ~c"wW" and b4 in ~c"sS", do: :rows
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"rR" and b2 in ~c"pP" and b3 in ~c"aA" and b4 in ~c"dD", do: :rpad
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"rR" and b2 in ~c"tT" and b3 in ~c"rR" and b4 in ~c"iI" and b5 in ~c"mM", do: :rtrim
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"rR" and b2 in ~c"uU" and b3 in ~c"nN" and b4 in ~c"nN" and b5 in ~c"iI" and b6 in ~c"nN" and
  b7 in ~c"gG", do: :running
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"sS" and b2 in ~c"aA" and b3 in ~c"vV" and b4 in ~c"eE" and b5 in ~c"pP" and b6 in ~c"oO" and
  b7 in ~c"iI" and b8 in ~c"nN" and b9 in ~c"tT", do: :savepoint
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"sS" and b2 in ~c"cC" and b3 in ~c"oO" and b4 in ~c"pP" and b5 in ~c"eE", do: :scope
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"sS" and b2 in ~c"cC" and b3 in ~c"rR" and b4 in ~c"oO" and b5 in ~c"lL" and b6 in ~c"lL", do: :scroll
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"sS" and b2 in ~c"eE" and b3 in ~c"aA" and b4 in ~c"rR" and b5 in ~c"cC" and b6 in ~c"hH", do: :search
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"sS" and b2 in ~c"eE" and b3 in ~c"cC" and b4 in ~c"oO" and b5 in ~c"nN" and b6 in ~c"dD", do: :second
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"sS" and b2 in ~c"eE" and b3 in ~c"eE" and b4 in ~c"kK", do: :seek
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"sS" and b2 in ~c"eE" and b3 in ~c"lL" and b4 in ~c"eE" and b5 in ~c"cC" and b6 in ~c"tT", do: :select
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"sS" and b2 in ~c"eE" and b3 in ~c"nN" and b4 in ~c"sS" and b5 in ~c"iI" and b6 in ~c"tT" and
  b7 in ~c"iI" and b8 in ~c"vV" and b9 in ~c"eE", do: :sensitive
  
    def ident(:ident, [[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when b1 in ~c"sS" and b2 in ~c"eE" and b3 in ~c"sS" and b4 in ~c"sS" and b5 in ~c"iI" and b6 in ~c"oO" and
  b7 in ~c"nN" and b8 in ~c"_" and b9 in ~c"uU" and b10 in ~c"sS" and b11 in ~c"eE" and
  b12 in ~c"rR", do: :session_user
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"sS" and b2 in ~c"eE" and b3 in ~c"tT", do: :set
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"sS" and b2 in ~c"hH" and b3 in ~c"oO" and b4 in ~c"wW", do: :show
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"sS" and b2 in ~c"iI" and b3 in ~c"mM" and b4 in ~c"iI" and b5 in ~c"lL" and b6 in ~c"aA" and
  b7 in ~c"rR", do: :similar
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"sS" and b2 in ~c"iI" and b3 in ~c"nN", do: :sin
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"sS" and b2 in ~c"iI" and b3 in ~c"nN" and b4 in ~c"hH", do: :sinh
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"sS" and b2 in ~c"kK" and b3 in ~c"iI" and b4 in ~c"pP", do: :skip
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"sS" and b2 in ~c"mM" and b3 in ~c"aA" and b4 in ~c"lL" and b5 in ~c"lL" and b6 in ~c"iI" and
  b7 in ~c"nN" and b8 in ~c"tT", do: :smallint
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"sS" and b2 in ~c"oO" and b3 in ~c"mM" and b4 in ~c"eE", do: :some
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"sS" and b2 in ~c"pP" and b3 in ~c"eE" and b4 in ~c"cC" and b5 in ~c"iI" and b6 in ~c"fF" and
  b7 in ~c"iI" and b8 in ~c"cC", do: :specific
  
    def ident(:ident, [[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when b1 in ~c"sS" and b2 in ~c"pP" and b3 in ~c"eE" and b4 in ~c"cC" and b5 in ~c"iI" and b6 in ~c"fF" and
  b7 in ~c"iI" and b8 in ~c"cC" and b9 in ~c"tT" and b10 in ~c"yY" and b11 in ~c"pP" and
  b12 in ~c"eE", do: :specifictype
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"sS" and b2 in ~c"qQ" and b3 in ~c"lL", do: :sql
  
    def ident(:ident, [[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when b1 in ~c"sS" and b2 in ~c"qQ" and b3 in ~c"lL" and b4 in ~c"eE" and b5 in ~c"xX" and b6 in ~c"cC" and
  b7 in ~c"eE" and b8 in ~c"pP" and b9 in ~c"tT" and b10 in ~c"iI" and b11 in ~c"oO" and
  b12 in ~c"nN", do: :sqlexception
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"sS" and b2 in ~c"qQ" and b3 in ~c"lL" and b4 in ~c"sS" and b5 in ~c"tT" and b6 in ~c"aA" and
  b7 in ~c"tT" and b8 in ~c"eE", do: :sqlstate
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"sS" and b2 in ~c"qQ" and b3 in ~c"lL" and b4 in ~c"wW" and b5 in ~c"aA" and b6 in ~c"rR" and
  b7 in ~c"nN" and b8 in ~c"iI" and b9 in ~c"nN" and b10 in ~c"gG", do: :sqlwarning
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"sS" and b2 in ~c"qQ" and b3 in ~c"rR" and b4 in ~c"tT", do: :sqrt
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"sS" and b2 in ~c"tT" and b3 in ~c"aA" and b4 in ~c"rR" and b5 in ~c"tT", do: :start
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"sS" and b2 in ~c"tT" and b3 in ~c"aA" and b4 in ~c"tT" and b5 in ~c"iI" and b6 in ~c"cC", do: :static
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"sS" and b2 in ~c"tT" and b3 in ~c"dD" and b4 in ~c"dD" and b5 in ~c"eE" and b6 in ~c"vV" and
  b7 in ~c"_" and b8 in ~c"pP" and b9 in ~c"oO" and b10 in ~c"pP", do: :stddev_pop
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"sS" and b2 in ~c"tT" and b3 in ~c"dD" and b4 in ~c"dD" and b5 in ~c"eE" and b6 in ~c"vV" and
  b7 in ~c"_" and b8 in ~c"sS" and b9 in ~c"aA" and b10 in ~c"mM" and b11 in ~c"pP", do: :stddev_samp
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"sS" and b2 in ~c"uU" and b3 in ~c"bB" and b4 in ~c"mM" and b5 in ~c"uU" and b6 in ~c"lL" and
  b7 in ~c"tT" and b8 in ~c"iI" and b9 in ~c"sS" and b10 in ~c"eE" and b11 in ~c"tT", do: :submultiset
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"sS" and b2 in ~c"uU" and b3 in ~c"bB" and b4 in ~c"sS" and b5 in ~c"eE" and b6 in ~c"tT", do: :subset
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"sS" and b2 in ~c"uU" and b3 in ~c"bB" and b4 in ~c"sS" and b5 in ~c"tT" and b6 in ~c"rR" and
  b7 in ~c"iI" and b8 in ~c"nN" and b9 in ~c"gG", do: :substring
  
    def ident(:ident, [[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when b1 in ~c"sS" and b2 in ~c"uU" and b3 in ~c"bB" and b4 in ~c"sS" and b5 in ~c"tT" and b6 in ~c"rR" and
  b7 in ~c"iI" and b8 in ~c"nN" and b9 in ~c"gG" and b10 in ~c"_" and b11 in ~c"rR" and
  b12 in ~c"eE" and b13 in ~c"gG" and b14 in ~c"eE" and b15 in ~c"xX", do: :substring_regex
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"sS" and b2 in ~c"uU" and b3 in ~c"cC" and b4 in ~c"cC" and b5 in ~c"eE" and b6 in ~c"eE" and
  b7 in ~c"dD" and b8 in ~c"sS", do: :succeeds
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"sS" and b2 in ~c"uU" and b3 in ~c"mM", do: :sum
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"sS" and b2 in ~c"yY" and b3 in ~c"mM" and b4 in ~c"mM" and b5 in ~c"eE" and b6 in ~c"tT" and
  b7 in ~c"rR" and b8 in ~c"iI" and b9 in ~c"cC", do: :symmetric
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"sS" and b2 in ~c"yY" and b3 in ~c"sS" and b4 in ~c"tT" and b5 in ~c"eE" and b6 in ~c"mM", do: :system
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"sS" and b2 in ~c"yY" and b3 in ~c"sS" and b4 in ~c"tT" and b5 in ~c"eE" and b6 in ~c"mM" and
  b7 in ~c"_" and b8 in ~c"tT" and b9 in ~c"iI" and b10 in ~c"mM" and b11 in ~c"eE", do: :system_time
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"sS" and b2 in ~c"yY" and b3 in ~c"sS" and b4 in ~c"tT" and b5 in ~c"eE" and b6 in ~c"mM" and
  b7 in ~c"_" and b8 in ~c"uU" and b9 in ~c"sS" and b10 in ~c"eE" and b11 in ~c"rR", do: :system_user
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"tT" and b2 in ~c"aA" and b3 in ~c"bB" and b4 in ~c"lL" and b5 in ~c"eE", do: :table
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"tT" and b2 in ~c"aA" and b3 in ~c"bB" and b4 in ~c"lL" and b5 in ~c"eE" and b6 in ~c"sS" and
  b7 in ~c"aA" and b8 in ~c"mM" and b9 in ~c"pP" and b10 in ~c"lL" and b11 in ~c"eE", do: :tablesample
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"tT" and b2 in ~c"aA" and b3 in ~c"nN", do: :tan
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"tT" and b2 in ~c"aA" and b3 in ~c"nN" and b4 in ~c"hH", do: :tanh
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"tT" and b2 in ~c"hH" and b3 in ~c"eE" and b4 in ~c"nN", do: :then
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"tT" and b2 in ~c"iI" and b3 in ~c"mM" and b4 in ~c"eE", do: :time
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"tT" and b2 in ~c"iI" and b3 in ~c"mM" and b4 in ~c"eE" and b5 in ~c"sS" and b6 in ~c"tT" and
  b7 in ~c"aA" and b8 in ~c"mM" and b9 in ~c"pP", do: :timestamp
  
    def ident(:ident, [[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13]) when b1 in ~c"tT" and b2 in ~c"iI" and b3 in ~c"mM" and b4 in ~c"eE" and b5 in ~c"zZ" and b6 in ~c"oO" and
  b7 in ~c"nN" and b8 in ~c"eE" and b9 in ~c"_" and b10 in ~c"hH" and b11 in ~c"oO" and
  b12 in ~c"uU" and b13 in ~c"rR", do: :timezone_hour
  
    def ident(:ident, [[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when b1 in ~c"tT" and b2 in ~c"iI" and b3 in ~c"mM" and b4 in ~c"eE" and b5 in ~c"zZ" and b6 in ~c"oO" and
  b7 in ~c"nN" and b8 in ~c"eE" and b9 in ~c"_" and b10 in ~c"mM" and b11 in ~c"iI" and
  b12 in ~c"nN" and b13 in ~c"uU" and b14 in ~c"tT" and b15 in ~c"eE", do: :timezone_minute
  
    def ident(:ident, [[[], b1], b2]) when b1 in ~c"tT" and b2 in ~c"oO", do: :to
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"tT" and b2 in ~c"rR" and b3 in ~c"aA" and b4 in ~c"iI" and b5 in ~c"lL" and b6 in ~c"iI" and
  b7 in ~c"nN" and b8 in ~c"gG", do: :trailing
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"tT" and b2 in ~c"rR" and b3 in ~c"aA" and b4 in ~c"nN" and b5 in ~c"sS" and b6 in ~c"lL" and
  b7 in ~c"aA" and b8 in ~c"tT" and b9 in ~c"eE", do: :translate
  
    def ident(:ident, [[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when b1 in ~c"tT" and b2 in ~c"rR" and b3 in ~c"aA" and b4 in ~c"nN" and b5 in ~c"sS" and b6 in ~c"lL" and
  b7 in ~c"aA" and b8 in ~c"tT" and b9 in ~c"eE" and b10 in ~c"_" and b11 in ~c"rR" and
  b12 in ~c"eE" and b13 in ~c"gG" and b14 in ~c"eE" and b15 in ~c"xX", do: :translate_regex
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"tT" and b2 in ~c"rR" and b3 in ~c"aA" and b4 in ~c"nN" and b5 in ~c"sS" and b6 in ~c"lL" and
  b7 in ~c"aA" and b8 in ~c"tT" and b9 in ~c"iI" and b10 in ~c"oO" and b11 in ~c"nN", do: :translation
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"tT" and b2 in ~c"rR" and b3 in ~c"eE" and b4 in ~c"aA" and b5 in ~c"tT", do: :treat
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"tT" and b2 in ~c"rR" and b3 in ~c"iI" and b4 in ~c"gG" and b5 in ~c"gG" and b6 in ~c"eE" and
  b7 in ~c"rR", do: :trigger
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"tT" and b2 in ~c"rR" and b3 in ~c"iI" and b4 in ~c"mM", do: :trim
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"tT" and b2 in ~c"rR" and b3 in ~c"iI" and b4 in ~c"mM" and b5 in ~c"_" and b6 in ~c"aA" and
  b7 in ~c"rR" and b8 in ~c"rR" and b9 in ~c"aA" and b10 in ~c"yY", do: :trim_array
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"tT" and b2 in ~c"rR" and b3 in ~c"uU" and b4 in ~c"eE", do: true
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"tT" and b2 in ~c"rR" and b3 in ~c"uU" and b4 in ~c"nN" and b5 in ~c"cC" and b6 in ~c"aA" and
  b7 in ~c"tT" and b8 in ~c"eE", do: :truncate
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"uU" and b2 in ~c"eE" and b3 in ~c"sS" and b4 in ~c"cC" and b5 in ~c"aA" and b6 in ~c"pP" and
  b7 in ~c"eE", do: :uescape
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"uU" and b2 in ~c"nN" and b3 in ~c"iI" and b4 in ~c"oO" and b5 in ~c"nN", do: :union
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"uU" and b2 in ~c"nN" and b3 in ~c"iI" and b4 in ~c"qQ" and b5 in ~c"uU" and b6 in ~c"eE", do: :unique
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"uU" and b2 in ~c"nN" and b3 in ~c"kK" and b4 in ~c"nN" and b5 in ~c"oO" and b6 in ~c"wW" and
  b7 in ~c"nN", do: :unknown
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"uU" and b2 in ~c"nN" and b3 in ~c"nN" and b4 in ~c"eE" and b5 in ~c"sS" and b6 in ~c"tT", do: :unnest
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"uU" and b2 in ~c"pP" and b3 in ~c"dD" and b4 in ~c"aA" and b5 in ~c"tT" and b6 in ~c"eE", do: :update
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"uU" and b2 in ~c"pP" and b3 in ~c"pP" and b4 in ~c"eE" and b5 in ~c"rR", do: :upper
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"uU" and b2 in ~c"sS" and b3 in ~c"eE" and b4 in ~c"rR", do: :user
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"uU" and b2 in ~c"sS" and b3 in ~c"iI" and b4 in ~c"nN" and b5 in ~c"gG", do: :using
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"vV" and b2 in ~c"aA" and b3 in ~c"lL" and b4 in ~c"uU" and b5 in ~c"eE", do: :value
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"vV" and b2 in ~c"aA" and b3 in ~c"lL" and b4 in ~c"uU" and b5 in ~c"eE" and b6 in ~c"sS", do: :values
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"vV" and b2 in ~c"aA" and b3 in ~c"lL" and b4 in ~c"uU" and b5 in ~c"eE" and b6 in ~c"_" and
  b7 in ~c"oO" and b8 in ~c"fF", do: :value_of
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"vV" and b2 in ~c"aA" and b3 in ~c"rR" and b4 in ~c"_" and b5 in ~c"pP" and b6 in ~c"oO" and
  b7 in ~c"pP", do: :var_pop
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"vV" and b2 in ~c"aA" and b3 in ~c"rR" and b4 in ~c"_" and b5 in ~c"sS" and b6 in ~c"aA" and
  b7 in ~c"mM" and b8 in ~c"pP", do: :var_samp
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"vV" and b2 in ~c"aA" and b3 in ~c"rR" and b4 in ~c"bB" and b5 in ~c"iI" and b6 in ~c"nN" and
  b7 in ~c"aA" and b8 in ~c"rR" and b9 in ~c"yY", do: :varbinary
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"vV" and b2 in ~c"aA" and b3 in ~c"rR" and b4 in ~c"cC" and b5 in ~c"hH" and b6 in ~c"aA" and
  b7 in ~c"rR", do: :varchar
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"vV" and b2 in ~c"aA" and b3 in ~c"rR" and b4 in ~c"yY" and b5 in ~c"iI" and b6 in ~c"nN" and
  b7 in ~c"gG", do: :varying
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"vV" and b2 in ~c"eE" and b3 in ~c"rR" and b4 in ~c"sS" and b5 in ~c"iI" and b6 in ~c"oO" and
  b7 in ~c"nN" and b8 in ~c"iI" and b9 in ~c"nN" and b10 in ~c"gG", do: :versioning
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"wW" and b2 in ~c"hH" and b3 in ~c"eE" and b4 in ~c"nN", do: :when
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"wW" and b2 in ~c"hH" and b3 in ~c"eE" and b4 in ~c"nN" and b5 in ~c"eE" and b6 in ~c"vV" and
  b7 in ~c"eE" and b8 in ~c"rR", do: :whenever
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"wW" and b2 in ~c"hH" and b3 in ~c"eE" and b4 in ~c"rR" and b5 in ~c"eE", do: :where
  
    def ident(:ident, [[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when b1 in ~c"wW" and b2 in ~c"iI" and b3 in ~c"dD" and b4 in ~c"tT" and b5 in ~c"hH" and b6 in ~c"_" and
  b7 in ~c"bB" and b8 in ~c"uU" and b9 in ~c"cC" and b10 in ~c"kK" and b11 in ~c"eE" and
  b12 in ~c"tT", do: :width_bucket
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"wW" and b2 in ~c"iI" and b3 in ~c"nN" and b4 in ~c"dD" and b5 in ~c"oO" and b6 in ~c"wW", do: :window
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"wW" and b2 in ~c"iI" and b3 in ~c"tT" and b4 in ~c"hH", do: :with
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"wW" and b2 in ~c"iI" and b3 in ~c"tT" and b4 in ~c"hH" and b5 in ~c"iI" and b6 in ~c"nN", do: :within
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"wW" and b2 in ~c"iI" and b3 in ~c"tT" and b4 in ~c"hH" and b5 in ~c"oO" and b6 in ~c"uU" and
  b7 in ~c"tT", do: :without
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"yY" and b2 in ~c"eE" and b3 in ~c"aA" and b4 in ~c"rR", do: :year
  
    def ident(:ident, [[], b1]) when b1 in ~c"aA", do: :a
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"aA" and b2 in ~c"bB" and b3 in ~c"sS" and b4 in ~c"oO" and b5 in ~c"lL" and b6 in ~c"uU" and
  b7 in ~c"tT" and b8 in ~c"eE", do: :absolute
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"aA" and b2 in ~c"cC" and b3 in ~c"tT" and b4 in ~c"iI" and b5 in ~c"oO" and b6 in ~c"nN", do: :action
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"aA" and b2 in ~c"dD" and b3 in ~c"aA", do: :ada
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"aA" and b2 in ~c"dD" and b3 in ~c"dD", do: :add
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"aA" and b2 in ~c"dD" and b3 in ~c"mM" and b4 in ~c"iI" and b5 in ~c"nN", do: :admin
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"aA" and b2 in ~c"fF" and b3 in ~c"tT" and b4 in ~c"eE" and b5 in ~c"rR", do: :after
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"aA" and b2 in ~c"lL" and b3 in ~c"wW" and b4 in ~c"aA" and b5 in ~c"yY" and b6 in ~c"sS", do: :always
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"aA" and b2 in ~c"sS" and b3 in ~c"cC", do: :asc
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"aA" and b2 in ~c"sS" and b3 in ~c"sS" and b4 in ~c"eE" and b5 in ~c"rR" and b6 in ~c"tT" and
  b7 in ~c"iI" and b8 in ~c"oO" and b9 in ~c"nN", do: :assertion
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"aA" and b2 in ~c"sS" and b3 in ~c"sS" and b4 in ~c"iI" and b5 in ~c"gG" and b6 in ~c"nN" and
  b7 in ~c"mM" and b8 in ~c"eE" and b9 in ~c"nN" and b10 in ~c"tT", do: :assignment
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"aA" and b2 in ~c"tT" and b3 in ~c"tT" and b4 in ~c"rR" and b5 in ~c"iI" and b6 in ~c"bB" and
  b7 in ~c"uU" and b8 in ~c"tT" and b9 in ~c"eE", do: :attribute
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"aA" and b2 in ~c"tT" and b3 in ~c"tT" and b4 in ~c"rR" and b5 in ~c"iI" and b6 in ~c"bB" and
  b7 in ~c"uU" and b8 in ~c"tT" and b9 in ~c"eE" and b10 in ~c"sS", do: :attributes
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"bB" and b2 in ~c"eE" and b3 in ~c"fF" and b4 in ~c"oO" and b5 in ~c"rR" and b6 in ~c"eE", do: :before
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"bB" and b2 in ~c"eE" and b3 in ~c"rR" and b4 in ~c"nN" and b5 in ~c"oO" and b6 in ~c"uU" and
  b7 in ~c"lL" and b8 in ~c"lL" and b9 in ~c"iI", do: :bernoulli
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"bB" and b2 in ~c"rR" and b3 in ~c"eE" and b4 in ~c"aA" and b5 in ~c"dD" and b6 in ~c"tT" and
  b7 in ~c"hH", do: :breadth
  
    def ident(:ident, [[], b1]) when b1 in ~c"cC", do: :c
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"cC" and b2 in ~c"aA" and b3 in ~c"sS" and b4 in ~c"cC" and b5 in ~c"aA" and b6 in ~c"dD" and
  b7 in ~c"eE", do: :cascade
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"cC" and b2 in ~c"aA" and b3 in ~c"tT" and b4 in ~c"aA" and b5 in ~c"lL" and b6 in ~c"oO" and
  b7 in ~c"gG", do: :catalog
  
    def ident(:ident, [[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when b1 in ~c"cC" and b2 in ~c"aA" and b3 in ~c"tT" and b4 in ~c"aA" and b5 in ~c"lL" and b6 in ~c"oO" and
  b7 in ~c"gG" and b8 in ~c"_" and b9 in ~c"nN" and b10 in ~c"aA" and b11 in ~c"mM" and
  b12 in ~c"eE", do: :catalog_name
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"cC" and b2 in ~c"hH" and b3 in ~c"aA" and b4 in ~c"iI" and b5 in ~c"nN", do: :chain
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"cC" and b2 in ~c"hH" and b3 in ~c"aA" and b4 in ~c"iI" and b5 in ~c"nN" and b6 in ~c"iI" and
  b7 in ~c"nN" and b8 in ~c"gG", do: :chaining
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21]) when b1 in ~c"cC" and b2 in ~c"hH" and b3 in ~c"aA" and b4 in ~c"rR" and b5 in ~c"aA" and b6 in ~c"cC" and
  b7 in ~c"tT" and b8 in ~c"eE" and b9 in ~c"rR" and b10 in ~c"_" and b11 in ~c"sS" and
  b12 in ~c"eE" and b13 in ~c"tT" and b14 in ~c"_" and b15 in ~c"cC" and b16 in ~c"aA" and
  b17 in ~c"tT" and b18 in ~c"aA" and b19 in ~c"lL" and b20 in ~c"oO" and b21 in ~c"gG", do: :character_set_catalog
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18]) when b1 in ~c"cC" and b2 in ~c"hH" and b3 in ~c"aA" and b4 in ~c"rR" and b5 in ~c"aA" and b6 in ~c"cC" and
  b7 in ~c"tT" and b8 in ~c"eE" and b9 in ~c"rR" and b10 in ~c"_" and b11 in ~c"sS" and
  b12 in ~c"eE" and b13 in ~c"tT" and b14 in ~c"_" and b15 in ~c"nN" and b16 in ~c"aA" and
  b17 in ~c"mM" and b18 in ~c"eE", do: :character_set_name
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20]) when b1 in ~c"cC" and b2 in ~c"hH" and b3 in ~c"aA" and b4 in ~c"rR" and b5 in ~c"aA" and b6 in ~c"cC" and
  b7 in ~c"tT" and b8 in ~c"eE" and b9 in ~c"rR" and b10 in ~c"_" and b11 in ~c"sS" and
  b12 in ~c"eE" and b13 in ~c"tT" and b14 in ~c"_" and b15 in ~c"sS" and b16 in ~c"cC" and
  b17 in ~c"hH" and b18 in ~c"eE" and b19 in ~c"mM" and b20 in ~c"aA", do: :character_set_schema
  
    def ident(:ident, [[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when b1 in ~c"cC" and b2 in ~c"hH" and b3 in ~c"aA" and b4 in ~c"rR" and b5 in ~c"aA" and b6 in ~c"cC" and
  b7 in ~c"tT" and b8 in ~c"eE" and b9 in ~c"rR" and b10 in ~c"iI" and b11 in ~c"sS" and
  b12 in ~c"tT" and b13 in ~c"iI" and b14 in ~c"cC" and b15 in ~c"sS", do: :characteristics
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"cC" and b2 in ~c"hH" and b3 in ~c"aA" and b4 in ~c"rR" and b5 in ~c"aA" and b6 in ~c"cC" and
  b7 in ~c"tT" and b8 in ~c"eE" and b9 in ~c"rR" and b10 in ~c"sS", do: :characters
  
    def ident(:ident, [[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when b1 in ~c"cC" and b2 in ~c"lL" and b3 in ~c"aA" and b4 in ~c"sS" and b5 in ~c"sS" and b6 in ~c"_" and
  b7 in ~c"oO" and b8 in ~c"rR" and b9 in ~c"iI" and b10 in ~c"gG" and b11 in ~c"iI" and
  b12 in ~c"nN", do: :class_origin
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"bB" and b4 in ~c"oO" and b5 in ~c"lL", do: :cobol
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"lL" and b4 in ~c"lL" and b5 in ~c"aA" and b6 in ~c"tT" and
  b7 in ~c"iI" and b8 in ~c"oO" and b9 in ~c"nN", do: :collation
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"lL" and b4 in ~c"lL" and b5 in ~c"aA" and b6 in ~c"tT" and
  b7 in ~c"iI" and b8 in ~c"oO" and b9 in ~c"nN" and b10 in ~c"_" and b11 in ~c"cC" and
  b12 in ~c"aA" and b13 in ~c"tT" and b14 in ~c"aA" and b15 in ~c"lL" and b16 in ~c"oO" and
  b17 in ~c"gG", do: :collation_catalog
  
    def ident(:ident, [[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"lL" and b4 in ~c"lL" and b5 in ~c"aA" and b6 in ~c"tT" and
  b7 in ~c"iI" and b8 in ~c"oO" and b9 in ~c"nN" and b10 in ~c"_" and b11 in ~c"nN" and
  b12 in ~c"aA" and b13 in ~c"mM" and b14 in ~c"eE", do: :collation_name
  
    def ident(:ident, [[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"lL" and b4 in ~c"lL" and b5 in ~c"aA" and b6 in ~c"tT" and
  b7 in ~c"iI" and b8 in ~c"oO" and b9 in ~c"nN" and b10 in ~c"_" and b11 in ~c"sS" and
  b12 in ~c"cC" and b13 in ~c"hH" and b14 in ~c"eE" and b15 in ~c"mM" and b16 in ~c"aA", do: :collation_schema
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"lL" and b4 in ~c"uU" and b5 in ~c"mM" and b6 in ~c"nN" and
  b7 in ~c"sS", do: :columns
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"lL" and b4 in ~c"uU" and b5 in ~c"mM" and b6 in ~c"nN" and
  b7 in ~c"_" and b8 in ~c"nN" and b9 in ~c"aA" and b10 in ~c"mM" and b11 in ~c"eE", do: :column_name
  
    def ident(:ident, [[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"mM" and b4 in ~c"mM" and b5 in ~c"aA" and b6 in ~c"nN" and
  b7 in ~c"dD" and b8 in ~c"_" and b9 in ~c"fF" and b10 in ~c"uU" and b11 in ~c"nN" and
  b12 in ~c"cC" and b13 in ~c"tT" and b14 in ~c"iI" and b15 in ~c"oO" and b16 in ~c"nN", do: :command_function
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"mM" and b4 in ~c"mM" and b5 in ~c"aA" and b6 in ~c"nN" and
  b7 in ~c"dD" and b8 in ~c"_" and b9 in ~c"fF" and b10 in ~c"uU" and b11 in ~c"nN" and
  b12 in ~c"cC" and b13 in ~c"tT" and b14 in ~c"iI" and b15 in ~c"oO" and b16 in ~c"nN" and
  b17 in ~c"_" and b18 in ~c"cC" and b19 in ~c"oO" and b20 in ~c"dD" and b21 in ~c"eE", do: :command_function_code
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"mM" and b4 in ~c"mM" and b5 in ~c"iI" and b6 in ~c"tT" and
  b7 in ~c"tT" and b8 in ~c"eE" and b9 in ~c"dD", do: :committed
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"nN" and b4 in ~c"dD" and b5 in ~c"iI" and b6 in ~c"tT" and
  b7 in ~c"iI" and b8 in ~c"oO" and b9 in ~c"nN" and b10 in ~c"aA" and b11 in ~c"lL", do: :conditional
  
    def ident(:ident, [[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"nN" and b4 in ~c"dD" and b5 in ~c"iI" and b6 in ~c"tT" and
  b7 in ~c"iI" and b8 in ~c"oO" and b9 in ~c"nN" and b10 in ~c"_" and b11 in ~c"nN" and
  b12 in ~c"uU" and b13 in ~c"mM" and b14 in ~c"bB" and b15 in ~c"eE" and b16 in ~c"rR", do: :condition_number
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"nN" and b4 in ~c"nN" and b5 in ~c"eE" and b6 in ~c"cC" and
  b7 in ~c"tT" and b8 in ~c"iI" and b9 in ~c"oO" and b10 in ~c"nN", do: :connection
  
    def ident(:ident, [[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"nN" and b4 in ~c"nN" and b5 in ~c"eE" and b6 in ~c"cC" and
  b7 in ~c"tT" and b8 in ~c"iI" and b9 in ~c"oO" and b10 in ~c"nN" and b11 in ~c"_" and
  b12 in ~c"nN" and b13 in ~c"aA" and b14 in ~c"mM" and b15 in ~c"eE", do: :connection_name
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"nN" and b4 in ~c"sS" and b5 in ~c"tT" and b6 in ~c"rR" and
  b7 in ~c"aA" and b8 in ~c"iI" and b9 in ~c"nN" and b10 in ~c"tT" and b11 in ~c"_" and
  b12 in ~c"cC" and b13 in ~c"aA" and b14 in ~c"tT" and b15 in ~c"aA" and b16 in ~c"lL" and
  b17 in ~c"oO" and b18 in ~c"gG", do: :constraint_catalog
  
    def ident(:ident, [[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"nN" and b4 in ~c"sS" and b5 in ~c"tT" and b6 in ~c"rR" and
  b7 in ~c"aA" and b8 in ~c"iI" and b9 in ~c"nN" and b10 in ~c"tT" and b11 in ~c"_" and
  b12 in ~c"nN" and b13 in ~c"aA" and b14 in ~c"mM" and b15 in ~c"eE", do: :constraint_name
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"nN" and b4 in ~c"sS" and b5 in ~c"tT" and b6 in ~c"rR" and
  b7 in ~c"aA" and b8 in ~c"iI" and b9 in ~c"nN" and b10 in ~c"tT" and b11 in ~c"_" and
  b12 in ~c"sS" and b13 in ~c"cC" and b14 in ~c"hH" and b15 in ~c"eE" and b16 in ~c"mM" and
  b17 in ~c"aA", do: :constraint_schema
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"nN" and b4 in ~c"sS" and b5 in ~c"tT" and b6 in ~c"rR" and
  b7 in ~c"aA" and b8 in ~c"iI" and b9 in ~c"nN" and b10 in ~c"tT" and b11 in ~c"sS", do: :constraints
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"nN" and b4 in ~c"sS" and b5 in ~c"tT" and b6 in ~c"rR" and
  b7 in ~c"uU" and b8 in ~c"cC" and b9 in ~c"tT" and b10 in ~c"oO" and b11 in ~c"rR", do: :constructor
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"nN" and b4 in ~c"tT" and b5 in ~c"iI" and b6 in ~c"nN" and
  b7 in ~c"uU" and b8 in ~c"eE", do: :continue
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"cC" and b2 in ~c"oO" and b3 in ~c"pP" and b4 in ~c"aA" and b5 in ~c"rR" and b6 in ~c"tT" and
  b7 in ~c"iI" and b8 in ~c"tT" and b9 in ~c"iI" and b10 in ~c"oO" and b11 in ~c"nN", do: :copartition
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"cC" and b2 in ~c"uU" and b3 in ~c"rR" and b4 in ~c"sS" and b5 in ~c"oO" and b6 in ~c"rR" and
  b7 in ~c"_" and b8 in ~c"nN" and b9 in ~c"aA" and b10 in ~c"mM" and b11 in ~c"eE", do: :cursor_name
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"dD" and b2 in ~c"aA" and b3 in ~c"tT" and b4 in ~c"aA", do: :data
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22]) when b1 in ~c"dD" and b2 in ~c"aA" and b3 in ~c"tT" and b4 in ~c"eE" and b5 in ~c"tT" and b6 in ~c"iI" and
  b7 in ~c"mM" and b8 in ~c"eE" and b9 in ~c"_" and b10 in ~c"iI" and b11 in ~c"nN" and
  b12 in ~c"tT" and b13 in ~c"eE" and b14 in ~c"rR" and b15 in ~c"vV" and b16 in ~c"aA" and
  b17 in ~c"lL" and b18 in ~c"_" and b19 in ~c"cC" and b20 in ~c"oO" and b21 in ~c"dD" and
  b22 in ~c"eE", do: :datetime_interval_code
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22], b23], b24], b25], b26], b27]) when b1 in ~c"dD" and b2 in ~c"aA" and b3 in ~c"tT" and b4 in ~c"eE" and b5 in ~c"tT" and b6 in ~c"iI" and
  b7 in ~c"mM" and b8 in ~c"eE" and b9 in ~c"_" and b10 in ~c"iI" and b11 in ~c"nN" and
  b12 in ~c"tT" and b13 in ~c"eE" and b14 in ~c"rR" and b15 in ~c"vV" and b16 in ~c"aA" and
  b17 in ~c"lL" and b18 in ~c"_" and b19 in ~c"pP" and b20 in ~c"rR" and b21 in ~c"eE" and
  b22 in ~c"cC" and b23 in ~c"iI" and b24 in ~c"sS" and b25 in ~c"iI" and b26 in ~c"oO" and
  b27 in ~c"nN", do: :datetime_interval_precision
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"dD" and b2 in ~c"eE" and b3 in ~c"fF" and b4 in ~c"aA" and b5 in ~c"uU" and b6 in ~c"lL" and
  b7 in ~c"tT" and b8 in ~c"sS", do: :defaults
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"dD" and b2 in ~c"eE" and b3 in ~c"fF" and b4 in ~c"eE" and b5 in ~c"rR" and b6 in ~c"rR" and
  b7 in ~c"aA" and b8 in ~c"bB" and b9 in ~c"lL" and b10 in ~c"eE", do: :deferrable
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"dD" and b2 in ~c"eE" and b3 in ~c"fF" and b4 in ~c"eE" and b5 in ~c"rR" and b6 in ~c"rR" and
  b7 in ~c"eE" and b8 in ~c"dD", do: :deferred
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"dD" and b2 in ~c"eE" and b3 in ~c"fF" and b4 in ~c"iI" and b5 in ~c"nN" and b6 in ~c"eE" and
  b7 in ~c"dD", do: :defined
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"dD" and b2 in ~c"eE" and b3 in ~c"fF" and b4 in ~c"iI" and b5 in ~c"nN" and b6 in ~c"eE" and
  b7 in ~c"rR", do: :definer
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"dD" and b2 in ~c"eE" and b3 in ~c"gG" and b4 in ~c"rR" and b5 in ~c"eE" and b6 in ~c"eE", do: :degree
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"dD" and b2 in ~c"eE" and b3 in ~c"pP" and b4 in ~c"tT" and b5 in ~c"hH", do: :depth
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"dD" and b2 in ~c"eE" and b3 in ~c"rR" and b4 in ~c"iI" and b5 in ~c"vV" and b6 in ~c"eE" and
  b7 in ~c"dD", do: :derived
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"dD" and b2 in ~c"eE" and b3 in ~c"sS" and b4 in ~c"cC", do: :desc
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"dD" and b2 in ~c"eE" and b3 in ~c"sS" and b4 in ~c"cC" and b5 in ~c"rR" and b6 in ~c"iI" and
  b7 in ~c"pP" and b8 in ~c"tT" and b9 in ~c"oO" and b10 in ~c"rR", do: :descriptor
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"dD" and b2 in ~c"iI" and b3 in ~c"aA" and b4 in ~c"gG" and b5 in ~c"nN" and b6 in ~c"oO" and
  b7 in ~c"sS" and b8 in ~c"tT" and b9 in ~c"iI" and b10 in ~c"cC" and b11 in ~c"sS", do: :diagnostics
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"dD" and b2 in ~c"iI" and b3 in ~c"sS" and b4 in ~c"pP" and b5 in ~c"aA" and b6 in ~c"tT" and
  b7 in ~c"cC" and b8 in ~c"hH", do: :dispatch
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"dD" and b2 in ~c"oO" and b3 in ~c"mM" and b4 in ~c"aA" and b5 in ~c"iI" and b6 in ~c"nN", do: :domain
  
    def ident(:ident, [[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16]) when b1 in ~c"dD" and b2 in ~c"yY" and b3 in ~c"nN" and b4 in ~c"aA" and b5 in ~c"mM" and b6 in ~c"iI" and
  b7 in ~c"cC" and b8 in ~c"_" and b9 in ~c"fF" and b10 in ~c"uU" and b11 in ~c"nN" and
  b12 in ~c"cC" and b13 in ~c"tT" and b14 in ~c"iI" and b15 in ~c"oO" and b16 in ~c"nN", do: :dynamic_function
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21]) when b1 in ~c"dD" and b2 in ~c"yY" and b3 in ~c"nN" and b4 in ~c"aA" and b5 in ~c"mM" and b6 in ~c"iI" and
  b7 in ~c"cC" and b8 in ~c"_" and b9 in ~c"fF" and b10 in ~c"uU" and b11 in ~c"nN" and
  b12 in ~c"cC" and b13 in ~c"tT" and b14 in ~c"iI" and b15 in ~c"oO" and b16 in ~c"nN" and
  b17 in ~c"_" and b18 in ~c"cC" and b19 in ~c"oO" and b20 in ~c"dD" and b21 in ~c"eE", do: :dynamic_function_code
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"eE" and b2 in ~c"nN" and b3 in ~c"cC" and b4 in ~c"oO" and b5 in ~c"dD" and b6 in ~c"iI" and
  b7 in ~c"nN" and b8 in ~c"gG", do: :encoding
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"eE" and b2 in ~c"nN" and b3 in ~c"fF" and b4 in ~c"oO" and b5 in ~c"rR" and b6 in ~c"cC" and
  b7 in ~c"eE" and b8 in ~c"dD", do: :enforced
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"eE" and b2 in ~c"rR" and b3 in ~c"rR" and b4 in ~c"oO" and b5 in ~c"rR", do: :error
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"eE" and b2 in ~c"xX" and b3 in ~c"cC" and b4 in ~c"lL" and b5 in ~c"uU" and b6 in ~c"dD" and
  b7 in ~c"eE", do: :exclude
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"eE" and b2 in ~c"xX" and b3 in ~c"cC" and b4 in ~c"lL" and b5 in ~c"uU" and b6 in ~c"dD" and
  b7 in ~c"iI" and b8 in ~c"nN" and b9 in ~c"gG", do: :excluding
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"eE" and b2 in ~c"xX" and b3 in ~c"pP" and b4 in ~c"rR" and b5 in ~c"eE" and b6 in ~c"sS" and
  b7 in ~c"sS" and b8 in ~c"iI" and b9 in ~c"oO" and b10 in ~c"nN", do: :expression
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"fF" and b2 in ~c"iI" and b3 in ~c"nN" and b4 in ~c"aA" and b5 in ~c"lL", do: :final
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"fF" and b2 in ~c"iI" and b3 in ~c"nN" and b4 in ~c"iI" and b5 in ~c"sS" and b6 in ~c"hH", do: :finish
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"fF" and b2 in ~c"iI" and b3 in ~c"rR" and b4 in ~c"sS" and b5 in ~c"tT", do: :first
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"fF" and b2 in ~c"lL" and b3 in ~c"aA" and b4 in ~c"gG", do: :flag
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"fF" and b2 in ~c"oO" and b3 in ~c"lL" and b4 in ~c"lL" and b5 in ~c"oO" and b6 in ~c"wW" and
  b7 in ~c"iI" and b8 in ~c"nN" and b9 in ~c"gG", do: :following
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"fF" and b2 in ~c"oO" and b3 in ~c"rR" and b4 in ~c"mM" and b5 in ~c"aA" and b6 in ~c"tT", do: :format
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"fF" and b2 in ~c"oO" and b3 in ~c"rR" and b4 in ~c"tT" and b5 in ~c"rR" and b6 in ~c"aA" and
  b7 in ~c"nN", do: :fortran
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"fF" and b2 in ~c"oO" and b3 in ~c"uU" and b4 in ~c"nN" and b5 in ~c"dD", do: :found
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"fF" and b2 in ~c"uU" and b3 in ~c"lL" and b4 in ~c"fF" and b5 in ~c"iI" and b6 in ~c"lL" and
  b7 in ~c"lL", do: :fulfill
  
    def ident(:ident, [[], b1]) when b1 in ~c"gG", do: :g
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"gG" and b2 in ~c"eE" and b3 in ~c"nN" and b4 in ~c"eE" and b5 in ~c"rR" and b6 in ~c"aA" and
  b7 in ~c"lL", do: :general
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"gG" and b2 in ~c"eE" and b3 in ~c"nN" and b4 in ~c"eE" and b5 in ~c"rR" and b6 in ~c"aA" and
  b7 in ~c"tT" and b8 in ~c"eE" and b9 in ~c"dD", do: :generated
  
    def ident(:ident, [[[], b1], b2]) when b1 in ~c"gG" and b2 in ~c"oO", do: :go
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"gG" and b2 in ~c"oO" and b3 in ~c"tT" and b4 in ~c"oO", do: :goto
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"gG" and b2 in ~c"rR" and b3 in ~c"aA" and b4 in ~c"nN" and b5 in ~c"tT" and b6 in ~c"eE" and
  b7 in ~c"dD", do: :granted
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"hH" and b2 in ~c"iI" and b3 in ~c"eE" and b4 in ~c"rR" and b5 in ~c"aA" and b6 in ~c"rR" and
  b7 in ~c"cC" and b8 in ~c"hH" and b9 in ~c"yY", do: :hierarchy
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"iI" and b2 in ~c"gG" and b3 in ~c"nN" and b4 in ~c"oO" and b5 in ~c"rR" and b6 in ~c"eE", do: :ignore
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"iI" and b2 in ~c"mM" and b3 in ~c"mM" and b4 in ~c"eE" and b5 in ~c"dD" and b6 in ~c"iI" and
  b7 in ~c"aA" and b8 in ~c"tT" and b9 in ~c"eE", do: :immediate
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"iI" and b2 in ~c"mM" and b3 in ~c"mM" and b4 in ~c"eE" and b5 in ~c"dD" and b6 in ~c"iI" and
  b7 in ~c"aA" and b8 in ~c"tT" and b9 in ~c"eE" and b10 in ~c"lL" and b11 in ~c"yY", do: :immediately
  
    def ident(:ident, [[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when b1 in ~c"iI" and b2 in ~c"mM" and b3 in ~c"pP" and b4 in ~c"lL" and b5 in ~c"eE" and b6 in ~c"mM" and
  b7 in ~c"eE" and b8 in ~c"nN" and b9 in ~c"tT" and b10 in ~c"aA" and b11 in ~c"tT" and
  b12 in ~c"iI" and b13 in ~c"oO" and b14 in ~c"nN", do: :implementation
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"iI" and b2 in ~c"nN" and b3 in ~c"cC" and b4 in ~c"lL" and b5 in ~c"uU" and b6 in ~c"dD" and
  b7 in ~c"iI" and b8 in ~c"nN" and b9 in ~c"gG", do: :including
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"iI" and b2 in ~c"nN" and b3 in ~c"cC" and b4 in ~c"rR" and b5 in ~c"eE" and b6 in ~c"mM" and
  b7 in ~c"eE" and b8 in ~c"nN" and b9 in ~c"tT", do: :increment
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"iI" and b2 in ~c"nN" and b3 in ~c"iI" and b4 in ~c"tT" and b5 in ~c"iI" and b6 in ~c"aA" and
  b7 in ~c"lL" and b8 in ~c"lL" and b9 in ~c"yY", do: :initially
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"iI" and b2 in ~c"nN" and b3 in ~c"pP" and b4 in ~c"uU" and b5 in ~c"tT", do: :input
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"iI" and b2 in ~c"nN" and b3 in ~c"sS" and b4 in ~c"tT" and b5 in ~c"aA" and b6 in ~c"nN" and
  b7 in ~c"cC" and b8 in ~c"eE", do: :instance
  
    def ident(:ident, [[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when b1 in ~c"iI" and b2 in ~c"nN" and b3 in ~c"sS" and b4 in ~c"tT" and b5 in ~c"aA" and b6 in ~c"nN" and
  b7 in ~c"tT" and b8 in ~c"iI" and b9 in ~c"aA" and b10 in ~c"bB" and b11 in ~c"lL" and
  b12 in ~c"eE", do: :instantiable
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"iI" and b2 in ~c"nN" and b3 in ~c"sS" and b4 in ~c"tT" and b5 in ~c"eE" and b6 in ~c"aA" and
  b7 in ~c"dD", do: :instead
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"iI" and b2 in ~c"nN" and b3 in ~c"vV" and b4 in ~c"oO" and b5 in ~c"kK" and b6 in ~c"eE" and
  b7 in ~c"rR", do: :invoker
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"iI" and b2 in ~c"sS" and b3 in ~c"oO" and b4 in ~c"lL" and b5 in ~c"aA" and b6 in ~c"tT" and
  b7 in ~c"iI" and b8 in ~c"oO" and b9 in ~c"nN", do: :isolation
  
    def ident(:ident, [[], b1]) when b1 in ~c"kK", do: :k
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"kK" and b2 in ~c"eE" and b3 in ~c"eE" and b4 in ~c"pP", do: :keep
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"kK" and b2 in ~c"eE" and b3 in ~c"yY", do: :key
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"kK" and b2 in ~c"eE" and b3 in ~c"yY" and b4 in ~c"sS", do: :keys
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"kK" and b2 in ~c"eE" and b3 in ~c"yY" and b4 in ~c"_" and b5 in ~c"mM" and b6 in ~c"eE" and
  b7 in ~c"mM" and b8 in ~c"bB" and b9 in ~c"eE" and b10 in ~c"rR", do: :key_member
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"kK" and b2 in ~c"eE" and b3 in ~c"yY" and b4 in ~c"_" and b5 in ~c"tT" and b6 in ~c"yY" and
  b7 in ~c"pP" and b8 in ~c"eE", do: :key_type
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"lL" and b2 in ~c"aA" and b3 in ~c"sS" and b4 in ~c"tT", do: :last
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"lL" and b2 in ~c"eE" and b3 in ~c"nN" and b4 in ~c"gG" and b5 in ~c"tT" and b6 in ~c"hH", do: :length
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"lL" and b2 in ~c"eE" and b3 in ~c"vV" and b4 in ~c"eE" and b5 in ~c"lL", do: :level
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"lL" and b2 in ~c"oO" and b3 in ~c"cC" and b4 in ~c"aA" and b5 in ~c"tT" and b6 in ~c"oO" and
  b7 in ~c"rR", do: :locator
  
    def ident(:ident, [[], b1]) when b1 in ~c"mM", do: :m
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"mM" and b2 in ~c"aA" and b3 in ~c"pP", do: :map
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"mM" and b2 in ~c"aA" and b3 in ~c"tT" and b4 in ~c"cC" and b5 in ~c"hH" and b6 in ~c"eE" and
  b7 in ~c"dD", do: :matched
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"mM" and b2 in ~c"aA" and b3 in ~c"xX" and b4 in ~c"vV" and b5 in ~c"aA" and b6 in ~c"lL" and
  b7 in ~c"uU" and b8 in ~c"eE", do: :maxvalue
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"mM" and b2 in ~c"eE" and b3 in ~c"aA" and b4 in ~c"sS" and b5 in ~c"uU" and b6 in ~c"rR" and
  b7 in ~c"eE" and b8 in ~c"sS", do: :measures
  
    def ident(:ident, [[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when b1 in ~c"mM" and b2 in ~c"eE" and b3 in ~c"sS" and b4 in ~c"sS" and b5 in ~c"aA" and b6 in ~c"gG" and
  b7 in ~c"eE" and b8 in ~c"_" and b9 in ~c"lL" and b10 in ~c"eE" and b11 in ~c"nN" and
  b12 in ~c"gG" and b13 in ~c"tT" and b14 in ~c"hH", do: :message_length
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20]) when b1 in ~c"mM" and b2 in ~c"eE" and b3 in ~c"sS" and b4 in ~c"sS" and b5 in ~c"aA" and b6 in ~c"gG" and
  b7 in ~c"eE" and b8 in ~c"_" and b9 in ~c"oO" and b10 in ~c"cC" and b11 in ~c"tT" and
  b12 in ~c"eE" and b13 in ~c"tT" and b14 in ~c"_" and b15 in ~c"lL" and b16 in ~c"eE" and
  b17 in ~c"nN" and b18 in ~c"gG" and b19 in ~c"tT" and b20 in ~c"hH", do: :message_octet_length
  
    def ident(:ident, [[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when b1 in ~c"mM" and b2 in ~c"eE" and b3 in ~c"sS" and b4 in ~c"sS" and b5 in ~c"aA" and b6 in ~c"gG" and
  b7 in ~c"eE" and b8 in ~c"_" and b9 in ~c"tT" and b10 in ~c"eE" and b11 in ~c"xX" and
  b12 in ~c"tT", do: :message_text
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"mM" and b2 in ~c"iI" and b3 in ~c"nN" and b4 in ~c"vV" and b5 in ~c"aA" and b6 in ~c"lL" and
  b7 in ~c"uU" and b8 in ~c"eE", do: :minvalue
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"mM" and b2 in ~c"oO" and b3 in ~c"rR" and b4 in ~c"eE", do: :more
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"mM" and b2 in ~c"uU" and b3 in ~c"mM" and b4 in ~c"pP" and b5 in ~c"sS", do: :mumps
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"nN" and b2 in ~c"aA" and b3 in ~c"mM" and b4 in ~c"eE", do: :name
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"nN" and b2 in ~c"aA" and b3 in ~c"mM" and b4 in ~c"eE" and b5 in ~c"sS", do: :names
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"nN" and b2 in ~c"eE" and b3 in ~c"sS" and b4 in ~c"tT" and b5 in ~c"eE" and b6 in ~c"dD", do: :nested
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"nN" and b2 in ~c"eE" and b3 in ~c"sS" and b4 in ~c"tT" and b5 in ~c"iI" and b6 in ~c"nN" and
  b7 in ~c"gG", do: :nesting
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"nN" and b2 in ~c"eE" and b3 in ~c"xX" and b4 in ~c"tT", do: :next
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"nN" and b2 in ~c"fF" and b3 in ~c"cC", do: :nfc
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"nN" and b2 in ~c"fF" and b3 in ~c"dD", do: :nfd
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"nN" and b2 in ~c"fF" and b3 in ~c"kK" and b4 in ~c"cC", do: :nfkc
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"nN" and b2 in ~c"fF" and b3 in ~c"kK" and b4 in ~c"dD", do: :nfkd
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"nN" and b2 in ~c"oO" and b3 in ~c"rR" and b4 in ~c"mM" and b5 in ~c"aA" and b6 in ~c"lL" and
  b7 in ~c"iI" and b8 in ~c"zZ" and b9 in ~c"eE" and b10 in ~c"dD", do: :normalized
  
    def ident(:ident, [[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13]) when b1 in ~c"nN" and b2 in ~c"uU" and b3 in ~c"lL" and b4 in ~c"lL" and b5 in ~c"_" and b6 in ~c"oO" and
  b7 in ~c"rR" and b8 in ~c"dD" and b9 in ~c"eE" and b10 in ~c"rR" and b11 in ~c"iI" and
  b12 in ~c"nN" and b13 in ~c"gG", do: :null_ordering
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"nN" and b2 in ~c"uU" and b3 in ~c"lL" and b4 in ~c"lL" and b5 in ~c"aA" and b6 in ~c"bB" and
  b7 in ~c"lL" and b8 in ~c"eE", do: :nullable
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"nN" and b2 in ~c"uU" and b3 in ~c"lL" and b4 in ~c"lL" and b5 in ~c"sS", do: :nulls
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"nN" and b2 in ~c"uU" and b3 in ~c"mM" and b4 in ~c"bB" and b5 in ~c"eE" and b6 in ~c"rR", do: :number
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"oO" and b2 in ~c"bB" and b3 in ~c"jJ" and b4 in ~c"eE" and b5 in ~c"cC" and b6 in ~c"tT", do: :object
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"oO" and b2 in ~c"cC" and b3 in ~c"cC" and b4 in ~c"uU" and b5 in ~c"rR" and b6 in ~c"rR" and
  b7 in ~c"eE" and b8 in ~c"nN" and b9 in ~c"cC" and b10 in ~c"eE", do: :occurrence
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"oO" and b2 in ~c"cC" and b3 in ~c"tT" and b4 in ~c"eE" and b5 in ~c"tT" and b6 in ~c"sS", do: :octets
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"oO" and b2 in ~c"pP" and b3 in ~c"tT" and b4 in ~c"iI" and b5 in ~c"oO" and b6 in ~c"nN", do: :option
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"oO" and b2 in ~c"pP" and b3 in ~c"tT" and b4 in ~c"iI" and b5 in ~c"oO" and b6 in ~c"nN" and
  b7 in ~c"sS", do: :options
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"oO" and b2 in ~c"rR" and b3 in ~c"dD" and b4 in ~c"eE" and b5 in ~c"rR" and b6 in ~c"iI" and
  b7 in ~c"nN" and b8 in ~c"gG", do: :ordering
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"oO" and b2 in ~c"rR" and b3 in ~c"dD" and b4 in ~c"iI" and b5 in ~c"nN" and b6 in ~c"aA" and
  b7 in ~c"lL" and b8 in ~c"iI" and b9 in ~c"tT" and b10 in ~c"yY", do: :ordinality
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"oO" and b2 in ~c"tT" and b3 in ~c"hH" and b4 in ~c"eE" and b5 in ~c"rR" and b6 in ~c"sS", do: :others
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"oO" and b2 in ~c"uU" and b3 in ~c"tT" and b4 in ~c"pP" and b5 in ~c"uU" and b6 in ~c"tT", do: :output
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"oO" and b2 in ~c"vV" and b3 in ~c"eE" and b4 in ~c"rR" and b5 in ~c"fF" and b6 in ~c"lL" and
  b7 in ~c"oO" and b8 in ~c"wW", do: :overflow
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"oO" and b2 in ~c"vV" and b3 in ~c"eE" and b4 in ~c"rR" and b5 in ~c"rR" and b6 in ~c"iI" and
  b7 in ~c"dD" and b8 in ~c"iI" and b9 in ~c"nN" and b10 in ~c"gG", do: :overriding
  
    def ident(:ident, [[], b1]) when b1 in ~c"pP", do: :p
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"pP" and b2 in ~c"aA" and b3 in ~c"dD", do: :pad
  
    def ident(:ident, [[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when b1 in ~c"pP" and b2 in ~c"aA" and b3 in ~c"rR" and b4 in ~c"aA" and b5 in ~c"mM" and b6 in ~c"eE" and
  b7 in ~c"tT" and b8 in ~c"eE" and b9 in ~c"rR" and b10 in ~c"_" and b11 in ~c"mM" and
  b12 in ~c"oO" and b13 in ~c"dD" and b14 in ~c"eE", do: :parameter_mode
  
    def ident(:ident, [[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when b1 in ~c"pP" and b2 in ~c"aA" and b3 in ~c"rR" and b4 in ~c"aA" and b5 in ~c"mM" and b6 in ~c"eE" and
  b7 in ~c"tT" and b8 in ~c"eE" and b9 in ~c"rR" and b10 in ~c"_" and b11 in ~c"nN" and
  b12 in ~c"aA" and b13 in ~c"mM" and b14 in ~c"eE", do: :parameter_name
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22], b23], b24], b25], b26]) when b1 in ~c"pP" and b2 in ~c"aA" and b3 in ~c"rR" and b4 in ~c"aA" and b5 in ~c"mM" and b6 in ~c"eE" and
  b7 in ~c"tT" and b8 in ~c"eE" and b9 in ~c"rR" and b10 in ~c"_" and b11 in ~c"oO" and
  b12 in ~c"rR" and b13 in ~c"dD" and b14 in ~c"iI" and b15 in ~c"nN" and b16 in ~c"aA" and
  b17 in ~c"lL" and b18 in ~c"_" and b19 in ~c"pP" and b20 in ~c"oO" and b21 in ~c"sS" and
  b22 in ~c"iI" and b23 in ~c"tT" and b24 in ~c"iI" and b25 in ~c"oO" and b26 in ~c"nN", do: :parameter_ordinal_position
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22], b23], b24], b25], b26]) when b1 in ~c"pP" and b2 in ~c"aA" and b3 in ~c"rR" and b4 in ~c"aA" and b5 in ~c"mM" and b6 in ~c"eE" and
  b7 in ~c"tT" and b8 in ~c"eE" and b9 in ~c"rR" and b10 in ~c"_" and b11 in ~c"sS" and
  b12 in ~c"pP" and b13 in ~c"eE" and b14 in ~c"cC" and b15 in ~c"iI" and b16 in ~c"fF" and
  b17 in ~c"iI" and b18 in ~c"cC" and b19 in ~c"_" and b20 in ~c"cC" and b21 in ~c"aA" and
  b22 in ~c"tT" and b23 in ~c"aA" and b24 in ~c"lL" and b25 in ~c"oO" and b26 in ~c"gG", do: :parameter_specific_catalog
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22], b23]) when b1 in ~c"pP" and b2 in ~c"aA" and b3 in ~c"rR" and b4 in ~c"aA" and b5 in ~c"mM" and b6 in ~c"eE" and
  b7 in ~c"tT" and b8 in ~c"eE" and b9 in ~c"rR" and b10 in ~c"_" and b11 in ~c"sS" and
  b12 in ~c"pP" and b13 in ~c"eE" and b14 in ~c"cC" and b15 in ~c"iI" and b16 in ~c"fF" and
  b17 in ~c"iI" and b18 in ~c"cC" and b19 in ~c"_" and b20 in ~c"nN" and b21 in ~c"aA" and
  b22 in ~c"mM" and b23 in ~c"eE", do: :parameter_specific_name
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22], b23], b24], b25]) when b1 in ~c"pP" and b2 in ~c"aA" and b3 in ~c"rR" and b4 in ~c"aA" and b5 in ~c"mM" and b6 in ~c"eE" and
  b7 in ~c"tT" and b8 in ~c"eE" and b9 in ~c"rR" and b10 in ~c"_" and b11 in ~c"sS" and
  b12 in ~c"pP" and b13 in ~c"eE" and b14 in ~c"cC" and b15 in ~c"iI" and b16 in ~c"fF" and
  b17 in ~c"iI" and b18 in ~c"cC" and b19 in ~c"_" and b20 in ~c"sS" and b21 in ~c"cC" and
  b22 in ~c"hH" and b23 in ~c"eE" and b24 in ~c"mM" and b25 in ~c"aA", do: :parameter_specific_schema
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"pP" and b2 in ~c"aA" and b3 in ~c"rR" and b4 in ~c"tT" and b5 in ~c"iI" and b6 in ~c"aA" and
  b7 in ~c"lL", do: :partial
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"pP" and b2 in ~c"aA" and b3 in ~c"sS" and b4 in ~c"cC" and b5 in ~c"aA" and b6 in ~c"lL", do: :pascal
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"pP" and b2 in ~c"aA" and b3 in ~c"sS" and b4 in ~c"sS", do: :pass
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"pP" and b2 in ~c"aA" and b3 in ~c"sS" and b4 in ~c"sS" and b5 in ~c"iI" and b6 in ~c"nN" and
  b7 in ~c"gG", do: :passing
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"pP" and b2 in ~c"aA" and b3 in ~c"sS" and b4 in ~c"tT", do: :past
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"pP" and b2 in ~c"aA" and b3 in ~c"tT" and b4 in ~c"hH", do: :path
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"pP" and b2 in ~c"eE" and b3 in ~c"rR" and b4 in ~c"mM" and b5 in ~c"uU" and b6 in ~c"tT" and
  b7 in ~c"eE", do: :permute
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"pP" and b2 in ~c"iI" and b3 in ~c"pP" and b4 in ~c"eE", do: :pipe
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"pP" and b2 in ~c"lL" and b3 in ~c"aA" and b4 in ~c"cC" and b5 in ~c"iI" and b6 in ~c"nN" and
  b7 in ~c"gG", do: :placing
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"pP" and b2 in ~c"lL" and b3 in ~c"aA" and b4 in ~c"nN", do: :plan
  
    def ident(:ident, [[[[], b1], b2], b3]) when b1 in ~c"pP" and b2 in ~c"lL" and b3 in ~c"iI", do: :pli
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"pP" and b2 in ~c"rR" and b3 in ~c"eE" and b4 in ~c"cC" and b5 in ~c"eE" and b6 in ~c"dD" and
  b7 in ~c"iI" and b8 in ~c"nN" and b9 in ~c"gG", do: :preceding
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"pP" and b2 in ~c"rR" and b3 in ~c"eE" and b4 in ~c"sS" and b5 in ~c"eE" and b6 in ~c"rR" and
  b7 in ~c"vV" and b8 in ~c"eE", do: :preserve
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"pP" and b2 in ~c"rR" and b3 in ~c"eE" and b4 in ~c"vV", do: :prev
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"pP" and b2 in ~c"rR" and b3 in ~c"iI" and b4 in ~c"oO" and b5 in ~c"rR", do: :prior
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"pP" and b2 in ~c"rR" and b3 in ~c"iI" and b4 in ~c"vV" and b5 in ~c"aA" and b6 in ~c"tT" and
  b7 in ~c"eE", do: :private
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"pP" and b2 in ~c"rR" and b3 in ~c"iI" and b4 in ~c"vV" and b5 in ~c"iI" and b6 in ~c"lL" and
  b7 in ~c"eE" and b8 in ~c"gG" and b9 in ~c"eE" and b10 in ~c"sS", do: :privileges
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"pP" and b2 in ~c"rR" and b3 in ~c"uU" and b4 in ~c"nN" and b5 in ~c"eE", do: :prune
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"pP" and b2 in ~c"uU" and b3 in ~c"bB" and b4 in ~c"lL" and b5 in ~c"iI" and b6 in ~c"cC", do: :public
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"qQ" and b2 in ~c"uU" and b3 in ~c"oO" and b4 in ~c"tT" and b5 in ~c"eE" and b6 in ~c"sS", do: :quotes
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"aA" and b4 in ~c"dD", do: :read
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"lL" and b4 in ~c"aA" and b5 in ~c"tT" and b6 in ~c"iI" and
  b7 in ~c"vV" and b8 in ~c"eE", do: :relative
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"pP" and b4 in ~c"eE" and b5 in ~c"aA" and b6 in ~c"tT" and
  b7 in ~c"aA" and b8 in ~c"bB" and b9 in ~c"lL" and b10 in ~c"eE", do: :repeatable
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"sS" and b4 in ~c"pP" and b5 in ~c"eE" and b6 in ~c"cC" and
  b7 in ~c"tT", do: :respect
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"sS" and b4 in ~c"tT" and b5 in ~c"aA" and b6 in ~c"rR" and
  b7 in ~c"tT", do: :restart
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"sS" and b4 in ~c"tT" and b5 in ~c"rR" and b6 in ~c"iI" and
  b7 in ~c"cC" and b8 in ~c"tT", do: :restrict
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"tT" and b4 in ~c"uU" and b5 in ~c"rR" and b6 in ~c"nN" and
  b7 in ~c"eE" and b8 in ~c"dD" and b9 in ~c"_" and b10 in ~c"cC" and b11 in ~c"aA" and
  b12 in ~c"rR" and b13 in ~c"dD" and b14 in ~c"iI" and b15 in ~c"nN" and b16 in ~c"aA" and
  b17 in ~c"lL" and b18 in ~c"iI" and b19 in ~c"tT" and b20 in ~c"yY", do: :returned_cardinality
  
    def ident(:ident, [[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"tT" and b4 in ~c"uU" and b5 in ~c"rR" and b6 in ~c"nN" and
  b7 in ~c"eE" and b8 in ~c"dD" and b9 in ~c"_" and b10 in ~c"lL" and b11 in ~c"eE" and
  b12 in ~c"nN" and b13 in ~c"gG" and b14 in ~c"tT" and b15 in ~c"hH", do: :returned_length
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"tT" and b4 in ~c"uU" and b5 in ~c"rR" and b6 in ~c"nN" and
  b7 in ~c"eE" and b8 in ~c"dD" and b9 in ~c"_" and b10 in ~c"oO" and b11 in ~c"cC" and
  b12 in ~c"tT" and b13 in ~c"eE" and b14 in ~c"tT" and b15 in ~c"_" and b16 in ~c"lL" and
  b17 in ~c"eE" and b18 in ~c"nN" and b19 in ~c"gG" and b20 in ~c"tT" and b21 in ~c"hH", do: :returned_octet_length
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"tT" and b4 in ~c"uU" and b5 in ~c"rR" and b6 in ~c"nN" and
  b7 in ~c"eE" and b8 in ~c"dD" and b9 in ~c"_" and b10 in ~c"sS" and b11 in ~c"qQ" and
  b12 in ~c"lL" and b13 in ~c"sS" and b14 in ~c"tT" and b15 in ~c"aA" and b16 in ~c"tT" and
  b17 in ~c"eE", do: :returned_sqlstate
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"rR" and b2 in ~c"eE" and b3 in ~c"tT" and b4 in ~c"uU" and b5 in ~c"rR" and b6 in ~c"nN" and
  b7 in ~c"iI" and b8 in ~c"nN" and b9 in ~c"gG", do: :returning
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"rR" and b2 in ~c"oO" and b3 in ~c"lL" and b4 in ~c"eE", do: :role
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"rR" and b2 in ~c"oO" and b3 in ~c"uU" and b4 in ~c"tT" and b5 in ~c"iI" and b6 in ~c"nN" and
  b7 in ~c"eE", do: :routine
  
    def ident(:ident, [[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when b1 in ~c"rR" and b2 in ~c"oO" and b3 in ~c"uU" and b4 in ~c"tT" and b5 in ~c"iI" and b6 in ~c"nN" and
  b7 in ~c"eE" and b8 in ~c"_" and b9 in ~c"cC" and b10 in ~c"aA" and b11 in ~c"tT" and
  b12 in ~c"aA" and b13 in ~c"lL" and b14 in ~c"oO" and b15 in ~c"gG", do: :routine_catalog
  
    def ident(:ident, [[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when b1 in ~c"rR" and b2 in ~c"oO" and b3 in ~c"uU" and b4 in ~c"tT" and b5 in ~c"iI" and b6 in ~c"nN" and
  b7 in ~c"eE" and b8 in ~c"_" and b9 in ~c"nN" and b10 in ~c"aA" and b11 in ~c"mM" and
  b12 in ~c"eE", do: :routine_name
  
    def ident(:ident, [[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when b1 in ~c"rR" and b2 in ~c"oO" and b3 in ~c"uU" and b4 in ~c"tT" and b5 in ~c"iI" and b6 in ~c"nN" and
  b7 in ~c"eE" and b8 in ~c"_" and b9 in ~c"sS" and b10 in ~c"cC" and b11 in ~c"hH" and
  b12 in ~c"eE" and b13 in ~c"mM" and b14 in ~c"aA", do: :routine_schema
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"rR" and b2 in ~c"oO" and b3 in ~c"wW" and b4 in ~c"_" and b5 in ~c"cC" and b6 in ~c"oO" and
  b7 in ~c"uU" and b8 in ~c"nN" and b9 in ~c"tT", do: :row_count
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"sS" and b2 in ~c"cC" and b3 in ~c"aA" and b4 in ~c"lL" and b5 in ~c"aA" and b6 in ~c"rR", do: :scalar
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"sS" and b2 in ~c"cC" and b3 in ~c"aA" and b4 in ~c"lL" and b5 in ~c"eE", do: :scale
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"sS" and b2 in ~c"cC" and b3 in ~c"hH" and b4 in ~c"eE" and b5 in ~c"mM" and b6 in ~c"aA", do: :schema
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"sS" and b2 in ~c"cC" and b3 in ~c"hH" and b4 in ~c"eE" and b5 in ~c"mM" and b6 in ~c"aA" and
  b7 in ~c"_" and b8 in ~c"nN" and b9 in ~c"aA" and b10 in ~c"mM" and b11 in ~c"eE", do: :schema_name
  
    def ident(:ident, [[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13]) when b1 in ~c"sS" and b2 in ~c"cC" and b3 in ~c"oO" and b4 in ~c"pP" and b5 in ~c"eE" and b6 in ~c"_" and
  b7 in ~c"cC" and b8 in ~c"aA" and b9 in ~c"tT" and b10 in ~c"aA" and b11 in ~c"lL" and
  b12 in ~c"oO" and b13 in ~c"gG", do: :scope_catalog
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"sS" and b2 in ~c"cC" and b3 in ~c"oO" and b4 in ~c"pP" and b5 in ~c"eE" and b6 in ~c"_" and
  b7 in ~c"nN" and b8 in ~c"aA" and b9 in ~c"mM" and b10 in ~c"eE", do: :scope_name
  
    def ident(:ident, [[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when b1 in ~c"sS" and b2 in ~c"cC" and b3 in ~c"oO" and b4 in ~c"pP" and b5 in ~c"eE" and b6 in ~c"_" and
  b7 in ~c"sS" and b8 in ~c"cC" and b9 in ~c"hH" and b10 in ~c"eE" and b11 in ~c"mM" and
  b12 in ~c"aA", do: :scope_schema
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"sS" and b2 in ~c"eE" and b3 in ~c"cC" and b4 in ~c"tT" and b5 in ~c"iI" and b6 in ~c"oO" and
  b7 in ~c"nN", do: :section
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"sS" and b2 in ~c"eE" and b3 in ~c"cC" and b4 in ~c"uU" and b5 in ~c"rR" and b6 in ~c"iI" and
  b7 in ~c"tT" and b8 in ~c"yY", do: :security
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"sS" and b2 in ~c"eE" and b3 in ~c"lL" and b4 in ~c"fF", do: :self
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"sS" and b2 in ~c"eE" and b3 in ~c"mM" and b4 in ~c"aA" and b5 in ~c"nN" and b6 in ~c"tT" and
  b7 in ~c"iI" and b8 in ~c"cC" and b9 in ~c"sS", do: :semantics
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"sS" and b2 in ~c"eE" and b3 in ~c"qQ" and b4 in ~c"uU" and b5 in ~c"eE" and b6 in ~c"nN" and
  b7 in ~c"cC" and b8 in ~c"eE", do: :sequence
  
    def ident(:ident, [[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when b1 in ~c"sS" and b2 in ~c"eE" and b3 in ~c"rR" and b4 in ~c"iI" and b5 in ~c"aA" and b6 in ~c"lL" and
  b7 in ~c"iI" and b8 in ~c"zZ" and b9 in ~c"aA" and b10 in ~c"bB" and b11 in ~c"lL" and
  b12 in ~c"eE", do: :serializable
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"sS" and b2 in ~c"eE" and b3 in ~c"rR" and b4 in ~c"vV" and b5 in ~c"eE" and b6 in ~c"rR" and
  b7 in ~c"_" and b8 in ~c"nN" and b9 in ~c"aA" and b10 in ~c"mM" and b11 in ~c"eE", do: :server_name
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"sS" and b2 in ~c"eE" and b3 in ~c"sS" and b4 in ~c"sS" and b5 in ~c"iI" and b6 in ~c"oO" and
  b7 in ~c"nN", do: :session
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"sS" and b2 in ~c"eE" and b3 in ~c"tT" and b4 in ~c"sS", do: :sets
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"sS" and b2 in ~c"iI" and b3 in ~c"mM" and b4 in ~c"pP" and b5 in ~c"lL" and b6 in ~c"eE", do: :simple
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"sS" and b2 in ~c"iI" and b3 in ~c"zZ" and b4 in ~c"eE", do: :size
  
    def ident(:ident, [[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when b1 in ~c"sS" and b2 in ~c"oO" and b3 in ~c"rR" and b4 in ~c"tT" and b5 in ~c"_" and b6 in ~c"dD" and
  b7 in ~c"iI" and b8 in ~c"rR" and b9 in ~c"eE" and b10 in ~c"cC" and b11 in ~c"tT" and
  b12 in ~c"iI" and b13 in ~c"oO" and b14 in ~c"nN", do: :sort_direction
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"sS" and b2 in ~c"oO" and b3 in ~c"uU" and b4 in ~c"rR" and b5 in ~c"cC" and b6 in ~c"eE", do: :source
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"sS" and b2 in ~c"pP" and b3 in ~c"aA" and b4 in ~c"cC" and b5 in ~c"eE", do: :space
  
    def ident(:ident, [[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13]) when b1 in ~c"sS" and b2 in ~c"pP" and b3 in ~c"eE" and b4 in ~c"cC" and b5 in ~c"iI" and b6 in ~c"fF" and
  b7 in ~c"iI" and b8 in ~c"cC" and b9 in ~c"_" and b10 in ~c"nN" and b11 in ~c"aA" and
  b12 in ~c"mM" and b13 in ~c"eE", do: :specific_name
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"sS" and b2 in ~c"tT" and b3 in ~c"aA" and b4 in ~c"tT" and b5 in ~c"eE", do: :state
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"sS" and b2 in ~c"tT" and b3 in ~c"aA" and b4 in ~c"tT" and b5 in ~c"eE" and b6 in ~c"mM" and
  b7 in ~c"eE" and b8 in ~c"nN" and b9 in ~c"tT", do: :statement
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"sS" and b2 in ~c"tT" and b3 in ~c"rR" and b4 in ~c"iI" and b5 in ~c"nN" and b6 in ~c"gG", do: :string
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"sS" and b2 in ~c"tT" and b3 in ~c"rR" and b4 in ~c"uU" and b5 in ~c"cC" and b6 in ~c"tT" and
  b7 in ~c"uU" and b8 in ~c"rR" and b9 in ~c"eE", do: :structure
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"sS" and b2 in ~c"tT" and b3 in ~c"yY" and b4 in ~c"lL" and b5 in ~c"eE", do: :style
  
    def ident(:ident, [[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when b1 in ~c"sS" and b2 in ~c"uU" and b3 in ~c"bB" and b4 in ~c"cC" and b5 in ~c"lL" and b6 in ~c"aA" and
  b7 in ~c"sS" and b8 in ~c"sS" and b9 in ~c"_" and b10 in ~c"oO" and b11 in ~c"rR" and
  b12 in ~c"iI" and b13 in ~c"gG" and b14 in ~c"iI" and b15 in ~c"nN", do: :subclass_origin
  
    def ident(:ident, [[], b1]) when b1 in ~c"tT", do: :t
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"tT" and b2 in ~c"aA" and b3 in ~c"bB" and b4 in ~c"lL" and b5 in ~c"eE" and b6 in ~c"_" and
  b7 in ~c"nN" and b8 in ~c"aA" and b9 in ~c"mM" and b10 in ~c"eE", do: :table_name
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"tT" and b2 in ~c"eE" and b3 in ~c"mM" and b4 in ~c"pP" and b5 in ~c"oO" and b6 in ~c"rR" and
  b7 in ~c"aA" and b8 in ~c"rR" and b9 in ~c"yY", do: :temporary
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"tT" and b2 in ~c"hH" and b3 in ~c"rR" and b4 in ~c"oO" and b5 in ~c"uU" and b6 in ~c"gG" and
  b7 in ~c"hH", do: :through
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"tT" and b2 in ~c"iI" and b3 in ~c"eE" and b4 in ~c"sS", do: :ties
  
    def ident(:ident, [[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when b1 in ~c"tT" and b2 in ~c"oO" and b3 in ~c"pP" and b4 in ~c"_" and b5 in ~c"lL" and b6 in ~c"eE" and
  b7 in ~c"vV" and b8 in ~c"eE" and b9 in ~c"lL" and b10 in ~c"_" and b11 in ~c"cC" and
  b12 in ~c"oO" and b13 in ~c"uU" and b14 in ~c"nN" and b15 in ~c"tT", do: :top_level_count
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"tT" and b2 in ~c"rR" and b3 in ~c"aA" and b4 in ~c"nN" and b5 in ~c"sS" and b6 in ~c"aA" and
  b7 in ~c"cC" and b8 in ~c"tT" and b9 in ~c"iI" and b10 in ~c"oO" and b11 in ~c"nN", do: :transaction
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18]) when b1 in ~c"tT" and b2 in ~c"rR" and b3 in ~c"aA" and b4 in ~c"nN" and b5 in ~c"sS" and b6 in ~c"aA" and
  b7 in ~c"cC" and b8 in ~c"tT" and b9 in ~c"iI" and b10 in ~c"oO" and b11 in ~c"nN" and
  b12 in ~c"_" and b13 in ~c"aA" and b14 in ~c"cC" and b15 in ~c"tT" and b16 in ~c"iI" and
  b17 in ~c"vV" and b18 in ~c"eE", do: :transaction_active
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22]) when b1 in ~c"tT" and b2 in ~c"rR" and b3 in ~c"aA" and b4 in ~c"nN" and b5 in ~c"sS" and b6 in ~c"aA" and
  b7 in ~c"cC" and b8 in ~c"tT" and b9 in ~c"iI" and b10 in ~c"oO" and b11 in ~c"nN" and
  b12 in ~c"sS" and b13 in ~c"_" and b14 in ~c"cC" and b15 in ~c"oO" and b16 in ~c"mM" and
  b17 in ~c"mM" and b18 in ~c"iI" and b19 in ~c"tT" and b20 in ~c"tT" and b21 in ~c"eE" and
  b22 in ~c"dD", do: :transactions_committed
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22], b23], b24]) when b1 in ~c"tT" and b2 in ~c"rR" and b3 in ~c"aA" and b4 in ~c"nN" and b5 in ~c"sS" and b6 in ~c"aA" and
  b7 in ~c"cC" and b8 in ~c"tT" and b9 in ~c"iI" and b10 in ~c"oO" and b11 in ~c"nN" and
  b12 in ~c"sS" and b13 in ~c"_" and b14 in ~c"rR" and b15 in ~c"oO" and b16 in ~c"lL" and
  b17 in ~c"lL" and b18 in ~c"eE" and b19 in ~c"dD" and b20 in ~c"_" and b21 in ~c"bB" and
  b22 in ~c"aA" and b23 in ~c"cC" and b24 in ~c"kK", do: :transactions_rolled_back
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"tT" and b2 in ~c"rR" and b3 in ~c"aA" and b4 in ~c"nN" and b5 in ~c"sS" and b6 in ~c"fF" and
  b7 in ~c"oO" and b8 in ~c"rR" and b9 in ~c"mM", do: :transform
  
    def ident(:ident, [[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when b1 in ~c"tT" and b2 in ~c"rR" and b3 in ~c"aA" and b4 in ~c"nN" and b5 in ~c"sS" and b6 in ~c"fF" and
  b7 in ~c"oO" and b8 in ~c"rR" and b9 in ~c"mM" and b10 in ~c"sS", do: :transforms
  
    def ident(:ident, [[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when b1 in ~c"tT" and b2 in ~c"rR" and b3 in ~c"iI" and b4 in ~c"gG" and b5 in ~c"gG" and b6 in ~c"eE" and
  b7 in ~c"rR" and b8 in ~c"_" and b9 in ~c"cC" and b10 in ~c"aA" and b11 in ~c"tT" and
  b12 in ~c"aA" and b13 in ~c"lL" and b14 in ~c"oO" and b15 in ~c"gG", do: :trigger_catalog
  
    def ident(:ident, [[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when b1 in ~c"tT" and b2 in ~c"rR" and b3 in ~c"iI" and b4 in ~c"gG" and b5 in ~c"gG" and b6 in ~c"eE" and
  b7 in ~c"rR" and b8 in ~c"_" and b9 in ~c"nN" and b10 in ~c"aA" and b11 in ~c"mM" and
  b12 in ~c"eE", do: :trigger_name
  
    def ident(:ident, [[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when b1 in ~c"tT" and b2 in ~c"rR" and b3 in ~c"iI" and b4 in ~c"gG" and b5 in ~c"gG" and b6 in ~c"eE" and
  b7 in ~c"rR" and b8 in ~c"_" and b9 in ~c"sS" and b10 in ~c"cC" and b11 in ~c"hH" and
  b12 in ~c"eE" and b13 in ~c"mM" and b14 in ~c"aA", do: :trigger_schema
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"tT" and b2 in ~c"yY" and b3 in ~c"pP" and b4 in ~c"eE", do: :type
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"uU" and b2 in ~c"nN" and b3 in ~c"bB" and b4 in ~c"oO" and b5 in ~c"uU" and b6 in ~c"nN" and
  b7 in ~c"dD" and b8 in ~c"eE" and b9 in ~c"dD", do: :unbounded
  
    def ident(:ident, [[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when b1 in ~c"uU" and b2 in ~c"nN" and b3 in ~c"cC" and b4 in ~c"oO" and b5 in ~c"mM" and b6 in ~c"mM" and
  b7 in ~c"iI" and b8 in ~c"tT" and b9 in ~c"tT" and b10 in ~c"eE" and b11 in ~c"dD", do: :uncommitted
  
    def ident(:ident, [[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13]) when b1 in ~c"uU" and b2 in ~c"nN" and b3 in ~c"cC" and b4 in ~c"oO" and b5 in ~c"nN" and b6 in ~c"dD" and
  b7 in ~c"iI" and b8 in ~c"tT" and b9 in ~c"iI" and b10 in ~c"oO" and b11 in ~c"nN" and
  b12 in ~c"aA" and b13 in ~c"lL", do: :unconditional
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"uU" and b2 in ~c"nN" and b3 in ~c"dD" and b4 in ~c"eE" and b5 in ~c"rR", do: :under
  
    def ident(:ident, [[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when b1 in ~c"uU" and b2 in ~c"nN" and b3 in ~c"mM" and b4 in ~c"aA" and b5 in ~c"tT" and b6 in ~c"cC" and
  b7 in ~c"hH" and b8 in ~c"eE" and b9 in ~c"dD", do: :unmatched
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"uU" and b2 in ~c"nN" and b3 in ~c"nN" and b4 in ~c"aA" and b5 in ~c"mM" and b6 in ~c"eE" and
  b7 in ~c"dD", do: :unnamed
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"uU" and b2 in ~c"sS" and b3 in ~c"aA" and b4 in ~c"gG" and b5 in ~c"eE", do: :usage
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22], b23], b24], b25]) when b1 in ~c"uU" and b2 in ~c"sS" and b3 in ~c"eE" and b4 in ~c"rR" and b5 in ~c"_" and b6 in ~c"dD" and
  b7 in ~c"eE" and b8 in ~c"fF" and b9 in ~c"iI" and b10 in ~c"nN" and b11 in ~c"eE" and
  b12 in ~c"dD" and b13 in ~c"_" and b14 in ~c"tT" and b15 in ~c"yY" and b16 in ~c"pP" and
  b17 in ~c"eE" and b18 in ~c"_" and b19 in ~c"cC" and b20 in ~c"aA" and b21 in ~c"tT" and
  b22 in ~c"aA" and b23 in ~c"lL" and b24 in ~c"oO" and b25 in ~c"gG", do: :user_defined_type_catalog
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22]) when b1 in ~c"uU" and b2 in ~c"sS" and b3 in ~c"eE" and b4 in ~c"rR" and b5 in ~c"_" and b6 in ~c"dD" and
  b7 in ~c"eE" and b8 in ~c"fF" and b9 in ~c"iI" and b10 in ~c"nN" and b11 in ~c"eE" and
  b12 in ~c"dD" and b13 in ~c"_" and b14 in ~c"tT" and b15 in ~c"yY" and b16 in ~c"pP" and
  b17 in ~c"eE" and b18 in ~c"_" and b19 in ~c"cC" and b20 in ~c"oO" and b21 in ~c"dD" and
  b22 in ~c"eE", do: :user_defined_type_code
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22]) when b1 in ~c"uU" and b2 in ~c"sS" and b3 in ~c"eE" and b4 in ~c"rR" and b5 in ~c"_" and b6 in ~c"dD" and
  b7 in ~c"eE" and b8 in ~c"fF" and b9 in ~c"iI" and b10 in ~c"nN" and b11 in ~c"eE" and
  b12 in ~c"dD" and b13 in ~c"_" and b14 in ~c"tT" and b15 in ~c"yY" and b16 in ~c"pP" and
  b17 in ~c"eE" and b18 in ~c"_" and b19 in ~c"nN" and b20 in ~c"aA" and b21 in ~c"mM" and
  b22 in ~c"eE", do: :user_defined_type_name
  
    def ident(:ident, [[[[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22], b23], b24]) when b1 in ~c"uU" and b2 in ~c"sS" and b3 in ~c"eE" and b4 in ~c"rR" and b5 in ~c"_" and b6 in ~c"dD" and
  b7 in ~c"eE" and b8 in ~c"fF" and b9 in ~c"iI" and b10 in ~c"nN" and b11 in ~c"eE" and
  b12 in ~c"dD" and b13 in ~c"_" and b14 in ~c"tT" and b15 in ~c"yY" and b16 in ~c"pP" and
  b17 in ~c"eE" and b18 in ~c"_" and b19 in ~c"sS" and b20 in ~c"cC" and b21 in ~c"hH" and
  b22 in ~c"eE" and b23 in ~c"mM" and b24 in ~c"aA", do: :user_defined_type_schema
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"uU" and b2 in ~c"tT" and b3 in ~c"fF" and b4 in ~c"1" and b5 in ~c"6", do: :utf16
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"uU" and b2 in ~c"tT" and b3 in ~c"fF" and b4 in ~c"3" and b5 in ~c"2", do: :utf32
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"uU" and b2 in ~c"tT" and b3 in ~c"fF" and b4 in ~c"8", do: :utf8
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"vV" and b2 in ~c"iI" and b3 in ~c"eE" and b4 in ~c"wW", do: :view
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"wW" and b2 in ~c"oO" and b3 in ~c"rR" and b4 in ~c"kK", do: :work
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"wW" and b2 in ~c"rR" and b3 in ~c"aA" and b4 in ~c"pP" and b5 in ~c"pP" and b6 in ~c"eE" and
  b7 in ~c"rR", do: :wrapper
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"wW" and b2 in ~c"rR" and b3 in ~c"iI" and b4 in ~c"tT" and b5 in ~c"eE", do: :write
  
    def ident(:ident, [[[[[], b1], b2], b3], b4]) when b1 in ~c"zZ" and b2 in ~c"oO" and b3 in ~c"nN" and b4 in ~c"eE", do: :zone
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"lL" and b2 in ~c"iI" and b3 in ~c"mM" and b4 in ~c"iI" and b5 in ~c"tT", do: :limit
  
    def ident(:ident, [[[[[[], b1], b2], b3], b4], b5]) when b1 in ~c"iI" and b2 in ~c"lL" and b3 in ~c"iI" and b4 in ~c"kK" and b5 in ~c"eE", do: :ilike
  
    def ident(:ident, [[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when b1 in ~c"bB" and b2 in ~c"aA" and b3 in ~c"cC" and b4 in ~c"kK" and b5 in ~c"wW" and b6 in ~c"aA" and
  b7 in ~c"rR" and b8 in ~c"dD", do: :backward
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"fF" and b2 in ~c"oO" and b3 in ~c"rR" and b4 in ~c"wW" and b5 in ~c"aA" and b6 in ~c"rR" and
  b7 in ~c"dD", do: :forward
  
    def ident(:ident, [[[[[[[], b1], b2], b3], b4], b5], b6]) when b1 in ~c"iI" and b2 in ~c"sS" and b3 in ~c"nN" and b4 in ~c"uU" and b5 in ~c"lL" and b6 in ~c"lL", do: :isnull
  
    def ident(:ident, [[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when b1 in ~c"nN" and b2 in ~c"oO" and b3 in ~c"tT" and b4 in ~c"nN" and b5 in ~c"uU" and b6 in ~c"lL" and
  b7 in ~c"lL", do: :notnull
  
    def ident(type, _), do: type
end
