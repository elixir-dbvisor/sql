# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Adapters.Postgres do
  @moduledoc """
    A SQL adapter for [PostgreSQL](https://www.postgresql.org).
  """
  @moduledoc since: "0.2.0"
  use SQL.Token

  require Logger

  @sync <<?S, 4::32-big>>
  @ssl <<8::32, 80877103::32>>

  def start(state) do
    pid = spawn_link(fn -> init(state) end)
    case :persistent_term.get(state.name, nil) do
      nil -> {:ok, pid}
      pool -> {:persistent_term.put(state.name, :erlang.setelement(state.scheduler_id, pool, pid)), pid}
    end
  end

  defp to_iodata({:in, m, [{:not, _, left}, {:binding, _, [idx]}]}, format, case, acc) do
    to_iodata(left, format, case, indention(["!= ANY($#{idx})"|acc], format, m))
  end
  defp to_iodata({:in, m, [left, {:binding, _, [idx]} ]}, format, case, acc) do
    to_iodata(left, format, case, indention(["= ANY($#{idx})"|acc], format, m))
  end
  defp to_iodata({:binding, m, [idx]}, format, _case, acc) do
    indention(["$#{idx}"|acc], format, m)
  end
  defp to_iodata(token, format, case, acc), do: __to_iodata__(token, format, case, acc)

  defp init(%{domain: domain, type: type, protocol: protocol, username: username, database: database}=state) do
    handle = make_ref()
    {:ok, socket} = :socket.open(domain, type, protocol, Map.take(state, [:netns, :use_registry, :debug]))
    :socket.monitor(socket)
    for {level, opts} <- Map.take(state, [:otp, :socket]), {k, v} <- opts, do: :socket.setopt(socket, level, k, v)
    :socket.connect(socket, Map.take(state, [:family, :port, :addr]), handle)
    receive do
      {:"$socket", ^socket, :select, ^handle} ->
        :socket.connect(socket)
        :socket.recv(socket, 0, [], handle)
        state
        |> Map.put(:sock, socket)
        |> Map.put(:handle, handle)
        |> case do
          %{ssl: false} = state ->
            send_data(state, <<25+byte_size(username)+byte_size(database)::32, 196_608::32, "user", 0, username::binary, 0, "database", 0, database::binary, 0, 0>>)
            loop(state, <<>>, %{}, %{}, 0, 1, :queue.new(), nil, [], 0)
          state ->
            send_data(state, @ssl)
            loop(state, <<>>, %{}, %{}, 0, 1, :queue.new(), nil, [], 0)
        end
    end
  end

  defp cancel(%{domain: domain, type: type, protocol: protocol, pid: pid, secret: secret}=state) do
    {:ok, socket} = :socket.open(domain, type, protocol, Map.take(state, [:netns, :use_registry, :debug]))
    for {level, opts} <- Map.take(state, [:otp, :socket]), {k, v} <- opts, do: :socket.setopt(socket, level, k, v)
    :socket.connect(socket, Map.take(state, [:family, :port, :addr]))
    :socket.send(socket, <<16::32-big, 80877102::32-big, pid::32-big, secret::32-big>>)
    :socket.recv(socket, 0, [])
    :socket.close(socket)
    state
  end

  defp loop(%{sock: socket, handle: handle, timeout: timeout} = state, buffer, inflight, prepared, total, current, queue, owner, rows, count) do
    receive do
      {:cancel, ref} ->
        case Enum.find(inflight, fn {_, {r, _caller, _timestamp, _sql}} -> r == ref end) do
          nil -> loop(state, buffer, inflight, prepared, total, current, :queue.filter(fn {r, _caller, _timestamp, _sql} -> r != ref  end, queue), owner, rows, count)
          {^current, {^ref, _caller, _timestamp, _sql}} -> loop(cancel(state), buffer, inflight, prepared, total, current, queue, owner, rows, count)
          _ -> loop(state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
        end
      {ref, caller, _timestamp, %{tokens: [{:begin, _, _}]}}=entry when is_nil(owner) ->
        send caller, {ref, :begin}
        prepare(entry, state, buffer, inflight, prepared, total, current, queue, caller, rows, count)
      {_ref, ^owner, _timestamp, %{tokens: [{:commit, _, _}]}}=entry ->
        prepare(entry, state, buffer, inflight, prepared, total, current, queue, nil, rows, count)
      {_ref, ^owner, _timestamp, %{tokens: [{:rollback, _, _}]}}=entry ->
        prepare(entry, state, buffer, inflight, prepared, total, current, queue, nil, rows, count)
      {ref, ^owner, _timestamp, %{tokens: [{:savepoint, _, _}|_]}}=entry ->
        send owner, {ref, :begin}
        prepare(entry, state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
      {_ref, ^owner, _timestamp, %{tokens: [{:release, _, _}|_]}}=entry ->
        prepare(entry, state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
      {_ref, ^owner, _timestamp, %{tokens: [{:rollback, _, _}|_]}}=entry ->
        prepare(entry, state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
      {^owner, entry} ->
        prepare_execute(entry, state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
      {_ref, _caller, _timestamp, %SQL{}} = entry when is_nil(owner) ->
        prepare_execute(entry, state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
      {_ref, _caller, _timestamp, %SQL{}} = entry ->
        loop(state, buffer, inflight, prepared, total, current, :queue.in(entry, queue), owner, rows, count)
      {:"$socket", ^socket, :select, ^handle} ->
        drain(state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
      {:ssl, ^socket, data} ->
        :ssl.setopts(socket, active: :once)
        parse_messages(state, <<buffer::binary, data::binary>>, inflight, prepared, total, current, queue, owner, rows, count)
      {:ssl_closed, ^socket} = other ->
        raise other
      {:ssl_error, ^socket, reason} ->
        raise reason
      after
        5 ->
          case inflight do
            %{^current => {ref, _caller, timestamp, sql}} ->
              if System.convert_time_unit(System.monotonic_time()-timestamp, :native, :millisecond) >= (sql.timeout || timeout) do
                send(self(), {:cancel, ref})
              end
            _ ->
              :ok
          end
          case owner do
            nil ->
              case :queue.out(queue) do
                {:empty, _} ->
                  loop(state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
                {{:value, entry}, queue} ->
                  send(self(), entry)
                  loop(state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
              end
            _owner ->
              loop(state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
          end
    end
  end

  defp prepare({_ref, _caller, _timestamp, %SQL{name: name}=sql}, state, buffer, inflight, prepared, total, current, queue, owner, rows, count) do
    case !is_map_key(prepared, name) do
      false ->
        send_data(state, bind(sql, owner))
        loop(state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
      prepare ->
        send_data(state, prepare(sql, [bind(sql, owner)]))
        loop(state, buffer, inflight, Map.put(prepared, name, prepare), total, current, queue, owner, rows, count)
    end
  end

  defp prepare_execute({_ref, _caller, _timestamp, %SQL{name: name}=sql}=entry, state, buffer, inflight, prepared, total, current, queue, owner, rows, count) do
    total = total + 1
    case !is_map_key(prepared, name) do
      false ->
        send_data(state, bind(sql, owner))
        loop(state, buffer, Map.put(inflight, total, entry), prepared, total, current, queue, owner, rows, count)
      prepare ->
        send_data(state, prepare(sql, [bind(sql, owner)]))
        loop(state, buffer, Map.put(inflight, total, entry), Map.put(prepared, name, prepare), total, current, queue, owner, rows, count)
    end
    # if Enum.find(inflight, fn {_, {_, _, s}} -> sql===s end) == nil do
      # if prepare, do: send_data(state, prepare(sql))
      # send_data(state, bind(sql))
    # end
  end

  defp drain(%{sock: socket, handle: handle} = state, <<buffer::binary>>, inflight, prepared, total, current, queue, owner, rows, count) do
    case :socket.recv(socket, 0, [], handle) do
      {:ok, data} -> drain(state, <<buffer::binary, data::binary>>, inflight, prepared, total, current, queue, owner, rows, count)
      {:select, {:select_info, :recv, ^handle}} -> parse_messages(state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
    end
  end

  defp send_data(%{sock: {:"$socket", _ref}=socket}, data) do
    :socket.send(socket, data)
  end
  defp send_data(%{sock: socket}, data) do
    :ssl.send(socket, data)
  end

  defp handle_data(state, ""=buffer, inflight, prepared, total, current, queue, owner, rows, count) do
    loop(state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
  end
  defp handle_data(state, buffer, inflight, prepared, total, current, queue, owner, rows, count) do
    parse_messages(state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
  end

  defp parse_messages(%{sock: socket, ssl: ssl, password: password, username: username, parameter: parameter, database: database, timeout: timeout}=state, <<buffer::binary>>, inflight, prepared, total, current, queue, owner, rows, count) do
    case buffer do
      <<?S, rest::binary>> when elem(socket, 0) == :"$socket" and is_list(ssl) ->
        {:ok, socket} = :ssl.connect(socket, ssl, timeout)
        :ssl.setopts(socket, active: :once)
        state = %{state | socket: socket}
        send_data(state, <<25+byte_size(username)+byte_size(database)::32, 196_608::32, "user", 0, username::binary, 0, "database", 0, database::binary, 0, 0>>)
        parse_messages(state, rest, inflight, prepared, total, current, queue, owner, rows, count)
      <<?N, _rest::binary>> when elem(socket, 0) == :"$socket" and is_list(ssl) ->
        raise "SSL not supported by server"
      <<?R, len::32, 10::32, payload::binary-size(len-8), rest::binary>> ->
        mechanisms = :binary.split(payload, <<0>>, [:global])
        if "SCRAM-SHA-256" in mechanisms do
          scram_nonce = Base.encode64(:crypto.strong_rand_bytes(18))
          send_data(state, <<?p,54::32,"SCRAM-SHA-256",0,32::32,?n,?,,?,,?n,?=,?,,?r,?=,scram_nonce::binary>>)
          parse_messages(Map.put(state, :scram_nonce, scram_nonce), rest, inflight, prepared, total, current, queue, owner, rows, count)
        else
          raise "Unsupported SASL mechanism: #{inspect(mechanisms)}"
        end
      <<?R, len::32, 11::32, payload::binary-size(len-8), rest::binary>> ->
        %{?r => r, ?s => s, ?i => i} = for kv <- :binary.split(payload, ",", [:global]), into: %{} do
          <<k, "=", v::binary>> = kv
          {k, v}
        end
        salt = Base.decode64!(s)
        iter = String.to_integer(i)
        salted_password = :crypto.pbkdf2_hmac(:sha256, password, salt, iter, 32)
        client_key = :crypto.mac(:hmac, :sha256, salted_password, "Client Key")
        auth_message = <<?n,?=,?,,?r,?=,binary_part(r, 0, 24)::binary,?,,?r,?=,r::binary,?,,?s,?=,s::binary,?,,?i,?=,i::binary,?,,?c,?=,?b,?i,?w,?s,?,,?r,?=,r::binary>>
        client_signature = :crypto.mac(:hmac, :sha256, :crypto.hash(:sha256, client_key), auth_message)
        proof = Base.encode64(:crypto.exor(client_key, client_signature))
        send_data(state,  <<?p,byte_size(r)+byte_size(proof)+16::32,?c,?=,?b,?i,?w,?s,?,,?r,?=,r::binary,?,,?p,?=,proof::binary>>)
        parse_messages(Map.put(Map.put(state, :scram_salted_password, salted_password), :scram_auth_message, auth_message), rest, inflight, prepared, total, current, queue, owner, rows, count)
      <<?R, len::32-big, 12::32-big, payload::binary-size(len-8), rest::binary>> ->
        %{?v => server_signature_b64} = for kv <- :binary.split(payload, ",", [:global]), into: %{} do
                                        <<k, "=", v::binary>> = kv
                                        {k, v}
                                      end
        server_key = :crypto.mac(:hmac, :sha256, state.scram_salted_password, "Server Key")
        expected_sig = Base.encode64(:crypto.mac(:hmac, :sha256, server_key, state.scram_auth_message))
        if server_signature_b64 != expected_sig do
          raise "SCRAM server signature mismatch"
        end
        parse_messages(state, rest, inflight, prepared, total, current, queue, owner, rows, count)
      <<?R, len::32, 5::32, salt::binary-size(len-8), rest::binary>> ->
        password = "md5#{Base.encode16(:crypto.hash(:md5, [Base.encode16(:crypto.hash(:md5, [password, username]), case: :lower), salt]), case: :lower)}"
        send_data(state, <<?p, 5+byte_size(password)::32, password::binary, 0>>)
        handle_data(state, rest, inflight, prepared, total, current, queue, owner, rows, count)
      <<?R, 4::32, 3::32, rest::binary>> ->
        send_data(state, <<?p, 5+byte_size(password)::32, password::binary, 0>>)
        handle_data(state, rest, inflight, prepared, total, current, queue, owner, rows, count)
      <<?R, 4::32, 0::32, rest::binary>> ->
        parse_messages(state, rest, inflight, prepared, total, current, queue, owner, rows, count)
      <<?E, len::32, payload::binary-size(len-4), rest::binary>> ->
        error = error(payload)
        case inflight do
          %{^current => {ref, caller, _timestamp, sql}} ->
            send(caller, {ref, {:error, %{error|sql: sql.string}}})
            parse_messages(state, rest, Map.delete(inflight, current), prepared, total, current+1, queue, owner, rows, count)
          _ ->
            Logger.error(error)
            parse_messages(state, rest, inflight, prepared, total, current, queue, owner, rows, count)
        end
      <<?C, len::32, "BEGIN", _payload::binary-size(len-9), rest::binary>> ->
        parse_messages(state, rest, inflight, prepared, total, current, queue, owner, rows, count)
      <<?C, len::32, "COMMIT", _payload::binary-size(len-10), rest::binary>> ->
        parse_messages(state, rest, inflight, prepared, total, current, queue, owner, rows, count)
      <<?C, len::32, "SAVEPOINT", _payload::binary-size(len-13), rest::binary>> ->
        parse_messages(state, rest, inflight, prepared, total, current, queue, owner, rows, count)
      <<?C, len::32, "RELEASE", _payload::binary-size(len-11), rest::binary>> ->
        parse_messages(state, rest, inflight, prepared, total, current, queue, owner, rows, count)
      <<?C, len::32, "ROLLBACK", _payload::binary-size(len-12), rest::binary>> ->
        parse_messages(state, rest, inflight, prepared, total, current, queue, owner, rows, count)
      <<?C, len::32, _payload::binary-size(len-4), rest::binary>> ->
        %{^current => {ref, caller, _timestamp, sql}} = inflight
        send_data(state, close(sql))
        send caller, {ref, Enumerable.reduce(rows, {:cont, []}, sql.fn)}
        parse_messages(state, rest, Map.delete(inflight, current), prepared, total, current+1, queue, owner, [], 0)
        # case Map.split_with(inflight, fn {_k, {s, _}} -> sql===s end) do
        #   {callers, inf} when map_size(inf) == 0 ->
        #     # current = Enum.max(Map.keys(inflight))+1
        #     for {_k, {_, caller}} <- callers, do: send(caller, result)
        #     parse_messages(state, rest, inf, prepared, total, total+1, [], 0)
        #   {callers, inflight} ->
        #     current = Enum.min(Map.keys(inflight))
        #     for {_k, {_, caller}} <- callers, do: send(caller, result)
        #     parse_messages(state, rest, inflight, prepared, total, current, [], 0)
        # end
      <<?s, len::32, _payload::binary-size(len-4), rest::binary>> ->
        %{^current => {_ref, _caller, _timestamp, sql}} = inflight
        send_data(state, execute(sql, owner))
        parse_messages(state, rest, inflight, prepared, total, current, queue, owner, rows, count)
      <<?K, 12::32, pid::32, secret::32, rest::binary>> ->
        parse_messages(Map.put(Map.put(state, :secret, secret), :pid, pid), rest, inflight, prepared, total, current, queue, owner, rows, count)
      <<?D, len::32, payload::binary-size(len-4), rest::binary>> when count == 999 and owner != nil ->
        %{^current => {ref, caller, _timestamp, %{columns: columns, fn: fun}}} = inflight
        {_, rows} = Enumerable.reduce([parse_data_row(payload, columns)|rows], {:cont, []}, fun)
        send caller, {ref, {:cont, rows}}
        parse_messages(state, rest, inflight, prepared, total, current, queue, owner, [], 0)
      <<?D, len::32, payload::binary-size(len-4), rest::binary>> ->
        %{^current => {_ref, _caller, _timestamp, %{columns: columns}}} = inflight
        parse_messages(state, rest, inflight, prepared, total, current, queue, owner, [parse_data_row(payload, columns)|rows], count+1)
      <<?Z, len::32, _payload::binary-size(len-4), rest::binary>> when total == 0 and map_size(prepared) == 0 ->
        case :persistent_term.get({SQL, :queries}, []) do
          [] ->
            handle_data(state, rest, inflight, prepared, total, current, queue, owner, rows, count)
          queries ->
            send_data(state, prepare(queries))
            handle_data(state, rest, inflight, Enum.reduce(queries, prepared, &Map.put(&2, &1.name, true)), total, current, queue, owner, rows, count)
        end
      <<?Z, len::32, _payload::binary-size(len-4), rest::binary>> ->
        parse_messages(state, rest, inflight, prepared, total, current, queue, owner, rows, count)
      <<?S, len::32, payload::binary-size(len-4), rest::binary>> ->
        [k, v, _] = :binary.split(payload, <<0>>, [:global])
        parse_messages(%{state | parameter: Map.put(parameter, k, v)}, rest, inflight, prepared, total, current, queue, owner, rows, count)
      <<_tag::8, len::32, _payload::binary-size(len-4), rest::binary>> ->
        parse_messages(state, rest, inflight, prepared, total, current, queue, owner, rows, count)
      _ ->
        loop(state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
    end
  end

  defp error(data, len \\ 1, acc \\ %{severity: nil, __severity__: nil, hint: nil, schema: nil, table: nil, data_type: nil, constraint: nil, column: nil, where: nil, position: nil, detail: nil, code: nil, message: nil, file: nil, line: nil, routine: nil, sql: nil}) do
    case data do
      <<0>> -> acc
      <<?S, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, %{acc|severity: value})
      <<?V, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, %{acc|__severity__: value})
      <<?C, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, %{acc|code: value})
      <<?M, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, %{acc|message: value})
      <<?D, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, %{acc|detail: value})
      <<?H, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, %{acc|hint: value})
      <<?P, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, %{acc|position: value})
      <<?p, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, %{acc|__position__: value})
      <<?q, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, %{acc|__query__: value})
      <<?W, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, %{acc|where: value})
      <<?s, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, %{acc|schema: value})
      <<?t, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, %{acc|table: value})
      <<?c, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, %{acc|column: value})
      <<?d, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, %{acc|data_type: value})
      <<?n, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, %{acc|constraint: value})
      <<?F, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, %{acc|file: value})
      <<?L, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, %{acc|line: value})
      <<?R, value::binary-size(^len), 0, rest::binary>> -> error(rest, 1, %{acc|routine: value})
      _ -> error(data, len+1, acc)
    end
  end

  defp close(%{portal: portal, p_len: len}), do: <<?C,len+6::32,?P,portal::binary,0,?S,4::32-big>>
  defp execute(%{portal: portal, p_len: len}, nil), do: <<?E,len+9::32,portal::binary,0,0::32-big,?S,4::32-big>>
  defp execute(%{portal: portal, p_len: len}, _owner), do: <<?E,len+9::32,portal::binary,0,500::32-big,?S,4::32-big>>

  defp prepare(queries), do: prepare(queries, [@sync])
  defp prepare([], acc), do: acc
  defp prepare([sql|rest], acc), do: prepare(rest, prepare(sql, acc))
  defp prepare(%{name: name, string: string, params: _params, types: types, idx: idx}, acc) do
    len = 8+byte_size(name)+byte_size(string)+(4*idx)
    [<<?P,len::32-big,name::binary,0,string::binary,0,idx::16-big>>, (for p <- types, do: oid(p))|acc]
  end

  defp bind(%{name: name, idx: idx, params: params, columns: _columns, c_len: c_len, types: types, portal: portal, p_len: len}, nil) do
    params_bin = for {type, p} <- Enum.zip(types, params), into: "", do: encode(type, p)
    bind_len = 12+len+byte_size(name)+((idx+c_len)*2)+byte_size(params_bin)
    <<?B, bind_len::32-big, portal::binary, 0, name::binary, 0, idx::16-big, formats(idx)::binary, idx::16-big, params_bin::binary, c_len::16-big, formats(c_len)::binary, ?E,len+9::32,portal::binary,0,0::32-big,?S,4::32-big>>
  end
  defp bind(%{name: name, idx: idx, params: params, columns: _columns, c_len: c_len, types: types, portal: portal, p_len: len}, _owner) do
    params_bin = for {type, p} <- Enum.zip(types, params), into: "", do: encode(type, p)
    bind_len = 12+len+byte_size(name)+((idx+c_len)*2)+byte_size(params_bin)
    <<?B, bind_len::32-big, portal::binary, 0, name::binary, 0, idx::16-big, formats(idx)::binary, idx::16-big, params_bin::binary, c_len::16-big, formats(c_len)::binary, ?E,len+9::32,portal::binary,0,500::32-big,?S,4::32-big>>
  end

  defp formats(0), do: ""
  defp formats(n), do: <<1::16-big, formats(n-1)::binary>>

  defp parse_data_row(<<_::16-signed, rest::binary>>, columns) do
    parse_data_row(rest, columns, [], Enum.all?(columns, fn
      {:array, _} -> true
      {_, col} when is_nil(col) -> true
      {_, _} -> false
      _ -> true
    end))
  end
  defp parse_data_row(<<>>, [], acc, _), do: Enum.reverse(acc)
  defp parse_data_row(<<-1::32-signed, rest::binary>>, [{_type, col}|cols], acc, false=flag) do
    parse_data_row(rest, cols, [{col, nil}|acc],flag)
  end
  defp parse_data_row(<<len::32-signed, value::binary-size(len), rest::binary>>, [{:record, _}=type|cols], acc, false=flag) do
    parse_data_row(rest, cols, [decode(type, value)|acc],flag)
  end
  defp parse_data_row(<<len::32-signed, value::binary-size(len), rest::binary>>, [{type, col}|cols], acc, false=flag) do
    parse_data_row(rest, cols, [{col, decode(type, value)}|acc],flag)
  end
  defp parse_data_row(<<-1::32-signed, rest::binary>>, [_type|cols], acc, true=flag) do
    parse_data_row(rest, cols, [nil|acc],flag)
  end
  defp parse_data_row(<<len::32-signed, value::binary-size(len), rest::binary>>, [type|cols], acc, true=flag) do
    parse_data_row(rest, cols, [decode(type, value)|acc],flag)
  end


  defp decode({type, nil}, bin), do: decode(type, bin)
  defp decode(:array, <<0::32, _null_flag::32-big, _oid::32-big>>), do: []
  defp decode(:array, <<ndim::32, _null_flag::32-big, oid::32-big, rest::binary>>) do
    decode_array(rest, oid, :dims, ndim, 1, [])
  end
  defp decode({:array, type}, <<ndim::32, _null_flag::32-big, _oid::32-big, rest::binary>>) do
    decode_array(rest, type, :dims, ndim, 1, [])
  end
  defp decode({:record, types}, <<count::32-big, rest::binary>>) do
    decode_record(rest, types, count, [])
  end
  defp decode(:bool, <<0>>), do: false
  defp decode(:bool, <<1>>), do: true
  defp decode(:uuid, <<a::32, b::16, c::16, d::16, e::48>>) do
    IO.iodata_to_binary(:io_lib.format("~8.16.0b-~4.16.0b-~4.16.0b-~4.16.0b-~12.16.0b",[a, b, c, d, e]))
  end
  defp decode({:composite, count}, bin), do: decode_composite(bin, count, [])
  defp decode(:date, <<days::signed-32-big>>), do: Date.from_gregorian_days(days+730485)
  defp decode(:jsonb, <<1, b::binary>>), do: :json.decode(b)
  defp decode(:json, bin), do: :json.decode(bin)
  defp decode(:timestamp, <<ms::64-big>>), do: NaiveDateTime.from_gregorian_seconds(div(ms, 1_000_000)+63113904000, {rem(ms, 1_000_000), 6})
  defp decode(:timestamptz, <<ms::signed-64-big>>), do: DateTime.from_gregorian_seconds(div(ms, 1_000_000)+63113904000, {rem(ms, 1_000_000), 6})
  defp decode(:time, <<val::signed-64-big>>) do
    Time.from_seconds_after_midnight(div(val, 1_000_000), {rem(val, 1_000_000), 6})
  end
  defp decode(:timetz, <<microsecs::signed-64-big, 0::32-big>>) do
    microsecs =
      cond do
        microsecs < 0 ->
          microsecs + 86_400_000_000

        microsecs >= 86_400_000_000 ->
          microsecs - 86_400_000_000

        true ->
          microsecs
      end

    Time.from_seconds_after_midnight(
      div(microsecs, 1_000_000),
      {rem(microsecs, 1_000_000), 6}
    )
  end
  defp decode(:int2, <<val::signed-16-big>>), do: val
  defp decode(type, <<val::signed-32-big>>) when type in ~w[cardinal_number int4]a, do: val
  defp decode(:int8, <<val::signed-64-big>>), do: val
  defp decode(:float4, <<val::float-32-big>>), do: val
  defp decode(:float8, <<val::float-64-big>>), do: val
  defp decode(:money, <<val::signed-64-big>>), do: val
  defp decode(type, <<val::32-big>>) when type in ~w[regtype regrole regprocedure regproc regoperator regoper regnamespace regdictionary regconfig regcollation regclass]a, do: val
  defp decode(:xid8, <<val::unsigned-64-big>>), do: val
  defp decode(:xid, <<val::signed-32-big>>), do: val
  defp decode(:cid, <<val::32-big>>), do: val
  defp decode(:oid, <<val::32-big>>), do: val
  defp decode(:tid, <<block::32-big, tuple::16-big>>), do: {block, tuple}
  defp decode(type, <<1::signed-8, b::binary>>) when type in ~w[ltree lquery]a, do: b
  defp decode(:hstore, <<count::32-big, rest::binary>>) do
    decode_hstore(rest, count, %{})
  end
  defp decode(:interval, <<us::signed-64-big, days::signed-32-big, months::signed-32-big>>) do
    seconds = div(us, 1_000_000)
    micros  = rem(us, 1_000_000)
    minutes = div(seconds, 60)
    seconds = rem(seconds, 60)
    hours   = div(minutes, 60)
    minutes = rem(minutes, 60)
    Duration.new!(year: div(months, 12), month: rem(months, 12), week: 0, day: days, hour: hours, minute: minutes, second: seconds, microsecond: {micros, 6})
  end
  defp decode(:numeric, <<ndigits::16-big, weight::16-signed-big, sign::16-big, dscale::16-big, rest::binary>>) do
    int_len = max(weight + 1, 0) * 4
    frac_len = min(max(ndigits * 4-int_len, 0), dscale)
    acc = if sign == 0x4000, do: [?-], else: []
    Enum.reverse(decode_numeric(rest, ndigits, 0, int_len, frac_len, acc))
  end
  defp decode(:numeric, <<val::signed-16-big>>),  do: val
  defp decode(:numeric, <<val::signed-32-big>>),  do: val
  defp decode(:numeric, <<val::signed-64-big>>),  do: val
  defp decode(:tsvector, <<_::32-big, words::binary>>) do
    decode_tsvector(words, [])
  end
  defp decode(:point, <<x::float-64, y::float-64>>) do
    {x, y}
  end
  defp decode(:circle, <<x::float-64, y::float-64, r::float-64>>) do
    {{x, y}, r}
  end
  defp decode(:line, <<a::float-64, b::float-64, c::float-64>>) do
    {a, b, c}
  end
  defp decode(:lseg, <<x1::float-64, y1::float-64, x2::float-64, y2::float-64>>) do
    {{x1, y1}, {x2, y2}}
  end
  defp decode(:box, <<x1::float-64, y1::float-64, x2::float-64, y2::float-64>>) do
    {{x2, y2}, {x1, y1}}
  end
  defp decode(:path, <<_closed::8, _npoints::32-big, rest::binary>>) do
    for <<x::float-64, y::float-64 <- rest>>, do: {x, y}
  end
  defp decode(:polygon, <<_npoints::32-big, rest::binary>>) do
    for <<x::float-64, y::float-64 <- rest>>, do: {x, y}
  end
  defp decode(:inet, val) do
    case val do
      <<2::8, _mask::8, _is_cidr::8, 4::8, a,b,c,d>> -> {a,b,c,d}
      <<3::8, _mask::8, _is_cidr::8, 8::8, a,b,c,d,e,f,_g,h>> -> {a,b,c,d,e,f,h}
    end
  end
  defp decode(:cidr, <<_family::8, mask::8, _is_cidr::8, 4::8, a,b,c,d>>) do
    {a,b,c,d,mask}
  end
  defp decode(type, <<count::unsigned-32, data::binary-size(div(count + 7, 8)), _::binary>>) when type in ~w[bit varbit]a do
    <<bits::bitstring-size(^count), _::bitstring>> = data
    bits
  end
  defp decode(:txid_snapshot, <<_::32-big, xmin::64-big, xmax::64-big, rest::binary>>) do
    {xmin, xmax, (for <<xid::64-big <- rest>>, do: xid)}
  end
  defp decode(:daterange, <<flags::8, lower::32-signed-big, upper::32-signed-big>>) do
    if :erlang.band(flags, 0x10) != 0 do
      Date.range(Date.add(~D[2000-01-01], lower), Date.add(~D[2000-01-01], upper))
    else
      Date.range(Date.add(~D[2000-01-01], lower), Date.add(Date.add(~D[2000-01-01], upper), -1))
    end
  end
  defp decode(:int8range, <<flags::8, lower::64-signed-big, upper::64-signed-big>>) do
    if :erlang.band(flags, 0x10) != 0 do
      Range.new(lower, upper)
    else
      Range.new(lower, upper-1)
    end
  end
  defp decode(nil, <<0::32-big>>), do: :void
  defp decode(_, <<-1::32-signed-big>>), do: nil
  defp decode(_type, bin) do
    bin
  end

  defp decode_hstore(<<>>, 0, acc), do: acc

  defp decode_hstore(
         <<len::32-big, key::binary-size(len),
           -1::signed-32-big, rest::binary>>,
         count,
         acc
       ) do
    decode_hstore(rest, count-1, Map.put(acc, key, nil))
  end
  defp decode_hstore(
         <<klen::32-big, key::binary-size(klen),
           vlen::32-big, val::binary-size(vlen), rest::binary>>,
         count,
         acc
       ) do
    decode_hstore(rest, count-1, Map.put(acc, key, val))
  end

  defp decode_tsvector(<<>>, acc), do: acc
  defp decode_tsvector(words, acc) do
    [word, <<count::16, positions::binary-size(count*2), rest::binary>>] = :binary.split(words, <<0>>)
    positions =
      for <<weight::2, position::14 <- positions>>, do: {position, case weight do
        3 -> :A
        2 -> :B
        1 -> :C
        0 -> nil
      end}
    decode_tsvector(rest, [{word, positions}|acc])
  end


  defp decode_numeric(_bin, 0, _pos, _int_len, _frac_len, acc), do: acc
  defp decode_numeric(<<group::16-big, rest::binary>>, n, pos, int_len, frac_len, acc) do
    # process the 4 digits in this group
    decode_numeric(rest, n-1, pos+4, int_len, frac_len, decode_group(group, pos, int_len, frac_len, acc, 0))
  end
  defp decode_group(_group, _pos, _int_len, _frac_len, acc, 4), do: acc
  defp decode_group(group, pos, int_len, frac_len, acc, i) do
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
    decode_group(group, pos, int_len, frac_len, acc, i + 1)
  end

  defp decode_array(<<>>, _type, _part, 0, _total, acc), do: Enum.reverse(acc)
  defp decode_array(rest, type, :dims, 0, total, acc) do
    decode_array(rest, type, :elems, total, total, acc)
  end
  defp decode_array(<<len::32-big, _lower_bound::32-big, rest::binary>>, type, :dims, n, total, acc) do
    decode_array(rest, type, :dims, n-1, total*len, acc)
  end
  defp decode_array(<<-1::32-signed-big, rest::binary>>, type, part, n, total, acc) do
    decode_array(rest, type, part, n-1, total, [nil|acc])
  end
  defp decode_array(<<len::32-big, data::binary-size(len), rest::binary>>, type, part, n, total, acc) do
    decode_array(rest, type, part, n-1, total, [decode(type, data)|acc])
  end

  def decode_record(<<>>, _types, 0, acc), do: Enum.reverse(acc)
  def decode_record(<<_::32-big, -1::32-signed-big, rest::binary>>, [_|types], count, acc), do: decode_record(rest, types, count-1, [nil|acc])
  def decode_record(<<_::32-big, len::32-big, data::binary-size(len), rest::binary>>, [{type, _col}|types], count, acc) when type not in ~w[array record]a, do: decode_record(rest, types, count-1, [decode(type, data)|acc])
  def decode_record(<<_::32-big, len::32-big, data::binary-size(len), rest::binary>>, [type|types], count, acc), do: decode_record(rest, types, count-1, [decode(type, data)|acc])


  defp decode_composite(<<>>, 0, acc), do: List.to_tuple(Enum.reverse(acc))
  defp decode_composite(<<-1::32-signed-big, rest::binary>>, count, acc) do
    decode_composite(rest, count-1, [nil | acc])
  end
  defp decode_composite(<<len::32-big, bin::binary-size(len), rest::binary>>, count, acc) do
    decode_composite(rest, count-1, [bin | acc])
  end

  defp encode({:array, type}, list) do
    len = length(list)
    oid = oid(type)
    elements = for el <- list, into: <<>>, do: encode(type, el)
    <<20+byte_size(elements)::32-big, 1::32-big, 0::32-big, oid::binary, len::32-big, 1::32-big, elements::binary>>
  end
  defp encode({:composite, count}, tuple) do
    elements = for i <- 0..(count-1), into: <<>>, do: encode(:dynamic, elem(tuple, i))
    <<byte_size(elements)::32-big, elements::binary>>
  end
  defp encode(:jsonb, value) do
    b = :erlang.iolist_to_binary(:json.encode(value))
    <<1+byte_size(b)::32-big, 1, b::binary>>
  end
  defp encode(:json, value) do
    b = :erlang.iolist_to_binary(:json.encode(value))
    <<byte_size(b)::32-big, b::binary>>
  end
  defp encode(_, nil), do: <<-1::32-big>>
  defp encode(_, :void), do: <<0::32-big>>
  defp encode(type, b) when type in ~w[citext text]a, do: <<byte_size(b)::32-big, b::binary>>
  defp encode(type, b) when type in ~w[ltree lquery]a, do: <<byte_size(b)+1::32-big, 1::signed-8, b::binary>>
  defp encode(:hstore, map) when is_map(map) do
    bin = for {<<k::binary>>, v} <- map, into: <<map_size(map)::32-big>> do
      case v do
        nil -> <<byte_size(k)::32-big, k::binary, -1::32-big>>
        v   -> <<byte_size(k)::32-big, k::binary, byte_size(v)::32-big, v::binary>>
      end
    end
    <<byte_size(bin)::32-big, bin::binary>>
  end
  defp encode(:bool, true), do: <<1::32-big, 1>>
  defp encode(:bool, false), do: <<1::32-big, 0>>
  defp encode(:xid8, v), do: <<8::32-big, v::unsigned-64-big>>
  defp encode(:"\"char\"", <<v::8>>), do: <<1::32-big, v::8>>
  defp encode(:int2, v), do: <<2::32-big, v::signed-16-big>>
  defp encode(:int4, v), do: <<4::32-big, v::signed-32-big>>
  defp encode(:int8, v), do: <<8::32-big, v::signed-64-big>>
  defp encode(:float4, v), do: <<4::32-big, v::float-32-big>>
  defp encode(:float8, v), do: <<8::32-big, v::float-64-big>>
  # family = 2 (IPv4), mask = mask, is_cidr = 1, length = 4
  defp encode(:inet, {a, b, c, d}), do: <<8::32-big, 2::8, 32::8, 1::8, 4::8, a, b, c, d>>
  defp encode(:cidr, {a, b, c, d, mask}), do: <<8::32-big, 2::8, mask::8, 1::8, 4::8, a, b, c, d>>
  defp encode(:macaddr, b), do: <<byte_size(b)::32-big, b::binary>>
  defp encode(:macaddr8, b), do: <<byte_size(b)::32-big, b::binary>>
  defp encode(type, b) when type in ~w[bit varbit]a do
    count = bit_size(b)
    bytes = div(count+7, 8)
    pad = bytes*8-count
    <<4+bytes::32-big, count::unsigned-32-big, b::bitstring, 0::size(pad)>>
  end
  defp encode(:circle, {{x, y}, r}), do: <<24::32-big, x::float-64, y::float-64, r::float-64>>
  defp encode(:point, {x, y}), do: <<16::32-big, x::float-64, y::float-64>>
  defp encode(:line, {a, b, c}), do: <<24::32-big, a::float-64, b::float-64, c::float-64>>
  defp encode(:lseg, {{x1, y1}, {x2, y2}}), do: <<32::32-big, x1::float-64, y1::float-64, x2::float-64, y2::float-64>>
  defp encode(:box, {{x1, y1}, {x2, y2}}), do: <<32::32-big, x1::float-64, y1::float-64, x2::float-64, y2::float-64>>
  defp encode(:path, points) do
    n = length(points)
    Enum.reduce(points, <<5+(n*16)::32-big, 1::8, n::32-big>>, fn {x, y}, acc -> <<acc::binary, x::float, y::float>> end)
  end
  defp encode(:polygon, points) do
    n = length(points)
    Enum.reduce(points, <<4+(n*16)::32, n::32-big>>, fn {x, y}, acc -> <<acc::binary, x::float-64, y::float-64>> end)
  end
  defp encode(type, oid) when type in ~w[regtype regrole regprocedure regproc regoperator regoper regnamespace regdictionary regconfig regcollation regclass]a, do: <<4::32-big, oid::32-big>>
  defp encode(type, oid) when type in ~w[xid xid8]a, do: <<4::32-big, oid::32-big>>
  defp encode(:cid, b), do: <<4::32-big, b::32-big>>
  defp encode(:tid, {block_number, tuple_index}), do: <<6::32-big, block_number::32-big, tuple_index::16-big>>
  defp encode(:oid, b), do: <<4::32-big, b::32-big>>
  defp encode(:interval, %Duration{year: year, week: week, day: day, month: month, hour: hour, minute: minute, second: second, microsecond: {microsecond, _}}) do
    months = 12 * year + month
    days = 7 * week + day
    us = 1_000_000 * (3600 * hour + 60 * minute + second) + microsecond
    <<16::32-big, us::64-signed-big, days::32-signed-big, months::32-signed-big>>
  end
  defp encode(:numeric, b) do
    case b do
      [?-|rest] -> encode_numeric(rest, 0x4000, 0, nil, 0, 0, 0, <<>>)
      rest -> encode_numeric(rest, 0x0000, 0, nil, 0, 0, 0, <<>>)
    end
  end
  defp encode(:tsvector, lexemes) do
    bin = encode_lexemes(lexemes, <<>>, 0)
    <<byte_size(bin)::32-big, bin::binary>>
  end
  defp encode(:money, b), do: <<8::32-big, b::64-signed-big>>
  defp encode(:uuid, <<_::128>> = bin) do
    <<16::32-big, bin::binary>>
  end
  defp encode(:uuid, <<a1::binary-size(8), ?-, a2::binary-size(4), ?-, a3::binary-size(4), ?-, a4::binary-size(4), ?-, a5::binary-size(12)>>) do
    <<16::32-big, Base.decode16!(<<a1::binary, a2::binary, a3::binary, a4::binary, a5::binary>>, case: :mixed)::binary>>
  end
  defp encode(type, b) when type in ~w[refcursor bytea bpchar xml tsquery varchar char character_data name sql_identifier jsonpath]a, do: encode(:text, to_string(b))
  defp encode(:timetz, %Time{}=time) do
    {seconds, ms} = Time.to_seconds_after_midnight(time)
    ms = seconds*1_000_000+ms
    <<12::32-big, ms::signed-64-big, 0::signed-32-big>>
  end
  defp encode(:time, [%Time{}|_]=list), do: encode({:array, :time}, list)
  defp encode(:time, %Time{}=time) do
    {seconds, _ms} = Time.to_seconds_after_midnight(time)
    <<8::32-big, seconds*1_000_000::signed-64-big>>
  end
  defp encode(type, %DateTime{time_zone: "Etc/UTC"}=datetime) when type in ~w[timestamp time_stamp]a do
    {seconds, _ms} = DateTime.to_gregorian_seconds(datetime)
    <<8::32-big, (seconds-63113904000)*1_000_000::signed-64-big>>
  end
  defp encode(type, %NaiveDateTime{}=datetime) when type in ~w[timestamp time_stamp]a do
    {seconds, _ms} = NaiveDateTime.to_gregorian_seconds(datetime)
    <<8::32-big, (seconds-63113904000)*1_000_000::signed-64-big>>
  end
  defp encode(:timestamptz, %DateTime{time_zone: "Etc/UTC"}=datetime) do
    {seconds, _ms} = DateTime.to_gregorian_seconds(datetime)
    <<8::32-big, (seconds-63113904000)*1_000_000::signed-64-big>>
  end
  defp encode(:date, [%Date{}|_]=list), do: encode({:array, :date}, list)
  defp encode(:date, %Date{}=date), do: <<4::32-big, Date.to_gregorian_days(date)-730485::signed-32-big>>

  defp encode(:daterange, %Date.Range{first: first, last: last}) do
    <<8::32-big, 0x0E::8, Date.diff(first, ~D[2000-01-01])::32-signed-big, Date.diff(last, ~D[2000-01-01])::32-signed-big>>
  end
  defp encode(:int4range, %Range{first: lower, last: upper}) do
    <<9::32-big, 0x0E::8, lower::32-signed-big, upper::32-signed-big>>
  end
  defp encode(:int8range, %Range{first: lower, last: upper}) do
    <<17::32-big, 0x0E::8, lower::64-signed-big, upper::64-signed-big>>
  end
  defp encode(:txid_snapshot, {xmin, xmax, [xid|rest]=xip}), do: encode_values(rest, <<length(xip)::32-big, xmin::64-big, xmax::64-big, xid::64-big>>)

  defp encode_values([], acc), do: acc
  defp encode_values([xid|rest], acc), do: encode_values(rest, <<acc::binary, xid::64-big>>)

  defp encode_lexemes(list, acc, count) do
    case list do
      [] -> <<count::32-big, acc::binary>>
      [{word, positions} | rest] -> encode_lexemes(rest, encode_positions(positions, <<acc::binary, word::binary, 0, length(positions)::16-big>>), count + 1)
    end
  end

  defp encode_positions(list, acc) do
    case list do
      [] -> acc
      [{pos, weight} | rest] ->
        w =
          case weight do
            :A -> 3
            :B -> 2
            :C -> 1
            nil -> 0
          end

        encode_positions(rest, <<acc::binary, w::2, pos::14>>)
    end
  end

  defp encode_numeric([], sign, weight, nil, group, len, count, bin) do
    case len do
      0 ->
        <<10+count::32-big, count::16-big, weight-1::16-big, sign::16-big, 0::16-big, bin::binary>>
      _ ->
        count = count+1
        <<10+count::32-big, count::16-big, weight::16-big, sign::16-big, 0::16-big, bin::binary, group::16>>
    end
  end
  defp encode_numeric([], sign, weight, scale, group, len, count, bin) do
    case len do
      0 ->
        <<10+count::32-big, count::16-big, weight-1::16-big, sign::16-big, scale::16-big, bin::binary>>
      _ ->
        count = count+1
        <<10+count::32-big, count::16-big, weight-1::16-big, sign::16-big, scale+1::16-big, bin::binary, group::16>>
    end
  end
  defp encode_numeric([?.|rest], sign, 0, nil, group, len, count, bin) do
    encode_numeric(rest, sign, count, 0, group, len, count, bin)
  end
  defp encode_numeric([n|rest], sign, weight, scale=nil, group, len, count, bin) do
    digit = n-?0
    case len+1 do
      4 -> encode_numeric(rest, sign, weight, scale, 0, 0, count+1, <<bin::binary, group*10+digit::16>>)
      len -> encode_numeric(rest, sign, weight, scale, group*10+digit, len, count, bin)
    end
  end
  defp encode_numeric([n|rest], sign, weight, scale, group, len, count, bin) do
    digit = n-?0
    case len+1 do
      4 -> encode_numeric(rest, sign, weight, scale+1, 0, 0, count+1, <<bin::binary, group*10+digit::16>>)
      len -> encode_numeric(rest, sign, weight, scale+1, group*10+digit, len, count, bin)
    end
  end

  defp oid(type) do
    case :persistent_term.get({:default, :oids}, nil) do
      %{^type => [oid]} -> <<oid::32-big>>
      %{^type => [_, oid]} -> <<oid::32-big>>
      _ -> <<0::32-big>>
    end
  end
end
