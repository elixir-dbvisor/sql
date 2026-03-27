# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Application do
  @moduledoc false
  import SQL

  def start(_type, _args) do
    pools = Application.get_env(:sql, :pools, [])
    children = for {name, opts} <- pools do
      {SQL.Pool, Map.put(Map.new(opts), :name, name)}
    end
    result = {:ok, _sup} = Supervisor.start_link(children, strategy: :one_for_one)
    for {name, opts} <- pools do
      pid = Process.whereis(name)
      children = Supervisor.which_children(pid)
      pids = Enum.reverse(Enum.map(children, fn {_id, pid, _type, _mod} -> pid end))
      :persistent_term.put(name, List.to_tuple(pids))
      config = {name, Map.new(opts)}
      SQL.begin(:transaction, name)
      oids = Mix.Tasks.Sql.Get.oids(config)
      get = Mix.Tasks.Sql.Get.get(config)
      SQL.commit(:transaction)
      :persistent_term.put({name, :oids}, oids)
      :persistent_term.put({name, :columns}, get)
    end
    result
  end
end
