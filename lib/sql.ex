# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL do
  @moduledoc "README.md"
               |> File.read!()
               |> String.split("<!-- MDOC !-->")
               |> Enum.fetch!(1)
  @moduledoc since: "0.1.0"

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @doc false
      @behaviour SQL
      import SQL
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

  defstruct [:tokens, :params, :module, :id]

  @doc """
  Returns a parameterized SQL.

  ## Examples
      iex(1)> email = "john@example.com"
      iex(2)> SQL.to_sql(~SQL"select id, email from users where email = \#{email}")
      {"select id, email from users where email = $0", ["john@example.com"]}
  """
  @doc since: "0.1.0"
  def to_sql(%{params: params, id: id, module: module}), do: {:persistent_term.get({module, id, :plan}), params}

  @doc """
  Handles the sigil `~SQL` for SQL.

  It returns a `%SQL{}` struct that can be transformed to a parameterized query.

  ## Examples
      iex(1)> ~SQL"from users select id, email"
      "select id, email from users"
  """
  @doc since: "0.1.0"
  defmacro sigil_SQL(left \\ [], right, modifiers) do
    SQL.build(left, right, modifiers, __CALLER__)
  end

  @doc false
  @doc since: "0.1.0"
  def parse(binary) do
    {:ok, _opts, _, _, _, _, tokens} = SQL.Lexer.lex(binary, {1, 0, nil}, 0, [format: true])
    tokens
    |> SQL.Parser.parse()
    |> to_query()
    |> to_string(SQL.String)
  end

  @doc false
  @doc since: "0.1.0"
  @acc ~w[for create drop insert alter with update delete select set fetch from join where group having window except intersect union order limit offset lock colon in declare start grant revoke commit rollback open close comment comments into]a
  def to_query([value | _] = tokens) when is_tuple(value) and elem(value, 0) in @acc do
    Enum.reduce(@acc, [], fn key, acc -> acc ++ for {k, meta, v} <- Enum.filter(tokens, &(elem(&1, 0) == key)), do: {k, meta, Enum.map(v, &to_query/1)} end)
  end
  def to_query({:parens = tag, meta, values}) do
    {tag, meta, to_query(values)}
  end
  def to_query({tag, meta, values}) do
    {tag, meta, Enum.map(values, &to_query/1)}
  end
  def to_query(tokens) when is_list(tokens) do
    Enum.map(tokens, &to_query/1)
  end
  def to_query(token) do
    token
  end

  defimpl Inspect, for: SQL do
    def inspect(sql, _opts), do: Inspect.Algebra.concat(["~SQL\"\"\"\n", :persistent_term.get({sql.id, :inspect}), "\n\"\"\""])
  end

  defimpl String.Chars, for: SQL do
    def to_string(%{id: id, module: module}), do: :persistent_term.get({module, id, :plan})
    def to_string(%{tokens: tokens, module: module}), do: SQL.to_string(tokens, module)
  end

  @doc false
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
        <<";", _::binary>> = v -> [acc | v]
        v -> [acc, " " | v]
      end
    end)
    |> IO.iodata_to_binary()
  end

  @doc false
  def build(left, {:<<>>, _, _} = right, _modifiers, env) do
    data = build(left, right)
    quote bind_quoted: [module: env.module, left: Macro.unpipe(left), right: right, file: env.file, id: id(data), data: data] do
      plan_inspect(data, id)
      {t, p} = Enum.reduce(left, {[], []}, fn
        {[], 0}, acc -> acc
        {v, 0}, {t, p} ->
        {t ++ v.tokens, p ++ v.params}
        end)
      {tokens, params} = tokens(right, file, length(p), id)
      tokens = t ++ tokens
      plan(tokens, id, module)
      struct(SQL, params: cast_params(params, p, binding()), tokens: tokens, id: id, module: module)
    end
  end

  @doc false
  def build(left, {:<<>>, _, right}) do
    left
    |> Macro.unpipe()
    |> Enum.reduce({:iodata, right}, fn
        {[], 0}, acc -> acc
        {{:sigil_SQL, _meta, [{:<<>>, _, value}, []]}, 0}, {type, acc} -> {type, [value, ?\s, acc]}
        {{_, _, _} = var, 0}, {_, acc} ->
        {:dynamic, [var, ?\s, acc]}
    end)
    |> case do
      {:iodata, data} -> IO.iodata_to_binary(data)
      {:dynamic, data} -> data
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
  def cast_params(bindings, params, binding) do
    Enum.reduce(bindings, params, fn
        {:var, var}, acc -> if v = binding[String.to_atom(var)], do: acc ++ [v], else: acc
        {:code, code}, acc -> acc ++ [elem(Code.eval_string(code, binding), 0)]
    end)
  end

  @doc false
  def tokens(binary, file, count, id) do
    key = {id, :lex}
    if result = :persistent_term.get(key, nil) do
      result
    else
      {:ok, opts, _, _, _, _, tokens} = SQL.Lexer.lex(binary, file, count)
      result = {tokens, opts[:binding]}
      :persistent_term.put(key, result)
      result
    end
  end

  @doc false
  def plan(tokens, id, module) do
    key = {module, id, :plan}
    if :persistent_term.get(key, nil) do
      id
    else
      :persistent_term.put(key, to_string(SQL.to_query(SQL.Parser.parse(tokens)), module))
      id
    end
  end

  @doc false
  def plan_inspect(data, id) do
    key = {id, :inspect}
    if !:persistent_term.get(key, nil) do
      data = case data do
               data when is_list(data) ->
                 data
                 |> Enum.map(fn
                    ast when is_struct(ast) -> :persistent_term.get({ast.id, :inspect}, nil)
                    x -> x
                 end)
                 |> IO.iodata_to_binary()

               data -> data
             end

      :persistent_term.put(key, data)
    end
  end
end
