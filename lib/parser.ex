# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Parser do
  @moduledoc false
  @compile {:inline, validate: 3, validate_columns: 3, validate_table: 3, sort: 1}

  def describe(tokens, columns), do: description(tokens, columns, [], [], [])

  def parse(tokens, context), do: parse(tokens, context, [], [], [], [], [])

  defp parse([], context, [], [], [], tokens, errors) do
    {:ok, %{context | errors: errors++context.errors}, tokens}
  end
  defp parse([], context, [], [], acc, tokens, errors) do
    sorted = sort(acc)
    context = if sorted != acc do
      %{context|format: :dynamic}
    else
      context
    end
    {:ok, %{context | errors: errors++context.errors}, sorted++tokens}
  end
  defp parse([], context, a, acc, [], [], errors) do
    {:ok, %{context | errors: errors++context.errors}, __parse__(a)++acc}
  end
  defp parse([], context, a, [], root, [], errors) do
    {:ok, %{context | errors: errors++context.errors}, __parse__(a)++root}
  end
  defp parse([], context, unit, acc, root, [], errors) do
    {:ok, %{context | errors: errors++context.errors}, unit++acc++root}
  end
  defp parse([{:paren=t,[{_, {l, c, l, _, 0, 0, 0, 0}}|_]=mm,a}, {:ident,[{_, {l, _, l, c, _, _}}|_]=m,v}|tokens], context, unit, acc, root, acc2, errors) do
    {:ok, context, a} = parse(a, context)
    parse(tokens, context, [{:"#{:string.lowercase(v)}",m,[{t,mm,a}]}|unit], acc, root, acc2, errors)
  end
  defp parse([{:paren=t,m,a},{tt,[_,{:type, :reserved}|_]=mm,aa}|tokens], context, unit, acc, root, acc2, errors) when tt not in ~w[select where group having order limit offset join over]a do
    {:ok, context, a} = parse(a, context)
    parse(tokens, context, [{tt,mm,[{t,m,a}|aa]}|unit], acc, root, acc2, errors)
  end
  defp parse([{:with=t, m, unit}|tokens], context, a, acc, root, acc2, errors) do
    sorted = sort(root)
    context = if sorted != root do
      %{context|format: :dynamic}
    else
      context
    end
    parse(tokens, context, unit, unit, [{t, m, __parse__(a)++acc++sorted}], acc2, errors)
  end
  defp parse([{:colon=t, m, a}, {tag, _, _} = node|tokens], context, unit, acc, root, acc2, errors) when tag in ~w[begin commit rollback]a do
    parse(tokens, context, unit, acc, [{t, m, [node|a]}|root], acc2, errors)
  end
  defp parse([{:comma=t, m, a}|tokens], context, unit, acc, root, acc2, errors) do
    parse(tokens, context, a, [{t, m, __parse__(unit)}|acc], root, acc2, errors)
  end
  defp parse([{:when=t, m, a}|tokens], context, unit, acc, root, acc2, errors) do
    Process.put(:status, true)
    parse(tokens, context, a, [{t, m, __parse__(unit)}|acc], root, acc2, errors)
  end
  defp parse([{:else=t, m, a}|tokens], context, unit, acc, root, acc2, errors) do
    parse(tokens, context, a, [{t, m, __parse__(unit)}|acc], root, acc2, errors)
  end
  defp parse([{:colon=t, tm, ta}|tokens], context, []=unit, []=acc, root, acc2, errors) do
    {:ok, context, ta} = parse(ta, context)
    sorted = sort(root)
    context = if sorted != root do
      %{context|format: :dynamic}
    else
      context
    end
    parse(tokens, context, unit, acc, acc, [{t, tm, ta},sorted|acc2], errors)
  end
  defp parse([{:quote,_,_}=r, {:interval=t,m,a}|tokens], context, unit, acc, root, acc2, errors) do
    parse(tokens, context, [{t,m,[r|a]}|unit], acc, root, acc2, errors)
  end
  defp parse([{:dot=t,tm,ta},l|tokens], context, [{:dot,_,_}=r|unit], acc, root, acc2, errors) do
    parse(tokens, context, [{t,tm,[l,r|ta]}|unit], acc, root, acc2, errors)
  end
  defp parse([l,{:dot=t,tm,ta},r|tokens], context, unit, acc, root, acc2, errors) do
    parse(tokens, context, [{t,tm,[r,l|ta]}|unit], acc, root, acc2, errors)
  end
  defp parse([r,{:in=t,tm,ta},l,{t2,[_,_,{:tag,t3}|_]=t3m,_},{:fetch=f,fm,fa}|tokens], context, []=unit, []=acc, root, acc2, errors) when t3 in ~w[absolute relative]a or t2 in ~w[backward forward]a do
    parse(tokens, context, unit, acc, [{f,fm,[{t,tm,[{t3,t3m,[l]},r|ta]}|fa]}|root], acc2, errors)
  end
  defp parse([r,{:in=t,tm,ta},{_,[_,_,{:tag,l}|_]=lm,_la},{:fetch=f,fm,fa}|tokens], context, []=unit, []=acc, root, acc2, errors) do
    parse(tokens, context, unit, acc, [{f,fm,[{t,tm,[{l,lm,[]},r|ta]}|fa]}|root], acc2, errors)
  end
  defp parse([r,{:in=t,tm,ta},l,{:fetch=f,fm,fa}|tokens], context, []=unit, []=acc, root, acc2, errors) do
    parse(tokens, context, unit, acc, [{f,fm,[{t,tm,[l,r|ta]}|fa]}|root], acc2, errors)
  end
  defp parse([r,{:from=t,tm,ta},l,{t2,[_,_,{:tag,t3}|_]=t3m,_},{:fetch=f,fm,fa}|tokens], context, []=unit, []=acc, root, acc2, errors) when t3 in ~w[absolute relative]a or t2 in ~w[backward forward]a do
    parse(tokens, context, unit, acc, [{f,fm,[{t3,t3m,[l]}, {t,tm,[r|ta]}|fa]}|root], acc2, errors)
  end
  defp parse([r,{:from=t,tm,ta},{_,[_,_,{:tag,l}|_]=lm,_la},{:fetch=f,fm,fa}|tokens], context, []=unit, []=acc, root, acc2, errors) do
    parse(tokens, context, unit, acc, [{f,fm,[{l,lm,[]},{t,tm,[r|ta]}|fa]}|root], acc2, errors)
  end
  defp parse([r,{:from=t,tm,ta},l,{:fetch=f,fm,fa}|tokens], context, []=unit, []=acc, root, acc2, errors) do
    parse(tokens, context, unit, acc, [{f,fm,[l,{t,tm,[r|ta]}|fa]}|root], acc2, errors)
  end
  defp parse([{t,m,unit}|tokens], context, a, acc, root, acc2, errors) when t in ~w[by on into]a do
    parse(tokens, context, unit, [{t,m,__parse__(a)++acc}], root, acc2, errors)
  end
  defp parse([{_,[_,_,{:tag,t}|_]=m,_}|tokens], context, unit, acc, root, acc2, errors) when t in ~w[asc desc]a do
    parse(tokens, context, [{t,m,[]}|unit], acc, root, acc2, errors)
  end
  defp parse([{:paren=r,rm,ra},{:all=a, am, aa},{t, tm, []=ta}, {:paren=l, lm, la}|tokens], context, unit, acc, root, acc2, errors) when t in ~w[except intersect union]a do
    {:ok, context, la} = parse(la, context)
    {:ok, context, ra} = parse(ra, context)
    parse(tokens, context, unit, acc, [{t,tm,[{l,lm,la},{a, am, [{r, rm, ra}|aa]}|ta]}|root], acc2, errors)
  end
  defp parse([{:paren=r,rm,ra},{t, tm, []=ta},{:paren=l, lm, la}|tokens], context, unit, acc, root, acc2, errors) when t in ~w[except intersect union]a do
    {:ok, context, la} = parse(la, context)
    {:ok, context, ra} = parse(ra, context)
    parse(tokens, context, unit, acc, [{t,tm,[{l,lm,la},{r,rm,ra}|ta]}|root], acc2, errors)
  end
  defp parse([{a, am, []}, {t, tm, []=ta}, {:paren=l, lm, la}|tokens], context, unit, acc, root, acc2, errors) when t in ~w[except intersect union]a and a in ~w[all distinct]a do
    {:ok, context, la} = parse(la, context)
    sorted = sort(root)
    context = if sorted != root do
      %{context|format: :dynamic}
    else
      context
    end
    parse(tokens, context, unit, acc, [{t,tm,[{l, lm, la},{a, am, sorted}|ta]}], acc2, errors)
  end
  defp parse([{t, tm, []=ta}, {:paren=r,rm,ra}|tokens], context, []=unit, []=acc, root, acc2, errors) when t in ~w[except intersect union]a do
    {:ok, context, ra} = parse(ra, context)
    sorted = sort(root)
    context = if sorted != root do
      %{context|format: :dynamic}
    else
      context
    end
    parse(tokens, context, unit, acc, [{t,tm,[{r,rm,ra},sorted|ta]}], acc2, errors)
  end
  defp parse([{a, am, []}, {t, tm, []=ta}|tokens], context, unit, []=acc, root, acc2, errors) when t in ~w[except intersect union]a and a in ~w[all distinct]a do
    right = if unit == [], do: root, else: unit
    {:ok, context, la} = parse(tokens, context)
    sorted = sort(right)
    context = if sorted != right do
      %{context|format: :dynamic}
    else
      context
    end
    parse([], context, acc, acc, [{t,tm,[la,{a,am, sorted}|ta]}], acc2, errors)
  end
  defp parse([{t, tm, []=ta}|tokens], context, []=unit, []=acc, root, acc2, errors) when t in ~w[except intersect union]a do
    {:ok, context, la} = parse(tokens, context)
    sorted = sort(root)
    context = if sorted != root do
      %{context|format: :dynamic}
    else
      context
    end
    parse([], context, unit, acc, [{t,tm,[la, sorted|ta]}], acc2, errors)
  end
  defp parse([{:join=t,m,[]=unit}, {:outer=o, om, oa}, {l, lm, la}, {:natural=n, nm, na}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2, errors) when l in ~w[left right full]a and tag in ~w[double_quote bracket dot ident as paren]a do
    node = {t,m,__parse__(a)++acc}
    parse(tokens, context, unit, unit, [{n, nm, [{l, lm, [{o, om, [node|oa]}|la]}|na]}|root], acc2, validate(node, context, errors))
  end
  defp parse([{:join=t,m,[]=unit}, {:outer=o, om, oa}, {l, lm, la}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2, errors) when l in ~w[left right full]a and tag in ~w[double_quote bracket dot ident as paren]a do
    node = {t,m,__parse__(a)++acc}
    parse(tokens, context, unit, unit, [{l, lm, [{o, om, [node|oa]}|la]}|root], acc2, validate(node, context, errors))
  end
  defp parse([{:join=t,m,[]=unit}, {:inner=i, im, ia}, {:natural=n, nm, []=na}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2, errors) when tag in ~w[double_quote bracket dot ident as paren]a do
    node = {t,m,__parse__(a)++acc}
    parse(tokens, context, unit, unit, [{n, nm, [{i, im, [node|ia]}|na]}|root], acc2, validate(node, context, errors))
  end
  defp parse([{:join=t,m,[]=unit}, {l, lm, []=la}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2, errors) when l in ~w[inner left right full natural cross]a and tag in ~w[double_quote bracket dot ident as paren]a do
    node = {t,m,__parse__(a)++acc}
    parse(tokens, context, unit, unit, [{l, lm, [node|la]}|root], acc2, validate(node, context, errors))
  end
  defp parse([{:join=t,m,[]=unit}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2, errors) when tag in ~w[double_quote bracket dot ident as paren]a do
    node = {t,m,__parse__(a)++acc}
    parse(tokens, context, unit, unit, [node|root], acc2, validate(node, context, errors))
  end
  defp parse([{:from=t,m,[]=unit}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2, errors) when tag in ~w[double_quote bracket dot ident as generate_series]a do
    node = {t,m,__parse__(a)++acc}
    parse(tokens, context, unit, unit, [node|root], acc2, validate(node, context, errors))
  end
  defp parse([{t,m,[]=unit}|tokens], context, a, acc, root, acc2, errors) when t in ~w[select where group having order limit offset delete update set insert]a do
    node = {t,m,__parse__(a)++acc}
    parse(tokens, context, unit, unit, [node|root], acc2, validate(node, context, errors))
  end
  defp parse([{_,[span, type, {:tag, t} | m],_}|tokens], context, a, acc, root, acc2, errors) when t in ~w[returning]a do
    node = {t,[span, type|m],__parse__(a)++acc}
    parse(tokens, context, [], [], [node|root], acc2, validate(node, context, errors))
  end
  defp parse([{t,m,a}|tokens], context, unit, acc, root, acc2, errors) when t in ~w[paren bracket]a do
    {:ok, context, a} = parse(a, context)
    parse(tokens, context, [{t,m,a}|unit], acc, root, acc2, errors)
  end
  defp parse([{:case=t,m,a}|tokens], context, unit, acc, root, acc2, errors) do
    {:ok, context, a} = parse(a, context)
    parse(tokens, context, [{t,m,a}|unit], acc, root, acc2, errors)
  end
  defp parse([{:table=tt,mt,at}, {:create=tc,mc,ac}|tokens], context, unit, acc, root, acc2, errors) do
    parse(tokens, context, at, acc, [{tc,mc,[{tt,mt,unit++acc}|ac]}|root], acc2, errors)
  end
  defp parse([node|tokens], context, unit, acc, root, acc2, errors) do
    parse(tokens, context, [node|unit], acc, root, acc2, errors)
  end

  @literal ~w[numeric ident double_quote quote bracket dot binding paren some ::]a
  @comparison ~w[= != <> < > <= >= in is like ilike between notnull isnull and or]a
  defp __parse__(tokens) do
    case tokens do
      [{tl, _, [_,_]}=l, {t=:then, m, []=a}, r|[]=rest] when tl in ~w[and or =]a -> __parse__([{t, m, [l,r|a]}|rest])

      [{tl, _, [_,_]}=l, {t=:and, m, []=a}, {tr, _, [_,_]}=r|rest] when tl in @comparison and tr in @comparison -> __parse__([{t, m, [l,r|a]}|rest])
      [{tl, _, [_,_]}=l, {t=:or, m, []=a}, {tr, _, [_,_]}=r|rest] when tl in @comparison and tr in @comparison -> __parse__([{t, m, [l,r|a]}|rest])

      [{tl, _, [_,_]}=l, {t=:and, m, []=a}, {tr, _, []}=r|rest] when tl in @comparison and tr in ~w[true false null unknown]a -> __parse__([{t, m, [l,r|a]}|rest])
      [{tl, _, [_,_]}=l, {t=:or, m, []=a}, {tr, _, []}=r|rest] when tl in @comparison and tr in ~w[true false null unknown]a -> __parse__([{t, m, [l,r|a]}|rest])

      [{tl, _, []}=l, {t=:and, m, []=a}, {tr, _, [_,_]}=r|rest] when tl in ~w[true false null unknown]a and tr in @comparison -> __parse__([{t, m, [l,r|a]}|rest])
      [{tl, _, []}=l, {t=:or, m, []=a}, {tr, _, [_,_]}=r|rest] when tl in ~w[true false null unknown]a and tr in @comparison -> __parse__([{t, m, [l,r|a]}|rest])


      [{tl, _, [_,_]}=l, {:and, _, []}=r|rest] when tl in @comparison ->
        __parse__([l,r|__parse__(rest)])
      [{tl, _, [_,_]}=l, {:or, _, []}=r|rest] when tl in @comparison ->
        __parse__([l,r|__parse__(rest)])

      [{tl, _, _}=l, {t=:asc, m, []=a}|rest] when tl in @literal -> __parse__([{t, m, [l|a]}|rest])
      [{tl, _, _}=l, {t=:desc, m, []=a}|rest] when tl in @literal -> __parse__([{t, m, [l|a]}|rest])

      [l, {t=:*, m, []=a}, r|[]=rest] -> __parse__([{t, m, [l,r|a]}|rest])
      [l, {t=:/, m, []=a}, r|[]=rest] -> __parse__([{t, m, [l,r|a]}|rest])
      [l, {t=:%, m, []=a}, r|[]=rest] -> __parse__([{t, m, [l,r|a]}|rest])
      [l, {t=:+, m, []=a}, r|[]=rest] -> __parse__([{t, m, [l,r|a]}|rest])
      [l, {t=:-, m, []=a}, r|[]=rest] -> __parse__([{t, m, [l,r|a]}|rest])

      [l, {t=:*, m, []=a}, r|[{tr, _, _}|_]=rest] when tr in ~w[and or then]a -> __parse__([{t, m, [l,r|a]}|rest])
      [l, {t=:/, m, []=a}, r|[{tr, _, _}|_]=rest] when tr in ~w[and or then]a -> __parse__([{t, m, [l,r|a]}|rest])
      [l, {t=:%, m, []=a}, r|[{tr, _, _}|_]=rest] when tr in ~w[and or then]a -> __parse__([{t, m, [l,r|a]}|rest])
      [l, {t=:+, m, []=a}, r|[{tr, _, _}|_]=rest] when tr in ~w[and or then]a -> __parse__([{t, m, [l,r|a]}|rest])
      [l, {t=:-, m, []=a}, r|[{tr, _, _}|_]=rest] when tr in ~w[and or then]a -> __parse__([{t, m, [l,r|a]}|rest])

      [l, {t=:=, m, []=a}, r|[{tr, _, _}|_]=rest] when tr in ~w[and or then]a -> __parse__([{t, m, [l,r|a]}|rest])
      [l, {t=:!=, m, []=a}, r|[{tr, _, _}|_]=rest] when tr in ~w[and or then]a -> __parse__([{t, m, [l,r|a]}|rest])
      [l, {t=:<>, m, []=a}, r|[{tr, _, _}|_]=rest] when tr in ~w[and or then]a -> __parse__([{t, m, [l,r|a]}|rest])
      [l, {t=:<, m, []=a}, r|[{tr, _, _}|_]=rest] when tr in ~w[and or then]a -> __parse__([{t, m, [l,r|a]}|rest])
      [l, {t=:>, m, []=a}, r|[{tr, _, _}|_]=rest] when tr in ~w[and or then]a -> __parse__([{t, m, [l,r|a]}|rest])
      [l, {t=:<=, m, []=a}, r|[{tr, _, _}|_]=rest] when tr in ~w[and or then]a -> __parse__([{t, m, [l,r|a]}|rest])
      [l, {t=:>=, m, []=a}, r|[{tr, _, _}|_]=rest] when tr in ~w[and or then]a -> __parse__([{t, m, [l,r|a]}|rest])

      [{tl, _, _}=l, {t=:=, m, []=a}, r|[]=rest] when tl in @literal -> __parse__([{t, m, [l,r|a]}|rest])
      [{tl, _, _}=l, {t=:!=, m, []=a}, r|[]=rest] when tl in @literal -> __parse__([{t, m, [l,r|a]}|rest])
      [{tl, _, _}=l, {t=:<>, m, []=a}, r|[]=rest] when tl in @literal -> __parse__([{t, m, [l,r|a]}|rest])
      [{tl, _, _}=l, {t=:<, m, []=a}, r|[]=rest] when tl in @literal -> __parse__([{t, m, [l,r|a]}|rest])
      [{tl, _, _}=l, {t=:>, m, []=a}, r|[]=rest] when tl in @literal -> __parse__([{t, m, [l,r|a]}|rest])
      [{tl, _, _}=l, {t=:<=, m, []=a}, r|[]=rest] when tl in @literal -> __parse__([{t, m, [l,r|a]}|rest])
      [{tl, _, _}=l, {t=:>=, m, []=a}, r|[]=rest] when tl in @literal  -> __parse__([{t, m, [l,r|a]}|rest])

      [l, {:=, _, _}=r|rest] ->
        __parse__([l,r|__parse__(rest)])
      [l, {:!=, _, _}=r|rest] ->
        __parse__([l,r|__parse__(rest)])
      [l, {:<>, _, _}=r|rest] ->
        __parse__([l,r|__parse__(rest)])
      [l, {:<, _, _}=r|rest] ->
        __parse__([l,r|__parse__(rest)])
      [l, {:>, _, _}=r|rest] ->
        __parse__([l,r|__parse__(rest)])
      [l, {:<=, _, _}=r|rest] ->
        __parse__([l,r|__parse__(rest)])
      [l, {:>=, _, _}=r|rest] ->
        __parse__([l,r|__parse__(rest)])

      [{_, _, _}=l, {t=:"::", m, []=a}, {_, _, _}=r, {bt=:bracket, bm, ba=[]}|rest] -> __parse__([{t, m, [l,{bt, bm, [r|ba]}|a]}|rest])

      [{_, _, _}=l, {t=:"::", m, []=a}, {_, _, _}=r|rest]  -> __parse__([{t, m, [l,r|a]}|rest])

      [{_, _, _}=l, {t=:"||", m, []=a}, {_, _, _}=r|rest]  -> __parse__([{t, m, [l,r|a]}|rest])
      [{_, _, _}=l, {t=:"->", m, []=a}, {_, _, _}=r|rest]  -> __parse__([{t, m, [l,r|a]}|rest])
      [{_, _, _}=l, {t=:"->>", m, []=a}, {_, _, _}=r|rest]  -> __parse__([{t, m, [l,r|a]}|rest])
      [{_, _, _}=l, {t=:"-|-", m, []=a}, {_, _, _}=r|rest]  -> __parse__([{t, m, [l,r|a]}|rest])
      [{_, _, _}=l, {t=:">>=", m, []=a}, {_, _, _}=r|rest]  -> __parse__([{t, m, [l,r|a]}|rest])
      [{_, _, _}=l, {t=:"@@", m, []=a}, {_, _, _}=r|rest]  -> __parse__([{t, m, [l,r|a]}|rest])
      [{_, _, _}=l, {t=:"|&>", m, []=a}, {_, _, _}=r|rest]  -> __parse__([{t, m, [l,r|a]}|rest])
      [{_, _, _}=l, {t=:"|>>", m, []=a}, {_, _, _}=r|rest]  -> __parse__([{t, m, [l,r|a]}|rest])
      [{_, _, _}=l, {t=:"<<|", m, []=a}, {_, _, _}=r|rest]  -> __parse__([{t, m, [l,r|a]}|rest])
      [{_, _, _}=l, {t=:"&<|", m, []=a}, {_, _, _}=r|rest]  -> __parse__([{t, m, [l,r|a]}|rest])
      [{_, _, _}=l, {t=:"<@", m, []=a}, {_, _, _}=r|rest]  -> __parse__([{t, m, [l,r|a]}|rest])
      [{_, _, _}=l, {t=:"@>", m, []=a}, {_, _, _}=r|rest]  -> __parse__([{t, m, [l,r|a]}|rest])
      [{_, _, _}=l, {t=:"~=", m, []=a}, {_, _, _}=r|rest]  -> __parse__([{t, m, [l,r|a]}|rest])
      [{_, _, _}=l, {t=:">>", m, []=a}, {_, _, _}=r|rest]  -> __parse__([{t, m, [l,r|a]}|rest])
      [{_, _, _}=l, {t=:"&>", m, []=a}, {_, _, _}=r|rest]  -> __parse__([{t, m, [l,r|a]}|rest])
      [{_, _, _}=l, {t=:"&&", m, []=a}, {_, _, _}=r|rest]  -> __parse__([{t, m, [l,r|a]}|rest])
      [{_, _, _}=l, {t=:"&<", m, []=a}, {_, _, _}=r|rest]  -> __parse__([{t, m, [l,r|a]}|rest])
      [{_, _, _}=l, {t=:"<<", m, []=a}, {_, _, _}=r|rest]  -> __parse__([{t, m, [l,r|a]}|rest])

      [{_, _, _}=l, {t=:as, m, []=a}, {_, _, _}=r|rest] -> __parse__([{t, m, [l,r|a]}|rest])
      [{_, _, _}=l, {t=:over, m, []=a}, {_, _, _}=r|rest] -> __parse__([{t, m, [l,r|a]}|rest])

      [{tl, _, _}=l, {t=:notnull, m, []=a}|rest] when tl in @literal -> __parse__([{t, m, [l|a]}|rest])
      [{tl, _, _}=l, {t=:isnull, m, []=a}|rest] when tl in @literal -> __parse__([{t, m, [l|a]}|rest])
      [{tl, _, _}=l, {t=:in, m, []=a}, {tr, _, _}=r|rest] when tl in @literal and tr in @literal -> __parse__([{t, m, [l,r|a]}|rest])
      [{tl, _, _}=l, {t=:like, m, []=a}, {ll, _, _}=lll, {et=:escape, em, []=ea}, {tr, _, _}=r|rest] when tl in @literal and ll in @literal and tr in @literal -> __parse__([{t, m, [l,{et, em, [lll, r|ea]}|a]}|rest])
      [{tl, _, _}=l, {t=:ilike, m, []=a}, {ll, _, _}=lll, {et=:escape, em, []=ea}, {tr, _, _}=r|rest] when tl in @literal and ll in @literal and tr in @literal -> __parse__([{t, m, [l,{et, em, [lll, r|ea]}|a]}|rest])

      [{tl, _, _}=l, {t=:like, m, []=a}, {tr, _, _}=r|rest] when tl in @literal and tr in @literal -> __parse__([{t, m, [l,r|a]}|rest])
      [{tl, _, _}=l, {t=:ilike, m, []=a}, {tr, _, _}=r|rest] when tl in @literal and tr in @literal -> __parse__([{t, m, [l,r|a]}|rest])

      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:like, m, []=a}, {ll, _, _}=lll, {et=:escape, em, []=ea}, {tr, _, _}=r|rest] when tl in @literal and ll in @literal and tr in @literal -> __parse__([{t, m, [{nt, nm, [l|na]},{et, em, [lll, r|ea]}|a]}|rest])
      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:ilike, m, []=a}, {ll, _, _}=lll, {et=:escape, em, []=ea}, {tr, _, _}=r|rest] when tl in @literal and ll in @literal and tr in @literal -> __parse__([{t, m, [{nt, nm, [l|na]},{et, em, [lll, r|ea]}|a]}|rest])
      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:in, m, []=a}, {tr, _, _}=r|rest] when tl in @literal and tr in @literal -> __parse__([{t, m, [{nt, nm, [l|na]},r|a]}|rest])
      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:like, m, []=a}, {tr, _, _}=r|rest] when  tl in @literal and tr in @literal -> __parse__([{t, m, [{nt, nm, [l|na]},r|a]}|rest])
      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:ilike, m, []=a}, {tr, _, _}=r|rest] when tl in @literal and tr in @literal -> __parse__([{t, m, [{nt, nm, [l|na]},r|a]}|rest])


      [{tl, _, _}=l, {t=:is, m, []=a}, {false, _, _}=r|rest] when tl in @literal -> __parse__([{t, m, [l,r|a]}|rest])
      [{tl, _, _}=l, {t=:is, m, []=a}, {true, _, _}=r|rest] when tl in @literal -> __parse__([{t, m, [l,r|a]}|rest])
      [{tl, _, _}=l, {t=:is, m, []=a}, {:null, _, _}=r|rest] when tl in @literal -> __parse__([{t, m, [l,r|a]}|rest])
      [{tl, _, _}=l, {t=:is, m, []=a}, {:unknown, _, _}=r|rest] when tl in @literal -> __parse__([{t, m, [l,r|a]}|rest])
      [{tl, _, _}=l, {t=:is, m, []=a}, {:binding, _, _}=r|rest] when tl in @literal -> __parse__([{t, m, [l,r|a]}|rest])
      [{tl, _, _}=l, {t=:is, m, []=a}, {nt=:not, nm, []=na}, {:distinct=d,dm,[]=da}, {:from=f,fm,[]=fa}, {tr, _, _}=r|rest] when tl in @literal and tr in @literal -> __parse__([{t, m, [l, {nt, nm, [{d,dm,[{f,fm,[r|fa]}|da]}|na]}|a]}|rest])
      [{tl, _, _}=l, {t=:is, m, []=a}, {:distinct=d,dm,[]=da}, {:from=f,fm,[]=fa}, {tr, _, _}=r|rest] when tl in @literal and tr in @literal -> __parse__([{t, m, [l,{d,dm,[{f,fm,[r|fa]}|da]}|a]}|rest])
      [{tl, _, _}=l, {t=:between, m, []=a}, {:asymmetric=d,dm,[]=da}, {ll, _, _}=lll, {:and=aa,am,[]=aaa}, {tr, _, _}=r|rest] when tl in @literal and ll in @literal and tr in @literal -> __parse__([{t, m, [l, {d,dm,[{aa,am,[lll,r|aaa]}|da]}|a]}|rest])
      [{tl, _, _}=l, {t=:between, m, []=a}, {:symmetric=d,dm,[]=da}, {ll, _, _}=lll, {:and=aa,am,[]=aaa}, {tr, _, _}=r|rest] when tl in @literal and ll in @literal and tr in @literal -> __parse__([{t, m, [l, {d,dm,[{aa,am,[lll,r|aaa]}|da]}|a]}|rest])
      [{tl, _, _}=l, {t=:between, m, []=a}, {ll, _, _}=lll, {:and=aa,am,[]=aaa}, {tr, _, _}=r|rest] when tl in @literal and ll in @literal and tr in @literal -> __parse__([{t, m, [l, {aa,am,[lll,r|aaa]}|a]}|rest])

      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:in, m, []=a}, {tr, _, _}=r|rest] when tl in @literal and tr in @literal -> __parse__([{t, m, [{nt, nm, [l|na]},r|a]}|rest])
      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:is, m, []=a}, {false, _, _}=r|rest] when tl in @literal -> __parse__([{t, m, [{nt, nm, [l|na]},r|a]}|rest])
      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:is, m, []=a}, {true, _, _}=r|rest] when tl in @literal -> __parse__([{t, m, [{nt, nm, [l|na]},r|a]}|rest])
      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:is, m, []=a}, {:null, _, _}=r|rest] when tl in @literal -> __parse__([{t, m, [{nt, nm, [l|na]},r|a]}|rest])
      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:is, m, []=a}, {:unknown, _, _}=r|rest] when tl in @literal -> __parse__([{t, m, [{nt, nm, [l|na]},r|a]}|rest])
      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:is, m, []=a}, {:binding, _, _}=r|rest] when tl in @literal -> __parse__([{t, m, [{nt, nm, [l|na]},r|a]}|rest])

      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:between, m, []=a}, {:asymmetric=d,dm,[]=da}, {ll, _, _}=lll, {:and=aa,am,[]=aaa}, {tr, _, _}=r|rest] when tl in @literal and ll in @literal and tr in @literal -> __parse__([{t, m, [{nt, nm, [l|na]}, {d,dm,[{aa,am,[lll,r|aaa]}|da]}|a]}|rest])
      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:between, m, []=a}, {:symmetric=d,dm,[]=da}, {ll, _, _}=lll, {:and=aa,am,[]=aaa}, {tr, _, _}=r|rest] when tl in @literal and ll in @literal and tr in @literal -> __parse__([{t, m, [{nt, nm, [l|na]}, {d,dm,[{aa,am,[lll,r|aaa]}|da]}|a]}|rest])
      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:between, m, []=a}, {ll, _, _}=lll, {:and=aa,am,[]=aaa}, {tr, _, _}=r|rest] when tl in @literal and ll in @literal and tr in @literal -> __parse__([{t, m, [{nt, nm, [l|na]}, {aa,am,[lll,r|aaa]}|a]}|rest])

      [{t=:array, m, []=a}, {:bracket, _, _}=r|rest] -> __parse__([{t, m, [r|a]}|rest])

      [{_,[_,{_, :literal}|_],_}=l,{_,[_,{_, :literal}|_],_}=r|rest] -> __parse__([{:as, [], [l,r]}|rest])
      [{:dot, _, _}=l, {:ident, _, _}=r|rest] ->  __parse__([{:as, [], [l,r]}|rest])
      [{:ident, _, _}=l, {:ident, _, _}=r|rest] -> __parse__([{:as, [], [l,r]}|rest])

      tokens -> tokens
    end
  end

  @order %{insert: 0, delete: 0, update: 0, select: 0, set: 1, from: 1, join: 2, left: 2, right: 2, inner: 2, natural: 2, full: 2, cross: 2, where: 3, group: 4, having: 5, window: 6, order: 7, limit: 8, offset: 9, fetch: 10, returning: 11}
  defp sort(acc), do: Enum.sort_by(acc, fn {tag, _, _} -> Map.get(@order, tag) end, :asc)

  defp validate(_, %{validate: nil}, errors), do: errors
  defp validate({tag, _, values}, %{validate: fun}, errors) when tag in ~w[select set having where on by order group returning insert into]a do
    case validate_columns(fun, values, []) do
      [] -> errors
      e -> e++errors
    end
  end
  defp validate({tag, _, values}, %{validate: fun} = context, errors) when tag in ~w[delete update from join]a do
    values
    |> Enum.reduce([], fn
      {:on, _, _} = node, acc -> validate(node, context, acc)
      {tag, _, _}=node, acc when tag in ~w[ident double_quote]a -> validate_table(fun, node, acc)
      {:as, _, [{tag, _, _}=node, _]}, acc when tag in ~w[ident double_quote]a  -> validate_table(fun, node, acc)
      {:dot, _, [_, {tag, _, _}=node]}, acc when tag in ~w[ident double_quote]a -> validate_table(fun, node, acc)
      {:dot, _, [_, {:bracket, _, [{:ident, _, _}=node]}]}, acc -> validate_table(fun, node, acc)
      {:comma, _, [{:dot, _, [_, {:bracket, _, [{:ident, _, _}=node]}]}]}, acc -> validate_table(fun, node, acc)
      {:comma, _, [{:dot, _, [_, {tag, _, _}=node]}]}, acc when tag in ~w[ident double_quote]a -> validate_table(fun, node, acc)
      {:comma, _, [{:as, _, [{tag, _, _}=node, _]}]}, acc when tag in ~w[ident double_quote]a  -> validate_table(fun, node, acc)
      {:comma, _, [{tag, _, _}=node|_]}, acc when tag in ~w[ident double_quote]a -> validate_table(fun, node, acc)
      _, acc -> acc
    end)
    |> case do
      [] -> errors
      values -> values++errors
    end
  end
  defp validate({tag, _, [{t, _, _}]}, _, errors) when tag in ~w[offset limit]a and t in ~w[numeric binary hexadecimal octal]a, do: errors
  defp validate({tag, _, _} = node, _, errors) when tag in ~w[offset limit]a, do: [node|errors]

  defp validate_table(fun, {_, _, value}=node, acc)  do
    case fun.(value, nil) do
      true -> acc
      false -> [node|acc]
    end
  end

  defp validate_columns(fun, {tag, _, value}=node, acc) when tag in ~w[ident double_quote]a do
    case fun.(nil, value) do
      true -> acc
      false -> [node|acc]
    end
  end
  defp validate_columns(fun, {:as, _, [left, _]}, acc), do: validate_columns(fun, left, acc)
  defp validate_columns(fun, {_, _, values}, acc), do: validate_columns(fun, values, acc)
  defp validate_columns(fun, [node|values], acc) do
    validate_columns(fun, values, validate_columns(fun, node, acc))
  end
  defp validate_columns(_fun, _, acc), do: acc

  defp description([{tag, _, [left, right]}|_rest], columns, froms, select, bindings) when tag in ~w[except intersect union]a do
    left = description(List.wrap(left), columns, froms, select, bindings)
    right = description(List.wrap(right), columns, froms, select, bindings)
    if left == right, do: left, else: right
  end
  defp description([{:paren, _, [[_|_]=values]}|rest], columns, froms, select, bindings) do
    description(values++rest, columns, froms, select, bindings)
  end
  defp description([{tag, _, _}=node|rest], columns, froms, select, bindings) when tag in ~w[insert from update inner outer left right full natural cross join]a do
    description(rest, columns, [node|froms], select, [node|bindings])
  end
  defp description([{tag, _, _}=node|rest], columns, froms, select, bindings) when tag in ~w[select returning]a do
    description(rest, columns, froms, [node|select], [node|bindings])
  end
  defp description([{_, _, _}=node|rest], columns, froms, select, bindings) do
    description(rest, columns, froms, select, [node|bindings])
  end
  defp description([[{_, _, _}|_]=rest], columns, froms, select, bindings) do
    description(rest, columns, froms, select, bindings)
  end
  defp description([], columns, []=aliases, [], bindings) do
    {types, params} = resolve_binding(Enum.reverse(bindings), aliases, columns, [], [])
    {:ok, [], 0, Enum.reverse(types), Enum.reverse(params)}
  end
  defp description([], columns, froms, select, bindings) do
    aliases = resolve_aliases(froms, columns, [])
    description = resolve_description(select, aliases, columns, [])
    {types, params} = resolve_binding(Enum.reverse(bindings), aliases, columns, [], [])
    {:ok, description, length(description), Enum.reverse(types), params}
  end

  defp resolve_description([], _aliases, _columns, []=acc), do: acc
  defp resolve_description([], _aliases, _columns, acc), do: List.last(acc)
  defp resolve_description([node|rest], aliases, columns, acc) do
    resolve_description(rest, aliases, columns, [resolve_desc(node, columns, aliases)|acc])
  end

  defp resolve_desc({:select, _, [{:distinct, _, _}|values]}, columns, aliases) do
    resolve_desc(values, aliases, columns, [])
  end
  defp resolve_desc({tag, _, values}, columns, aliases) when tag in ~w[select returning]a do
    resolve_desc(values, aliases, columns, [])
  end
  defp resolve_desc([], _aliases, _columns, acc), do: Enum.reverse(acc)
  defp resolve_desc([{:*, _, []}], aliases, _columns, []), do: Enum.flat_map(aliases, fn {_, [value]} ->
    case elem(value, tuple_size(value)-1) do
      [{_, [_|_]=cols}] -> cols
      cols -> cols
    end
  end)
  defp resolve_desc([{:comma, _, [node]}|rest], aliases, columns, acc) do
    resolve_desc(rest, aliases, columns, [resolve_column(node, aliases, columns)|acc])
  end
  defp resolve_desc([{_,_,_}=node|rest], aliases, columns, acc) do
    resolve_desc(rest, aliases, columns, [resolve_column(node, aliases, columns)|acc])
  end

  defp find_column([], _column), do: nil
  defp find_column([{_, column}=type|_], column), do: type
  defp find_column([_|rest], column), do: find_column(rest, column)

  defp columns(_table, []=columns), do: columns
  defp columns(_table, [from: _values]) do
    []
  end
  defp columns(table, columns) do
    table = "#{table}"
    columns
    |> Enum.filter(&(&1.table_name == table))
    |> Enum.sort_by(& &1.ordinal_position)
    |> Enum.map(fn col -> {:"#{col.udt_name}", :"#{col.column_name}"} end)
  end

  defp columns(_schema, _table, []=columns), do: columns
  defp columns(schema, table, columns) do
    schema = "#{schema}"
    table = "#{table}"
    columns
    |> Enum.filter(&(&1.table_schema == schema and &1.table_name == table))
    |> Enum.sort_by(& &1.ordinal_position)
    |> Enum.map(fn col -> {:"#{col.udt_name}", :"#{col.column_name}"} end)
  end

  defp resolve_aliases([{tag, _, value}|rest], columns, aliases) when tag in ~w[insert from update delete inner outer left right full natural cross join]a do
    resolve_aliases(rest, columns, [{tag, resolve_aliases(value, columns, [])}|aliases])
  end
  defp resolve_aliases([{:into, _, [{:ident,_,table}|_]}|rest], columns, aliases) do
    resolve_aliases(rest, columns, [{:"#{table}", columns(table, columns)}|aliases])
  end
  defp resolve_aliases([{:as, _, [{:ident,_,table},{:ident,_,as}]}|rest], columns, aliases) do
    resolve_aliases(rest, columns, [{:"#{table}", :"#{as}", columns(table, columns)}|aliases])
  end
  defp resolve_aliases([{:as, _, [{:dot,_,[{:ident,_,schema},{:ident,_,table}]},{:ident,_,as}]}|rest], columns, aliases) do
    resolve_aliases(rest, columns, [{:"#{schema}", :"#{table}", :"#{as}", columns(schema, table, columns)}|aliases])
  end
  defp resolve_aliases([{:ident,_,table}|rest], columns, aliases) do
    resolve_aliases(rest, columns, [{:"#{table}", columns(table, columns)}|aliases])
  end
  defp resolve_aliases([{:dot,_,[{:ident,_,schema},{:ident,_,table}]}|rest], columns, aliases) do
    resolve_aliases(rest, columns, [{:"#{schema}", :"#{table}", columns(schema, table, columns)}|aliases])
  end
  defp resolve_aliases([{:paren,_, _value}, {:ident,_,as}|rest], columns, aliases) do
    resolve_aliases(rest, columns, [{:"#{as}", []}|aliases])
  end
  defp resolve_aliases([{:paren,_, _value}|rest], columns, aliases) do
    resolve_aliases(rest, columns, [{:paren, []}|aliases])
  end
  defp resolve_aliases([_|rest], columns, aliases) do
    resolve_aliases(rest, columns, aliases)
  end
  defp resolve_aliases([], _columns, aliases), do: aliases


  defp resolve_type([{tag, values}|rest], column, prospect) when tag in ~w[from join update]a do
    resolve_type(rest, column, Enum.flat_map(values, &List.wrap(find_column(elem(&1, tuple_size(&1)-1), column)))++prospect)
  end
  defp resolve_type([{_tag, values}|rest], column, prospect) do
    resolve_type(rest, column, resolve_type(values, column, prospect))
  end
  defp resolve_type([], _column, prospect), do: prospect

  defp resolve_binding([], [], types, params), do: {types, params}
  defp resolve_binding([{:binding, _, [value]}|values], [{type, _col}|aliases], types, params) do
    resolve_binding(values, aliases, [type|types], [value|params])
  end
  defp resolve_binding([{:comma, _, [{:binding, _, [value]}]}|values], [{type, _col}|aliases], types, params) do
    resolve_binding(values, aliases, [type|types], [value|params])
  end
  defp resolve_binding([_|values], [_|aliases], types, params) do
    resolve_binding(values, aliases, types, params)
  end

  defp resolve_binding([{:into, _, [_, {:paren,_, c}, {:values,_,[{:paren, _, values}]}]}|rest], [insert: [insert]]=aliases, columns, types, params) do
    {types, params} = resolve_binding(values, resolve_values(c, elem(insert, tuple_size(insert)-1), []), types, params)
    resolve_binding(rest, aliases, columns, types, params)
  end
  defp resolve_binding([{:as, _, [{:binding, _, [value]}, _right]}|rest], aliases, columns, types, params) do
    resolve_binding(rest, aliases, columns, [nil|types], [value|params])
  end
  defp resolve_binding([{_, [_, {:type, :operator}|_], [{:not, _, [{:binding, _, [l]}]}, {:binding, _, [r]}]}|rest], aliases, columns, types, params) do
    resolve_binding(rest, aliases, columns, [nil,nil|types], [r,l|params])
  end
  defp resolve_binding([{_, [_, {:type, :operator}|_], [{:binding, _, [l]}, {:binding, _, [r]}]}|rest], aliases, columns, types, params) do
    resolve_binding(rest, aliases, columns, [nil,nil|types], [r,l|params])
  end
  defp resolve_binding([{_, [_, {:type, :operator}|_], [{:binding, _, [value]}, right]}|rest], aliases, columns, types, params) do
    case type(right, aliases) do
      [{type, _col}] -> resolve_binding(rest, aliases, columns, [type|types], [value|params])
      type -> resolve_binding(rest, aliases, columns, [type|types], [value|params])
    end
  end
  defp resolve_binding([{_, [_, {:type, :operator}|_], [left, {:binding, _, [value]}]}|rest], aliases, columns, types, params) do
    case type(left, aliases) do
      [{type, _col}] -> resolve_binding(rest, aliases, columns, [type|types], [value|params])
      type -> resolve_binding(rest, aliases, columns, [type|types], [value|params])
    end
  end
  defp resolve_binding([{:binding, _, [value]}|rest], []=aliases, columns, types, params) do
    resolve_binding(rest, aliases, columns, [nil|types], [value|params])
  end
  defp resolve_binding([{_, _, [{_, _, _}|_]=value}|rest], aliases, columns, types, params) do
    {types, params} = resolve_binding(value, aliases, columns, types, params)
    resolve_binding(rest, aliases, columns, types, params)
  end
  defp resolve_binding([{_, _, _}|rest], aliases, columns, types, params) do
    resolve_binding(rest, aliases, columns, types, params)
  end
  defp resolve_binding([], _aliases, _columns, types, params) do
    {types, params}
  end

  defp resolve_values([], _columns, acc), do: Enum.reverse(acc)
  defp resolve_values([{:ident, _, ident}|rest], columns, acc) do
    resolve_values(rest, columns, [find_column(columns, :"#{ident}")|acc])
  end
  defp resolve_values([{:comma, _, [{:ident, _, ident}]}|rest], columns, acc) do
    resolve_values(rest, columns, [find_column(columns, :"#{ident}")|acc])
  end

  defp type({:paren, _, [{:select, _, _}|_]}, aliases), do: {:record, aliases}
  defp type({:over, _, [{:rank, _, _}, _]}, _aliases), do: :numeric
  defp type({tag, _, [_, right]}, aliases) when tag in ~w[:: dot]a, do: type(right, aliases)
  defp type({:array_agg, _, [type|_]}, aliases) do
    case resolve_column(type, aliases, []) do
      {type, _} -> {:array, type}
      type -> {:array, type}
    end
  end
  defp type({:bracket, _, [type|_]}, aliases), do: {:array, type(type, aliases)}
  defp type({:quote, _, _}, _aliases), do: :text
  defp type({tag, _, _}, _aliases) when tag in ~w[true false]a, do: :bool
  defp type({tag, _, _}, _aliases) when tag in ~w[numeric avg - + *]a, do: :numeric
  defp type({tag, _, _}, _aliases) when tag in ~w[null hstore]a, do: tag
  defp type({:ident, _, ident}, aliases) do
    col = :"#{ident}"
    case resolve_type(aliases, col, []) do
      [] -> col
      type -> type
    end
  end

  defp type({type, _, []}, _aliases), do: type
  defp type({_, _, [{:paren, _, _}]}, _aliases), do: :void
  defp type({_, _, _}, []=aliases), do: {:record, aliases}
  defp type(_, _aliases), do: nil



  defp column({:ident, _, col}, _aliases), do: :"#{col}"
  defp column({col, _, []}, _aliases), do: col
  defp column({:dot, _, [_, right]}, aliases), do: column(right, aliases)
  defp column({:comma, _, [right]}, aliases), do: column(right, aliases)
  defp column({_tag, _, [{:paren, _, [left, right]}]}, aliases), do: column(left, aliases) || column(right, aliases)
  defp column(_, _), do: nil


  defp resolve_column({:as, _, [left, right]}, aliases, _columns), do: {type(left, aliases), column(right, aliases)}
  defp resolve_column({:"::", _, [{:paren, _, _} = _left, {:dot, _, [{:ident, _, schema}, {:ident, _, table}]}]}, aliases, _columns), do: columns(schema, table, aliases)
  defp resolve_column({:"::", _, [{t, _, _}, right]}, aliases, _columns) when t in ~w[binding paren numeric quote]a, do: {type(right, aliases), nil}
  defp resolve_column({:"::", _, [left, right]}, aliases, _columns), do: {type(right, aliases), column(left, aliases)}
  defp resolve_column({:dot, _, [{:dot, _, [{:ident, _, schema}, {:ident, _, table}]}, {:*, _, []}]}, aliases, _columns), do: columns(schema, table, aliases)
  defp resolve_column({:dot, _, [{:ident, _, table}, {:*, _, []}]}, aliases, _columns), do: columns(table, aliases)
  defp resolve_column({:=, _, [left, right]}, aliases, _columns), do: {:bool, column(left, aliases) || column(right, aliases)}
  defp resolve_column({:coalesce, _, [{:paren, _, [left, right]}]}, aliases, _columns), do: column(left, aliases) || column(right, aliases)
  defp resolve_column({tag, _, [type|_]}, aliases, columns) when tag in ~w[array_agg bracket]a, do: {:array, resolve_column(type, aliases, columns)}
  defp resolve_column({:array, _, [type]}, aliases, columns), do: resolve_column(type, aliases, columns)
  defp resolve_column({:paren, _, [{:select, _, _}|_] = values}, aliases, columns) do
    {:record, resolve_desc(values, aliases, columns, [])}
  end

  defp resolve_column({:paren, _, [left|_]}, aliases, columns), do: resolve_column(left, aliases, columns)
  defp resolve_column({:select, _, [{:ident, _, _}, {:paren, _, _}]}, _aliases, _columns) do
    {:record, [:void]}
  end
  defp resolve_column({:row, _, [{:paren, _, values}]}, aliases, columns) do
    {:record, resolve_desc(values, aliases, columns, [])}
  end
  defp resolve_column(node, aliases, _columns) do
    type = type(node, aliases)
    column = column(node, aliases)
    case type == column do
      true -> {nil, column}
      false -> {type, column}
    end
  end
end
