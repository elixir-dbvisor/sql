# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Pool do
  @moduledoc false
  use Supervisor

  @derive {Inspect, only: []}
  defstruct [ssl: false, timeout: 15_000, max_rows: 500, parameter: %{}, name: :default, domain: :inet, type: :stream, protocol: :tcp, use_registry: false, debug: false, otp: %{rcvbuf: {64_000, 128_000}}, socket: %{keepalive: true, linger: %{onoff: true, linger: 5}}, family: :inet, port: 5432, addr: {127, 0, 0, 1}, scheduler_id: nil, label: nil, adapter: nil, username: nil, password: nil, hostname: nil, database: nil]

  def start_link(opts) do
    state = struct(__MODULE__, opts)
    Supervisor.start_link(__MODULE__, state, name: state.name)
  end

  @impl true
  def init(state) do
    children =
      for n <- 1..:erlang.system_info(:schedulers_online) do
        %{
          id: {:conn, n},
          start: {state.adapter, :start, [struct(state, scheduler_id: n+1, label: :"#{state.name}_#{n}")]},
          restart: :permanent,
          shutdown: 5000,
          type: :worker,
        }
      end
    Supervisor.init(children, strategy: :one_for_one)
  end
end
