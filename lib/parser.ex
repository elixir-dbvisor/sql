# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Parser do
  @moduledoc false
  @compile {:inline, validate: 3, parse: 2, __parse__: 2, sort: 1}

  def parse(tokens, context) do
    parse(tokens, context, [], [], [], [], [])
  end
  def parse([], context, [], [], [], tokens, errors) do
    {:ok, Map.update!(context, :errors, &errors++&1), tokens}
  end
  def parse([], context, [], [], acc, tokens, errors) do
    sorted = sort(acc)
    context = if sorted != acc do
      %{context|format: :dynamic}
    else
      context
    end
    {:ok, Map.update!(context, :errors, &errors++&1), sorted++tokens}
  end
  def parse([], context, a, acc, [], [], errors) do
    {a, context} = __parse__(a, context)
    {:ok, Map.update!(context, :errors, &errors++&1), a++acc}
  end
  def parse([], context, unit, acc, root, [], errors) do
    {:ok, Map.update!(context, :errors, &errors++&1), unit++acc++root}
  end
  def parse([{:paren=t,[{:span, {l,c,_,_}}|_]=m,a},{tt,[{:span, {_,_,_,c}},_,{:type, :reserved}|_]=mm,aa}|tokens], context, unit, acc, root, acc2, errors) do
    {:ok, context, a} = parse(a, context)
    preset = case a do
      [{_, [{:span, {pl,pc,_,_}}|_], _}|_] -> {pl-l, (pc-c)-1}
      _ -> {0,0}
    end
    parse(tokens, context, [{tt,mm,[{t,[{:preset, preset}|m],a}|aa]}|unit], acc, root, acc2, errors)
  end
  def parse([{:paren=t,[{:span, {l,c,_,_}}|_]=m,a}, {_,[{:span, {_,_,_,c}}|_],_} = r,{:recursive=tt,mm,aa}|tokens], context, unit, acc, root, acc2, errors) do
    {:ok, context, a} = parse(a, context)
    preset = case a do
      [{_, [{:span, {pl,pc,_,_}}|_], _}|_] -> {pl-l, (pc-c)-1}
      _ -> {0,0}
    end
    parse(tokens, context, [{tt,mm,[{:fn, [], [r, {t,[{:preset, preset}|m],a}]}|aa]}|unit], acc, root, acc2, errors)
  end
  def parse([{:paren=t,[{:span, {l,c,_,_}}|_]=m,a},{:ident,[{:span, {_,_,_,c}}|_],_}=r|tokens], context, unit, acc, root, acc2, errors) do
    {:ok, context, a} = parse(a, context)
    preset = case a do
      [{_, [{:span, {pl,pc,_,_}}|_], _}|_] -> {pl-l, (pc-c)-1}
      _ -> {0,0}
    end
    parse(tokens, context, [{:fn, [], [r, {t,[{:preset, preset}|m],a}]}|unit], acc, root, acc2, errors)
  end
  def parse([{:with=t, m, unit}|tokens], context, a, acc, root, acc2, errors) do
    {a, context} = __parse__(a, context)
    sorted = sort(root)
    context = if sorted != root do
      %{context|format: :dynamic}
    else
      context
    end
    parse(tokens, context, unit, unit, [{t, m, a++acc++sorted}], acc2, errors)
  end
  def parse([{:comma=t, m, a}|tokens], context, unit, acc, root, acc2, errors) do
    {unit, context} = __parse__(unit, context)
    parse(tokens, context, a, [{t, m, unit}|acc], root, acc2, errors)
  end
  def parse([{:colon=t, tm, ta}|tokens], context, []=unit, []=acc, root, acc2, errors) do
    {:ok, context, ta} = parse(ta, context)
    sorted = sort(root)
    context = if sorted != root do
      %{context|format: :dynamic}
    else
      context
    end
    parse(tokens, context, unit, acc, acc, [{t, tm, ta},sorted|acc2], errors)
  end
  def parse([{:dot=t,tm,ta},l|tokens], context, [{:dot,_,_}=r|unit], acc, root, acc2, errors) do
    parse(tokens, context, [{t,tm,[l,r|ta]}|unit], acc, root, acc2, errors)
  end
  def parse([l,{:dot=t,tm,ta},r|tokens], context, unit, acc, root, acc2, errors) do
    parse(tokens, context, [{t,tm,[r,l|ta]}|unit], acc, root, acc2, errors)
  end
  def parse([r,{:in=t,tm,ta},l,{t2,[_,_,_,{:tag,t3}|_]=t3m,_},{:fetch=f,fm,fa}|tokens], context, []=unit, []=acc, root, acc2, errors) when t3 in ~w[absolute relative]a or t2 in ~w[backward forward]a do
    parse(tokens, context, unit, acc, [{f,fm,[{t,tm,[{t3,t3m,[l]},r|ta]}|fa]}|root], acc2, errors)
  end
  def parse([r,{:in=t,tm,ta},{_,[_,_,_,{:tag,l}|_]=lm,_la},{:fetch=f,fm,fa}|tokens], context, []=unit, []=acc, root, acc2, errors) do
    parse(tokens, context, unit, acc, [{f,fm,[{t,tm,[{l,lm,[]},r|ta]}|fa]}|root], acc2, errors)
  end
  def parse([r,{:in=t,tm,ta},l,{:fetch=f,fm,fa}|tokens], context, []=unit, []=acc, root, acc2, errors) do
    parse(tokens, context, unit, acc, [{f,fm,[{t,tm,[l,r|ta]}|fa]}|root], acc2, errors)
  end
  def parse([r,{:from=t,tm,ta},l,{t2,[_,_,_,{:tag,t3}|_]=t3m,_},{:fetch=f,fm,fa}|tokens], context, []=unit, []=acc, root, acc2, errors) when t3 in ~w[absolute relative]a or t2 in ~w[backward forward]a do
    parse(tokens, context, unit, acc, [{f,fm,[{t3,t3m,[l]}, {t,tm,[r|ta]}|fa]}|root], acc2, errors)
  end
  def parse([r,{:from=t,tm,ta},{_,[_,_,_,{:tag,l}|_]=lm,_la},{:fetch=f,fm,fa}|tokens], context, []=unit, []=acc, root, acc2, errors) do
    parse(tokens, context, unit, acc, [{f,fm,[{l,lm,[]},{t,tm,[r|ta]}|fa]}|root], acc2, errors)
  end
  def parse([r,{:from=t,tm,ta},l,{:fetch=f,fm,fa}|tokens], context, []=unit, []=acc, root, acc2, errors) do
    parse(tokens, context, unit, acc, [{f,fm,[l,{t,tm,[r|ta]}|fa]}|root], acc2, errors)
  end
  def parse([{t,m,unit}|tokens], context, a, acc, root, acc2, errors) when t in ~w[by on]a do
    {a, context} = __parse__(a, context)
    parse(tokens, context, unit, [{t,m,a++acc}], root, acc2, errors)
  end
  def parse([{_,[_,_,_,{:tag,t}|_]=m,_}|tokens], context, unit, acc, root, acc2, errors) when t in ~w[asc desc]a do
    parse(tokens, context, [{t,m,[]}|unit], acc, root, acc2, errors)
  end
  def parse([{:paren=r,[{:span, {rl,rc,_,_}}|_]=rm,ra}, {:all=a, am, aa}, {t, tm, []=ta}, {:paren=l, [{:span, {ll,lc,_,_}}|_]=lm, la}|tokens], context, unit, acc, root, acc2, errors) when t in ~w[except intersect union]a do
    {:ok, context, la} = parse(la, context)
    {:ok, context, ra} = parse(ra, context)
    lpreset = case la do
      [{_, [{:span, {pl,pc,_,_}}|_], _}|_] -> {pl-ll, (pc-lc)-1}
      _ -> {0,0}
    end
    rpreset = case ra do
      [{_, [{:span, {pl,pc,_,_}}|_], _}|_] -> {pl-rl, (pc-rc)-1}
      _ -> {0,0}
    end
    parse(tokens, context, unit, acc, [{t,tm,[{l,[{:preset, lpreset}|lm],la},{a, am, [{r, [{:preset, rpreset}|rm], ra}|aa]}|ta]}|root], acc2, errors)
  end
  def parse([{:paren=r,[{:span, {rl,rc,_,_}}|_]=rm,ra}, {t, tm, []=ta}, {:paren=l, [{:span, {ll,lc,_,_}}|_]=lm, la}|tokens], context, unit, acc, root, acc2, errors) when t in ~w[except intersect union]a do
    {:ok, context, la} = parse(la, context)
    {:ok, context, ra} = parse(ra, context)
    lpreset = case la do
      [{_, [{:span, {pl,pc,_,_}}|_], _}|_] -> {pl-ll, (pc-lc)-1}
      _ -> {0,0}
    end
    rpreset = case ra do
      [{_, [{:span, {pl,pc,_,_}}|_], _}|_] -> {pl-rl, (pc-rc)-1}
      _ -> {0,0}
    end
    parse(tokens, context, unit, acc, [{t,tm,[{l,[{:preset, lpreset}|lm],la},{r, [{:preset, rpreset}|rm], ra}|ta]}|root], acc2, errors)
  end
  def parse([{a, am, []}, {t, tm, []=ta}, {:paren=l, [{:span, {ll,cc,_,_}}|_]=lm, la}|tokens], context, unit, acc, root, acc2, errors) when t in ~w[except intersect union]a and a in ~w[all distinct]a do
    {:ok, context, la} = parse(la, context)
    sorted = sort(root)
    context = if sorted != root do
      %{context|format: :dynamic}
    else
      context
    end
    preset = case la do
      [{_, [{:span, {pl,pc,_,_}}|_], _}|_] -> {pl-ll, (pc-cc)-1}
      _ -> {0,0}
    end
    parse(tokens, context, unit, acc, [{t,tm,[{l, [{:preset, preset}|lm], la},{a, am, sorted}|ta]}], acc2, errors)
  end
  def parse([{t, tm, []=ta}, {:paren=r, [{:span, {l,c,_,_}}|_]=rm, ra}|tokens], context, []=unit, []=acc, root, acc2, errors) when t in ~w[except intersect union]a do
    {:ok, context, ra} = parse(ra, context)
    sorted = sort(root)
    context = if sorted != root do
      %{context|format: :dynamic}
    else
      context
    end
    preset = case ra do
      [{_, [{:span, {pl,pc,_,_}}|_], _}|_] -> {pl-l, (pc-c)-1}
      _ -> {0,0}
    end
    parse(tokens, context, unit, acc, [{t,tm,[{r, [{:preset, preset}|rm], ra}, sorted|ta]}], acc2, errors)
  end
  def parse([{a, am, []}, {t, tm, []=ta}|tokens], context, unit, []=acc, root, acc2, errors) when t in ~w[except intersect union]a and a in ~w[all distinct]a do
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
  def parse([{t, tm, []=ta}|tokens], context, []=unit, []=acc, root, acc2, errors) when t in ~w[except intersect union]a do
    {:ok, context, la} = parse(tokens, context)
    sorted = sort(root)
    context = if sorted != root do
      %{context|format: :dynamic}
    else
      context
    end
    parse([], context, unit, acc, [{t,tm,[la, sorted|ta]}], acc2, errors)
  end
  def parse([{:join=t,m,[]=unit}, {:outer=o, om, oa}, {l, lm, la}, {:natural=n, nm, na}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2, errors) when l in ~w[left right full]a and tag in ~w[double_quote bracket dot ident as paren]a do
    {a, context} = __parse__(a, context)
    node = {t,m,a++acc}
    parse(tokens, context, unit, unit, [{n, nm, [{l, lm, [{o, om, [node|oa]}|la]}|na]}|root], acc2, validate(node, context, errors))
  end
  def parse([{:join=t,m,[]=unit}, {:outer=o, om, oa}, {l, lm, la}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2, errors) when l in ~w[left right full]a and tag in ~w[double_quote bracket dot ident as paren]a do
    {a, context} = __parse__(a, context)
    node = {t,m,a++acc}
    parse(tokens, context, unit, unit, [{l, lm, [{o, om, [node|oa]}|la]}|root], acc2, validate(node, context, errors))
  end
  def parse([{:join=t,m,[]=unit}, {:inner=i, im, ia}, {:natural=n, nm, []=na}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2, errors) when tag in ~w[double_quote bracket dot ident as paren]a do
    {a, context} = __parse__(a, context)
    node = {t,m,a++acc}
    parse(tokens, context, unit, unit, [{n, nm, [{i, im, [node|ia]}|na]}|root], acc2, validate(node, context, errors))
  end
  def parse([{:join=t,m,[]=unit}, {l, lm, []=la}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2, errors) when l in ~w[inner left right full natural cross]a and tag in ~w[double_quote bracket dot ident as paren]a do
    {a, context} = __parse__(a, context)
    node = {t,m,a++acc}
    parse(tokens, context, unit, unit, [{l, lm, [node|la]}|root], acc2, validate(node, context, errors))
  end
  def parse([{:join=t,m,[]=unit}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2, errors) when tag in ~w[double_quote bracket dot ident as paren]a do
    {a, context} = __parse__(a, context)
    node = {t,m,a++acc}
    parse(tokens, context, unit, unit, [node|root], acc2, validate(node, context, errors))
  end
  def parse([{:from=t,m,[]=unit}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2, errors) when tag in ~w[double_quote bracket dot ident as binding]a do
    {a, context} = __parse__(a, context)
    node = {t,m,a++acc}
    parse(tokens, context, unit, unit, [node|root], acc2, validate(node, context, errors))
  end
  def parse([{t,m,[]=unit}|tokens], context, a, acc, root, acc2, errors) when t in ~w[select where group having order limit offset]a do
    {a, context} = __parse__(a, context)
    node = {t,m,a++acc}
    parse(tokens, context, unit, unit, [node|root], acc2, validate(node, context, errors))
  end
  def parse([{:paren=t,[{:span, {l,c,_,_}}|_]=m,a}|tokens], context, unit, acc, root, acc2, errors) do
    {:ok, context, a} = parse(a, context)
    preset = case a do
      [{tag, _, [[{_, [{:span, {pl,pc,_,_}}|_], _}|_]|_]}|_] when tag in ~w[except intersect union]a ->
        {pl-l, (pc-c)-1}
      [{_, [_,_,{:type, :operator}|_], [{_, [{:span, {pl,pc,_,_}}|_], _}|_]}|_] ->
        {pl-l, (pc-c)-1}
      [{_, [{:span, {pl,pc,_,_}}|_], _}|_] ->
        {pl-l, (pc-c)-1}
      _ -> {0,0}
    end
    parse(tokens, context, [{t,[{:preset, preset}|m],a}|unit], acc, root, acc2, errors)
  end
  def parse([{:table=tt,mt,at}, {:create=tc,mc,ac}|tokens], context, unit, acc, root, acc2, errors) do
    parse(tokens, context, at, acc, [{tc,mc,[{tt,mt,unit++acc}|ac]}|root], acc2, errors)
  end
  def parse([node|tokens], context, unit, acc, root, acc2, errors) do
    parse(tokens, context, [node|unit], acc, root, acc2, errors)
  end

  def __parse__([b,{:between=n,nm,[]=na},l,{:and=f,fm,[]=fa},r|rest],context), do: __parse__([{n,nm,[b,{f,fm,[l,r|fa]}|na]}|rest],context)
  def __parse__([l,{t,m,a},r|[{c,_,[]}|_]=rest],context) when c in ~w[and or]a, do: __parse__([{t,m,[l,r|a]}|rest],context)
  def __parse__([b,{c,cm,[]=ca},l,{t,m,a},r|[{c2,_,[]}|_]=rest],context) when c in ~w[and or]a and c2 in ~w[and or]a, do: __parse__([{c,cm,[b,{t,m,[l,r|a]}|ca]}|rest],context)
  def __parse__([b,{c,cm,[]=ca},l,{t,m,a},r|rest],context) when c in ~w[and or]a, do: __parse__([{c,cm,[b,{t,m,[l,r|a]}|ca]}|rest],context)
  def __parse__([{c,_,[_, _]}=l,{c2,c2m,[]=c2a},r|rest],context) when c in ~w[and or]a and c2 in ~w[and or]a, do: __parse__([{c2,c2m,[l,r|c2a]}|rest],context)
  def __parse__([b,{c,cm,[]=ca}|rest],context) when c in ~w[asc desc notnull isnull]a, do: __parse__([{c,cm,[b|ca]}|rest],context)
  def __parse__([b,{:not=c,cm,[]=ca},{:between=n,nm,[]=na},{d,dm,[]=da},l,{:and=f,fm,[]=fa},r|rest],context) when d in ~w[asymmetric symmetric]a, do: __parse__([{n,nm,[{c,cm,[b|ca]},{d,dm,[{f,fm,[l,r|fa]}|da]}|na]}|rest],context)
  def __parse__([b,{:not=c,cm,[]=ca},{:between=n,nm,[]=na},l,{:and=f,fm,[]=fa},r|rest],context), do: __parse__([{n,nm,[{c,cm,[b|ca]},{f,fm,[l,r|fa]}|na]}|rest],context)
  def __parse__([b,{:between=n,nm,[]=na},{d,dm,[]=da},l,{:and=f,fm,[]=fa},r|rest],context) when d in ~w[asymmetric symmetric]a, do: __parse__([{n,nm,[b,{d,dm,[{f,fm,[l,r|fa]}|da]}|na]}|rest],context)

  def __parse__([b,{:is=c,cm,[]=ca},{:not=n,nm,[]=na},{:distinct=d,dm,[]=da},{:from=f,fm,[]=fa},node|rest],context), do: __parse__([{c,cm,[b,{n,nm,[{d,dm,[{f,fm,[node|fa]}|da]}|na]}|ca]}|rest],context)
  def __parse__([b,{:is=c,cm,[]=ca},{:distinct=d,dm,[]=da},{:from=f,fm,[]=fa},node|rest],context), do: __parse__([{c,cm,[b,{d,dm,[{f,fm,[node|fa]}|da]}|ca]}|rest],context)
  def __parse__([b,{:is=c,cm,[]=ca},{:not=n,nm,[]=na},{t,_,[]}=node|rest],context) when t in ~w[false true unknown null binding]a, do: __parse__([{c,cm,[b,{n,nm,[node|na]}|ca]}|rest],context)
  def __parse__([b,{:is=c,cm,[]=ca},{t,_,[]}=node|rest],context) when t in ~w[false true unknown null binding]a, do: __parse__([{c,cm,[b,node|ca]}|rest],context)
  def __parse__([b,{:not=n,nm,[]=na},{:in=c,cm,[]=ca},node|rest],context), do: __parse__([{c,cm,[{n,nm,[b|na]},node|ca]}|rest],context)
  def __parse__([{tl,_,a}=l,{tr,_,as}=r|rest],context) when tl in ~w[ident double_quote bracket dot binding]a and tr in ~w[ident double_quote bracket dot binding]a, do: __parse__([{:as, [], [l,r]}|rest], Map.update!(context, :aliases, &[{as, a}|&1]))
  def __parse__([b,{c,[_,_,{:type, :operator}|_]=cm,[]=ca},n|rest],context), do: __parse__([{c,cm,[b,n|ca]}|rest],context)
  def __parse__([t,t2,b,{c,[_,_,{:type, :operator}|_]=cm,[]=ca},n|rest],context), do: __parse__([t,t2,{c,cm,[b,n|ca]}|rest],context)
  def __parse__(unit, context), do: {unit, context}

  @order %{select: 0, from: 1, join: 2, where: 3, group: 4, having: 5, window: 6, order: 7, limit: 8, offset: 9, fetch: 10}
  def sort(acc), do: Enum.sort_by(acc, fn {tag, _, _} -> Map.get(@order, tag) end, :asc)

  def validate(_, %{sql_lock: nil}, errors), do: errors
  def validate({tag, _, _}, %{sql_lock: %{columns: []}}, errors) when tag in ~w[select having where on by order group]a, do: errors
  def validate({tag, _, values}, %{sql_lock: %{columns: columns}}, errors) when tag in ~w[select having where on by order group]a do
    case validate_columns(columns, values, []) do
      [] -> errors
      e -> e++errors
    end
  end
  def validate({tag, _, _}, %{sql_lock: %{tables: []}}, errors) when tag in ~w[from join]a, do: errors
  def validate({tag, _, values}, %{sql_lock: %{tables: tables}} = context, errors) when tag in ~w[from join]a do
    values
    |> Enum.reduce([], fn
      {:paren, _, _}, acc -> acc
      {:on, _, _} = node, acc -> validate(node, context, acc)
      {tag, _, _}=node, acc when tag in ~w[ident double_quote]a -> validate_table(tables, node, acc)
      {:as, _, [{tag, _, _}=node, _]}, acc when tag in ~w[ident double_quote]a  -> validate_table(tables, node, acc)
      {:dot, _, [_, {tag, _, _}=node]}, acc when tag in ~w[ident double_quote]a -> validate_table(tables, node, acc)
      {:dot, _, [_, {:bracket, _, [{:ident, _, _}=node]}]}, acc -> validate_table(tables, node, acc)
      {:comma, _, [{:dot, _, [_, {:bracket, _, [{:ident, _, _}=node]}]}]}, acc -> validate_table(tables, node, acc)
      {:comma, _, [{:dot, _, [_, {tag, _, _}=node]}]}, acc when tag in ~w[ident double_quote]a -> validate_table(tables, node, acc)
      {:comma, _, [{:as, _, [{tag, _, _}=node, _]}]}, acc when tag in ~w[ident double_quote]a  -> validate_table(tables, node, acc)
      {:comma, _, [{tag, _, _}=node]}, acc when tag in ~w[ident double_quote]a -> validate_table(tables, node, acc)
    end)
    |> case do
      [] -> errors
      values -> values++errors
    end
  end
  def validate({tag, _, [{t, _, _}]}, _, errors) when tag in ~w[offset limit]a and t in ~w[numeric binary hexadecimal octal]a, do: errors
  def validate({tag, _, _} = node, _, errors) when tag in ~w[offset limit]a, do: [node|errors]

  def validate_table(tables, {_, _, value}=node, acc)  do
    case Enum.find(tables, false, fn %{table_name: {_, _, fun}} -> fun.(value) end) do
      true -> acc
      false -> [node|acc]
    end
  end

  def validate_columns(columns, {tag, _, value}=node, acc) when tag in ~w[ident double_quote]a do
    case Enum.find(columns, false, fn %{column_name: {_, _, fun}} -> fun.(value) end) do
      true -> acc
      false -> [node|acc]
    end
  end
  def validate_columns(columns, [node|values], acc) do
    validate_columns(columns, values, validate_columns(columns, node, acc))
  end
  def validate_columns(_columns, _, acc), do: acc
end
