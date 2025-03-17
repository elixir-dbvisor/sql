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
      def token_to_sql(token), do: token_to_sql(token)
      defoverridable token_to_sql: 1
    end
  end
  @optional_callbacks token_to_sql: 1

  @doc """
  Returns a SQL string for a given token.
  """
  @doc since: "0.1.0"
  @callback token_to_sql(token :: {atom, keyword, list}) :: String.t()

  defstruct [:tokens, :query, :params, :module]

  @doc """
  Returns a parameterized SQL.

  ## Examples
      iex(1)> email = "john@example.com"
      iex(2)> SQL.to_sql(~SQL"select id, email from users where email = \#{email}")
      {"select id, email from users where email = $0", ["john@example.com"]}
  """
  @doc since: "0.1.0"
  def to_sql(sql), do: {"#{sql}", sql.params}

  @doc false
  def build(right, {:<<>>, meta, _} = left, _modifiers, env) do
    quote bind_quoted: [right: Macro.unpipe(right), left: left, meta: Macro.escape({meta[:line], meta[:column] || 0, env.file})] do
      {t, p} = Enum.reduce(right, {[], []}, fn
        {[], 0}, acc -> acc
        {v, 0}, {tokens, params} -> {tokens ++ v.tokens, params ++ v.params}
        end)
      {:ok, tokens, params} = SQL.Parser.parse(left, binding(), meta, p)
      t ++ tokens
      |> SQL.to_query()
      |> Map.merge(%{module: __MODULE__, params: params})
    end
  end

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
  def parse(binary) do
    {:ok, tokens, []} = SQL.Parser.parse(binary, false, {1, 0, nil})
    to_query(tokens)
  end

  @doc false
  @acc ~w[; with update delete select fetch from join where group having window except intersect union order limit offset lock]a
  def to_query([value | _] = tokens) when is_tuple(value) and elem(value, 0) in @acc do
    struct(SQL, tokens: tokens, query: Enum.reduce(@acc, [], fn key, acc -> acc ++ for {k, meta, v} <- Enum.filter(tokens, &(elem(&1, 0) == key)), do: {k, meta, Enum.map(v, &to_query/1)} end))
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

  @doc false
  def __token_to_sql__(sql) do
    if Kernel.function_exported?(sql.module, :token_to_sql, 1) do
      &sql.module.token_to_sql/1
    else
      &SQL.String.token_to_sql/1
    end
  end

  defimpl Inspect, for: SQL do
    def inspect(sql, _opts) do
      fun = SQL.__token_to_sql__(sql)
      string = "#SQL<#{to_string(sql)}"
      Enum.reduce(0..length(sql.params), String.pad_trailing(string, byte_size(string)+2, ";>"), &String.replace(&2, fun.({:binding, [], [&1]}), fun.(Enum.at(sql.params, &1))))
    end
  end

  defimpl String.Chars, for: SQL do
    def to_string(sql) do
      Enum.map_join(sql.query, " ", &SQL.__token_to_sql__(sql).(&1))
    end
  end
end
