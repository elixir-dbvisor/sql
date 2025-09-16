# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL do
  @moduledoc "README.md"
               |> File.read!()
               |> String.split("<!-- MDOC !-->")
               |> Enum.fetch!(1)
  @moduledoc since: "0.1.0"
  alias SQL.Adapters.ANSI

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @doc false
      import SQL
      if File.exists?(Path.relative_to_cwd("sql.lock")) do
        config = Keyword.merge([case: :lower, adapter: Application.compile_env(:sql, :adapter, ANSI), lock: build_lock()], opts)
        Module.put_attribute(__MODULE__, :sql_config, Map.new(config))
        def sql_config, do: unquote(Macro.escape(Map.new(config)))
      else
        IO.warn("Could not find a sql.lock, please run mix sql.get")
        config = Keyword.merge([case: :lower, adapter: Application.compile_env(:sql, :adapter, ANSI), lock: nil], opts)
        Module.put_attribute(__MODULE__, :sql_config, Map.new(config))
        def sql_config, do: unquote(Macro.escape(Map.new(config)))
      end
    end
  end

  defstruct [tokens: [], idx: 0, params: [], module: nil, id: nil, string: nil, inspect: nil, fn: nil]

  defimpl Inspect, for: SQL do
    def inspect(sql, _opts), do: sql.inspect
  end

  defimpl String.Chars, for: SQL do
    def to_string(sql), do: sql.string
  end

  @doc """
  Returns a parameterized SQL.

  ## Examples
      iex(1)> email = "john@example.com"
      iex(2)> SQL.to_sql(~SQL"select id, email from users where email = {{email}}")
      {"select id, email from users where email = ?", ["john@example.com"]}
  """
  @doc since: "0.1.0"
  def to_sql(sql), do: {sql.string, sql.params}

  @doc """
  Handles the sigil `~SQL` for SQL.

  It returns a `%SQL{}` struct that can be transformed to a parameterized query.

  ## Examples
      iex(1)> ~SQL"from users select id, email"
      ~SQL\"\"\"
      select
        id,
        email
      from
        users
      \"\"\"
  """
  @doc since: "0.1.0"
  defmacro sigil_SQL(left \\ [], right, modifiers) do
    SQL.build(left, right, modifiers, __CALLER__)
  end

  @doc """
  Perform transformation on the result set.

  ## Examples
      iex(1)> SQL.map(~SQL"from users select id, email", fn row, columns -> Map.new(Enum.zip(columns, row)) end)
      ~SQL\"\"\"
      select
        id,
        email
      from
        users
      \"\"\"
  """
  @doc since: "0.4.0"
  defmacro map(left, right) do
    SQL.build(left, right, __CALLER__)
  end

  @doc false
  @doc since: "0.1.0"
  def parse(binary, opts \\ [format: :block, module: ANSI, sql_lock: nil]) do
    {:ok, context, tokens} = SQL.Lexer.lex(binary)
    {:ok, context, tokens} = SQL.Parser.parse(tokens, Map.merge(context, Map.new(opts)))
    iodata = context.module.to_iodata(tokens, context, 0, [])
    if context.errors != [], do: IO.warn([?\n, format_error(context.errors), "  \n  ", iodata, ?\n])
    IO.iodata_to_binary(iodata)
  end

  @doc false
  def build(left, {:<<>>, _, _} = right, _modifiers, env) do
    config = %{case: :lower, adapter: Application.get_env(:sql, :adapter, ANSI), lock: nil}
    config = if env.module, do: Module.get_attribute(env.module, :sql_config, config), else: config
    sql = struct(SQL, module: config.adapter)
    stack = if env.function do
              {env.module, elem(env.function, 0), elem(env.function, 1), [file: Path.relative_to_cwd(env.file), line: env.line]}
            else
              {env.module, env.function, 0, [file: Path.relative_to_cwd(env.file), line: env.line]}
            end
    case build(left, right) do
      {:static, data} ->
        id = id(data)
        {:ok, context, tokens} = SQL.Lexer.lex(data, env.file)
        {:ok, context, tokens} = SQL.Parser.parse(tokens, %{context|sql_lock: config.lock, module: config.adapter, case: config.case})
        sql = %{sql | idx: context.idx, tokens: tokens, string: IO.iodata_to_binary(context.module.to_iodata(tokens, context, 0, [])), inspect: __inspect__(tokens, context, stack), id: id}
        case context.binding do
          []     -> Macro.escape(sql)
          params ->
            quote bind_quoted: [params: params, sql: Macro.escape(sql), env: Macro.escape(env)] do
              %{sql | params: cast_params(params, binding(), env, [])}
            end
        end

      {:dynamic, data} ->
        sql = %{sql | id: id(data)}
        quote bind_quoted: [left: Macro.unpipe(left), right: right, file: env.file, data: data, sql: Macro.escape(sql), env: Macro.escape(env), config: Macro.escape(config), stack: Macro.escape(stack)] do
          {t,p,idx} = Enum.reduce(left, {[], [], 0}, fn
            {[], 0}, acc        -> acc
            {v, 0}, {t, p, idx} -> {t++v.tokens, p++v.params, idx+v.idx}
            end)
          {:ok, context, tokens} = tokens(right, file, idx, sql.id)
          tokens = t++tokens
          {string, inspect} = plan(tokens, %{context|sql_lock: config.lock, module: config.adapter, format: :dynamic}, sql.id, stack)
          %{sql | params: p++cast_params(context.binding, binding(), env, []), tokens: tokens, string: string, inspect: inspect}
        end
    end
  end

  @doc false
  def build(left, {tag, _, _} = right, _env) when tag in ~w[fn &]a do
    {_type, data, acc2} = left
    |> Macro.unpipe()
    |> Enum.reduce({:static, [], []}, fn
        {[], 0}, acc -> acc
        {{_, _, []} = r, 0}, {_, l, right} -> {:dynamic, Macro.pipe(l, r, 0), right}
        {{:sigil_SQL, _meta, [{:<<>>, _, _}, []]} = r, 0}, {type, l, right} -> {type, Macro.pipe(l, r, 0), right}
        {{{:.,_,[{_,_,[:SQL]},:map]},_,[left]}, 0}, {type, acc, acc2} -> {type, acc, [left|acc2]}
    end)
    [r | rest] = Enum.reverse([right|acc2])
    right = Enum.reduce(rest, r, fn r, {t, m, [{t2, m2, [vars, block]}]} -> {t, m, [{t2, m2, [vars, quote(do: unquote(r).(unquote(block)))]}]} end)
    quote bind_quoted: [left: data, right: right] do
      %{left | fn: right}
    end
  end

  @doc false
  def build(left, {:<<>>, _, right}) do
    left
    |> Macro.unpipe()
    |> Enum.reduce({:static, right}, fn
        {[], 0}, acc -> acc
        {{:sigil_SQL, _meta, [{:<<>>, _, value}, []]}, 0}, {type, acc} -> {type, [value, ?\s, acc]}
        {{_, _, _} = var, 0}, {_, acc} -> {:dynamic, [var, ?\s, acc]}
    end)
    |> case do
      {:static, data}  -> {:static, IO.iodata_to_binary(data)}
      {:dynamic, data} -> {:dynamic, data}
    end
  end

  @doc false
  def id(data) do
    case :persistent_term.get(data, nil) do
      nil ->
        id = System.unique_integer([:positive])
        :persistent_term.put(data, id)
        id
      id -> id
    end
  end

  @doc false
  def cast_params([], _binding, _env, acc), do: acc
  def cast_params([q|params], binding, env, acc) when is_tuple(q) do
    {q, _, _} = Code.eval_quoted_with_env(q, binding, env)
    cast_params(params, binding, env, [q|acc])
  end
  def cast_params([q|params], binding, env, acc), do: cast_params(params, binding, env, [q|acc])

  @doc false
  def tokens(binary, file, count, id) do
    key = {id, :lex}
    case :persistent_term.get(key, nil)  do
      nil ->
        result = SQL.Lexer.lex(binary, file, count)
        :persistent_term.put(key, result)
        result

      result ->
        result
    end
  end

  @doc false
  def plan(tokens, context, id, stack) do
    key = {context.module, id, :plan}
    case :persistent_term.get(key, nil) do
      nil ->
        {:ok, context, tokens} = SQL.Parser.parse(tokens, context)
        format = {IO.iodata_to_binary(context.module.to_iodata(tokens, context, 0, [])), __inspect__(tokens, context, stack)}
        :persistent_term.put(key, format)
        format

      format ->
        format
    end
  end

  @doc false
  def build_lock() do
    case elem(Code.eval_file("sql.lock", File.cwd!()), 0) do
      %{tables: tables, columns: columns} = data ->
        %{data |
        tables: Enum.map(tables, fn %{table_name: table_name} = table -> %{table | table_name: to_match(table_name)} end),
        columns: Enum.map(columns, fn %{table_name: table_name, column_name: column_name} = column -> %{column | table_name: to_match(table_name), column_name: to_match(column_name)} end)
      }
      data -> data
    end
  end

  @doc false
  def to_match(value), do: {value, atom(value), function(value)}

  @doc false
  def function(value) do
    {:fn, [], [head(value),{:->, [], [[{:_, [], Elixir}], false]}]}
    |> Code.eval_quoted()
    |> elem(0)
  end

  @doc false
  def atom(value), do: String.to_atom(String.downcase(value))

  @doc false
  def match(value), do: Enum.reduce(1..byte_size(value), [], fn n, acc -> [acc | [{:"b#{n}", [], Elixir}]] end)

  @doc false
  def head(value), do: {:->, [], [[{:when, [],[match(value),guard(value)]}], true]}

  @doc false
  def guard(value, acc \\ []) do
    {value, _n} = for <<k <- String.downcase(value)>>, reduce: {acc, 1} do
      {[], n}  -> {__guard__(k, n), n+1}
      {acc, n} -> {{:and, [context: Elixir, imports: [{2, Kernel}]], [acc,__guard__(k, n)]}, n+1}
    end
    value
  end

  @doc false
  def __guard__(k, n) do
    {:in, [context: Elixir, imports: [{2, Kernel}]],[{:"b#{n}", [], Elixir},{:sigil_c, [delimiter: "\"", context: Elixir, imports: [{2, Kernel}]],[{:<<>>, [], ["#{<<k>>}#{String.upcase(<<k>>)}"]}, []]}]}
  end

  @doc false
  def __inspect__(tokens, %{errors: [], module: module} = context, _stack) do
    IO.iodata_to_binary(["~SQL\"\"\""|pad(module.to_iodata(tokens, %{context|format: :block}, 0, ["\n\"\"\""]))])
  end
  def __inspect__(tokens, %{errors: errors, module: module} = context, stack) do
    inspect = IO.iodata_to_binary(["~SQL\"\"\""|pad(module.to_iodata(tokens, %{context|format: :block}, 0, ["\n\"\"\""]))])
    {:current_stacktrace, [_|t]} = Process.info(self(), :current_stacktrace)
    IO.warn([?\n,format_error(errors), inspect], [stack|t])
    inspect
  end

  @doc false
  def format_error(errors), do: Enum.group_by(errors, &elem(&1, 2)) |> Enum.reduce([], fn
    {k, [{:special, _, _}]}, acc -> [acc|["the operator \e[31m",k,"\e[0m is invalid, did you mean any of #{__suggest__(k)}\n"]]
    {k, [{:special, _, _}|_]=v}, acc -> [acc|["the operator \e[31m",k,"\e[0m is mentioned #{length(v)} times but is invalid, did you mean any of #{__suggest__(k)}\n"]]
    {k, [_]}, acc -> [acc|["the relation \e[31m",k,"\e[0m does not exist\n"]]
    {k, v}, acc -> [acc|["the relation \e[31m",k,"\e[0m is mentioned #{length(v)} times but does not exist\n"]]
  end)

  @doc false
  def __suggest__(k), do: Enum.join(SQL.Lexer.suggest_operator(:erlang.iolist_to_binary(k)), ", ")

  @doc false
  def pad([?\n|_]=acc), do: acc
  def pad(acc), do: [?\n|acc]

  defimpl Enumerable, for: SQL do
    def count(_enumerable) do
      {:error, __MODULE__}
    end
    def member?(_enumerable, _element) do
      {:error, __MODULE__}
    end
    def reduce(%SQL{} = enumerable, acc, fun) do
      repo = enumerable.module.sql_config()[:repo]
      %{rows: rows, columns: columns} = repo.query!(enumerable.string, enumerable.params)
      fun = case Function.info(enumerable.fn, :arity) do
              {:arity, 1} -> fn row, acc -> fun.(enumerable.fn.(row), acc) end
              {:arity, 2} -> fn row, acc -> fun.(enumerable.fn.(row, columns), acc) end
              {:arity, 3} -> fn row, acc -> fun.(enumerable.fn.(row, columns, repo), acc) end
            end
      Enumerable.reduce(rows, acc, fun)
    end
    def slice(_enumerable) do
      {:error, __MODULE__}
    end
  end
end
