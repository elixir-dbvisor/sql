# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL do
  @moduledoc "README.md"
               |> File.read!()
               |> String.split("<!-- MDOC !-->")
               |> Enum.fetch!(1)
  @moduledoc since: "0.1.0"

  @adapters [SQL.Adapters.ANSI, SQL.Adapters.MySQL, SQL.Adapters.Postgres, SQL.Adapters.TDS]
  @compile {:inline, cast_params: 4}

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @doc false
      @behaviour SQL
      import SQL
      @sql_adapter opts[:adapter]
      def sql_config, do: unquote(opts)
      def token_to_sql(token), do: token_to_sql(token)
      defoverridable token_to_sql: 1
    end
  end
  @optional_callbacks token_to_sql: 1

  @doc """
  Returns a SQL string for a given token.
  """
  @doc since: "0.1.0"
  @doc deprecated: "Use SQL.Token.token_to_string/1 instead"
  @callback token_to_sql(token :: {atom, keyword, list}) :: String.t()

  defstruct [tokens: [], params: [], module: nil, id: nil, string: nil, inspect: nil]

  defimpl Inspect, for: SQL do
    def inspect(sql, _opts), do: Inspect.Algebra.concat(["~SQL\"\"\"\n", sql.inspect, "\n\"\"\""])
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
    {:ok, context, tokens} = SQL.Parser.parse(tokens, context)
    tokens
    |> to_query(context)
    |> to_string(SQL.Adapters.ANSI)
  end

  @doc false
  @doc since: "0.3.0"
  @acc ~w[for create drop insert alter with update delete select set fetch from join where group having window except intersect union order limit offset lock colon in declare start grant revoke commit rollback open close comment comments into]a
  def to_query([value | _] = tokens, context) when is_tuple(value) and elem(value, 0) in @acc do
    Enum.reduce(@acc, [], fn key, acc -> acc ++ for {k, meta, v} <- Enum.filter(tokens, &(elem(&1, 0) == key)), do: {k, meta, Enum.map(v, &to_query(&1, context))} end)
  end
  def to_query({:paren = tag, meta, values}, context) do
    {tag, meta, to_query(values, context)}
  end
  def to_query({tag, meta, values}, context) do
    {tag, meta, Enum.map(values, &to_query(&1, context))}
  end
  def to_query(tokens, context) when is_list(tokens) do
    Enum.map(tokens, &to_query(&1, context))
  end
  def to_query(token, _context) do
    token
  end

  @doc false
  def to_string(tokens, module) when module in @adapters do
    tokens
    |> Enum.reduce([], fn
      token, [] = acc -> [acc | module.token_to_string(token)]
      token, acc ->
      case module.token_to_string(token) do
        <<?;, _::binary>> = v -> [acc | v]
        v -> [acc, " " | v]
      end
    end)
    |> IO.iodata_to_binary()
  end
  def to_string(tokens, module) do
    fun = cond do
      Kernel.function_exported?(module, :sql_config, 0) -> &module.sql_config()[:adapter].token_to_string(&1)
      Kernel.function_exported?(module, :token_to_string, 2) -> &module.token_to_string(&1)
      true -> &SQL.String.token_to_sql(&1)
    end
    tokens
    |> Enum.reduce([], fn
      token, [] = acc -> [acc | fun.(token)]
      token, acc ->
      case fun.(token) do
        <<?;, _::binary>> = v -> [acc | v]
        v -> [acc, " " | v]
      end
    end)
    |> IO.iodata_to_binary()
  end

  @doc false
  def build(left, {:<<>>, _, _} = right, _modifiers, env) do
    module = if env.module, do: Module.get_attribute(env.module, :sql_adapter, SQL.Adapters.ANSI), else: SQL.Adapters.ANSI
    case build(left, right) do
      {:static, data} ->
        {:ok, context, tokens} = SQL.Lexer.lex(data, env.file)
        {:ok, context, t} = SQL.Parser.parse(tokens, context)
        sql = struct(SQL, tokens: tokens, string: SQL.to_string(SQL.to_query(t, context), module), module: env.module, inspect: data, id: id(data))
        case context.binding do
            [] -> Macro.escape(sql)
            params ->
                quote bind_quoted: [params: params, sql: Macro.escape(sql), env: Macro.escape(env)] do
                    %{sql | params: cast_params(params, [], binding(), env)}
                end
        end

      {:dynamic, data} ->
        sql = struct(SQL, id: id(data), module: env.module)
        quote bind_quoted: [left: Macro.unpipe(left), right: right, file: env.file, data: data, sql: Macro.escape(sql), env: Macro.escape(env)] do
          {t, p} = Enum.reduce(left, {[], []}, fn
            {[], 0}, acc   -> acc
            {v, 0}, {t, p} -> {t ++ v.tokens, p ++ v.params}
            end)
          {:ok, context, tokens} = tokens(right, file, length(p), sql.id)
          tokens = t ++ tokens
          %{sql | params: cast_params(context.binding, p, binding(), env), tokens: tokens, string: plan(tokens, context, sql.id, sql.module), inspect: plan_inspect(data, sql.id)}
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
      {:static, data} -> {:static, IO.iodata_to_binary(data)}
      {:dynamic, data} -> {:dynamic, data}
    end
  end

  @doc false
  def id(data) do
    if id = :persistent_term.get(data, nil) do
      id
    else
      id = System.unique_integer([:positive])
      :persistent_term.put(data, id)
      id
    end
  end

  @doc false
  def cast_params(bindings, params, binding, env) do
    Enum.reduce(bindings, params, fn
        quoted, acc when is_tuple(quoted) -> acc ++ [elem(Code.eval_quoted_with_env(quoted, binding, env), 0)]
        quoted, acc -> acc ++ [quoted]
    end)
  end

  @doc false
  def tokens(binary, file, count, id) do
    key = {id, :lex}
    if result = :persistent_term.get(key, nil) do
      result
    else
      result = SQL.Lexer.lex(binary, file, count)
      :persistent_term.put(key, result)
      result
    end
  end

  @doc false
  def plan(tokens, context, id, module) do
    key = {module, id, :plan}
    if string = :persistent_term.get(key, nil) do
      string
    else
      {:ok, context, tokens} = SQL.Parser.parse(tokens, context)
      string = to_string(SQL.to_query(tokens, context), module)
      :persistent_term.put(key, string)
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
