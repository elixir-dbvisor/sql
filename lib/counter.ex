defmodule SQL.Counter do
  @moduledoc false

  use GenServer

  def start_link(state \\ {[], :atomics.new(1, [])}) do
    Process.flag(:trap_exit, true)
    :dets.open_file(:sql, [type: :set, ram_file: true, file: ~c"#{Path.join(:code.priv_dir(:sql), "sql")}"])
    GenServer.start_link(__MODULE__, state, name: SQL.Counter)
  end

  @impl true
  def init({state, atomic}) do
    state = Map.new(:dets.foldl(fn
      {{_, _}, n} = el, acc when is_integer(n) -> [el|acc]
      _, acc -> acc
    end, state, :sql))
    case :dets.lookup(:sql, __MODULE__) do
      [] ->
        :atomics.put(atomic, 1, 0)
        {:ok, {state, atomic}}
      [{__MODULE__, count}] ->
        :atomics.put(atomic, 1, count)
        {:ok, {state, atomic}}
    end
  end

  @impl true
  def handle_call({:add_get, key}, _from, {state, atomic}=s) do
    case state do
      %{^key => count} ->
        {:reply, count, s}
      _ ->
        count = :atomics.add_get(atomic, 1, 1)
        {:reply, count, {Map.put(state, key, count), atomic}}
    end
  end

  @impl true
  def handle_cast(:stop, s) do
    terminate(:normal, s)
    {:noreply, s}
  end

  @impl true
  def terminate(_reason, {state, atomic}) do
    :dets.insert(:sql, [{__MODULE__, :atomics.get(atomic, 1)}|Map.to_list(state)])
    :dets.sync(:sql)
  end
end
