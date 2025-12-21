# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Pool do
  @moduledoc false
  use Supervisor

  @default %{ssl: false, timeout: 5000, parameter: %{}, name: :default, domain: :inet, type: :stream, protocol: :tcp, use_registry: false, debug: false, otp: %{rcvbuf: {64_000, 128_000}}, socket: %{keepalive: true, linger: %{onoff: true, linger: 5}}, family: :inet, port: 5432, addr: {127, 0, 0, 1}}
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, Map.merge(@default, opts), name: opts[:name])
  end

  @impl true
  def init(state) do
    children =
      for n <- 1..:erlang.system_info(:schedulers_online) do
        %{
          id: {:conn, n},
          start: {state.adapter, :start, [Map.put(state, :scheduler_id, n)]},
          restart: :permanent,
          shutdown: 5000,
          type: :worker,
        }
      end
    Supervisor.init(children, strategy: :one_for_one)
  end
end
