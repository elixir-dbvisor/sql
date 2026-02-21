# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Application do
  @moduledoc false

  def start(_type, _args) do
    pools = Application.get_env(:sql, :pools, [])
    children = for {name, opts} <- pools do
      # :persistent_term.put(name, List.to_tuple(for n <- 1..:erlang.system_info(:schedulers_online), do: :"#{name}_#{n}"))
      {SQL.Pool, Map.put(Map.new(opts), :name, name)}
    end
    result = {:ok, _sup} = Supervisor.start_link(children, strategy: :one_for_all)
    for {name, opts} <- pools do
      pid = Process.whereis(name)
      children = Supervisor.which_children(pid)
      pids = Enum.map(children, fn {_id, pid, _type, _mod} -> pid end)
      :persistent_term.put(name, List.to_tuple(pids))
      :persistent_term.put({name, :oids}, Mix.Tasks.Sql.Get.oids({name, %{adapter: opts.adapter}}))
      # :persistent_term.put({name, :types}, {Mix.Tasks.Sql.Get.get(key), Mix.Tasks.Sql.Get.columns(key), Mix.Tasks.Sql.Get.enums(key), Mix.Tasks.Sql.Get.oids(key), Mix.Tasks.Sql.Get.functions(key)})
    end
    result
  end
end
