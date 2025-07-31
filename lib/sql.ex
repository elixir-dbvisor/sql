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
        Module.put_attribute(__MODULE__, :sql_lock, build_lock())
      else
        IO.warn("Could not find a sql.lock, please run mix sql.get")
      end
      Module.put_attribute(__MODULE__, :sql_adapter, opts[:adapter])
      def sql_config, do: unquote(opts)
    end
  end

  defstruct [tokens: [], params: [], module: nil, id: nil, string: nil, inspect: nil]

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

  @doc false
  @doc since: "0.1.0"
  def parse(binary, opts \\ [format: true, module: ANSI, sql_lock: nil]) do
    {:ok, context, tokens} = SQL.Lexer.lex(binary)
    {:ok, context, tokens} = SQL.Parser.parse(tokens, Map.merge(context, Map.new(opts)))
    iodata = context.module.to_iodata(tokens, context, 0, [])
    if context.errors != [], do: IO.warn(IO.ANSI.format([?\n, format_error(context.errors), "  \n  ", IO.ANSI.format(iodata), ?\n]))
    IO.iodata_to_binary(IO.ANSI.format(iodata, false))
  end

  @doc false
  def build(left, {:<<>>, _, _} = right, _modifiers, env) do
    module = if env.module, do: Module.get_attribute(env.module, :sql_adapter, ANSI), else: Application.get_env(:sql, :adapter, ANSI)
    sql_lock = if env.module, do: Module.get_attribute(env.module, :sql_lock)
    sql = struct(SQL, module: env.module)
    stack = if env.function do
              {env.module, elem(env.function, 0), elem(env.function, 1), [file: Path.relative_to_cwd(env.file), line: env.line]}
            else
              {env.module, env.function, 0, [file: Path.relative_to_cwd(env.file), line: env.line]}
            end
    case build(left, right) do
      {:static, data} ->
        id = id(data)
        {:ok, context, tokens} = SQL.Lexer.lex(data, env.file)
        {:ok, context, t} = SQL.Parser.parse(tokens, Map.merge(context, %{sql_lock: sql_lock, module: module}))
        {string, inspect} = format(t, context, stack)
        sql = %{sql | tokens: t, string: string, inspect: inspect, id: id}
        case context.binding do
          []     -> Macro.escape(sql)
          params ->
            quote bind_quoted: [params: params, sql: Macro.escape(sql), env: Macro.escape(env)] do
              %{sql | params: cast_params(params, binding(), env)}
            end
        end

      {:dynamic, data} ->
        sql = %{sql | id: id(data)}
        quote bind_quoted: [left: Macro.unpipe(left), right: right, file: env.file, data: data, sql: Macro.escape(sql), env: Macro.escape(env), module: module, sql_lock: Macro.escape(sql_lock), stack: Macro.escape(stack)] do
          {t, p} = Enum.reduce(left, {[], []}, fn
            {[], 0}, acc   -> acc
            {v, 0}, {t, p} -> {t ++ v.tokens, p ++ v.params}
            end)
          {:ok, context, tokens} = tokens(right, file, length(p), sql.id)
          tokens = t ++ tokens
          {string, inspect} = plan(tokens, Map.merge(context, %{sql_lock: sql_lock, module: module}), sql.id, stack)
          %{sql | params: :lists.flatten(p, cast_params(context.binding, binding(), env)), tokens: tokens, string: string, inspect: inspect}
        end
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
  def cast_params(params, binding, env) do
    Enum.map(params, fn
      q when is_tuple(q) ->
        {q, _, _} = Code.eval_quoted_with_env(q, binding, env)
        q
      q -> q
    end)
  end

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
        format = format(tokens, context, stack)
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
  def format_error(errors), do: Enum.group_by(errors, &elem(&1, 2)) |> Enum.reduce([], fn
    {k, v}, acc -> [acc | ["the relation ", :red, k, :reset, " is mentioned #{length(v)} times but does not exist", ?\n]]
  end)

  @doc false
  def format(tokens, %{errors: [], module: module} = context, _stack) do
    {IO.iodata_to_binary(module.token_to_string(tokens)), ~s[~SQL"""\n#{IO.iodata_to_binary(IO.ANSI.format(module.to_iodata(tokens, Map.merge(%{format: true}, context), 0, []), false))}"""]}
  end

  @doc false
  def format(tokens, %{errors: errors, module: module} = context, stack) do
    iodata = module.to_iodata(tokens, Map.merge(%{format: true}, context), 0, [])
    {:current_stacktrace, [_|t]} = Process.info(self(), :current_stacktrace)
    IO.warn(IO.ANSI.format([?\n, format_error(errors), iodata]), [stack|t])
    {IO.iodata_to_binary(module.token_to_string(tokens)), ~s[~SQL"""\n#{IO.iodata_to_binary(IO.ANSI.format(iodata, false))}"""]}
  end
end
