# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Parser do
  @moduledoc false
  @compile {:inline, validate: 3, validate_columns: 3, validate_table: 3, sort: 1, description: 3}

  def parse(tokens, context, config \\ %{columns: []}) do
    case parse(tokens, context, [], [], [], [], []) do
      {:ok, context, tokens} -> {:ok, description(tokens, context, Map.get(config, :columns, [])), tokens}
    end
  end
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
    {a, context} = __parse__(a, context)
    {:ok, %{context | errors: errors++context.errors}, a++acc}
  end
  defp parse([], context, a, [], root, [], errors) do
    {a, context} = __parse__(a, context)
    {:ok, %{context | errors: errors++context.errors}, a++root}
  end
  defp parse([], context, unit, acc, root, [], errors) do
    {:ok, %{context | errors: errors++context.errors}, unit++acc++root}
  end
  defp parse([{:paren=t,[{_, {l, c, l, _, 0, 0, 0, 0}}|_]=mm,a}, {:ident,[{_, {l, _, l, c, _, _}}|_]=m,v}|tokens], context, unit, acc, root, acc2, errors) do
    {:ok, context, a} = parse(a, context)
    parse(tokens, context, [{:"#{:string.lowercase(v)}",m,[{t,mm,a}]}|unit], acc, root, acc2, errors)
  end
  defp parse([{:paren=t,m,a},{tt,[_,{:type, :reserved}|_]=mm,aa}|tokens], context, unit, acc, root, acc2, errors) when tt not in ~w[select where group having order limit offset]a do
    {:ok, context, a} = parse(a, context)
    parse(tokens, context, [{tt,mm,[{t,m,a}|aa]}|unit], acc, root, acc2, errors)
  end
  defp parse([{:with=t, m, unit}|tokens], context, a, acc, root, acc2, errors) do
    {a, context} = __parse__(a, context)
    sorted = sort(root)
    context = if sorted != root do
      %{context|format: :dynamic}
    else
      context
    end
    parse(tokens, context, unit, unit, [{t, m, a++acc++sorted}], acc2, errors)
  end
  defp parse([{:comma=t, m, a}|tokens], context, unit, acc, root, acc2, errors) do
    {unit, context} = __parse__(unit, context)
    parse(tokens, context, a, [{t, m, unit}|acc], root, acc2, errors)
  end
  defp parse([{:when=t, m, a}|tokens], context, unit, acc, root, acc2, errors) do
    Process.put(:status, true)
    {unit, context} = __parse__(unit, context)
    parse(tokens, context, a, [{t, m, unit}|acc], root, acc2, errors)
  end
  defp parse([{:else=t, m, a}|tokens], context, unit, acc, root, acc2, errors) do
    {unit, context} = __parse__(unit, context)
    parse(tokens, context, a, [{t, m, unit}|acc], root, acc2, errors)
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
  defp parse([{t,m,unit}|tokens], context, a, acc, root, acc2, errors) when t in ~w[by on]a do
    {a, context} = __parse__(a, context)
    parse(tokens, context, unit, [{t,m,a++acc}], root, acc2, errors)
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
    {a, context} = __parse__(a, context)
    node = {t,m,a++acc}
    parse(tokens, context, unit, unit, [{n, nm, [{l, lm, [{o, om, [node|oa]}|la]}|na]}|root], acc2, validate(node, context, errors))
  end
  defp parse([{:join=t,m,[]=unit}, {:outer=o, om, oa}, {l, lm, la}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2, errors) when l in ~w[left right full]a and tag in ~w[double_quote bracket dot ident as paren]a do
    {a, context} = __parse__(a, context)
    node = {t,m,a++acc}
    parse(tokens, context, unit, unit, [{l, lm, [{o, om, [node|oa]}|la]}|root], acc2, validate(node, context, errors))
  end
  defp parse([{:join=t,m,[]=unit}, {:inner=i, im, ia}, {:natural=n, nm, []=na}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2, errors) when tag in ~w[double_quote bracket dot ident as paren]a do
    {a, context} = __parse__(a, context)
    node = {t,m,a++acc}
    parse(tokens, context, unit, unit, [{n, nm, [{i, im, [node|ia]}|na]}|root], acc2, validate(node, context, errors))
  end
  defp parse([{:join=t,m,[]=unit}, {l, lm, []=la}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2, errors) when l in ~w[inner left right full natural cross]a and tag in ~w[double_quote bracket dot ident as paren]a do
    {a, context} = __parse__(a, context)
    node = {t,m,a++acc}
    parse(tokens, context, unit, unit, [{l, lm, [node|la]}|root], acc2, validate(node, context, errors))
  end
  defp parse([{:join=t,m,[]=unit}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2, errors) when tag in ~w[double_quote bracket dot ident as paren]a do
    {a, context} = __parse__(a, context)
    node = {t,m,a++acc}
    parse(tokens, context, unit, unit, [node|root], acc2, validate(node, context, errors))
  end
  defp parse([{:from=t,m,[]=unit}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2, errors) when tag in ~w[double_quote bracket dot ident as binding]a do
    {a, context} = __parse__(a, context)
    node = {t,m,a++acc}
    parse(tokens, context, unit, unit, [node|root], acc2, validate(node, context, errors))
  end
  defp parse([{t,m,[]=unit}|tokens], context, a, acc, root, acc2, errors) when t in ~w[select where group having order limit offset delete update set]a do
    {a, context} = __parse__(a, context)
    node = {t,m,a++acc}
    parse(tokens, context, unit, unit, [node|root], acc2, validate(node, context, errors))
  end
  defp parse([{_,[span, type, {:tag, t} | m],_}|tokens], context, a, acc, root, acc2, errors) when t in ~w[returning]a do
    {a, context} = __parse__(a, context)
    node = {t,[span, type|m],a++acc}
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
  defp __parse__(tokens, context) do
    case tokens do
      [{tl, _, [_,_]}=l, {t=:then, m, []=a}, r|[]=rest] when tl in ~w[and or =]a -> __parse__([{t, m, [l,r|a]}|rest], context)

      [{tl, _, [_,_]}=l, {t=:and, m, []=a}, {tr, _, [_,_]}=r|rest] when tl in @comparison and tr in @comparison -> __parse__([{t, m, [l,r|a]}|rest], context)
      [{tl, _, [_,_]}=l, {t=:or, m, []=a}, {tr, _, [_,_]}=r|rest] when tl in @comparison and tr in @comparison -> __parse__([{t, m, [l,r|a]}|rest], context)

      [{tl, _, [_,_]}=l, {t=:and, m, []=a}, {tr, _, []}=r|rest] when tl in @comparison and tr in ~w[true false null unknown]a -> __parse__([{t, m, [l,r|a]}|rest], context)
      [{tl, _, [_,_]}=l, {t=:or, m, []=a}, {tr, _, []}=r|rest] when tl in @comparison and tr in ~w[true false null unknown]a -> __parse__([{t, m, [l,r|a]}|rest], context)

      [{tl, _, []}=l, {t=:and, m, []=a}, {tr, _, [_,_]}=r|rest] when tl in ~w[true false null unknown]a and tr in @comparison -> __parse__([{t, m, [l,r|a]}|rest], context)
      [{tl, _, []}=l, {t=:or, m, []=a}, {tr, _, [_,_]}=r|rest] when tl in ~w[true false null unknown]a and tr in @comparison -> __parse__([{t, m, [l,r|a]}|rest], context)


      [{tl, _, [_,_]}=l, {:and, _, []}=r|rest] when tl in @comparison ->
        {tokens, context} = __parse__(rest, context)
        __parse__([l,r|tokens], context)
      [{tl, _, [_,_]}=l, {:or, _, []}=r|rest] when tl in @comparison ->
        {tokens, context} = __parse__(rest, context)
        __parse__([l,r|tokens], context)

      [{tl, _, _}=l, {t=:asc, m, []=a}|rest] when tl in @literal -> __parse__([{t, m, [l|a]}|rest], context)
      [{tl, _, _}=l, {t=:desc, m, []=a}|rest] when tl in @literal -> __parse__([{t, m, [l|a]}|rest], context)

      [{tl, _, _}=l, {t=:*, m, []=a}, {tr, _, _}=r|rest] when tl in @literal and tr in @literal -> __parse__([{t, m, [l,r|a]}|rest], context)
      [{tl, _, _}=l, {t=:/, m, []=a}, {tr, _, _}=r|rest] when tl in @literal and tr in @literal -> __parse__([{t, m, [l,r|a]}|rest], context)
      [{tl, _, _}=l, {t=:%, m, []=a}, {tr, _, _}=r|rest] when tl in @literal and tr in @literal -> __parse__([{t, m, [l,r|a]}|rest], context)
      [{tl, _, _}=l, {t=:+, m, []=a}, {tr, _, _}=r|rest] when tl in @literal and tr in @literal -> __parse__([{t, m, [l,r|a]}|rest], context)
      [{tl, _, _}=l, {t=:-, m, []=a}, {tr, _, _}=r|rest] when tl in @literal and tr in @literal -> __parse__([{t, m, [l,r|a]}|rest], context)

      [l, {t=:=, m, []=a}, r|[{tr, _, _}|_]=rest] when tr in ~w[and or then]a -> __parse__([{t, m, [l,r|a]}|rest], context)
      [l, {t=:!=, m, []=a}, r|[{tr, _, _}|_]=rest] when tr in ~w[and or then]a -> __parse__([{t, m, [l,r|a]}|rest], context)
      [l, {t=:<>, m, []=a}, r|[{tr, _, _}|_]=rest] when tr in ~w[and or then]a -> __parse__([{t, m, [l,r|a]}|rest], context)
      [l, {t=:<, m, []=a}, r|[{tr, _, _}|_]=rest] when tr in ~w[and or then]a -> __parse__([{t, m, [l,r|a]}|rest], context)
      [l, {t=:>, m, []=a}, r|[{tr, _, _}|_]=rest] when tr in ~w[and or then]a -> __parse__([{t, m, [l,r|a]}|rest], context)
      [l, {t=:<=, m, []=a}, r|[{tr, _, _}|_]=rest] when tr in ~w[and or then]a -> __parse__([{t, m, [l,r|a]}|rest], context)
      [l, {t=:>=, m, []=a}, r|[{tr, _, _}|_]=rest] when tr in ~w[and or then]a -> __parse__([{t, m, [l,r|a]}|rest], context)

      [{tl, _, _}=l, {t=:=, m, []=a}, r|[]=rest] when tl in @literal -> __parse__([{t, m, [l,r|a]}|rest], context)
      [{tl, _, _}=l, {t=:!=, m, []=a}, r|[]=rest] when tl in @literal -> __parse__([{t, m, [l,r|a]}|rest], context)
      [{tl, _, _}=l, {t=:<>, m, []=a}, r|[]=rest] when tl in @literal -> __parse__([{t, m, [l,r|a]}|rest], context)
      [{tl, _, _}=l, {t=:<, m, []=a}, r|[]=rest] when tl in @literal -> __parse__([{t, m, [l,r|a]}|rest], context)
      [{tl, _, _}=l, {t=:>, m, []=a}, r|[]=rest] when tl in @literal -> __parse__([{t, m, [l,r|a]}|rest], context)
      [{tl, _, _}=l, {t=:<=, m, []=a}, r|[]=rest] when tl in @literal -> __parse__([{t, m, [l,r|a]}|rest], context)
      [{tl, _, _}=l, {t=:>=, m, []=a}, r|[]=rest] when tl in @literal  -> __parse__([{t, m, [l,r|a]}|rest], context)

      [l, {:=, _, _}=r|rest] ->
        {tokens, context} = __parse__(rest, context)
        __parse__([l,r|tokens], context)
      [l, {:!=, _, _}=r|rest] ->
        {tokens, context} = __parse__(rest, context)
        __parse__([l,r|tokens], context)
      [l, {:<>, _, _}=r|rest] ->
        {tokens, context} = __parse__(rest, context)
        __parse__([l,r|tokens], context)
      [l, {:<, _, _}=r|rest] ->
        {tokens, context} = __parse__(rest, context)
        __parse__([l,r|tokens], context)
      [l, {:>, _, _}=r|rest] ->
        {tokens, context} = __parse__(rest, context)
        __parse__([l,r|tokens], context)
      [l, {:<=, _, _}=r|rest] ->
        {tokens, context} = __parse__(rest, context)
        __parse__([l,r|tokens], context)
      [l, {:>=, _, _}=r|rest] ->
        {tokens, context} = __parse__(rest, context)
        __parse__([l,r|tokens], context)

      [{_, _, _}=l, {t=:"::", m, []=a}, {_, _, _}=r, {bt=:bracket, bm, ba=[]}|rest] ->
        token = {t, m, [l,{bt, bm, [r|ba]}|a]}
        __parse__([token|rest], resolve_binding(token, context))

      [{_, _, _}=l, {t=:"::", m, []=a}, {_, _, _}=r|rest]  ->
        token = {t, m, [l,r|a]}
        __parse__([token|rest], resolve_binding(token, context))

      [{_, _, _}=l, {t=:as, m, []=a}, {_, _, _}=r|rest] -> __parse__([{t, m, [l,r|a]}|rest], context)

      [{tl, _, _}=l, {t=:notnull, m, []=a}|rest] when tl in @literal -> __parse__([{t, m, [l|a]}|rest], context)
      [{tl, _, _}=l, {t=:isnull, m, []=a}|rest] when tl in @literal -> __parse__([{t, m, [l|a]}|rest], context)
      [{tl, _, _}=l, {t=:in, m, []=a}, {tr, _, _}=r|rest] when tl in @literal and tr in @literal -> __parse__([{t, m, [l,r|a]}|rest], context)
      [{tl, _, _}=l, {t=:like, m, []=a}, {ll, _, _}=lll, {et=:escape, em, []=ea}, {tr, _, _}=r|rest] when tl in @literal and ll in @literal and tr in @literal -> __parse__([{t, m, [l,{et, em, [lll, r|ea]}|a]}|rest], context)
      [{tl, _, _}=l, {t=:ilike, m, []=a}, {ll, _, _}=lll, {et=:escape, em, []=ea}, {tr, _, _}=r|rest] when tl in @literal and ll in @literal and tr in @literal -> __parse__([{t, m, [l,{et, em, [lll, r|ea]}|a]}|rest], context)

      [{tl, _, _}=l, {t=:like, m, []=a}, {tr, _, _}=r|rest] when tl in @literal and tr in @literal -> __parse__([{t, m, [l,r|a]}|rest], context)
      [{tl, _, _}=l, {t=:ilike, m, []=a}, {tr, _, _}=r|rest] when tl in @literal and tr in @literal -> __parse__([{t, m, [l,r|a]}|rest], context)

      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:like, m, []=a}, {ll, _, _}=lll, {et=:escape, em, []=ea}, {tr, _, _}=r|rest] when tl in @literal and ll in @literal and tr in @literal -> __parse__([{t, m, [{nt, nm, [l|na]},{et, em, [lll, r|ea]}|a]}|rest], context)
      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:ilike, m, []=a}, {ll, _, _}=lll, {et=:escape, em, []=ea}, {tr, _, _}=r|rest] when tl in @literal and ll in @literal and tr in @literal -> __parse__([{t, m, [{nt, nm, [l|na]},{et, em, [lll, r|ea]}|a]}|rest], context)
      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:in, m, []=a}, {tr, _, _}=r|rest] when tl in @literal and tr in @literal -> __parse__([{t, m, [{nt, nm, [l|na]},r|a]}|rest], context)
      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:like, m, []=a}, {tr, _, _}=r|rest] when  tl in @literal and tr in @literal -> __parse__([{t, m, [{nt, nm, [l|na]},r|a]}|rest], context)
      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:ilike, m, []=a}, {tr, _, _}=r|rest] when tl in @literal and tr in @literal -> __parse__([{t, m, [{nt, nm, [l|na]},r|a]}|rest], context)


      [{tl, _, _}=l, {t=:is, m, []=a}, {false, _, _}=r|rest] when tl in @literal -> __parse__([{t, m, [l,r|a]}|rest], context)
      [{tl, _, _}=l, {t=:is, m, []=a}, {true, _, _}=r|rest] when tl in @literal -> __parse__([{t, m, [l,r|a]}|rest], context)
      [{tl, _, _}=l, {t=:is, m, []=a}, {:null, _, _}=r|rest] when tl in @literal -> __parse__([{t, m, [l,r|a]}|rest], context)
      [{tl, _, _}=l, {t=:is, m, []=a}, {:unknown, _, _}=r|rest] when tl in @literal -> __parse__([{t, m, [l,r|a]}|rest], context)
      [{tl, _, _}=l, {t=:is, m, []=a}, {:binding, _, _}=r|rest] when tl in @literal -> __parse__([{t, m, [l,r|a]}|rest], context)
      [{tl, _, _}=l, {t=:is, m, []=a}, {nt=:not, nm, []=na}, {:distinct=d,dm,[]=da}, {:from=f,fm,[]=fa}, {tr, _, _}=r|rest] when tl in @literal and tr in @literal -> __parse__([{t, m, [l, {nt, nm, [{d,dm,[{f,fm,[r|fa]}|da]}|na]}|a]}|rest], context)
      [{tl, _, _}=l, {t=:is, m, []=a}, {:distinct=d,dm,[]=da}, {:from=f,fm,[]=fa}, {tr, _, _}=r|rest] when tl in @literal and tr in @literal -> __parse__([{t, m, [l,{d,dm,[{f,fm,[r|fa]}|da]}|a]}|rest], context)
      [{tl, _, _}=l, {t=:between, m, []=a}, {:asymmetric=d,dm,[]=da}, {ll, _, _}=lll, {:and=aa,am,[]=aaa}, {tr, _, _}=r|rest] when tl in @literal and ll in @literal and tr in @literal -> __parse__([{t, m, [l, {d,dm,[{aa,am,[lll,r|aaa]}|da]}|a]}|rest], context)
      [{tl, _, _}=l, {t=:between, m, []=a}, {:symmetric=d,dm,[]=da}, {ll, _, _}=lll, {:and=aa,am,[]=aaa}, {tr, _, _}=r|rest] when tl in @literal and ll in @literal and tr in @literal -> __parse__([{t, m, [l, {d,dm,[{aa,am,[lll,r|aaa]}|da]}|a]}|rest], context)
      [{tl, _, _}=l, {t=:between, m, []=a}, {ll, _, _}=lll, {:and=aa,am,[]=aaa}, {tr, _, _}=r|rest] when tl in @literal and ll in @literal and tr in @literal -> __parse__([{t, m, [l, {aa,am,[lll,r|aaa]}|a]}|rest], context)

      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:in, m, []=a}, {tr, _, _}=r|rest] when tl in @literal and tr in @literal -> __parse__([{t, m, [{nt, nm, [l|na]},r|a]}|rest], context)
      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:is, m, []=a}, {false, _, _}=r|rest] when tl in @literal -> __parse__([{t, m, [{nt, nm, [l|na]},r|a]}|rest], context)
      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:is, m, []=a}, {true, _, _}=r|rest] when tl in @literal -> __parse__([{t, m, [{nt, nm, [l|na]},r|a]}|rest], context)
      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:is, m, []=a}, {:null, _, _}=r|rest] when tl in @literal -> __parse__([{t, m, [{nt, nm, [l|na]},r|a]}|rest], context)
      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:is, m, []=a}, {:unknown, _, _}=r|rest] when tl in @literal -> __parse__([{t, m, [{nt, nm, [l|na]},r|a]}|rest], context)
      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:is, m, []=a}, {:binding, _, _}=r|rest] when tl in @literal -> __parse__([{t, m, [{nt, nm, [l|na]},r|a]}|rest], context)

      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:between, m, []=a}, {:asymmetric=d,dm,[]=da}, {ll, _, _}=lll, {:and=aa,am,[]=aaa}, {tr, _, _}=r|rest] when tl in @literal and ll in @literal and tr in @literal -> __parse__([{t, m, [{nt, nm, [l|na]}, {d,dm,[{aa,am,[lll,r|aaa]}|da]}|a]}|rest], context)
      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:between, m, []=a}, {:symmetric=d,dm,[]=da}, {ll, _, _}=lll, {:and=aa,am,[]=aaa}, {tr, _, _}=r|rest] when tl in @literal and ll in @literal and tr in @literal -> __parse__([{t, m, [{nt, nm, [l|na]}, {d,dm,[{aa,am,[lll,r|aaa]}|da]}|a]}|rest], context)
      [{tl, _, _}=l, {nt=:not, nm, []=na}, {t=:between, m, []=a}, {ll, _, _}=lll, {:and=aa,am,[]=aaa}, {tr, _, _}=r|rest] when tl in @literal and ll in @literal and tr in @literal -> __parse__([{t, m, [{nt, nm, [l|na]}, {aa,am,[lll,r|aaa]}|a]}|rest], context)

      [{t=:array, m, []=a}, {:bracket, _, _}=r|rest] -> __parse__([{t, m, [r|a]}|rest], context)

      [{_,[_,{_, :literal}|_],a}=l,{_,[_,{_, :literal}|_],as}=r|rest] -> __parse__([{:as, [], [l,r]}|rest], %{context | aliases: [{as, a}|context.aliases]})
      [{:dot, _, [{:ident, _, schema}, {:ident, _, table}]}=l, {:ident, _, as}=r|rest] ->  __parse__([{:as, [], [l,r]}|rest], %{context | aliases: [{as, [schema, table]}|context.aliases]})
      [{:ident, _, a}=l, {:ident, _, as}=r|rest] -> __parse__([{:as, [], [l,r]}|rest], %{context | aliases: [{as, a}|context.aliases]})

      tokens -> {tokens, context}
    end
  end

  defp resolve_binding({:"::", _, [{:binding, _, [idx]}, right]}, context) do
    %{context|types: List.insert_at(context.types, idx, resolve_column(right, [], [], context))}
  end
  defp resolve_binding(_tokens, context) do
    context
  end

  @order %{delete: 0, update: 0, select: 0, set: 1, from: 1, join: 2, left: 2, right: 2, inner: 2, natural: 2, full: 2, cross: 2, where: 3, group: 4, having: 5, window: 6, order: 7, limit: 8, offset: 9, fetch: 10, returning: 11}
  defp sort(acc), do: Enum.sort_by(acc, fn {tag, _, _} -> Map.get(@order, tag) end, :asc)

  defp validate(_, %{validate: nil}, errors), do: errors
  defp validate({tag, _, values}, %{validate: fun}, errors) when tag in ~w[select set having where on by order group returning]a do
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

  defp description(tokens, context, columns) do
    from = elem(Enum.find(tokens, {[], [], []}, &(is_tuple(&1) && elem(&1, 0) in ~w[from update delete]a)), 2)
    description = case resolve_column(Enum.find(tokens, {[], [], []}, &(is_tuple(&1) && elem(&1, 0) in ~w[select returning]a)), from, columns, context) do
      {:record, values} -> values
      values -> values
    end
    %{context | description: description}
  end

  defp resolve_column({:*, _, []}, from, columns, context), do: Enum.map(from, &expand_star(&1, columns, context))
  defp resolve_column({:dot, _, [left, right]}, from, columns, context), do: [resolve_column(left, from, columns, context), resolve_column(right, from, columns, context)]
  defp resolve_column({:paren, _, [left|_]}, from, columns, context), do: resolve_column(left, from, columns, context)
  defp resolve_column({:=, _, [left, right]}, from, columns, context), do: {:bool, resolve_column(left, from, columns, context) || resolve_column(right, from, columns, context)}
  defp resolve_column({:coalesce, _, [{:paren, _, [left, right]}]}, from, columns, context), do: resolve_column(left, from, columns, context) || resolve_column(right, from, columns, context)
  defp resolve_column({tag, _, [type|_]}, from, columns, context) when tag in ~w[array_agg bracket]a, do: {:array, resolve_column(type, from, columns, context)}
  defp resolve_column({:array, _, [type]}, from, columns, context), do: resolve_column(type, from, columns, context)
  defp resolve_column({:quote, _, _}, _from, _columns, _context), do: :text
  defp resolve_column({:null=type, _, _}, _from, _columns, _context), do: type
  defp resolve_column({:hstore=type, _, _}, _from, _columns, _context), do: type
  defp resolve_column({tag, _, _}, _from, _columns, _context) when tag in ~w[true false]a, do: :bool
  defp resolve_column({tag, _, _}, _from, _columns, _context) when tag in ~w[numeric avg - + *]a, do: :numeric
  defp resolve_column({:select, _, [{:ident, _, _}, {:paren, _, _}]}, _from, _columns, _context) do
    {:record, [:void]}
  end
  defp resolve_column({:select, _, values}, from, columns, context) do
    {:record, List.flatten(Enum.map(values, &resolve_column(&1, from, columns, context)))}
  end
  defp resolve_column({:returning, _, values}, from, columns, context) do
    {:record, List.flatten(Enum.map(values, &resolve_column(&1, from, columns, context)))}
  end
  defp resolve_column({:row, _, [{:paren, _, values}]}, from, columns, context) do
    {:record, Enum.map(values, &resolve_column(&1, from, columns, context))}
  end
  defp resolve_column({:comma, _, [col]}, from, columns, context), do:
    resolve_column(col, from, columns, context)
  defp resolve_column({:as, _, [left, right]}, from, columns, context) do
    case resolve_column(left, from, columns, context) do
      {type, {t, _col}} -> {{type, t}, resolve_column(right, from, columns, context)}
      {type, _col} -> {type, resolve_column(right, from, columns, context)}
      type -> {type, resolve_column(right, from, columns, context)}
    end
  end
  defp resolve_column({:"::", _, [{t, _, _}, {:ident, _, tag}]}, _from, _columns, _context) when t in ~w[binding paren numeric quote]a, do: {:"#{tag}", nil}
  defp resolve_column({:"::", _, [{:quote, _, _}, {:bracket, _, [{:ident, _, tag}]}]}, _from, _columns, _context), do: {{:array, :"#{tag}"}, nil}
  defp resolve_column({:"::", _, [left, {:ident, _, value}]}, from, columns, context) do
    case Enum.find(context.aliases, fn {name, _} -> name == value end) do
      {^value, [{:ident, _, schema}, {:ident, _, table}]} -> columns("#{schema}", "#{table}", columns)
      nil ->
      case resolve_column(left, from, columns, context) do
        {:record, _col} = type -> type
        {type, col} -> {type, col}
        [_, col] -> {:"#{value}", col}
        type -> {:"#{value}", type}
      end
    end
  end
  defp resolve_column({:"::", _, [_left, right]}, from, columns, context) do
    case resolve_column(right, from, columns, context) do
      [schema, table] -> {:record, columns("#{schema}", "#{table}", columns)}
      value -> {value, nil}
    end
  end
  defp resolve_column({:ident, _, ident}, _from, columns, context) do
    case Enum.find(context.aliases, fn {name, _} -> name == ident end)  do
      {_, {schema, table}} -> columns("#{schema}", "#{table}", columns)
      {_, alias} -> columns("#{alias}", columns)
      nil -> :"#{ident}"
    end
  end
  defp resolve_column({type, _, _}, _from, _columns, _context), do: type

  defp expand_star({:comma, _, [col]},  columns, context), do: expand_star(col, columns, context)
  defp expand_star({:as, _, [left, _alias]}, columns, context) do
    expand_star(left, columns, context)
  end
  defp expand_star({:dot, _, [{:ident, _, schema}, {:ident, _, table}]}, columns, _context) do
    columns("#{schema}", "#{table}", columns)
  end
  defp expand_star({:dot, _, [{:double_quote, _, schema}, {:double_quote, _, table}]}, columns, _context) do
    columns("#{schema}", "#{table}", columns)
  end
  defp expand_star({:dot, _, [{:bracket, _, [{:ident, _, schema}]}, {:bracket, _, [{:ident, _, table}]}]}, columns, _context) do
    columns("#{schema}", "#{table}", columns)
  end
  defp expand_star({:ident, _, table}, columns, _context) do
    columns("#{table}", columns)
  end

  defp columns(table, columns) do
    columns
    |> Enum.filter(&(&1.table_name == "#{table}"))
    |> Enum.sort_by(& &1.ordinal_position)
    |> Enum.map(fn col -> {:"#{col.udt_name}", :"#{col.column_name}"} end)
  end

  defp columns(schema, table, columns) do
    columns
    |> Enum.filter(&(&1.table_schema == "#{schema}" and &1.table_name == "#{table}"))
    |> Enum.sort_by(& &1.ordinal_position)
    |> Enum.map(fn col -> {:"#{col.udt_name}", :"#{col.column_name}"} end)
  end
end
