# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule Mix.Tasks.Sql.Drop do
  use Mix.Task
  @moduledoc since: "0.5.0"

  @opts [strict: [pool: [:string, :keep], quiet: :boolean], aliases: [p: :pool, q: :quiet]]

  @shortdoc "Drop a database for each pool"
  def run(args) do
    {opts, _} = OptionParser.parse!(args, @opts)
    app = Mix.Project.config()[:app]
    Application.load(app)
    Mix.Task.run("app.config", args)
    pools = Application.get_env(:sql, :pools)
    only = opts |> Keyword.take([:pool]) |> Keyword.values |> Enum.map(&String.to_atom/1)
    pools = if only != [] do
              Enum.reject(pools, &elem(&1, 0) in only)
            else
              pools
            end
    for {name, config} <- pools do
      state = struct(SQL.Pool, [{:name, name}|config])
      {:ok, pid} = state.adapter.start(maintiance(state))
      Process.put(SQL.Conn, pid)
      execute(opts, state)
      Process.exit(pid, :normal)
    end
  end

  defp maintiance(%{adapter: SQL.Adapters.Postgres}=state) do
    Map.put(state, :database, "postgres")
  end

  defp execute(opts, %{adapter: SQL.Adapters.Postgres, name: name, database: database}) do
    case Enum.to_list(SQL.parse("select count(*)::int4 from pg_database where datname::text = '#{database}'")) do
      [[1]] ->
        try do
          [] = Enum.to_list(SQL.parse("drop database #{database}"))
          if !opts[:quit], do: Mix.shell().info("The database for #{name} has been dropped")
        catch
          e ->
            Mix.raise("The database for #{name} couldn't be dropped: #{e.message}")
        end
      [[0]] ->
        if !opts[:quit], do: Mix.shell().info("The database for #{name} has already been dropped")
    end
  end
end
