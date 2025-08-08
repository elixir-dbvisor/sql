# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Parser do
  @moduledoc false
  @compile {:inline, validate: 3, parse: 2, __parse__: 2, sort: 1}

  def parse(tokens, context) do
    parse(tokens, context, [], [], [], [], [])
  end
  def parse([], context, [], [], [], tokens, errors) do
    {:ok, Map.update!(context, :errors, &:lists.append([errors,&1])), tokens}
  end
  def parse([], context, [], [], acc, tokens, errors) do
    {:ok, Map.update!(context, :errors, &:lists.append([errors,&1])), :lists.append([sort(acc),tokens])}
  end
  def parse([], context, a, acc, [], [], errors) do
    {a, context} = __parse__(a, context)
    {:ok, Map.update!(context, :errors, &:lists.append([errors,&1])), [a|acc]}
  end
  def parse([], context, unit, acc, root, [], errors) do
    {:ok, Map.update!(context, :errors, &:lists.append([errors,&1])), :lists.append([unit, acc, root])}
  end
  def parse([{:paren=t,[_, _, {:column, c}|_]=m,a},{tt,[{:type, :reserved}, _, _, _,{:end_column, c}|_]=mm,aa}|tokens], context, unit, acc, root, acc2, errors) do
    {:ok, context, a} = parse(a, context)
    parse(tokens, context, [{tt,mm,[{t,m,a}|aa]}|unit], acc, root, acc2, errors)
  end
  def parse([{:paren=t,[_, _, {:column, c}|_]=m,a}, {_,[_, _, _, _,{:end_column, c}|_],_} = r,{:recursive=tt,mm,aa}|tokens], context, unit, acc, root, acc2, errors) do
    {:ok, context, a} = parse(a, context)
    parse(tokens, context, [{tt,mm,[{:fn, [], [r, {t,m,a}]}|aa]}|unit], acc, root, acc2, errors)
  end
  def parse([{:paren=t,[_, _, {:column, c}|_]=m,a},{:ident,[_, _, _, _,{:end_column, c}|_],_}=r|tokens], context, unit, acc, root, acc2, errors) do
    {:ok, context, a} = parse(a, context)
    parse(tokens, context, [{:fn, [], [r, {t,m,a}]}|unit], acc, root, acc2, errors)
  end
  def parse([{:with=t, m, unit}|tokens], context, a, acc, root, acc2, errors) do
    {a, context} = __parse__(a, context)
    parse(tokens, context, unit, unit, [{t, m, :lists.append([a,acc, sort(root)])}], acc2, errors)
  end
  def parse([{:comma, _, _}=node|tokens], context, a, acc, root, acc2, errors) do
    {a, context} = __parse__(a, context)
    parse(tokens, context, [node], :lists.append([a,acc]), root, acc2, errors)
  end
  def parse([{:colon=t, tm, ta}|tokens], context, []=unit, []=acc, root, acc2, errors) do
    {:ok, context, ta} = parse(ta, context)
    parse(tokens, context, unit, acc, [], [{t, tm, ta},sort(root)|acc2], errors)
  end
  def parse([{:dot=t,tm,ta},l|tokens], context, [{:dot,_,_}=r|unit], acc, root, acc2, errors) do
    parse(tokens, context, [{t,tm,[l,r|ta]}|unit], acc, root, acc2, errors)
  end
  def parse([l,{:dot=t,tm,ta},r|tokens], context, unit, acc, root, acc2, errors) do
    parse(tokens, context, [{t,tm,[r,l|ta]}|unit], acc, root, acc2, errors)
  end
  def parse([r,{t,tm,ta},l,{t2,[{:tag,t3}|t3m],_},{:fetch=f,fm,fa}|tokens], context, []=unit, []=acc, root, acc2, errors) when t in ~w[in]a and (t3 in ~w[absolute relative]a or t2 in ~w[backward forward]a) do
    parse(tokens, context, unit, acc, [{f,fm,[{t,tm,[{t3,t3m,[l]},r|ta]}|fa]}|root], acc2, errors)
  end
  def parse([r,{t,tm,ta},{_,[{:tag,l}|lm],_la},{:fetch=f,fm,fa}|tokens], context, []=unit, []=acc, root, acc2, errors) when t in ~w[in]a do
    parse(tokens, context, unit, acc, [{f,fm,[{t,tm,[{l,lm,[]},r|ta]}|fa]}|root], acc2, errors)
  end
  def parse([r,{t,tm,ta},l,{:fetch=f,fm,fa}|tokens], context, []=unit, []=acc, root, acc2, errors) when t in ~w[in]a do
    parse(tokens, context, unit, acc, [{f,fm,[{t,tm,[l,r|ta]}|fa]}|root], acc2, errors)
  end
  def parse([{t,m,unit}|tokens], context, a, acc, root, acc2, errors) when t in ~w[by on]a do
    {a, context} = __parse__(a, context)
    parse(tokens, context, unit, [{t,m,:lists.append([a,acc])}], root, acc2, errors)
  end
  def parse([{_,[{:tag,t}|m],_}|tokens], context, unit, acc, root, acc2, errors) when t in ~w[asc desc]a do
    parse(tokens, context, [{t,m,[]}|unit], acc, root, acc2, errors)
  end
  def parse([{:paren=r,rm,ra}, {:all=a, am, aa}, {t, tm, []=ta}, {:paren=l, lm, la}|tokens], context, unit, acc, root, acc2, errors) when t in ~w[except intersect union]a do
    {:ok, context, la} = parse(la, context)
    {:ok, context, ra} = parse(ra, context)
    parse(tokens, context, unit, acc, [{t,tm,[{l,lm,la},{a, am, [{r, rm, ra}|aa]}|ta]}|root], acc2, errors)
  end
  def parse([{:paren=r,rm,ra}, {t, tm, []=ta}, {:paren=l, lm, la}|tokens], context, unit, acc, root, acc2, errors) when t in ~w[except intersect union]a do
    {:ok, context, la} = parse(la, context)
    {:ok, context, ra} = parse(ra, context)
    parse(tokens, context, unit, acc, [{t,tm,[{l,lm,la},{r, rm, ra}|ta]}|root], acc2, errors)
  end
  def parse([{a, am, []=aa}, {t, tm, []=ta}, {:paren=l, lm, la}|tokens], context, unit, acc, root, acc2, errors) when t in ~w[except intersect union]a and a in ~w[all distinct]a do
    {:ok, context, la} = parse(la, context)
    parse(tokens, context, unit, acc, [{t,tm,[{l, lm, la},{a, am, [sort(root)|aa]}|ta]}], acc2, errors)
  end
  def parse([{t, tm, []=ta}, {:paren=r, rm, ra}|tokens], context, []=unit, []=acc, root, acc2, errors) when t in ~w[except intersect union]a do
    {:ok, context, ra} = parse(ra, context)
    parse(tokens, context, unit, acc, [{t,tm,[{r, rm, ra}, sort(root)|ta]}], acc2, errors)
  end
  def parse([{a, am, []=aa}, {t, tm, []=ta}|tokens], context, []=unit, []=acc, root, acc2, errors) when t in ~w[except intersect union]a and a in ~w[all distinct]a do
    {:ok, context, la} = parse(tokens, context)
    parse([], context, unit, acc, [{t,tm,[la,{a,am,[sort(root)|aa]}|ta]}], acc2, errors)
  end
  def parse([{t, tm, []=ta}|tokens], context, []=unit, []=acc, root, acc2, errors) when t in ~w[except intersect union]a do
    {:ok, context, la} = parse(tokens, context)
    parse([], context, unit, acc, [{t,tm,[la, sort(root)|ta]}], acc2, errors)
  end
  def parse([{:join=t,m,[]=unit}, {:outer=o, om, oa}, {l, lm, la}, {:natural=n, nm, na}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2, errors) when l in ~w[left right full]a and tag in ~w[double_quote bracket dot ident as paren]a do
    {a, context} = __parse__(a, context)
    node = {t,m,:lists.append([a,acc])}
    parse(tokens, context, unit, unit, [{n, nm, [{l, lm, [{o, om, [node|oa]}|la]}|na]}|root], acc2, validate(node, context, errors))
  end
  def parse([{:join=t,m,[]=unit}, {:outer=o, om, oa}, {l, lm, la}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2, errors) when l in ~w[left right full]a and tag in ~w[double_quote bracket dot ident as paren]a do
    {a, context} = __parse__(a, context)
    node = {t,m,:lists.append([a,acc])}
    parse(tokens, context, unit, unit, [{l, lm, [{o, om, [node|oa]}|la]}|root], acc2, validate(node, context, errors))
  end
  def parse([{:join=t,m,[]=unit}, {:inner=i, im, ia}, {:natural=n, nm, []=na}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2, errors) when tag in ~w[double_quote bracket dot ident as paren]a do
    {a, context} = __parse__(a, context)
    node = {t,m,:lists.append([a,acc])}
    parse(tokens, context, unit, unit, [{n, nm, [{i, im, [node|ia]}|na]}|root], acc2, validate(node, context, errors))
  end
  def parse([{:join=t,m,[]=unit}, {l, lm, []=la}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2, errors) when l in ~w[inner left right full natural cross]a and tag in ~w[double_quote bracket dot ident as paren]a do
    {a, context} = __parse__(a, context)
    node = {t,m,:lists.append([a,acc])}
    parse(tokens, context, unit, unit, [{l, lm, [node|la]}|root], acc2, validate(node, context, errors))
  end
  def parse([{:join=t,m,[]=unit}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2, errors) when tag in ~w[double_quote bracket dot ident as paren]a do
    {a, context} = __parse__(a, context)
    node = {t,m,:lists.append([a,acc])}
    parse(tokens, context, unit, unit, [node|root], acc2, validate(node, context, errors))
  end
  def parse([{:from=t,m,[]=unit}|tokens], context, [{tag,_,_}|_]=a, acc, root, acc2, errors) when tag in ~w[double_quote bracket dot ident as binding]a do
    {a, context} = __parse__(a, context)
    node = {t,m,:lists.append([a,acc])}
    parse(tokens, context, unit, unit, [node|root], acc2, validate(node, context, errors))
  end
  def parse([{t,m,[]=unit}|tokens], context, a, acc, root, acc2, errors) when t in ~w[select where group having order limit offset]a do
    {a, context} = __parse__(a, context)
    node = {t,m,:lists.append([a,acc])}
    parse(tokens, context, unit, unit, [node|root], acc2, validate(node, context, errors))
  end
  # def parse([{t,m,[r, {:paren=t2,m2,a2}]}|tokens], context, unit, acc, root, acc2, errors) do
  #   {:ok, context, a2} = parse(a2, context)
  #   parse(tokens, context, [{t,m,[r, {t2,m2,a2}]}|unit], acc, root, acc2, errors)
  # end
  def parse([{:paren=t,m,a}|tokens], context, unit, acc, root, acc2, errors) do
    {:ok, context, a} = parse(a, context)
    parse(tokens, context, [{t,m,a}|unit], acc, root, acc2, errors)
  end
  def parse([{:table=tt,mt,at}, {:create=tc,mc,ac}|tokens], context, unit, acc, root, acc2, errors) do
    parse(tokens, context, at, acc, [{tc,mc,[{tt,mt,:lists.append([unit,acc])}|ac]}|root], acc2, errors)
  end
  def parse([{tag,_,_}=node|tokens], context, unit, acc, root, acc2, errors) when tag in ~w[numeric ident quote double_quote backtick bracket dot binding]a do
    parse(tokens, context, [node|unit], acc, root, acc2, errors)
  end
  def parse([node|tokens], context, unit, acc, root, acc2, errors) do
    parse(tokens, context, [node|unit], acc, root, acc2, errors)
  end

  def __parse__([l,{t,m,a},r|[{c,_,[]}|_]=rest],context) when c in ~w[and or]a, do: __parse__([{t,m,[l,r|a]}|rest],context)
  def __parse__([b,{c,cm,[]=ca},l,{t,m,a},r|[{c2,_,[]}|_]=rest],context) when c in ~w[and or]a and c2 in ~w[and or]a, do: __parse__([{c,cm,[b,{t,m,[l,r|a]}|ca]}|rest],context)
  def __parse__([b,{c,cm,[]=ca},l,{t,m,a},r|rest],context) when c in ~w[and or]a, do: __parse__([{c,cm,[b,{t,m,[l,r|a]}|ca]}|rest],context)
  def __parse__([{c,_,[_, _]}=l,{c2,c2m,[]=c2a},r|rest],context) when c in ~w[and or]a and c2 in ~w[and or]a, do: __parse__([{c2,c2m,[l,r|c2a]}|rest],context)
  def __parse__([b,{c,cm,[]=ca}|rest],context) when c in ~w[asc desc notnull isnull]a, do: __parse__([{c,cm,[b|ca]}|rest],context)
  def __parse__([b,{:not=c,cm,[]=ca},{:between=n,nm,[]=na},{d,dm,[]=da},l,{:and=f,fm,[]=fa},r|rest],context) when d in ~w[asymmetric symmetric]a, do: __parse__([{n,nm,[{c,cm,[b|ca]},{d,dm,[{f,fm,[l,r|fa]}|da]}|na]}|rest],context)
  def __parse__([b,{:not=c,cm,[]=ca},{:between=n,nm,[]=na},l,{:and=f,fm,[]=fa},r|rest],context), do: __parse__([{n,nm,[{c,cm,[b|ca]},{f,fm,[l,r|fa]}|na]}|rest],context)
  def __parse__([b,{:between=n,nm,[]=na},{d,dm,[]=da},l,{:and=f,fm,[]=fa},r|rest],context) when d in ~w[asymmetric symmetric]a, do: __parse__([{n,nm,[b,{d,dm,[{f,fm,[l,r|fa]}|da]}|na]}|rest],context)
  def __parse__([b,{:between=n,nm,[]=na},l,{:and=f,fm,[]=fa},r|rest],context), do: __parse__([{n,nm,[b,{f,fm,[l,r|fa]}|na]}|rest],context)

  def __parse__([b,{:is=c,cm,[]=ca},{:not=n,nm,[]=na},{:distinct=d,dm,[]=da},{:from=f,fm,[]=fa},node|rest],context), do: __parse__([{c,cm,[b,{n,nm,[{d,dm,[{f,fm,[node|fa]}|da]}|na]}|ca]}|rest],context)
  def __parse__([b,{:is=c,cm,[]=ca},{:distinct=d,dm,[]=da},{:from=f,fm,[]=fa},node|rest],context), do: __parse__([{c,cm,[b,{d,dm,[{f,fm,[node|fa]}|da]}|ca]}|rest],context)
  def __parse__([b,{:is=c,cm,[]=ca},{:not=n,nm,[]=na},{t,_,[]}=node|rest],context) when t in ~w[false true unknown null binding]a, do: __parse__([{c,cm,[b,{n,nm,[node|na]}|ca]}|rest],context)
  def __parse__([b,{:is=c,cm,[]=ca},{t,_,[]}=node|rest],context) when t in ~w[false true unknown null binding]a, do: __parse__([{c,cm,[b,node|ca]}|rest],context)
  def __parse__([b,{:not=n,nm,[]=na},{:in=c,cm,[]=ca},node|rest],context), do: __parse__([{c,cm,[{n,nm,[b|na]},node|ca]}|rest],context)
  def __parse__([{tl,_,a}=l,{tr,_,as}=r],context) when tl in ~w[ident double_quote bracket dot binding]a and tr in ~w[ident double_quote bracket dot binding]a, do: __parse__([{:as, [], [l,r]}], Map.update!(context, :aliases, &[{as, a}|&1]))
  def __parse__([b,{c,[{:type, :operator}|_]=cm,[]=ca},n|rest],context), do: __parse__([{c,cm,[b,n|ca]}|rest],context)
  def __parse__([l,{:comma=tc,mc,[]=ac}|unit],context), do: {[{tc,mc,[l|ac]}|unit], context}
  def __parse__(unit, context), do: {unit, context}

  @order %{select: 0, from: 1, join: 2, where: 3, group: 4, having: 5, window: 6, order: 7, limit: 8, offset: 9, fetch: 10}
  def sort(acc), do: Enum.sort_by(acc, fn {tag, _, _} -> Map.get(@order, tag) end, :asc)

  def validate(_, %{sql_lock: nil}, errors), do: errors
  def validate({tag, _, _}, %{sql_lock: %{columns: []}}, errors) when tag in ~w[select having where on by order group]a, do: errors
  def validate({tag, _, values}, %{sql_lock: %{columns: columns}}, errors) when tag in ~w[select having where on by order group]a do
    case validate_columns(columns, values, []) do
      [] -> errors
      e -> :lists.append([e,errors])
    end
  end
  def validate({tag, _, _}, %{sql_lock: %{tables: []}}, errors) when tag in ~w[from join]a, do: errors
  def validate({tag, _meta, values}, %{sql_lock: %{tables: tables}} = context, errors) when tag in ~w[from join]a do
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
      values -> :lists.append([values,errors])
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
