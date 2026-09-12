# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQLTest.Helpers do
  def validate([[[[[], b1], b2], b3],b4], _) when b1 in ~c"tT" and  b2 in ~c"eE" and  b3 in ~c"sS" and b4 in ~c"tT", do: true
  def validate(_, _), do: false
  def set_validate(context \\ %{}), do: Map.merge(context, %{validate: &validate/2, module: SQL.Adapters.ANSI})
end

defmodule SQLTest.Postgres do
  @pg_ctl System.find_executable("pg_ctl")
  @ssl System.find_executable("openssl")
  @tmp_dir System.tmp_dir!()
  @path Path.join(@tmp_dir, "sql-test-postgres")
  @pwfile Path.join(@tmp_dir, ".postgres-password")
  @postgresql [{"listen_addresses","'127.0.0.1'"},{"max_connections", "10"},{"shared_buffers", "16MB"},{"fsync", "off"},{"synchronous_commit", "off"},{"full_page_writes", "off"}]
  @pools Application.compile_env(:sql, :pools)

  def start_all! do
    for {_pool, config} <- @pools do
      port = config[:port]
      dir = Path.join(@path, "#{port}")
      File.write!(@pwfile, config[:password])
      method = case port do
                 5433 -> "trust"
                 5436 -> "md5"
                 _    -> "scram-sha-256"
               end
      if File.exists?(Path.join(dir, "postmaster.pid")), do: {_, 0} = System.shell("#{@pg_ctl} stop -D #{dir} -w", stderr_to_stdout: true)
      File.rm_rf!(dir)
      File.mkdir_p!(dir)
      {_, 0} = System.shell("#{@pg_ctl} initdb -D #{dir} -o '#{"-U #{config[:username]} --no-locale -E UTF8 --pwfile #{@pwfile} -A #{method}"}'", stderr_to_stdout: false)
      case config[:ssl] do
        false ->
          path = Path.join(dir, "postgresql.conf")
          File.write!(path, Enum.reduce([{"port", "#{port}"}|@postgresql], File.read!(path), fn {k, v}, c -> Regex.replace(~r/^\s*#?\s*#{Regex.escape(k)}\s*=.*$/m, c, "#{k} = #{v}") end))
        true ->
          path = Path.join(dir, "pg_hba.conf")
          File.write!(path, Regex.replace(~r/^host\s+all\s+all\s+127\.0\.0\.1\/32\s+\S+\s*$/m,File.read!(path),"hostssl all all 127.0.0.1/32 #{method}"))
          key = Path.join(dir, "server.key")
          {_, 0} = System.shell("#{@ssl} req -new -x509 -nodes -days 1 -newkey rsa:2048 -keyout #{key} -out #{Path.join(dir, "server.crt")} -subj /CN=localhost", stderr_to_stdout: true)
          File.chmod!(key, 0o600)
          Application.put_env(:sql, :pools, Keyword.update!(@pools, :ssl, &Keyword.put(&1, :ssl, [verify: :verify_none])))
          path = Path.join(dir, "postgresql.conf")
          File.write!(path, Enum.reduce([{"ssl","on"}, {"ssl_cert_file", "'server.crt'"}, {"ssl_key_file", "'server.key'"},{"port", "#{port}"}|@postgresql], File.read!(path), fn {k, v}, c -> Regex.replace(~r/^\s*#?\s*#{Regex.escape(k)}\s*=.*$/m, c, "#{k} = #{v}") end))
      end
      {"waiting for server to start.... done\nserver started\n", 0} = System.shell("#{@pg_ctl} start -D #{dir} -l #{Path.join(dir, "postgresql.log")} -w", stderr_to_stdout: false)
    end
  end

  def stop_all!(_) do
    for {_pool, config} <- @pools do
      dir = Path.join([@path, "#{config[:port]}"])
      {_, 0} = System.shell("#{@pg_ctl} stop -D #{dir} -w", stderr_to_stdout: false)
      File.rm_rf!(dir)
    end
  end
end

SQLTest.Postgres.start_all!()
ExUnit.after_suite(&SQLTest.Postgres.stop_all!/1)
Mix.Task.run("sql.create", ["--quiet"])
Application.ensure_all_started(:sql)
ExUnit.start()
