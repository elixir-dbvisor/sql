# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Application do
  @moduledoc false

  def start(_type, _args) do
    pools = Application.get_env(:sql, :pools, [])
    children = for {name, opts} <- pools, do: {SQL.Pool, Map.put(opts, :name, name)}
    result = {:ok, _sup} = Supervisor.start_link(children, strategy: :one_for_all)
    for {name, _} <- pools do
      pid = Process.whereis(name)
      children = Supervisor.which_children(pid)
      pids = Enum.map(children, fn {_id, pid, _type, _mod} -> pid end)
      :persistent_term.put(name, List.to_tuple(pids))
    end
    result
  end
end
