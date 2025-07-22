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
      @sql_adapter opts[:adapter]
      def sql_config, do: unquote(opts)
    end
  end

  defstruct [tokens: [], params: [], module: nil, id: nil, string: nil, inspect: nil]

  defimpl Inspect, for: SQL do
    def inspect(sql, _opts), do: ~s[~SQL"""\n#{sql.inspect}\n"""]
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
      ~SQL"\"\"
      from users select id, email
      "\"\"
  """
  @doc since: "0.1.0"
  defmacro sigil_SQL(left \\ [], right, modifiers) do
    SQL.build(left, right, modifiers, __CALLER__)
  end

  @doc false
  @doc since: "0.1.0"
  def parse(binary) do
    {:ok, context, tokens} = SQL.Lexer.lex(binary, __ENV__.file, 0, [format: true])
    {:ok, _context, tokens} = SQL.Parser.parse(tokens, context)
    ANSI.token_to_string(tokens)
  end

  @doc false
  def build(left, {:<<>>, _, _} = right, _modifiers, env) do
    module = if env.module, do: Module.get_attribute(env.module, :sql_adapter, ANSI), else: ANSI
    sql = struct(SQL, module: env.module)
    case build(left, right) do
      {:static, data} ->
        id = id(data)
        {:ok, context, tokens} = SQL.Lexer.lex(data, env.file)
        {:ok, context, t} = SQL.Parser.parse(tokens, context)
        string = IO.iodata_to_binary(module.token_to_string(t))
        sql = %{sql | tokens: t, string: string, inspect: data, id: id}
        case context.binding do
          []     -> Macro.escape(sql)
          params ->
            quote bind_quoted: [params: params, sql: Macro.escape(sql), env: Macro.escape(env)] do
              %{sql | params: cast_params(params, binding(), env)}
            end
        end

      {:dynamic, data} ->
        sql = %{sql | id: id(data)}
        quote bind_quoted: [left: Macro.unpipe(left), right: right, file: env.file, data: data, sql: Macro.escape(sql), env: Macro.escape(env), module: module] do
          {t, p} = Enum.reduce(left, {[], []}, fn
            {[], 0}, acc   -> acc
            {v, 0}, {t, p} -> {t ++ v.tokens, p ++ v.params}
            end)
          {:ok, context, tokens} = tokens(right, file, length(p), sql.id)
          tokens = t ++ tokens
          %{sql | params: :lists.flatten(p, cast_params(context.binding, binding(), env)), tokens: tokens, string: plan(tokens, context, sql.id, module), inspect: plan_inspect(data, sql.id)}
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
  def plan(tokens, context, id, module) do
    key = {module, id, :plan}
    case :persistent_term.get(key, nil) do
      nil ->
        {:ok, _context, tokens} = SQL.Parser.parse(tokens, context)
        string = IO.iodata_to_binary(module.token_to_string(tokens))
        :persistent_term.put(key, string)
        string

      string ->
        string
    end
  end

  @doc false
  def plan_inspect(data, id) do
    key = {id, :inspect}
    case :persistent_term.get(key, nil) do
      nil when is_binary(data) ->
        :persistent_term.put(key, data)
        data
      nil ->
        inspect = data
                |> Enum.map(fn
                ast when is_struct(ast) -> ast.inspect
                x -> x
                end)
                |> IO.iodata_to_binary()
        :persistent_term.put(key, inspect)
        inspect
      inspect ->
        inspect
    end
  end
end
