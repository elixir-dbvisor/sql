# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL do
  @moduledoc "README.md"
               |> File.read!()
               |> String.split("<!-- MDOC !-->")
               |> Enum.fetch!(1)
  @moduledoc since: "0.1.0"
  # require Logger
  alias SQL.Adapters.ANSI

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @doc false
      import SQL
      config = Map.new(Keyword.merge([case: :lower, columns: [], adapter: Application.compile_env(:sql, :adapter, ANSI), validate: fn _, _ -> true end],  opts))
      @external_resource Path.relative_to_cwd("sql.lock")
      config = with true <- File.exists?(Path.relative_to_cwd("sql.lock")),
                    %{validate: validate, columns: columns} <- elem(Code.eval_file("sql.lock", File.cwd!()), 0) do
                    %{config | validate: validate, columns: columns}
               else
                _ ->
                  %{validate: validate, columns: columns} = case :persistent_term.get(SQL.Lock, nil) do
                    nil ->
                      lock = Mix.Tasks.Sql.Get.gen_template()
                      :persistent_term.put(SQL.Lock, lock)
                      lock
                    lock ->
                      lock
                  end
                  |> Code.eval_string()
                  |> elem(0)
                  %{config | columns: columns}
               end
      Module.put_attribute(__MODULE__, :sql_config, config)
      Module.put_attribute(__MODULE__, :sql_pool, opts[:pool] || :default)
    end
  end

  defstruct [tokens: [], idx: 0, params: [], module: nil, id: nil, string: nil, inspect: nil, fn: nil, context: nil, name: nil, columns: [], c_len: 0, types: [], pool: :default, portal: nil, p_len: 0, timeout: nil]

  defimpl Inspect, for: SQL do
    def inspect(%{inspect: nil, tokens: tokens, context: context}, _opts) do
      {:current_stacktrace, stack} = Process.info(self(), :current_stacktrace)
      SQL.__inspect__(tokens, context, hd(stack))
    end
    def inspect(%{inspect: inspect}, _opts), do: inspect
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

  @doc """
  Perform a transaction.

  ## Examples
      iex(1)> SQL.transaction, do: Enum.list(~SQL"from users select id, email")
  """
  @doc since: "0.5.0"
  defmacro transaction(do: block) do
    key = __CALLER__.function
    testing = Mix.env() == :test
    id = "sp_#{:erlang.unique_integer([:positive])}"
    savepoint = Macro.escape(parse("savepoint #{id}"))
    release = Macro.escape(parse("release savepoint #{id}"))
    rollback = Macro.escape(parse("rollback to savepoint #{id}"))
    pool = Module.get_attribute(__CALLER__.module, :sql_pool)
    quote do
      ref = make_ref()
      state = if unquote(testing), do: :persistent_term.get(unquote(key), Process.get(SQL.Transaction)), else: Process.get(SQL.Transaction)
      case state do
        nil ->
          owner = self()
          conn = conn(unquote(pool))
          state = {owner, conn}
          Process.put(SQL.Transaction, state)
          if unquote(testing) do
            :persistent_term.put({SQL.Conn, owner}, state)
            :persistent_term.put(unquote(key), state)
          end
          send conn, {ref, owner, System.monotonic_time(), ~SQL[begin]}
          receive do
            {^ref, :begin} ->
              try do
                result = unquote(block)
                send conn, {ref, owner, System.monotonic_time(), ~SQL[commit]}
                Process.delete(SQL.Transaction)
                result
              rescue
                e ->
                  send conn, {ref, owner, System.monotonic_time(), ~SQL[rollback]}
                  Process.delete(SQL.Transaction)
                  {:error, e}
                  reraise e, __STACKTRACE__
              end
          end
        {owner, conn} = state ->
          if unquote(testing), do: Process.put(SQL.Transaction, state)
          send conn, {ref, owner, System.monotonic_time(), unquote(savepoint)}
          receive do
            {^ref, :begin} ->
              try do
                result = unquote(block)
                send conn, {ref, owner, System.monotonic_time(), unquote(release)}
                result
              rescue
                e ->
                send conn, {ref, owner, System.monotonic_time(), unquote(rollback)}
                {:error, e}
                reraise e, __STACKTRACE__
              end
          end
      end
    end
  end

  @doc false
  @doc since: "0.1.0"
  def parse(binary, params \\ [], module \\ ANSI) do
    {:ok, context, tokens} = SQL.Lexer.lex(binary)
    {:ok, %{description: description} = context, tokens} = SQL.Parser.parse(tokens, context)
    id = :erlang.phash2(tokens)
    portal = "p_#{:erlang.unique_integer([:positive])}"
    struct(SQL, id: id, name: "sql_#{id}", tokens: tokens, context: context, string: IO.iodata_to_binary(module.to_iodata(tokens, context)), idx: length(params), types: context.types, params: params, columns: description, c_len: length(description), portal: portal, p_len: byte_size(portal))
  end

  @doc false
  def build(left, {:<<>>, _, _} = right, _modifiers, env) do
    config = %{case: :lower, adapter: Application.get_env(:sql, :adapter, ANSI), validate: fn _, _ -> true end}
    config = if env.module, do: Module.get_attribute(env.module, :sql_config, config), else: config
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
        %{context|validate: config.validate, module: config.adapter, case: config.case}
        {:ok, %{description: description}=context, tokens} = SQL.Parser.parse(tokens, %{context|validate: config.validate, module: config.adapter, case: config.case}, config)
        string = IO.iodata_to_binary(context.module.to_iodata(tokens, context))
        inspect = __inspect__(tokens, context, stack)
        portal = "p_#{:erlang.unique_integer([:positive])}"
        sql = %{sql | name: "sql_#{id}", idx: context.idx, tokens: tokens, string: string, inspect: inspect, id: id, types: context.types, columns: description, c_len: length(description), portal: portal, p_len: byte_size(portal)}
        case context.binding do
          []     ->
            Macro.escape(sql)
            # quote bind_quoted: [sql: Macro.escape(sql)] do
            #   portal = "p_#{:erlang.unique_integer([:positive])}"
            #   %{sql | portal: portal, p_len: byte_size(portal)}
            # end

          params ->
            quote bind_quoted: [params: params, sql: Macro.escape(sql), env: Macro.escape(env)] do
              portal = "p_#{:erlang.unique_integer([:positive])}"
              %{sql | params: cast_params(params, binding(), env, []), portal: portal, p_len: byte_size(portal)}
            end
        end

      {:dynamic, data} ->
        id = id(data)
        sql = %{sql | id: id, name: "sql_#{id}"}
        quote bind_quoted: [left: Macro.unpipe(left), right: right, file: env.file, data: data, sql: Macro.escape(sql), env: Macro.escape(env), config: Macro.escape(%{config| validate: nil}), stack: Macro.escape(stack)] do
          {t,p,idx} = Enum.reduce(left, {[], [], 0}, fn
            {[], 0}, acc        -> acc
            {v, 0}, {t, p, idx} -> {t++v.tokens, p++v.params, idx+v.idx}
            end)
          {:ok, context, tokens} = tokens(right, file, idx, sql.id, config)
          tokens = t++tokens
          {%{description: description}=context, string, inspect} = plan(tokens, %{context|validate: config.validate, module: config.adapter, types: context.types, format: :dynamic}, sql.id, stack, config)
          portal = "p_#{:erlang.unique_integer([:positive])}"
          %{sql | params: p++cast_params(context.binding, binding(), env, []), tokens: tokens, string: string, inspect: inspect, columns: description, c_len: length(description), portal: portal, p_len: byte_size(portal)}
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
  def tokens(binary, file, count, id, _config) do
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
  def plan(tokens, context, id, stack, config) do
    key = {context.module, id, :plan}
    case :persistent_term.get(key, nil) do
      nil ->
        {:ok, context, tokens} = SQL.Parser.parse(tokens, context, config)
        format = {context, IO.iodata_to_binary(context.module.to_iodata(tokens, context)), __inspect__(tokens, context, stack)}
        :persistent_term.put(key, format)
        format

      format ->
        format
    end
  end

  @error IO.ANSI.red()
  @reset IO.ANSI.reset()

  @doc false
  def __inspect__(tokens, context, stack) do
    inspect = IO.iodata_to_binary([@reset, "~SQL\"\"\""|[SQL.Format.to_iodata(tokens, context, 0, true)|~c"\n\"\"\""]])
    case context.errors do
      [] -> inspect
      errors ->
        {:current_stacktrace, [_|t]} = Process.info(self(), :current_stacktrace)
        IO.warn([?\n,format_error(errors), IO.iodata_to_binary([@reset, "  ~SQL\"\"\""|[SQL.Format.to_iodata(tokens, context, 1, true)|~c"\n  \"\"\""]])], [stack|t])
        inspect
    end
  end

  @doc false
  def format_error(errors), do: Enum.group_by(errors, &elem(&1, 2)) |> Enum.reduce([], fn
    {k, [{:special, _, _}]}, acc -> [acc|["  the operator", @error,k,@reset, " is invalid, did you mean any of #{__suggest__(k)}\n"]]
    {k, [{:special, _, _}|_]=v}, acc -> [acc|["  the operator ",@error,k,@reset," is mentioned #{length(v)} times but is invalid, did you mean any of #{__suggest__(k)}\n"]]
    {k, [_]}, acc -> [acc|["  the relation ",@error,k,@reset," does not exist\n"]]
    {k, v}, acc -> [acc|["  the relation ",@error,k,@reset," is mentioned #{length(v)} times but does not exist\n"]]
  end)

  def reduce(%SQL{fn: nil} = sql, acc, fun) do
    reduce(%{sql | fn: fn row, acc -> fun.(row, acc) end}, acc)
  end
  def reduce(sql, acc, fun) do
    reduce(%{sql | fn: fn row, acc -> fun.(sql.fn.(row), acc) end}, acc)
  end
  defp reduce(sql, _acc) do
    ref = make_ref()
    self = self()
    timestamp = System.monotonic_time()
    entry = {ref, self, timestamp, sql}
    case Process.get(SQL.Transaction) do
      nil ->
        conn = pick(sql.pool)
        send(conn, entry)
        result = recv(conn, ref, sql.timeout || 15_000)
        # Logger.debug(sql: sql, time: System.convert_time_unit(System.monotonic_time()-timestamp, :native, :millisecond))
        result
      {owner, conn} ->
        send(conn, {owner, entry})
        result = recv(conn, ref, sql.timeout || 15_000)
        # Logger.debug(sql: sql, time: System.convert_time_unit(System.monotonic_time()-timestamp, :native, :millisecond))
        result
    end
  end

  defp recv(conn, ref, timeout) do
    receive do
      {^ref, {:cont, _}} -> recv(conn, ref, timeout)
      {^ref, {:done, _}=msg} -> msg
      {^ref, {:error, %{message: message}}} -> raise RuntimeError, message
    after
      timeout ->
        send(conn, {:cancel, ref})
        recv(conn, ref, timeout)
    end
  end

  def conn(%SQL{pool: pool}), do: pick(pool)
  def conn(pool), do: pick(pool)

  if Mix.env == :test do
    defp conn() do
      {:links, links} = Process.info(self(), :links)
      Enum.find_value(links, Process.get(SQL.Conn), &:persistent_term.get({SQL.Conn, &1}, nil))
    end
  else
    defp conn() do
      Process.get(SQL.Conn)
    end
  end

  defp pick(pool) do
    case conn() do
      nil ->
        conns = :persistent_term.get(pool)
        conn = elem(conns, :erlang.phash2({self(), :rand.uniform(1_000_000)}, tuple_size(conns)-1))
        Process.put(SQL.Conn, conn)
        conn
      conn -> conn
    end
  end

  @doc false
  def __suggest__(k), do: Enum.join(SQL.Lexer.suggest_operator(:erlang.iolist_to_binary(k)), ", ")

  defimpl Enumerable, for: SQL do
    def count(_enumerable), do: {:error, __MODULE__}
    def member?(_enumerable, _element), do: {:error, __MODULE__}
    def reduce(enumerable, acc, fun), do: SQL.reduce(enumerable, acc, fun)
    def slice(_enumerable), do: {:error, __MODULE__}
  end
end
