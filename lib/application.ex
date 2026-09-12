# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Application do
  @moduledoc false

  def start(_type, _args) do
    {:ok, _} = :dets.open_file(:sql, [type: :set, ram_file: true])
    pools = Application.get_env(:sql, :pools, [])
    children = for {name, config} <- pools, do: %{id: name, start: {SQL.Pool, :start_link, [[{:name, name}|config]]}}
    result = Supervisor.start_link(children, strategy: :one_for_one)
    receive do
    after
      100 ->
        for {name, opts} <- pools, do: Module.concat(opts[:adapter], Queries).load(name)
        result
    end
  end

  def stop(_state) do
    :dets.sync(:sql)
    :dets.close(:sql)
  end
end
