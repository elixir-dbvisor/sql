# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL do
  @moduledoc "README.md"
               |> File.read!()
               |> String.split("<!-- MDOC !-->")
               |> Enum.fetch!(1)
  @moduledoc since: "0.1.0"
  alias SQL.Adapters.ANSI

  @pool :default
  @queue_timeout 50
  @db_timeout 15000
  @adapter ANSI

  defmacro __using__(opts) do
    quote do
      opts = unquote(opts)
      if Mix.Project.get() != SQL.MixProject, do: Application.ensure_all_started(:sql, :permanent)
      @doc false
      import SQL
      pool = opts[:pool] || unquote(@pool)
      config = Keyword.get(Application.compile_env(:sql, :pools, []), pool)
      adapter = opts[:adapter] || config[:adapter] || unquote(@adapter)
      queue_timeout = opts[:queue_timeout] || config[:queue_timeout] || unquote(@queue_timeout)
      config = Map.new(Keyword.merge([case: :lower, columns: [], adapter: adapter, validate: fn _, _ -> true end],  opts))
      path = Path.relative_to_cwd("sql.lock")
      @external_resource path
      config = with true <- File.exists?(path),
                    %{validate: validate, columns: columns} <- elem(Code.eval_file("sql.lock", File.cwd!()), 0) do
                    %{config | validate: validate, columns: columns}
               else
                _  ->
                  %{config | columns: :persistent_term.get({pool, :columns}, [])}
               end
      Module.put_attribute(__MODULE__, :sql_config, config)
      Module.put_attribute(__MODULE__, :sql_adapter, adapter)
      Module.put_attribute(__MODULE__, :sql_pool, pool)
      Module.put_attribute(__MODULE__, :sql_queue_timeout, queue_timeout)
    end
  end

  defstruct [tokens: [], params: [], vars: [], columns: [], types: nil, decoder: nil, adapter: nil, module: nil, id: nil, string: nil, inspect: nil, fn: nil, context: nil, pool: @pool, db_timeout: @db_timeout, msg: nil, max_rows: 0, acc: nil, queue_timeout: @queue_timeout]

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
      iex(1)> SQL.map(~SQL"from users select id, email", &IO.inspect/1)
      ~SQL\"\"\"
      select
        id,
        email
      from
        users
      \"\"\"
  """
  @doc since: "0.4.0"
  defmacro map(sql, fun) do
    SQL.build(sql, fun, __CALLER__)
  end

  @doc """
  Perform a transaction.

  ## Examples
      iex(1)> SQL.transaction, do: Enum.list(~SQL"from users select id, email")
  """
  @doc since: "0.5.0"
  defmacro transaction(opts \\ [], do: block) do
    pool = opts[:pool] || Module.get_attribute(__CALLER__.module, :sql_pool, @pool)
    timeout = opts[:timeout] || Module.get_attribute(__CALLER__.module, :sql_queue_timeout, @queue_timeout)
    adapter = opts[:adapter] || Module.get_attribute(__CALLER__.module, :sql_adapter, @adapter)
    id = :erlang.phash2(block)
    savepoint = parse("savepoint sp_#{id}", [adapter: adapter, pool: pool])
    release = parse("release savepoint sp_#{id}", [adapter: adapter, pool: pool])
    rollback = parse("rollback to savepoint sp_#{id}", [adapter: adapter, pool: pool])
    quote generated: true do
      case SQL.transaction() do
        nil ->
          case SQL.Pool.checkout(unquote(pool), unquote(timeout)) do
            {:error, :timeout} = error -> error
            {:ok, conn, socket, prepared, slot} ->
              Process.put(SQL.Transaction, {conn, socket, prepared})
              Stream.run(%{~SQL[begin] | pool: unquote(pool)})
              result = try do
                result = unquote(block)
                Stream.run(%{~SQL[commit] | pool: unquote(pool)})
                case result do
                  {status, _} when status in ~w[error ok]a -> result
                  result -> {:ok, result}
                end
              rescue
                e ->
                  Stream.run(%{~SQL[rollback] | pool: unquote(pool)})
                  {:error, e}
              end
              SQL.Pool.checkin(unquote(pool), slot)
              result
          end
        _ ->
          Stream.run(unquote(Macro.escape(savepoint)))
          try do
            result = unquote(block)
            Stream.run(unquote(Macro.escape(release)))
            case result do
              {status, _} when status in ~w[error ok]a -> result
              result -> {:ok, result}
            end
          rescue
            e ->
            Stream.run(unquote(Macro.escape(rollback)))
            {:error, e}
          end
      end
    end
  end

  @doc false
  @doc since: "0.5.0"
  defmacro begin() do
    pool = Module.get_attribute(__CALLER__.module, :sql_pool, @pool)
    timeout = Module.get_attribute(__CALLER__.module, :sql_queue_timeout, @queue_timeout)
    quote generated: true do
      binding = binding()
      key = binding[:tags][:test] || unquote(__CALLER__.function)
      pool = binding[:pool] || unquote(pool)
      case SQL.Pool.checkout(pool, unquote(timeout)) do
        {:error, :timeout} -> raise RuntimeError, "timeout"
        {:ok, conn, socket, prepared, slot} ->
          :persistent_term.put(key, {conn, socket, prepared, slot})
          Process.put(SQL.Transaction, {conn, socket, prepared})
          :persistent_term.put({SQL.Conn, self()}, {conn, socket, prepared})
          Stream.run(%{~SQL[begin] | pool: pool})
      end
    end
  end

  @doc false
  @doc since: "0.5.0"
  defmacro rollback() do
    pool = Module.get_attribute(__CALLER__.module, :sql_pool, @pool)
    quote generated: true do
      binding = binding()
      key = binding[:tags][:test] || unquote(__CALLER__.function)
      pool = binding[:pool] || unquote(pool)
      {conn, socket, prepared, slot} = :persistent_term.get(key)
      Process.put(SQL.Transaction, {conn, socket, prepared})
      Stream.run(%{~SQL[rollback] | pool: pool})
      SQL.Pool.checkin(pool, slot)
    end
  end

  @doc false
  @doc since: "0.5.0"
  defmacro commit() do
    pool = Module.get_attribute(__CALLER__.module, :sql_pool, @pool)
    quote generated: true do
      binding = binding()
      key = binding[:tags][:test] || unquote(__CALLER__.function)
      pool = binding[:pool] || unquote(pool)
      {conn, socket, prepared, slot} = :persistent_term.get(key)
      Process.put(SQL.Transaction, {conn, socket, prepared})
      Stream.run(%{~SQL[commit] | pool: pool})
      SQL.Pool.checkin(pool, slot)
    end
  end

  @doc """
  Returns a lazy enumerable.

  ## Examples
      iex(1)> SQL.transaction, do: ~SQL"from users select id, email" |> SQL.stream() |> Stream.run()
  """
  @doc since: "0.5.0"
  defmacro stream(sql, opts \\ [max_rows: 500]) do
    max_rows = Keyword.fetch!(opts, :max_rows)
    quote do
      %{unquote(sql) | max_rows: unquote(max_rows)}
    end
  end

  @doc false
  @doc since: "0.1.0"
  def parse(binary, opts \\ []) do
    adapter = Keyword.get(opts, :adapter, @adapter)
    pool = Keyword.get(opts, :pool, @pool)
    id = id(binary, adapter)
    key = {id, :parse}
    case :persistent_term.get(key, nil) do
      nil ->
        {:ok, context, tokens} = SQL.Lexer.lex(binary)
        context = %{context | module: adapter}
        {:ok, context, tokens} = SQL.Parser.parse(tokens, context)
        {:ok, t, c, types, params} = SQL.Parser.describe(tokens, [])
        result = SQL
                 |> struct(id: id, columns: c, types: t, adapter: adapter, fn: Keyword.get(opts, :fn), pool: Keyword.get(opts, :pool, @pool), tokens: tokens, context: context)
                 |> adapter.static(tokens, context, t, types, params)
        :persistent_term.put(key, result)
        result
      result ->
        result
    end
    |> Code.eval_quoted_with_env(Keyword.get(opts, :binding, []), Code.env_for_eval(__ENV__))
    |> elem(0)
    |> struct(pool: pool)
  end

  @doc false
  def build(left, {:<<>>, _, _} = right, _modifiers, env) do
    config = %{case: :lower, adapter: Application.get_env(:sql, :adapter, @adapter), validate: fn _, _ -> true end}
    config = if env.module, do: Module.get_attribute(env.module, :sql_config, config), else: config
    columns = Map.get(config, :columns, [])
    sql = struct(SQL, module: env.module, adapter: config.adapter)
    stack = if env.function do
              {env.module, elem(env.function, 0), elem(env.function, 1), [file: Path.relative_to_cwd(env.file), line: env.line]}
            else
              {env.module, env.function, 0, [file: Path.relative_to_cwd(env.file), line: env.line]}
            end
    case build(left, right) do
      {:static, data, max_rows} ->
        id = id(data, config.adapter)
        {:ok, context, tokens} = SQL.Lexer.lex(data, env.file)
        {:ok, context, parse_tokens} = SQL.Parser.parse(tokens, %{context|validate: config.validate, module: config.adapter, case: config.case})
        {:ok, t, c, types, params} = SQL.Parser.describe(parse_tokens, columns)
        inspect = SQL.Inspect.to_string(parse_tokens, context, stack)
        config.adapter.static(%{sql | tokens: tokens, vars: params, types: t, columns: c, inspect: inspect, id: id, max_rows: max_rows}, parse_tokens, context, t, types, params)
      {:dynamic, data, max_rows} ->
        id = id(data, config.adapter)
        sql = %{sql | id: id, max_rows: max_rows}
        quote do
          {t, v} = collect(unquote(Macro.unpipe(left)))
          {:ok, context, tokens} = case :persistent_term.get(unquote({id, :lex}), nil) do
            nil ->
              result = SQL.Lexer.lex(unquote(right), unquote(env.file))
              :persistent_term.put(unquote({id, :lex}), result)
              result

            result ->
              result
          end
          tokens = t++tokens
          key = {:erlang.phash2(tokens), :plan}
          {context, parsed_tokens, tokens, t, c, types, params, inspect} = case :persistent_term.get(key, nil) do
                                                                    nil ->
                                                                      context = %{context | validate: nil, module: unquote(config.adapter), format: :dynamic}
                                                                      {:ok, context, parsed_tokens} = SQL.Parser.parse(tokens, context)
                                                                      {:ok, t, c, types, params} = SQL.Parser.describe(parsed_tokens, unquote(Macro.escape(columns)))
                                                                      result = {context, parsed_tokens, tokens, t, c, types, params, SQL.Inspect.to_string(parsed_tokens, context, unquote(Macro.escape(stack)))}
                                                                      :persistent_term.put(key, result)
                                                                      result
                                                                    result ->
                                                                      result
                                                                  end
          binding = binding()
          vars = for {var, _, nil} <- params do
                    case binding[var] do
                      nil -> {var, v[var]}
                      val -> {var, val}
                    end
                  end
          %{unquote(Macro.escape(sql)) | tokens: tokens, columns: c, types: t, inspect: inspect, vars: vars}
          |> context.module.static(parsed_tokens, context, t, types, params)
          |> Code.eval_quoted_with_env(vars, unquote(Macro.escape(Code.env_for_eval(env))))
          |> elem(0)
        end
    end
  end

  @doc false
  def collect(value), do: collect(value, [], [])
  defp collect([], tokens, vars), do: {tokens, vars}
  defp collect([{[], 0}|rest], tokens, vars), do: collect(rest, tokens, vars)
  defp collect([{%{tokens: t, vars: v}, 0}|rest], tokens, vars), do: collect(rest, tokens++t, vars++v)

  @doc false
  def build(left, {tag, _, _} = right, _env) when tag in ~w[fn &]a do
    {_type, data, acc2, max_rows} = left
    |> Macro.unpipe()
    |> Enum.reduce({:static, [], [], 0}, fn
        {[], 0}, acc -> acc
        {{_, _, []} = r, 0}, {_, l, right, max_rows} -> {:dynamic, Macro.pipe(l, r, 0), right, max_rows}
        {{:sigil_SQL, _meta, [{:<<>>, _, _}, []]} = r, 0}, {type, l, right, max_rows} -> {type, Macro.pipe(l, r, 0), right, max_rows}
        {{{:.,_,[{_,_,[:SQL]},:map]},_,[left]}, 0}, {type, acc, acc2, max_rows} -> {type, acc, [left|acc2], max_rows}
    end)
    [r | rest] = Enum.reverse([right|acc2])
    right = Enum.reduce(rest, r, fn r, {t, m, [{t2, m2, [vars, block]}]} -> {t, m, [{t2, m2, [vars, quote(do: unquote(r).(unquote(block)))]}]} end)
    quote do
      %{unquote(data) | fn: unquote(right), max_rows: unquote(max_rows)}
    end
  end

  @doc false
  def build(left, {:<<>>, _, right}) do
    left
    |> Macro.unpipe()
    |> Enum.reduce({:static, right, 0}, fn
        {[], 0}, acc -> acc
        {{:sigil_SQL, _meta, [{:<<>>, _, value}, []]}, 0}, {type, acc, max_rows} -> {type, [value, ?\s, acc], max_rows}
        {{_, _, _} = var, 0}, {_, acc, max_rows} -> {:dynamic, [var, ?\s, acc], max_rows}
    end)
    |> case do
      {:static, data, max_rows}  -> {:static, IO.iodata_to_binary(data), max_rows}
      {:dynamic, data, max_rows} -> {:dynamic, data, max_rows}
    end
  end

  @doc false
  def id(data, mod), do: id({mod, data})

  defp id(key) do
    atomic = case :persistent_term.get(SQL.Counter, nil) do
           	   nil ->
                 atomic = :atomics.new(1, [])
                 :persistent_term.put(SQL.Counter, atomic)
                 atomic
               atomic -> atomic
             end
    case :persistent_term.get(key, nil) do
      nil ->
        id = :atomics.add_get(atomic, 1, 1)
        :persistent_term.put(key, id)
        id
      id -> id
    end
  end


  @doc false
  def reduce(%SQL{msg: nil}, _acc, _fun) do
    raise RuntimeError, "Invalid Something"
  end
  def reduce(sql, acc, fun) do
    do_reduce(sql, acc, fun)
  end
  defp do_reduce(sql, acc, fun) do
    # time: System.convert_time_unit(:erlang.monotonic_time(:millisecond)-timestamp, :native, :millisecond)
    case transaction() do
      nil ->
        case SQL.Pool.checkout(sql.pool, sql.queue_timeout) do
          {:error, :timeout} -> raise RuntimeError, "timeout"
          {:ok, conn, socket, prepared, slot} ->
            {:ok, rows, _time} = sql.adapter.prepare_execute(socket, conn, sql, prepared)
            SQL.Pool.checkin(sql.pool, slot)
            Enumerable.reduce(rows, acc, fun)
        end
      {conn, socket, prepared} ->
        {:ok, rows, _time} = sql.adapter.prepare_execute(socket, conn, sql, prepared)
        Enumerable.reduce(rows, acc, fun)
    end
  end

  if Application.compile_env(:sql, :env) == :test do
    @doc false
    def transaction() do
      case Process.get(SQL.Transaction) do
        nil ->
          {:links, links} = Process.info(self(), :links)
          {:parent, parent} = Process.info(self(), :parent)
          [parent|links]
          |> Kernel.++(Process.get(:"$callers", []))
          |> Kernel.++(Process.get(:"$ancestors", []))
          |> Enum.uniq()
          |> Enum.find_value(&:persistent_term.get({SQL.Conn, &1}, nil))

        transaction ->
          transaction
      end
    end
  else
    @doc false
    def transaction() do
      Process.get(SQL.Transaction)
    end
  end

  defimpl Enumerable, for: SQL do
    def count(_enumerable), do: {:error, __MODULE__}
    def member?(_enumerable, _element), do: {:error, __MODULE__}
    def reduce(enumerable, acc, fun), do: SQL.reduce(enumerable, acc, fun)
    def slice(_enumerable), do: {:error, __MODULE__}
  end
end
