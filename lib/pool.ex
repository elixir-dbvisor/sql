# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Pool do
  @moduledoc false
  use GenServer

  @default %{ssl: false, timeout: 5000, parameter: %{}, name: :default, protocol: :tcp, use_registry: false, debug: false, otp: %{rcvbuf: {64_000, 128_000}}, socket: %{keepalive: true, linger: %{onoff: true, linger: 5}}, family: :inet, port: 5432, addr: {127, 0, 0, 1}}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, Map.merge(@default, opts), name: __MODULE__)
  end

  @impl true
  def init(state) do
    :persistent_term.put(state.name, List.to_tuple(for n <- 1..:erlang.system_info(:schedulers_online), do: state.adapter.start(Map.put(state, :scheduler_id, n))))
    {:ok, state}
  end
end
