# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule Mix.Tasks.Sql.Create do
  use Mix.Task
  @moduledoc since: "0.5.0"

  @opts [strict: [pool: [:string, :keep], quiet: :boolean], aliases: [p: :pool, q: :quiet]]

  @shortdoc "Create a database for each pool"
  def run(args) do
    {opts, _} = OptionParser.parse!(args, @opts)
    app = Mix.Project.config()[:app]
    Application.load(app)
    Mix.Task.run("app.config", args)
    pools = Application.get_env(:sql, :pools)
    only = opts |> Keyword.take([:pool]) |> Keyword.values |> Enum.map(&String.to_atom/1)
    pools = if only != [], do: Enum.reject(pools, &elem(&1, 0) in only), else: pools
    for {name, config} <- pools do
      mod = Module.concat(config[:adapter], Queries)
      state = mod.maintiance(:create, name, config)
      {:ok, conn} = state.adapter.start(state)
      execute(mod, opts, Map.put(state, :database, config[:database]))
      Process.exit(conn, :normal)
    end
  end

  defp execute(mod, opts, %{name: name}=state) do
    case mod.count_database(state) do
      {:ok, [0]} ->
        try do
          [] = mod.create_database(state)
          if !opts[:quit], do: Mix.shell().info("The database for #{name} has been created")
        catch
          e ->
          Mix.raise("The database for #{name} couldn't be created: #{e.message}")
        end
      {:ok, [1]} ->
        if !opts[:quit], do: Mix.shell().info("The database for #{name} has already been created")
    end
  end
end
