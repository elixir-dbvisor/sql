# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Adapters.Postgres do
  @moduledoc """
    A SQL adapter for [PostgreSQL](https://www.postgresql.org).
  """
  @moduledoc since: "0.2.0"
  use SQL.Token

  @sync <<?S, 4::32-big>>
  @ssl <<8::32, 80877103::32>>

  @doc false
  def start(state) do
    {:ok, spawn_link(fn -> init(state) end)}
  end

  defp to_iodata({:in, m, [{:not, _, left}, {:binding, _, _}]}, format, case, acc) do
    idx = Process.get(:sql_binding)
    Process.put(:sql_binding, idx-1)
    to_iodata(left, format, case, indention(["!= ANY($#{idx})"|acc], format, m))
  end
  defp to_iodata({:in, m, [left, {:binding, _, _} ]}, format, case, acc) do
    idx = Process.get(:sql_binding)
    Process.put(:sql_binding, idx-1)
    to_iodata(left, format, case, indention(["= ANY($#{idx})"|acc], format, m))
  end
  defp to_iodata({:binding, m, _}, format, _case, acc) do
    idx = Process.get(:sql_binding)
    Process.put(:sql_binding, idx-1)
    indention(["$#{idx}"|acc], format, m)
  end
  defp to_iodata(token, format, case, acc), do: __to_iodata__(token, format, case, acc)

  def init(state) do
    Process.flag(:trap_exit, true)
    startup(state)
  end

  defp cancel(%{domain: domain, type: type, protocol: protocol, pid: pid, secret: secret} = state) do
    {:ok, socket} = :socket.open(domain, type, protocol, Map.take(state, [:netns, :use_registry, :debug]))
    for {level, opts} <- Map.take(state, [:tcp, :udp, :sctp, :ip, :ipv6, :otp, :socket]), {k, v} <- opts, do: :socket.setopt(socket, level, k, v)
    :socket.connect(socket, Map.take(state, [:family, :port, :addr]))
    :socket.send(socket, <<16::32-big, 80877102::32-big, pid::32-big, secret::32-big>>)
    :socket.recv(socket, 0, [])
    :socket.close(socket)
    loop(state)
  end

  defp startup(%{username: username, database: database, sockets: sockets, handle: handle} = state) do
     {:ok, socket} = :socket.open(state.domain, state.type, state.protocol, Map.take(state, [:netns, :use_registry, :debug]))
     for {level, opts} <- Map.take(state, [:tcp, :udp, :sctp, :ip, :ipv6, :otp, :socket]), {k, v} <- opts, do: :socket.setopt(socket, level, k, v)
     :ets.insert(sockets, {state.scheduler_id, socket, self()})
    :socket.monitor(socket)
    {:select, {:select_info, :connect, ^handle}} = :socket.connect(socket, Map.take(state, [:family, :port, :addr]), handle)
    receive do
      {:"$socket", ^socket, :select, ^handle} ->
        :ok = :socket.connect(socket)
        case state do
          %{ssl: false} ->
            send_data(socket, startup_msg(username, database))
          _ ->
            send_data(socket, @ssl)
        end
        startup(%{state | sock: socket}, <<>>, [])
    end
  end

  defp startup(state, <<buffer::binary-size(0)>>, params) do
    case :socket.recv(state.sock, 0, [], state.handle) do
      {:ok, <<data::binary>>} -> startup(state, data, params)
      {:select, {_, <<data::binary>>}} -> startup(state, data, params)
      {:select_read, {_, <<data::binary>>}} -> startup(state, data, params)
      {:error, :closed} -> exit(:normal)
      {:select, _} ->
        receive do
          {:"$socket", _socket, :select, _handle} ->
            startup(state, buffer, params)
        end
    end
  end
  defp startup(state, <<?E, len::32, data::binary-size(len-4), rest::binary>>, params) do
    IO.puts(error(data)[:message])
    startup(state, rest, params)
  end
  defp startup(state, <<?K, _::32, pid::32, secret::32, rest::binary>>, params) do
    startup(%{state | pid: pid, secret: secret}, rest, params)
  end
  defp startup(%{sock: {:"$socket", _}=socket, ssl: ssl}=state, <<?S, rest::binary>>, params) when is_list(ssl) do
    {:ok, socket} = :ssl.connect(socket, state.ssl, state.timeout)
    :ssl.setopts(socket, active: :once)
    send_data(socket, <<25+byte_size(state.username)+byte_size(state.database)::32, 196_608::32, "user", 0, state.username::binary, 0, "database", 0, state.database::binary, 0, 0>>)
    startup(%{state | sock: socket}, rest, params)
  end
  defp startup(%{sock: {:"$socket", _}, ssl: ssl}, <<?N, _rest::binary>>, _params) when is_list(ssl) do
    raise "SSL not supported by server"
  end
  defp startup(state, <<?R, len::32, 10::32, payload::binary-size(len-8), rest::binary>>, params) do
    mechanisms = :binary.split(payload, <<0>>, [:global])
    if "SCRAM-SHA-256" in mechanisms do
      scram_nonce = Base.encode64(:crypto.strong_rand_bytes(18))
      send_data(state.sock, <<?p,54::32,"SCRAM-SHA-256",0,32::32,?n,?,,?,,?n,?=,?,,?r,?=,scram_nonce::binary>>)
      startup(Map.put(state, :scram_nonce, scram_nonce), rest, params)
    else
      raise "Unsupported SASL mechanism: #{inspect(mechanisms)}"
    end
  end
  defp startup(state, <<?R, len::32, 11::32, payload::binary-size(len-8), rest::binary>>, params) do
    %{?r => r, ?s => s, ?i => i} = for kv <- :binary.split(payload, ",", [:global]), into: %{} do
      <<k, "=", v::binary>> = kv
      {k, v}
    end
    salt = Base.decode64!(s)
    iter = String.to_integer(i)
    salted_password = :crypto.pbkdf2_hmac(:sha256, state.password, salt, iter, 32)
    client_key = :crypto.mac(:hmac, :sha256, salted_password, "Client Key")
    auth_message = <<?n,?=,?,,?r,?=,binary_part(r, 0, 24)::binary,?,,?r,?=,r::binary,?,,?s,?=,s::binary,?,,?i,?=,i::binary,?,,?c,?=,?b,?i,?w,?s,?,,?r,?=,r::binary>>
    client_signature = :crypto.mac(:hmac, :sha256, :crypto.hash(:sha256, client_key), auth_message)
    proof = Base.encode64(:crypto.exor(client_key, client_signature))
    send_data(state.sock,  <<?p,byte_size(r)+byte_size(proof)+16::32,?c,?=,?b,?i,?w,?s,?,,?r,?=,r::binary,?,,?p,?=,proof::binary>>)
    startup(Map.put(Map.put(state, :scram_salted_password, salted_password), :scram_auth_message, auth_message), rest, params)
  end
  defp startup(state, <<?R, len::32-big, 12::32-big, payload::binary-size(len-8), rest::binary>>, params) do
    %{?v => server_signature_b64} = for kv <- :binary.split(payload, ",", [:global]), into: %{} do
                                    <<k, "=", v::binary>> = kv
                                    {k, v}
                                  end
    server_key = :crypto.mac(:hmac, :sha256, state.scram_salted_password, "Server Key")
    expected_sig = Base.encode64(:crypto.mac(:hmac, :sha256, server_key, state.scram_auth_message))
    if server_signature_b64 != expected_sig do
      raise "SCRAM server signature mismatch"
    end
    startup(state, rest, params)
  end
  defp startup(state, <<?R, len::32, 5::32, salt::binary-size(len-8), rest::binary>>, params) do
    password = "md5#{Base.encode16(:crypto.hash(:md5, [Base.encode16(:crypto.hash(:md5, [state.password, state.username]), case: :lower), salt]), case: :lower)}"
    send_data(state.sock, <<?p, 5+byte_size(password)::32, password::binary, 0>>)
    startup(state, rest, params)
  end
  defp startup(state, <<?R, 4::32, 3::32, rest::binary>>, params) do
    send_data(state.sock, <<?p, 5+byte_size(state.password)::32, state.password::binary, 0>>)
    startup(state, rest, params)
  end
  defp startup(state, <<?S, len::32, data::binary-size(len-4), rest::binary>>, params) do
    startup(state, rest, [List.to_tuple(split(data, "", []))|params])
  end
  defp startup(state, <<?1, len::32, _::binary-size(len-4), ?Z, _::32, ?I>>, params) do
    state = %{state | parameter: params}
    SQL.Pool.dequeue(state.metrics, state.queue, state.state, state.scheduler_id)
    loop(state)
  end
  defp startup(state, <<?Z, _::32, ?I>>, _params) do
    SQL.Pool.dequeue(state.metrics, state.queue, state.state, state.scheduler_id)
    loop(state)
  end
  defp startup(state, <<_tag, len::32, _::binary-size(len-4), rest::binary>>, params) do
    startup(state, rest, params)
  end

  defp startup_msg(username, database), do: <<25+byte_size(username)+byte_size(database)::32, 196_608::32, "user", 0, username::binary, 0, "database", 0, database::binary, 0, 0>>

  defp loop(state) do
    receive do
      msg -> handle_info(msg, state)
    end
  end

  defp handle_info(:cancel, state), do: cancel(state)
  defp handle_info({:EXIT, _, _reason}, state) do
    :socket.close(state.sock)
    :ok
  end

  def prepare_execute(socket, conn, %SQL{id: id, msg: [_parse, pbe, be, _execute, _close]}=sql, prepared) do
    timestamp = :erlang.monotonic_time(:millisecond)
    ref = Process.send_after(conn, :cancel, sql.db_timeout)
    key = {:erlang.phash2({id, conn}), 1}
    msg = if :ets.select_count(prepared, [{key, [], [true]}]) == 1, do: be, else: pbe
    send_data(socket, msg, sql)
    result = drain(socket, conn, sql, make_ref(), key, prepared)
    Process.cancel_timer(ref)
    {:ok, result, :erlang.monotonic_time(:millisecond)-timestamp}
  end

  defp send_data({:"$socket", _}=socket, data, _sql) do
    :socket.send(socket, data)
  end
  defp send_data(socket, data, _sql) do
    :ssl.send(socket, data)
  end

  defp send_data({:"$socket", _}=socket, data) do
    :socket.send(socket, data)
  end
  defp send_data(socket, data) do
    :ssl.send(socket, data)
  end

  defp split(<<0, rest::binary>>, v, acc), do: [v|split(rest, "", acc)]
  defp split(<<b::binary-size(1), rest::binary>>, v, acc) do
    split(rest, v<>b, acc)
  end
  defp split("", "", acc), do: acc
  defp split("", v, acc), do: [v|acc]

  defp drain(socket, conn, sql, ref, key, prepared) do
    case :socket.recv(socket, 0, [], ref) do
      {:error, :closed} ->
        Process.exit(conn, :normal)
        raise RuntimeError, "connection closed"
      {:select, {:select_info, :recv, ^ref}} ->
        receive do
          {:"$socket", ^socket, :select, ^ref} ->
            drain(socket, conn, sql, ref, key, prepared)
        end
      {:ok, data} ->
        process(data, socket, sql, [], ref, key, prepared)
      {_, {_, <<data::binary>>}} ->
        process(data, socket, sql, [], ref, key, prepared)
    end
  end

  defp more(buffer, socket, sql, rows, ref, key, prepared) do
    case :socket.recv(socket, 0, [], ref) do
      {:ok, data} -> process(IO.iodata_to_binary([buffer, data]), socket, sql, rows, ref, key, prepared)
      {_, {_, <<data::binary>>}} -> process(IO.iodata_to_binary([buffer, data]), socket, sql, rows, ref, key, prepared)
      {:select, {:select_info, :recv, ^ref}} ->
        receive do
          {:"$socket", ^socket, :select, ^ref} ->
            more(buffer, socket, sql, rows, ref, key, prepared)
        end
    end
  end

  defp process(<<rest::binary>>, socket, sql, rows, ref, key, prepared) do
    case rest do
      <<?D, len::32, _::16, row::binary-size(len-6), rest::binary>>->
        process(rest, socket, sql, [sql.decoder.decode_row(row, sql)|rows], ref, key, prepared)
      <<?C, len::32, "SELECT ", _count::binary-size(len-12), 0, 51, 4::32>> ->
        :lists.reverse(rows)
      <<?C, len::32, "UPDATE ", _count::binary-size(len-12), 0, 51, 4::32>> ->
        :lists.reverse(rows)
      <<?C, len::32, "DELETE ", _count::binary-size(len-12), 0, 51, 4::32>> ->
        :lists.reverse(rows)
      <<?C, len::32, "INSERT ", _count::binary-size(len-12), 0, 51, 4::32>> ->
        :lists.reverse(rows)
      <<?C, 18::32, "DROP DATABASE", 0, 51, 4::32>> ->
        send_data(socket, @sync)
        rows
      <<?C, 20::32, "CREATE DATABASE", 0, 51, 4::32>> ->
        send_data(socket, @sync)
        rows
      <<?C, 10::32, "BEGIN", 0, 51, 4::32>> ->
        rows
      <<?C, 11::32, "COMMIT", 0, 51, 4::32>> ->
        rows
      <<?C, 12::32, "RELEASE", 0, 51, 4::32>> ->
        rows
      <<?C, 13::32, "ROLLBACK", 0, 51, 4::32>> ->
        rows
      <<?C, 14::32, "SAVEPOINT", 0, 51, 4::32>> ->
        rows
      <<?E, len::32, data::binary-size(len-4)>> ->
        send_data(socket, @sync)
        raise RuntimeError, error(data)[:message]
      <<?Z, len::32, _::binary-size(len-4), rest::binary>> ->
        process(rest, socket, sql,  rows, ref, key, prepared)
      <<?s, len::32, _payload::binary-size(len-4), rest::binary>> ->
        %SQL{msg: [_parse, _pbe, _be, execute, _close]}=sql
        send_data(socket, execute, sql)
        more([rest], socket, sql, rows, ref, key, prepared)
      <<50, 4::32, 51, 4::32>> ->
        rows
      <<50, 4::32, rest::binary>> ->
        process(rest, socket, sql,  rows, ref, key, prepared)
      <<49, 4::32, rest::binary>> ->
        :ets.insert(prepared, key)
        process(rest, socket, sql,  rows, ref, key, prepared)
      <<rest::binary>>->
        more([rest], socket, sql, rows, ref, key, prepared)
    end
  end

  defp error(data), do: error(data, 1, [])
  defp error(data, len, acc) do
    case data do
      <<0>> -> acc
      <<?S, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, [{:severity, value}|acc])
      <<?V, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, [{:__severity__, value}|acc])
      <<?C, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, [{:code, value}|acc])
      <<?M, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, [{:message, value}|acc])
      <<?D, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, [{:detail, value}|acc])
      <<?H, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, [{:hint, value}|acc])
      <<?P, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, [{:position, value}|acc])
      <<?p, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, [{:__position__, value}|acc])
      <<?q, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, [{:__query__, value}|acc])
      <<?W, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, [{:where, value}|acc])
      <<?s, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, [{:schema, value}|acc])
      <<?t, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, [{:table, value}|acc])
      <<?c, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, [{:column, value}|acc])
      <<?d, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, [{:data_type, value}|acc])
      <<?n, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, [{:constraint, value}|acc])
      <<?F, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, [{:file, value}|acc])
      <<?L, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, [{:line, value}|acc])
      <<?R, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, [{:routine, value}|acc])
      _ -> error(data, len+1, acc)
    end
  end

  @doc false
  def dynamic(_types, params, count, [prepare, bind, execute, close]) do
    bind = bind(params, count, bind)
    [prepare, prepare<>bind<>execute, bind<>execute, execute, close]
  end

  defp static(_tokens, t, types, params, count, id, max_rows, string) do
    portal = "p_#{id}"
    name = "sql_#{id}"
    parse = parse(types, <<name::binary,0,string::binary,0,count::16-big>>)
    bind = bind(portal, name, count)
    len = byte_size(portal)+6
    execute = execute(portal, len, max_rows)
    close = close(portal, len)
    {string, decoder(t), encoder(Enum.reverse(types), params, []), [parse, bind, execute, close]}
  end

  defp decoder([]), do: nil
  defp decoder(t) do
    mod = Module.concat([__MODULE__.Decoder, "#{:erlang.phash2(t)}"])
    if :erlang.module_loaded(mod) == false do
      case Code.ensure_compiled(mod) do
        {:module, _} -> mod
        {:error, _} ->
          loc = Macro.Env.location(__ENV__)
          :dets.open_file(:sql, [type: :set, ram_file: true])
          if :dets.member(:sql, mod) == false do
            :dets.insert(:sql, {mod, t, __MODULE__, loc})
            :dets.sync(:sql)
          end
          {:module, ^mod, _binary, _term} = Module.create(mod, build_decoder(t), loc)
          mod
      end
    else
      mod
    end
  end

  defp encoder([], [], acc), do: acc
  defp encoder([t|types], [p|params], acc), do: encoder(types, params, [encode(t, p)|acc])

  defp bind(<<portal::binary>>, name, count) do
    <<portal::binary,0,name::binary,0,count::16-big,formats(count)::binary,count::16-big>>
  end

  defp bind([], count, acc) do
    acc = <<acc::binary, count::16-big, formats(count)::binary>>
    <<?B,byte_size(acc)+4::32-big,acc::binary>>
  end
  defp bind([param | params], count, acc) do
    bind(params, count, <<acc::binary, param::binary>>)
  end

  defp execute(portal, len, max_rows) do
    case max_rows do
      0 ->
        <<?E,len+3::32,portal::binary,0,max_rows::32-big,?C,len::32,?P,portal::binary,0,?H,4::32-big>>
      max_rows ->
        <<?E,len+3::32,portal::binary,0,max_rows::32-big,?H,4::32-big>>
    end
  end

  defp close(portal, len), do: <<?C,len::32,?P,portal::binary,0,?S,4::32-big>>

  defp parse([], acc), do: <<?P,byte_size(acc)+4::32-big,acc::binary>>
  defp parse([type | rest], acc), do: parse(rest, <<acc::binary,oid(type)::binary>>)

  defp formats(0), do: ""
  defp formats(n), do: <<1::16-big, formats(n-1)::binary>>

  defp oid(type) do
    case :persistent_term.get({:default, :oids}, nil) do
      %{^type => [oid]} -> <<oid::32-big>>
      %{^type => [_, oid]} -> <<oid::32-big>>
      _ -> <<0::32-big>>
    end
  end

  defp base_types([], acc), do: acc
  defp base_types([{:array, type}=t|types], acc), do: base_types(types, [t,type|acc])
  defp base_types([{:record, type}=t|types], acc), do: base_types(types, [t|base_types(type, acc)])
  defp base_types([type|types], acc), do: base_types(types, [type|acc])

  defp gen_helpers([], acc), do: acc
  defp gen_helpers([{:array, type}|types], acc), do: gen_helpers(types, [elem(array(type), 2)|acc])
  defp gen_helpers([{:record, type}|types], acc), do: gen_helpers(types, [elem(record(type), 2)|acc])
  defp gen_helpers([type|types], acc) when type in ~w[numeric hstore tsvector txid_snapshot path polygon]a, do: gen_helpers(types, [elem(helpers(type), 2)|acc])
  defp gen_helpers([_|types], acc), do: gen_helpers(types, acc)

  def build_decoder(types) do
    helpers = gen_helpers(Enum.uniq(base_types(types, [])), [])
    strides = Enum.chunk_every(types, 8)
    count = length(strides)
    block = for {types, index} <- Enum.with_index(strides, 1), do: stride(types, index, count)
    quote do
      @moduledoc false
      @compile [bin_opt_info: Application.compile_env(:sql, :bin_opt_info), inline: [decode_1: 2]]

      def decode_row(row, %{columns: [], fn: nil}), do: decode_1(row, [])
      def decode_row(row, %{columns: [], fn: fun}), do: fun.(decode_1(row, []))
      def decode_row(row, %{columns: columns, fn: nil}), do: Enum.zip(columns, decode_1(row, []))
      def decode_row(row, %{columns: columns, fn: fun}), do: fun.(Enum.zip(columns, decode_1(row, [])))

      unquote_splicing(block)
      unquote_splicing(helpers)
    end
  end

  defp stride(types, index, count) do
    name = :"decode_#{index}"
    next = if index == count, do: nil, else: :"decode_#{index+1}"
    quote do
      defp unquote(name)(rest, acc) do
        unquote(block(types, next, 1))
      end
    end
  end

  defp array(type) do
    name = :"array_#{type}"
    quote do
      @compile {:inline, [{unquote(name), 1}, {unquote(name), 3}]}
      defp unquote(name)(<<len::32-signed, 0::32, _null_flag::32-big, _oid::32-big, _::binary-size(len-12), rest::binary>>), do: {rest, []}
      defp unquote(name)(<<_::32-signed, ndim::32, _null_flag::32-big, _oid::32-big, rest::binary>>), do: unquote(name)(rest, ndim, 1)

      defp unquote(name)(rest, 0, total) when is_integer(total), do: unquote(name)(rest, total, [])
      defp unquote(name)(rest, 0, acc) when is_list(acc), do: {rest, :lists.reverse(acc)}
      defp unquote(name)(<<len::32-big, _lower_bound::32-big, rest::binary>>, n, acc) when is_integer(acc), do: unquote(name)(rest, n-1, len*acc)
      defp unquote(name)(unquote(match(type)), n, acc) do
        value = unquote(block(type))
        unquote(name)(rest, n-1, [value|acc])
      end
    end
  end

  defp record(types) do
    name = :"record_#{:erlang.phash2(types)}"
    count = length(types)
    blocks = for type <- types do
                quote do
                  defp unquote(name)(<<_::32-big>> <> unquote(match(type)), n, acc) do
                    value = unquote(block(type))
                    unquote(name)(rest, n-1, [value|acc])
                  end
                end
              end

    quote do
      @compile {:inline, [{unquote(name), 1}, {unquote(name), 3}]}

      defp unquote(name)(<<_::32-signed, unquote(count)::32-big, rest::binary>>), do: unquote(name)(rest, unquote(count), [])
      defp unquote(name)(rest, 0, acc), do: {rest, List.to_tuple(:lists.reverse(acc))}
      defp unquote(name)(<<_::32-big, -1::signed-32-big, rest::binary>>, n, acc), do: unquote(name)(rest, n-1, [nil|acc])
      unquote_splicing(blocks)
    end
  end

  defp helpers(:hstore) do
    quote do
      defp hstore("", 0, acc), do: acc
      defp hstore(
            <<len::32-big, key::binary-size(len),
              -1::signed-32-big, rest::binary>>,
            count,
            acc
          ) do
        hstore(rest, count-1, Map.put(acc, key, nil))
      end
      defp hstore(
            <<klen::32-big, key::binary-size(klen),
              vlen::32-big, val::binary-size(vlen), rest::binary>>,
            count,
            acc
          ) do
        hstore(rest, count-1, Map.put(acc, key, val))
      end
    end
  end
  defp helpers(:tsvector) do
    quote do
      defp tsvector(<<0, count::16, positions::binary-size(count*2), rest::binary>>, word, acc) do
        tsvector(rest, "", [{word, tsvector(positions, [])}|acc])
      end
      defp tsvector(<<b, rest::binary>>, word, acc), do: tsvector(rest, <<word::binary, b>>, acc)
      defp tsvector("", "", acc), do: acc
      defp tsvector(<<weight::2, position::14, rest::binary>>, acc) do
        case weight do
          3 -> tsvector(rest, [{position,:A}|acc])
          2 -> tsvector(rest, [{position,:B}|acc])
          1 -> tsvector(rest, [{position,:C}|acc])
          0 -> tsvector(rest, [{position,nil}|acc])
        end
      end
      defp tsvector("", acc), do: :lists.reverse(acc)
    end
  end
  defp helpers(:txid_snapshot) do
    quote do
      defp txid_snapshot(<<xid::64-big, rest::binary>>, acc) do
        [xid|txid_snapshot(rest, acc)]
      end
      defp txid_snapshot("", acc), do: acc
    end
  end
  defp helpers(:numeric) do
    quote do
      defp numeric(<<group::16-big, rest::binary>>, n, pos, int_len, frac_len, acc) do
        # process the 4 digits in this group
        numeric(rest, n-1, pos+4, int_len, frac_len, group(group, pos, int_len, frac_len, acc, 0))
      end
      defp numeric("", 0, _pos, _int_len, _frac_len, acc), do: acc
      defp group(_group, _pos, _int_len, _frac_len, acc, 4), do: acc
      defp group(group, pos, int_len, frac_len, acc, i) do
        digit =
          case i do
            0 -> div(group, 1000)
            1 -> div(rem(group, 1000), 100)
            2 -> div(rem(group, 100), 10)
            3 -> rem(group, 10)
          end
        acc =
          cond do
            digit == 0 and acc == [] -> acc
            pos + i < int_len -> [?0 + digit | acc]
            pos + i == int_len and frac_len > 0 -> [?0+digit, ?. | acc]
            pos + i > int_len and pos + i < int_len + frac_len -> [?0+digit | acc]
            true -> acc
          end
        group(group, pos, int_len, frac_len, acc, i + 1)
      end
    end
  end
  defp helpers(type) when type in ~w[path polygon]a do
    quote do
      defp path(<<x::float-64, y::float-64, rest::binary>>, acc) do
        [{x, y}|path(rest, acc)]
      end
      defp path("", acc), do: acc
    end
  end

  defp var(name, {_, _}) do
    quote do
      {rest, unquote(name)}
    end
  end
  defp var(name, _) do
    quote do
      unquote(name)
    end
  end

  defp block([], nil, idx) do
    vars = for n <- 1..idx-1, do: Macro.var(:"v#{n}", nil)
    quote do
      [unquote_splicing(vars)|acc]
    end
  end
  defp block([], next, idx) do
    vars = for n <- 1..idx-1, do: Macro.var(:"v#{n}", nil)
    quote do
      [unquote_splicing(vars)|unquote(next)(rest, acc)]
    end
  end
  defp block([type|types], next,  idx) do
    name = Macro.var(:"v#{idx}", nil)
    quote do
      case rest do
        <<-1::32-signed, rest::binary>> ->
          unquote(name) = nil
          unquote(block(types, next, idx+1))
        unquote(match(type)) ->
          unquote(var(name, type)) = unquote(block(type))
          unquote(block(types, next, idx+1))
      end
    end
  end
  defp block(:timestamptz) do
    quote do
      DateTime.from_gregorian_seconds(div(value, 1_000_000)+63113904000, {rem(value, 1_000_000), 6})
    end
  end
  defp block(type) when type in ~w[timestamp time_stamp]a do
    quote do
      NaiveDateTime.from_gregorian_seconds(div(value, 1_000_000)+63113904000, {rem(value, 1_000_000), 6})
    end
  end
  defp block(type) when type in ~w[name citext text macaddr macaddr8 bytea bpchar xml tsquery varchar char refcursor character_data sql_identifier jsonpath]a do
    quote do
      value
    end
  end
  defp block(type) when type in ~w[bool boolean]a  do
    quote do
      case value do
        1 -> true
        0 -> false
      end
    end
  end
  defp block(type) when type in ~w[bit varbit]a  do
    quote do
      <<bits::bitstring-size(^count), _::bitstring>> = value
      bits
    end
  end
  defp block(type) when type in ~w[regtype regrole regprocedure regproc regoperator regoper regnamespace regdictionary regconfig regcollation regclass cid oid xid int4 int2 int int8 money ltree lquery xid8 float8 float4 integer]a do
    quote do
      value
    end
  end
  defp block(:void) do
    quote do
      :void
    end
  end
  defp block(:inet) do
    quote do
      case value do
        <<2::8, _mask::8, _is_cidr::8, 4::8, a,b,c,d>> ->
          {a,b,c,d}

        <<3::8, _mask::8, _is_cidr::8, 8::8, a,b,c,d,e,f,_g,h>> ->
          {a,b,c,d,e,f,h}
      end
    end
  end
  defp block(:cidr) do
    quote do
      {a,b,c,d,mask}
    end
  end
  defp block(:uuid) do
    quote do
      :io_lib.bformat("~8.16.0b-~4.16.0b-~4.16.0b-~4.16.0b-~12.16.0b",[a, b, c, d, e])
    end
  end
  defp block(:hstore) do
    quote do
      hstore(value, count, %{})
    end
  end
  defp block(:tid) do
    quote do
      {block, tuple}
    end
  end
  defp block(type) when type in ~w[json jsonb]a do
    quote do
      :json.decode(value)
    end
  end
  defp block(type) when type in ~w[polygon path]a do
    quote do
      path(value, [])
    end
  end
  defp block(:lseg) do
    quote do
      {{x1, y1}, {x2, y2}}
    end
  end
  defp block(:box) do
    quote do
      {{x2, y2}, {x1, y1}}
    end
  end
  defp block(:circle) do
    quote do
      {{x, y}, r}
    end
  end
  defp block(:point) do
    quote do
      {x, y}
    end
  end
  defp block(:line) do
    quote do
      {a,b,c}
    end
  end
  defp block(:daterange) do
    quote do
      if :erlang.band(flags, 0x10) != 0 do
        Date.range(Date.add(~D[2000-01-01], lower), Date.add(~D[2000-01-01], upper))
      else
        Date.range(Date.add(~D[2000-01-01], lower), Date.add(Date.add(~D[2000-01-01], upper), -1))
      end
    end
  end
  defp block(:int8range) do
    quote do
      if :erlang.band(flags, 0x10) != 0 do
        Range.new(lower, upper)
      else
        Range.new(lower, upper-1)
      end
    end
  end
  defp block(:txid_snapshot) do
    quote do
      {xmin, xmax, txid_snapshot(value, [])}
    end
  end
  defp block(:date) do
    quote do
      Date.from_gregorian_days(value+730485)
    end
  end
  defp block(:time) do
    quote do
      Time.from_seconds_after_midnight(div(value, 1_000_000), {rem(value, 1_000_000), 6})
    end
  end
  defp block(:timetz) do
    quote do
      microsecs =
        cond do
          microsecs < 0 ->
            microsecs + 86_400_000_000

          microsecs >= 86_400_000_000 ->
            microsecs - 86_400_000_000

          true ->
            microsecs
        end
        Time.from_seconds_after_midnight(div(microsecs, 1_000_000),{rem(microsecs, 1_000_000), 6})
    end
  end
  defp block(:interval) do
    quote do
      seconds = div(us, 1_000_000)
      micros  = rem(us, 1_000_000)
      minutes = div(seconds, 60)
      seconds = rem(seconds, 60)
      hours   = div(minutes, 60)
      minutes = rem(minutes, 60)
      Duration.new!(year: div(months, 12), month: rem(months, 12), week: 0, day: days, hour: hours, minute: minutes, second: seconds, microsecond: {micros, 6})
    end
  end
  defp block(:tsvector) do
    quote do
      tsvector(value, <<>>, [])
    end
  end
  defp block(:numeric) do
    quote do
      int_len = max(weight + 1, 0) * 4
      frac_len = min(max(ndigits * 4-int_len, 0), dscale)
      acc2 = if sign == 0x4000, do: [?-], else: []
      :lists.reverse(numeric(value, ndigits, 0, int_len, frac_len, acc2))
    end
  end
  defp block(:"\"char\"") do
    quote do
      <<1::32-big, value::8>>
    end
  end
  defp block(:null) do
    quote do
      nil
    end
  end
  defp block({:array, type}) do
    name = :"array_#{type}"
    quote do
      unquote(name)(rest)
    end
  end
  defp block({:record, types}) do
    name = :"record_#{:erlang.phash2(types)}"
    quote do
      unquote(name)(rest)
    end
  end

  defp match({:array, _type}) do
    quote do
      <<rest::binary>>
    end
  end
  defp match({:record, _types}) do
    quote do
      <<rest::binary>>
    end
  end
  defp match(:null) do
    quote do
      <<-1::32-signed, rest::binary>>
    end
  end
  defp match(:"\"char\"") do
    quote do
      <<_::32-signed, value::8, rest::binary>>
    end
  end
  defp match(:numeric) do
    quote do
      <<len::32-signed, ndigits::16-big, weight::16-signed-big, sign::16-big, dscale::16-big, value::binary-size(len-8), rest::binary>>
    end
  end
  defp match(:tsvector) do
    quote do
      <<len::32-signed, _::32-big, value::binary-size(len-4), rest::binary>>
    end
  end
  defp match(:interval) do
    quote do
      <<_::32-signed, us::signed-64-big, days::signed-32-big, months::signed-32-big, rest::binary>>
    end
  end
  defp match(:timetz) do
    quote do
      <<_::32-signed, microsecs::signed-64-big, 0::32-big, rest::binary>>
    end
  end
  defp match(:txid_snapshot) do
    quote do
      <<len::32-signed, _::32-big, xmin::64-big, xmax::64-big, value::binary-size(len-20), rest::binary>>
    end
  end
  defp match(:daterange) do
    quote do
      <<_::32-signed, flags::8, lower::32-signed-big, upper::32-signed-big, rest::binary>>
    end
  end
  defp match(:int8range) do
    quote do
      <<_::32-signed, flags::8, lower::64-signed-big, upper::64-signed-big, rest::binary>>
    end
  end
  defp match(:circle) do
    quote do
      <<_::32-signed, x::float-64, y::float-64, r::float-64, rest::binary>>
    end
  end
  defp match(:point) do
    quote do
      <<_::32-signed, x::float-64, y::float-64, rest::binary>>
    end
  end
  defp match(:line) do
    quote do
      <<_::32-signed, a::float-64, b::float-64, c::float-64, rest::binary>>
    end
  end
  defp match(type) when type in ~w[box lseg]a do
    quote do
      <<_::32-signed, x1::float-64, y1::float-64, x2::float-64, y2::float-64, rest::binary>>
    end
  end
  defp match(:path) do
    quote do
      <<len::32-signed, _closed::8, _npoints::32-big, value::binary-size(len-5), rest::binary>>
    end
  end
  defp match(:polygon)  do
    quote do
      <<len::32-signed, _npoints::32-big, value::binary-size(len-4), rest::binary>>
    end
  end
  defp match(:jsonb)  do
    quote do
      <<len::32-signed, 1, value::binary-size(len-1), rest::binary>>
    end
  end
  defp match(:json)  do
    quote do
      <<len::32-signed, value::binary-size(len), rest::binary>>
    end
  end
  defp match(:tid)  do
    quote do
      <<_::32-signed, block::32-big, tuple::16-big, rest::binary>>
    end
  end
  defp match(:hstore)  do
    quote do
      <<len::32-signed, count::unsigned-32, value::binary-size(len-4), rest::binary>>
    end
  end
  defp match(:xid8)  do
    quote do
      <<_::32-signed, value::unsigned-64-big, rest::binary>>
    end
  end
  defp match(:float8)  do
    quote do
      <<_::32-signed, value::float-64-big, rest::binary>>
    end
  end
  defp match(:float4) do
    quote do
      <<_::32-signed, value::float-32-big, rest::binary>>
    end
  end
  defp match(:uuid)  do
    quote do
      <<_::32-signed, a::32, b::16, c::16, d::16, e::48, rest::binary>>
    end
  end
  defp match(:cidr)  do
    quote do
      <<_::32-signed, _family::8, mask::8, _is_cidr::8, 4::8, a,b,c,d, rest::binary>>
    end
  end
  defp match(:int2)  do
    quote do
      <<_::32-signed, value::signed-16-big, rest::binary>>
    end
  end
  defp match(:void)  do
    quote do
      <<0::32-signed, rest::binary>>
    end
  end
  defp match(type) when type in ~w[name citext text macaddr macaddr8 bytea bpchar xml tsquery varchar char refcursor character_data sql_identifier jsonpath inet]a do
    quote do
      <<len::32-signed, value::binary-size(len), rest::binary>>
    end
  end
  defp match(type) when type in ~w[bool boolean]a  do
    quote do
      <<1::32-signed, value, rest::binary>>
    end
  end
  defp match(type) when type in ~w[ltree lquery]a  do
    quote do
      <<len::32-signed, 1::signed-8, value::binary-size(len-1), rest::binary>>
    end
  end
  defp match(type) when type in ~w[bit varbit]a  do
    quote do
      <<len::32-signed, count::unsigned-32, value::binary-size(div(count + 7, 8)), _::binary-size(len-(div(count + 7, 8))-4), rest::binary>>
    end
  end
  defp match(type) when type in ~w[xid int4 int date integer]a  do
    quote do
      <<_::32-signed, value::signed-32-big, rest::binary>>
    end
  end
  defp match(type) when type in ~w[timestamp time_stamp timestamptz time int8 money]a do
    quote do
      <<_::32-signed, value::signed-64-big, rest::binary>>
    end
  end
  defp match(type) when type in ~w[regtype regrole regprocedure regproc regoperator regoper regnamespace regdictionary regconfig regcollation regclass cid oid]a do
    quote do
      <<_::32-signed, value::32-big, rest::binary>>
    end
  end

  defp encode({:array, type}, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        list ->
          len = length(list)
          oid = SQL.Adapters.Postgres.to_oid(unquote(type))
          elements = for l <- list, into: <<>>, do: unquote(encode(type, quote(do: l)))
          <<20+byte_size(elements)::32-big, 1::32-big, 0::32-big, oid::binary, len::32-big, 1::32-big, elements::binary>>
      end
    end
  end
  defp encode(:null, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
      end
    end
  end
  defp encode(:"\"char\"", value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        <<value::8>> -> <<1::32-big, value::8>>
      end
    end
  end
  defp encode(:interval, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        %Duration{year: year, week: week, day: day, month: month, hour: hour, minute: minute, second: second, microsecond: {microsecond, _}} ->
          months = 12 * year + month
          days = 7 * week + day
          us = 1_000_000 * (3600 * hour + 60 * minute + second) + microsecond
          <<16::32-big, us::64-signed-big, days::32-signed-big, months::32-signed-big>>
      end
    end
  end
  defp encode(:txid_snapshot, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        {xmin, xmax, [xid|rest]=xip} -> SQL.Adapters.Postgres.encode_txid_snapshot(rest, <<length(xip)::32-big, xmin::64-big, xmax::64-big, xid::64-big>>)
      end
    end
  end
  defp encode(:daterange, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        %Date.Range{first: first, last: last} -> <<8::32-big, 0x0E::8, Date.diff(first, ~D[2000-01-01])::32-signed-big, Date.diff(last, ~D[2000-01-01])::32-signed-big>>
      end
    end
  end
  defp encode(:int4range, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        %Range{first: lower, last: upper} -> <<9::32-big, 0x0E::8, lower::32-signed-big, upper::32-signed-big>>
      end
    end
  end
  defp encode(:int8range, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        %Range{first: lower, last: upper} -> <<17::32-big, 0x0E::8, lower::64-signed-big, upper::64-signed-big>>
      end
    end
  end
  defp encode(:circle, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        {{x, y}, r} -> <<24::32-big, x::float-64, y::float-64, r::float-64>>
      end
    end
  end
  defp encode(:point, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        {x, y} -> <<16::32-big, x::float-64, y::float-64>>
      end
    end
  end
  defp encode(:line, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        {a, b, c} -> <<24::32-big, a::float-64, b::float-64, c::float-64>>
      end
    end
  end
  defp encode(:lseg, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        {{x1, y1}, {x2, y2}} -> <<32::32-big, x1::float-64, y1::float-64, x2::float-64, y2::float-64>>
      end
    end
  end
  defp encode(:box, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        {{x1, y1}, {x2, y2}} -> <<32::32-big, x1::float-64, y1::float-64, x2::float-64, y2::float-64>>
      end
    end
  end
  defp encode(:polygon, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        points ->
          n = length(points)
          SQL.Adapters.Postgres.encode_polygon(points, <<4+(n*16)::32, n::32-big>>)
      end
    end
  end
  defp encode(:path, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        points ->
          n = length(points)
          SQL.Adapters.Postgres.encode_path(points, <<5+(n*16)::32-big, 1::8, n::32-big>>)
      end
    end
  end
  defp encode(:tid, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        {block_number, tuple_index} -> <<6::32-big, block_number::32-big, tuple_index::16-big>>
      end
    end
  end
  defp encode(:uuid, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        <<_::128>> = value -> <<16::32-big, value::binary>>
        <<a1::binary-size(8), ?-, a2::binary-size(4), ?-, a3::binary-size(4), ?-, a4::binary-size(4), ?-, a5::binary-size(12)>> -> <<16::32-big, Base.decode16!(<<a1::binary, a2::binary, a3::binary, a4::binary, a5::binary>>, case: :mixed)::binary>>
      end
    end
  end
  defp encode(:cidr, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        {a, b, c, d, mask} -> <<8::32-big, 2::8, mask::8, 1::8, 4::8, a, b, c, d>>
      end
    end
  end
  defp encode(:date, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        %Date{}=value -> <<4::32-big, Date.to_gregorian_days(value)-730485::signed-32-big>>
      end
    end
  end
  defp encode(:time, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        %Time{}=value ->
          {seconds, _ms} = Time.to_seconds_after_midnight(value)
          <<8::32-big, seconds*1_000_000::signed-64-big>>
      end
    end
  end
  defp encode(:timetz, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        %Time{}=value ->
          {seconds, ms} = Time.to_seconds_after_midnight(value)
          ms = seconds*1_000_000+ms
          <<12::32-big, ms::signed-64-big, 0::signed-32-big>>
      end
    end
  end
  defp encode(type, value) when type in ~w[timestamp time_stamp timestamptz]a do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        %NaiveDateTime{}=value ->
          {seconds, _ms} = NaiveDateTime.to_gregorian_seconds(value)
          <<8::32-big, (seconds-63113904000)*1_000_000::signed-64-big>>
        %DateTime{time_zone: "Etc/UTC"}=value ->
          {seconds, _ms} = DateTime.to_gregorian_seconds(value)
          <<8::32-big, (seconds-63113904000)*1_000_000::signed-64-big>>
      end
    end
  end
  defp encode(:int2, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        value -> <<2::32-big, value::signed-16-big>>
      end
    end
  end
  defp encode(type, value) when type in ~w[regtype regrole regprocedure regproc regoperator regoper regnamespace regdictionary regconfig regcollation regclass cid oid xid int4 int integer]a do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        value -> <<4::32-big, value::32-big>>
      end
    end
  end
  defp encode(type, value) when type in ~w[int8 money]a do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        value -> <<8::32-big, value::signed-64-big>>
      end
    end
  end
  defp encode(:xid8, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        value -> <<8::32-big, value::unsigned-64-big>>
      end
    end
  end
  defp encode(type, value) when type in ~w[bit varbit]a do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        value ->
          count = bit_size(value)
          bytes = div(count+7, 8)
          pad = bytes*8-count
          <<4+bytes::32-big, count::unsigned-32-big, value::bitstring, 0::size(pad)>>
      end
    end
  end
  defp encode(type, value) when type in ~w[ltree lquery]a do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        value -> <<byte_size(value)+1::32-big, 1::signed-8, value::binary>>
      end
    end
  end
  defp encode(type, value) when type in ~w[bool boolean]a do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        true -> <<1::32-big, 1>>
        false -> <<1::32-big, 0>>
      end
    end
  end
  defp encode(type, value) when type in ~w[name citext text macaddr macaddr8 bytea bpchar xml tsquery varchar char refcursor character_data sql_identifier jsonpath]a do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        value -> <<byte_size(value)::32-big, value::binary>>
      end
    end
  end
  defp encode(:inet, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        {a, b, c, d} -> <<8::32-big, 2::8, 32::8, 1::8, 4::8, a, b, c, d>>
      end
    end
  end
  defp encode(:void, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        _ -> <<0::32-big>>
      end
    end
  end
  defp encode(:float4, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        value -> <<4::32-big, value::float-32-big>>
      end
    end
  end
  defp encode(:float8, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        value -> <<8::32-big, value::float-64-big>>
      end
    end
  end
  defp encode(:hstore, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        value ->
          bin = for {<<k::binary>>, v} <- value, into: <<map_size(value)::32-big>> do
            case v do
              nil -> <<byte_size(k)::32-big, k::binary, -1::32-big>>
              v   -> <<byte_size(k)::32-big, k::binary, byte_size(v)::32-big, v::binary>>
            end
          end
          <<byte_size(bin)::32-big, bin::binary>>
      end
    end
  end
  defp encode(:json, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        value ->
          value = :erlang.iolist_to_binary(:json.encode(value))
          <<byte_size(value)::32-big, value::binary>>
      end
    end
  end
  defp encode(:jsonb, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        value ->
          bin = :erlang.iolist_to_binary(:json.encode(value))
          <<1+byte_size(bin)::32-big, 1, bin::binary>>
      end
    end
  end
  defp encode(:numeric, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        [?-|value] -> SQL.Adapters.Postgres.encode_numeric(value, 0x4000, 0, nil, 0, 0, 0, <<>>)
        value -> SQL.Adapters.Postgres.encode_numeric(value, 0x0000, 0, nil, 0, 0, 0, <<>>)
      end
    end
  end
  defp encode(:tsvector, value) do
    quote generated: true do
      case unquote(value) do
        nil -> <<-1::32-big>>
        value ->
          value = SQL.Adapters.Postgres.encode_tsvector(value, <<>>, 0)
          <<byte_size(value)::32-big, value::binary>>
      end
    end
  end

  def to_oid(type) do
    case :persistent_term.get({:default, :oids}, nil) do
      %{^type => [oid]} -> <<oid::32-big>>
      %{^type => [_, oid]} -> <<oid::32-big>>
      _ -> <<0::32-big>>
    end
  end

  def encode_path([], acc), do: acc
  def encode_path([{x, y} | points], acc), do: encode_path(points, <<acc::binary, x::float, y::float>>)

  def encode_polygon([], acc), do: acc
  def encode_polygon([{x, y} | points], acc), do: encode_polygon(points, <<acc::binary, x::float-64, y::float-64>>)

  def encode_tsvector(list, acc) do
    case list do
      [] -> acc
      [{pos, :A} | rest] -> encode_tsvector(rest, <<acc::binary, 3::2, pos::14>>)
      [{pos, :B} | rest] -> encode_tsvector(rest, <<acc::binary, 2::2, pos::14>>)
      [{pos, :C} | rest] -> encode_tsvector(rest, <<acc::binary, 1::2, pos::14>>)
      [{pos, nil} | rest] -> encode_tsvector(rest, <<acc::binary, 0::2, pos::14>>)
    end
  end
  def encode_tsvector(list, acc, count) do
    case list do
      [] -> <<count::32-big, acc::binary>>
      [{word, positions} | rest] -> encode_tsvector(rest, encode_tsvector(positions, <<acc::binary, word::binary, 0, length(positions)::16-big>>), count + 1)
    end
  end

  def encode_txid_snapshot([], acc), do: acc
  def encode_txid_snapshot([xid|rest], acc), do: encode_txid_snapshot(rest, <<acc::binary, xid::64-big>>)

  def encode_numeric([], sign, weight, scale, group, len, count, bin) do
    case len do
      0 ->
        scale = if scale, do: scale, else: 0
        <<10+count::32-big, count::16-big, weight-1::16-big, sign::16-big, scale::16-big, bin::binary>>
      _ ->
        scale = if scale, do: scale+1, else: 0
        count = count+1
        <<10+count::32-big, count::16-big, weight-1::16-big, sign::16-big, scale::16-big, bin::binary, group::16>>
    end
  end
  def encode_numeric([?.|rest], sign, 0, nil, group, len, count, bin) do
    encode_numeric(rest, sign, count, 0, group, len, count, bin)
  end
  def encode_numeric([n|rest], sign, weight, scale, group, len, count, bin) do
    scale = if scale, do: scale+1
    digit = n-?0
    case len+1 do
      4 -> encode_numeric(rest, sign, weight, scale, 0, 0, count+1, <<bin::binary, group*10+digit::16>>)
      len -> encode_numeric(rest, sign, weight, scale, group*10+digit, len, count, bin)
    end
  end
end
