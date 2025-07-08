# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Parser do
  @moduledoc false
  @compile {:inline, parse: 2, parse: 5, predicate: 1, insert_node: 5}
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
  defguard is_data_type(node) when elem(node, 0) in ~w[numeric ident quote double_quote backtick bracket paren dot binding]a
  defguard is_fetch(node) when elem(node, 0) == :fetch
  defguard is_fetch_dir(node) when elem(node, 0) in ~w[absolute backward forward relative]a or elem(hd(tl(elem(node, 1))), 1) in ~w[absolute backward forward relative]a
  defguard is_from(node) when elem(node, 0) == :from
  defguard is_for(node) when elem(node, 0) == :for
  defguard is_grant(node) when elem(node, 0) == :grant
  defguard is_revoke(node) when elem(node, 0) == :revoke
  defguard is_not(node) when elem(node, 0) == :not and elem(node, 2) == []
  defguard is_join(node) when elem(node, 0) == :join
  defguard is_paren(node) when elem(node, 0) == :paren
  defguard is_operator(node) when elem(node, 0) in ~w[:: + - * / ^ % & += -= *= /= %= &= ^-= |*= <=> <-> >>= || as <> <= >= != < > !< !> = like ilike in all any is isnull notnull between]a
  defguard is_of(node) when elem(node, 0) == :of
  defguard is_is(node) when elem(node, 0) == :is
  defguard is_on(node) when elem(node, 0) == :on
  defguard is_select(node) when elem(node, 0) == :select
  defguard is_keyword(node) when elem(hd(elem(node, 1)), 0) == :keyword

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

  def insert_node(node, unit, acc, context, root) when is_paren(node) do
    {:ok, _context, tokens} = parse(elem(node, 2), [])
    {[{elem(node, 0), elem(node, 1), tokens} | unit], acc, context, root}
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
  def insert_node({:into = tag, meta, []}, [ident, paren, values], acc, context, root) do
    {[], [{tag, meta, [ident, paren, values]} | acc], context, root}
  end
  def insert_node({tag, meta, []}, [ident, paren], acc, context, root) when tag in ~w[into table]a do
    {[], [{tag, meta, [ident, paren]} | acc], context, root}
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
  def insert_node({:with = tag, meta, []}, [{:recursive = t,  m, []}, {:fun, _, _} = l, {:as = t2, m2, a}], [], context, root) do
    {[], [], context, root ++ [{tag, meta, [{t2, m2, [{t, m, [l]} | a]}]}]}
  end
  def insert_node({:with = tag, meta, []}, [{:recursive = t,  m, []}, {:ident, _, _} = l, {:paren, _, _} = r, {:as = t2, m2, a}], [], context, root) do
    # {[], [], context, [{tag, meta, [{t2, m2, [{t, m, [l, r]} | a]}]}] ++ root}
    {[], [], context, root ++ [{tag, meta, [{t2, m2, [{t, m, [l, r]} | a]}]}]}
  end
  def insert_node({:with = tag, meta, []}, [{:ident, _, _} = l, {:paren, _, _} = r, {:as = t2, m2, a}], [], context, root) do
    # {[], [], context, [{tag, meta, [{t2, m2, [[l, r] | a]}]}] ++ root}
    {[], [], context, root ++ [{tag, meta, [{t2, m2, [[l, r] | a]}]}]}
  end
  def insert_node({:with = tag, meta, []}, [{:ident, _, _}, {:as, _, _}] = unit, acc, context, root) do
    {[], [], context, root ++ [{tag, meta, unit ++ acc}]}
  end

  # def insert_node({:with = tag, meta, []}, [{:recursive = t,  m, []}, {:ident, _, _} = l, {:paren, _, _} = r, {:as = t2, m2, []}, {:paren, _, _} = l2], [], context, root) do
  #   {[], [], context, root ++ [{tag, meta, [{t2, m2, [{t, m, [l, r]}, l2]}]}]}
  # end
  # def insert_node({:with = tag, meta, []}, [{:ident, _, _} = l, {:paren, _, _} = r, {:as = t2, m2, []}, {:paren, _, _} = l2], [], context, root) do
  #   {[], [], context, root ++ [{tag, meta, [{t2, m2, [[l, r], l2]}]}]}
  # end

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
  def insert_node({tag,_,value}=node, [paren | unit], acc, context, root) when is_paren(paren) and tag == :as and value == [] or is_paren(paren) and is_keyword(node) and tag != :as do
    {[{elem(node, 0), elem(node, 1), [paren]} | unit], acc, context, root}
  end
  def insert_node(node, unit, acc, context, root)  do
    {[node | unit], acc, context, root}
  end

  def parse(tokens, context) do
    {:ok, context, parse(tokens, [], [], [], [])}
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
  def parse([{t, m, [{t2, m2, tokens} = paren]} | rest], unit, acc, context, root) when is_paren(paren) do
    {:ok, _context, tokens} = parse(tokens, [])
    parse(rest, [{t, m, [{t2, m2, tokens}]} | unit], acc, context, root)
  end
  def parse([{t, m, [l, {t2, m2, tokens} = paren]} | rest], unit, acc, context, root) when is_paren(paren) do
    {:ok, _context, tokens} = parse(tokens, [])
    parse(rest, [{t, m, [l, {t2, m2, tokens}]} | unit], acc, context, root)
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
  def parse([paren, node | rest], unit, acc, [], root) when is_paren(paren) and is_combinator(node) do
    {:ok, _context, tokens} = parse(elem(paren, 2), [])
    parse(rest, unit, acc, {elem(node, 0), elem(node, 1), [{elem(paren, 0), elem(paren, 1), tokens}]}, root)
  end
  def parse([node | rest], unit, acc, context, root) when is_comma(node) do
    parse(rest, [], [{elem(node, 0), elem(node, 1), predicate(unit)} | acc], context, root)
  end
  def parse([node | rest], unit, acc, context, root) do
    {unit, acc, context, root} = insert_node(node, unit, acc, context, root)
    parse(rest, unit, acc, context, root)
  end
end
