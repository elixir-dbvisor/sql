# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Parser do
  @moduledoc false
  @compile {:inline, parse: 6, __parse__: 2}

  def parse(tokens, context) do
    parse(tokens, context, [], [], [], [])
  end
  def parse([], context, [], [], [], tokens) do
    {:ok, context, tokens}
  end
  def parse([], context, [], [], acc, tokens) do
    {:ok, context, :lists.flatten(sort(acc), tokens)}
  end
  def parse([], context, a, acc, [], []) do
    {a, context} = __parse__(a, context)
    {:ok, context, [a|acc]}
  end
  def parse([], context, unit, acc, root, []) do
    {:ok, context, :lists.flatten([unit|acc], root)}
  end
  def parse([{:with=t, m, []=unit}|tokens], context, a, acc, root, acc2) do
    {a, context} = __parse__(a, context)
    parse(tokens, context, unit, unit, [{t, m, [:lists.flatten(a, acc),sort(root)|unit]}], acc2)
  end
  def parse([{:comma=t, m, []=unit}|tokens], context, a, acc, root, acc2) do
    {a, context} = __parse__(a, context)
    parse(tokens, context, unit, [{t,m,a}|acc], root, acc2)
  end
  def parse([{:colon=t, tm, ta}|tokens], context, []=unit, []=acc, root, acc2) do
    {:ok, context, ta} = parse(ta, context)
    parse(tokens, context, unit, acc, [], [{t, tm, ta},sort(root)|acc2])
  end
  def parse([l,{t,tm,[]=ta},r,{t3,t3m,t3a},{:fetch=f,fm,[]=fa}|tokens], context, []=unit, []=acc, root, acc2) when t in ~w[from in]a and t3 in ~w[backward forward]a do
    parse(tokens, context, unit, acc, [{f,fm,[{t3,t3m,[r|t3a]},{t,tm,[l|ta]}|fa]}|root], acc2)
  end
  def parse([l,{t,tm,[]=ta},r,{_,[_,{:tag, t3}|_]=t3m,_},{:fetch=f,fm,[]=fa}|tokens], context, []=unit, []=acc, root, acc2) when t in ~w[from in]a and t3 in ~w[absolute relative]a do
    parse(tokens, context, unit, acc, [{f,fm,[{t3,t3m,[r]},{t,tm,[l|ta]}|fa]}|root], acc2)
  end
  def parse([r,{t,tm,[]=ta},{:ident,[_,{:tag, l}|_]=lm,_},{:fetch=f,fm,[]=fa}|tokens], context, []=unit, []=acc, root, acc2) when t in ~w[from in]a do
    parse(tokens, context, unit, acc, [{f,fm,[{l,lm,[{t,tm,[r|ta]}]}|fa]}|root], acc2)
  end
  def parse([r,{t,tm,[]=ta},{:numeric,_,_}=l,{:fetch=f,fm,[]=fa}|tokens], context, []=unit, []=acc, root, acc2) when t in ~w[from in]a do
    parse(tokens, context, unit, acc, [{f,fm,[l,{t,tm,[r|ta]}|fa]}|root], acc2)
  end
  def parse([r,{t,tm,[]=ta},{l,lm,la},{:fetch=f,fm,[]=fa}|tokens], context, []=unit, []=acc, root, acc2) when t in ~w[from in]a do
    parse(tokens, context, unit, acc, [{f,fm,[{l,lm, [{t,tm,[r|ta]}|la]}|fa]}|root], acc2)
  end
  def parse([{t,m,[]=unit}|tokens], context, a, acc, root, acc2) when t in ~w[by on]a do
    {a, context} = __parse__(a, context)
    parse(tokens, context, unit, [{t,m,:lists.flatten(a, acc)}], root, acc2)
  end
  def parse([{_,[_,{:tag,t}|_]=m,_}, node|tokens], context, unit, acc, root, acc2) when t in ~w[asc desc]a do
    parse(tokens, context, [{t,m,[node]}|unit], acc, root, acc2)
  end
  def parse([{:paren=r,rm,ra}, {:all=a, am, []=aa}, {t, tm, []=ta}, {:paren=l, lm, la}|tokens], context, unit, acc, root, acc2) when t in ~w[except intersect union]a do
    {:ok, context, la} = parse(la, context)
    {:ok, context, ra} = parse(ra, context)
    parse(tokens, context, unit, acc, [{t,tm,[{l,lm,la},{a, am, [{r, rm, ra}|aa]}|ta]}|root], acc2)
  end
  def parse([{:paren=r,rm,ra}, {t, tm, []=ta}, {:paren=l, lm, la}|tokens], context, unit, acc, root, acc2) when t in ~w[except intersect union]a do
    {:ok, context, la} = parse(la, context)
    {:ok, context, ra} = parse(ra, context)
    parse(tokens, context, unit, acc, [{t,tm,[{l,lm,la},{r, rm, ra}|ta]}|root], acc2)
  end
  def parse([{a, am, []=aa}, {t, tm, []=ta}, {:paren=l, lm, la}|tokens], context, unit, acc, root, acc2) when t in ~w[except intersect union]a and a in ~w[all distinct]a do
    {:ok, context, la} = parse(la, context)
    parse(tokens, context, unit, acc, [{t,tm,[{l, lm, la},{a, am, [sort(root)|aa]}|ta]}], acc2)
  end
  def parse([{t, tm, []=ta}, {:paren=r, rm, ra}|tokens], context, []=unit, []=acc, root, acc2) when t in ~w[except intersect union]a do
    {:ok, context, ra} = parse(ra, context)
    parse(tokens, context, unit, acc, [{t,tm,[{r, rm, ra}, sort(root)|ta]}], acc2)
  end
  def parse([{a, am, []=aa}, {t, tm, []=ta}|tokens], context, []=unit, []=acc, root, acc2) when t in ~w[except intersect union]a and a in ~w[all distinct]a do
    {:ok, context, la} = parse(tokens, context)
    parse([], context, unit, acc, [{t,tm,[la,{a,am,[sort(root)|aa]}|ta]}], acc2)
  end
  def parse([{t, tm, []=ta}|tokens], context, []=unit, []=acc, root, acc2) when t in ~w[except intersect union]a do
    {:ok, context, la} = parse(tokens, context)
    parse([], context, unit, acc, [{t,tm,[la, sort(root)|ta]}], acc2)
  end
  def parse([{:join=t,m,[]=unit}, {:outer=o, om, oa}, {l, lm, la}, {:natural=n, nm, na}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2) when l in ~w[left right full]a and tag in ~w[double_quote bracket dot ident as paren]a do
    {a, context} = __parse__(a, context)
    parse(tokens, context, unit, unit, [{n, nm, [{l, lm, [{o, om, [{t,m,:lists.flatten(a, acc)}|oa]}|la]}|na]}|root], acc2)
  end
  def parse([{:join=t,m,[]=unit}, {:outer=o, om, oa}, {l, lm, la}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2) when l in ~w[left right full]a and tag in ~w[double_quote bracket dot ident as paren]a do
    {a, context} = __parse__(a, context)
    parse(tokens, context, unit, unit, [{l, lm, [{o, om, [{t,m,:lists.flatten(a, acc)}|oa]}|la]}|root], acc2)
  end
  def parse([{:join=t,m,[]=unit}, {:inner=i, im, ia}, {:natural=n, nm, []=na}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2) when tag in ~w[double_quote bracket dot ident as paren]a do
    {a, context} = __parse__(a, context)
    parse(tokens, context, unit, unit, [{n, nm, [{i, im, [{t,m,:lists.flatten(a, acc)}|ia]}|na]}|root], acc2)
  end
  def parse([{:join=t,m,[]=unit}, {l, lm, []=la}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2) when l in ~w[inner left right full natural cross]a and tag in ~w[double_quote bracket dot ident as paren]a do
    {a, context} = __parse__(a, context)
    parse(tokens, context, unit, unit, [{l, lm, [{t,m,:lists.flatten(a, acc)}|la]}|root], acc2)
  end
  def parse([{:join=t,m,[]=unit}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2) when tag in ~w[double_quote bracket dot ident as paren]a do
    {a, context} = __parse__(a, context)
    parse(tokens, context, unit, unit, [{t,m,:lists.flatten(a, acc)}|root], acc2)
  end
  def parse([{:from=t,m,[]=unit}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2) when tag in ~w[double_quote bracket dot ident as]a do
    {a, context} = __parse__(a, context)
    parse(tokens, context, unit, unit, [{t,m,:lists.flatten(a, acc)}|root], acc2)
  end
  def parse([{t,m,[]=unit}|tokens], context, a, acc, root, acc2) when t in ~w[select where group having order limit offset]a do
    {a, context} = __parse__(a, context)
    parse(tokens, context, unit, unit, [{t,m,:lists.flatten(a, acc)}|root], acc2)
  end
  def parse([{t,m,[{:paren=t2,m2,a2}]}|tokens], context, unit, acc, root, acc2) do
    {:ok, context, a2} = parse(a2, context)
    parse(tokens, context, [{t,m,[{t2,m2,a2}]}|unit], acc, root, acc2)
  end
  def parse([{t,m,[r, {:paren=t2,m2,a2}]}|tokens], context, unit, acc, root, acc2) do
    {:ok, context, a2} = parse(a2, context)
    parse(tokens, context, [{t,m,[r, {t2,m2,a2}]}|unit], acc, root, acc2)
  end
  def parse([{:paren=t,m,a}|tokens], context, unit, acc, root, acc2) do
    {:ok, context, a} = parse(a, context)
    parse(tokens, context, [{t,m,a}|unit], acc, root, acc2)
  end
  def parse([{tag,_,_}=node|tokens], context, unit, acc, root, acc2) when tag in ~w[numeric ident quote double_quote backtick bracket dot binding]a do
    parse(tokens, context, [node|unit], acc, root, acc2)
  end
  def parse([node|tokens], context, unit, acc, root, acc2) do
    parse(tokens, context, [node|unit], acc, root, acc2)
  end

  def __parse__([l,{t,m,a},r|[{c,_,[]}|_]=rest],context) when c in ~w[and or]a, do: __parse__([{t,m,[l,r|a]}|rest],context)
  def __parse__([b,{c,cm,[]=ca},l,{t,m,a},r|[{c2,_,[]}|_]=rest],context) when c in ~w[and or]a and c2 in ~w[and or]a, do: __parse__([{c,cm,[b,{t,m,[l,r|a]}|ca]}|rest],context)
  def __parse__([b,{c,cm,[]=ca},l,{t,m,a},r|rest],context) when c in ~w[and or]a, do: __parse__([{c,cm,[b,{t,m,[l,r|a]}|ca]}|rest],context)
  def __parse__([{c,_,[_, _]}=l,{c2,c2m,[]=c2a},r|rest],context) when c in ~w[and or]a and c2 in ~w[and or]a, do: __parse__([{c2,c2m,[l,r|c2a]}|rest],context)
  def __parse__([b,{c,cm,[]=ca}|rest],context) when c in ~w[notnull isnull]a, do: __parse__([{c,cm,[b|ca]}|rest],context)
  def __parse__([b,{:not=c,cm,[]=ca},{:between=n,nm,[]=na},{d,dm,[]=da},l,{:and=f,fm,[]=fa},r|rest],context) when d in ~w[asymmetric symmetric]a, do: __parse__([{n,nm,[{c,cm,[b|ca]},{d,dm,[{f,fm,[l,r|fa]}|da]}|na]}|rest],context)
  def __parse__([b,{:not=c,cm,[]=ca},{:between=n,nm,[]=na},l,{:and=f,fm,[]=fa},r|rest],context), do: __parse__([{n,nm,[{c,cm,[b|ca]},{f,fm,[l,r|fa]}|na]}|rest],context)
  def __parse__([b,{:between=n,nm,[]=na},{d,dm,[]=da},l,{:and=f,fm,[]=fa},r|rest],context) when d in ~w[asymmetric symmetric]a, do: __parse__([{n,nm,[b,{d,dm,[{f,fm,[l,r|fa]}|da]}|na]}|rest],context)
  def __parse__([b,{:between=n,nm,[]=na},l,{:and=f,fm,[]=fa},r|rest],context), do: __parse__([{n,nm,[b,{f,fm,[l,r|fa]}|na]}|rest],context)

  def __parse__([b,{:is=c,cm,[]=ca},{:not=n,nm,[]=na},{:distinct=d,dm,[]=da},{:from=f,fm,[]=fa},node|rest],context), do: __parse__([{c,cm,[b,{n,nm,[{d,dm,[{f,fm,[node|fa]}|da]}|na]}|ca]}|rest],context)
  def __parse__([b,{:is=c,cm,[]=ca},{:distinct=d,dm,[]=da},{:from=f,fm,[]=fa},node|rest],context), do: __parse__([{c,cm,[b,{d,dm,[{f,fm,[node|fa]}|da]}|ca]}|rest],context)
  def __parse__([b,{:is=c,cm,[]=ca},{:not=n,nm,[]=na},{t,_,[]}=node|rest],context) when t in ~w[false true unknown null binding]a, do: __parse__([{c,cm,[b,{n,nm,[node|na]}|ca]}|rest],context)
  def __parse__([b,{:is=c,cm,[]=ca},{t,_,[]}=node|rest],context) when t in ~w[false true unknown null binding]a, do: __parse__([{c,cm,[b,node|ca]}|rest],context)
  def __parse__([b,{:not=n,nm,[]=na},{:in=c,cm,[]=ca},node|rest],context), do: __parse__([{n,nm,[b,{c,cm,[node|ca]}|na]}|rest],context)
  def __parse__([b,{:in=c,cm,[]=ca},node|rest],context), do: __parse__([{c,cm,[b,node|ca]}|rest],context)
  def __parse__([b,{c,cm,[]=ca},n|rest],context) when c in ~w[ilike like <= >= < > <> / * + - =]a, do: __parse__([{c,cm,[b,n|ca]}|rest],context)
  def __parse__([{tl,_,a}=l,{tr,_,as}=r],context) when tl in ~w[ident double_quote bracket dot binding]a and tr in ~w[ident double_quote bracket dot binding]a, do: __parse__([{:as, [], [l,r]}], Map.update!(context, :aliases, &[{as, a}|&1]))
  def __parse__([{tl,_,la}=l,{:as=tr,rm,ra}],context) when tl in ~w[ident double_quote bracket dot binding]a, do: __parse__([{:as=tr,rm,[l|ra]}], Map.update!(context, :aliases, &[{la, nil}|&1]))
  def __parse__(unit, context), do: {unit, context}

  @order %{select: 0, from: 1, join: 2, where: 3, group: 4, having: 5, window: 6, order: 7, limit: 8, offset: 9, fetch: 10}
  def sort(acc), do: Enum.sort_by(acc, fn {tag, _, _} -> Map.get(@order, tag) end, :asc)
end
