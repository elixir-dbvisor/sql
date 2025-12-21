# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Adapters.Postgres do
  @moduledoc """
    A SQL adapter for [PostgreSQL](https://www.postgresql.org).
  """
  @moduledoc since: "0.2.0"
  use SQL.Token

  @epoch_date ~D[2000-01-01]
  @epoch_naive ~N[2000-01-01 00:00:00]
  @epoch_unix_seconds 946_684_800
  @sync <<?S, 4::32-big>>
  @ssl <<8::32, 80877103::32>>

  def start(state) do
    {:ok, spawn(fn -> init(state) end)}
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
        |> Map.put(:socket, socket)
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

  defp loop(%{socket: socket, handle: handle} = state, buffer, inflight, prepared, total, current, queue, owner, rows, count) do
    receive do
      {ref, caller, %{tokens: [{:begin, _, _}]}}=entry when is_nil(owner) ->
        send caller, {ref, :begin}
        prepare(entry, state, buffer, inflight, prepared, total, current, queue, caller, rows, count)
      {_ref, ^owner, %{tokens: [{:commit, _, _}]}}=entry ->
        prepare(entry, state, buffer, inflight, prepared, total, current, queue, nil, rows, count)
      {_ref, ^owner, %{tokens: [{:rollback, _, _}]}}=entry ->
        prepare(entry, state, buffer, inflight, prepared, total, current, queue, nil, rows, count)
      {ref, ^owner, %{tokens: [{:savepoint, _, _}|_]}}=entry ->
        send owner, {ref, :begin}
        prepare(entry, state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
      {_ref, ^owner, %{tokens: [{:release, _, _}|_]}}=entry ->
        prepare(entry, state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
      {_ref, ^owner, %{tokens: [{:rollback, _, _}|_]}}=entry ->
        prepare(entry, state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
      {^owner, entry} ->
        prepare_execute(entry, state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
      {_ref, _caller, %SQL{}} = entry when is_nil(owner) ->
        prepare_execute(entry, state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
      {_ref, _caller, %SQL{}} = entry ->
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

  defp prepare({_ref, _caller, %SQL{name: name}=sql}, state, buffer, inflight, prepared, total, current, queue, owner, rows, count) do
    case !is_map_key(prepared, name) do
      false ->
        send_data(state, bind(sql))
        loop(state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
      prepare ->
        send_data(state, prepare(sql, [bind(sql)]))
        loop(state, buffer, inflight, Map.put(prepared, name, prepare), total, current, queue, owner, rows, count)
    end
  end

  defp prepare_execute({_ref, _caller, %SQL{name: name}=sql}=entry, state, buffer, inflight, prepared, total, current, queue, owner, rows, count) do
    total = total + 1
    case !is_map_key(prepared, name) do
      false ->
        send_data(state, bind(sql))
        loop(state, buffer, Map.put(inflight, total, entry), prepared, total, current, queue, owner, rows, count)
      prepare ->
        send_data(state, prepare(sql, [bind(sql)]))
        loop(state, buffer, Map.put(inflight, total, entry), Map.put(prepared, name, prepare), total, current, queue, owner, rows, count)
    end
    # if Enum.find(inflight, fn {_, {_, _, s}} -> sql===s end) == nil do
      # if prepare, do: send_data(state, prepare(sql))
      # send_data(state, bind(sql))
    # end
  end

  defp drain(%{socket: socket, handle: handle} = state, <<buffer::binary>>, inflight, prepared, total, current, queue, owner, rows, count) do
    case :socket.recv(socket, 0, [], handle) do
      {:ok, data} -> drain(state, <<buffer::binary, data::binary>>, inflight, prepared, total, current, queue, owner, rows, count)
      {:select, {:select_info, :recv, ^handle}} -> parse_messages(state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
    end
  end

  defp send_data(%{socket: {:"$socket", _ref}=socket}, data) do
    :socket.send(socket, data)
  end
  defp send_data(%{socket: socket}, data) do
    :ssl.send(socket, data)
  end

  defp handle_data(state, ""=buffer, inflight, prepared, total, current, queue, owner, rows, count) do
    loop(state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
  end
  defp handle_data(state, buffer, inflight, prepared, total, current, queue, owner, rows, count) do
    parse_messages(state, buffer, inflight, prepared, total, current, queue, owner, rows, count)
  end

  defp parse_messages(%{socket: socket, ssl: ssl, password: password, username: username, parameter: parameter, database: database, timeout: timeout}=state, <<buffer::binary>>, inflight, prepared, total, current, queue, owner, rows, count) do
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
        IO.inspect(parse_pg_error(payload), label: "#{DateTime.utc_now()} scheduler_id: #{state.scheduler_id} Unmatched PG Error")
        case inflight do
          %{^current => {ref, caller, _sql}} ->
            send(caller, {ref, {:error, payload}})
            parse_messages(state, rest, Map.delete(inflight, current), prepared, total, current+1, queue, owner, rows, count)
          _ ->
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
        %{^current => {ref, caller, sql}} = inflight
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
        %{^current => {_ref, _caller, sql}} = inflight
        send_data(state, execute(sql))
        parse_messages(state, rest, inflight, prepared, total, current, queue, owner, rows, count)
      <<?K, 12::32, pid::32, secret::32, rest::binary>> ->
        parse_messages(Map.put(Map.put(state, :secret, secret), :pid, pid), rest, inflight, prepared, total, current, queue, owner, rows, count)
      <<?D, len::32, payload::binary-size(len-4), rest::binary>> when count == 999 ->
        %{^current => {ref, caller, sql}} = inflight
        {_, rows} = Enumerable.reduce([parse_data_row(payload, sql.columns)|rows], {:cont, []}, sql.fn)
        send caller, {ref, {:cont, rows}}
        parse_messages(state, rest, inflight, prepared, total, current, queue, owner, [], 0)
      <<?D, len::32, payload::binary-size(len-4), rest::binary>> ->
        %{^current => {_ref, _caller, sql}} = inflight
        parse_messages(state, rest, inflight, prepared, total, current, queue, owner, [parse_data_row(payload, sql.columns)|rows], count+1)
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

  defp parse_pg_error(payload) do
    parse_fields(payload, %{})
  end

  defp parse_fields(<<0>>, acc), do: acc
  defp parse_fields(<<field_type, rest::binary>>, acc) do
    case :binary.match(rest, <<0>>) do
      {pos, 1} ->
        <<value::binary-size(^pos), 0, rest::binary>> = rest
        parse_fields(rest, Map.put(acc, field_type_to_atom(field_type), value))

      :nomatch ->
        parse_fields(<<>>, Map.put(acc, field_type_to_atom(field_type), rest))
    end
  end

  defp field_type_to_atom(?S), do: :severity
  defp field_type_to_atom(?C), do: :code
  defp field_type_to_atom(?M), do: :message
  defp field_type_to_atom(?F), do: :file
  defp field_type_to_atom(?L), do: :line
  defp field_type_to_atom(?R), do: :routine
  defp field_type_to_atom(other), do: other

  defp close(%{portal: portal, p_len: len}), do: <<?C,len+6::32,?P,portal::binary,0,?S,4::32-big>>
  defp execute(%{max_rows: max_rows, portal: portal, p_len: len}), do: <<?E,len+9::32,portal::binary,0,max_rows::32-big,?S,4::32-big>>

  defp prepare(queries), do: prepare(queries, [@sync])
  defp prepare([], acc), do: acc
  defp prepare([sql|rest], acc), do: prepare(rest, prepare(sql, acc))
  defp prepare(%{name: name, string: string, params: params, idx: idx}, acc) do
    len = 8+byte_size(name)+byte_size(string)+(4*idx)
    [<<?P,len::32-big,name::binary,0,string::binary,0,idx::16-big>>, (for p <- params, do: oid(p))|acc]
  end

  defp bind(%{name: name, idx: idx, params: params, columns: _columns, c_len: c_len, types: types, max_rows: max_rows, portal: portal, p_len: len}) do
    params_bin = for {type, p} <- Enum.zip(types, params), into: "", do: encode_param(type, p)
    bind_len = 12+len+byte_size(name)+((idx+c_len)*2)+byte_size(params_bin)
    <<?B, bind_len::32-big, portal::binary, 0, name::binary, 0, idx::16-big, formats(idx)::binary, idx::16-big, params_bin::binary, c_len::16-big, formats(c_len)::binary, ?E,len+9::32,portal::binary,0,max_rows::32-big,?S,4::32-big>>
  end

  defp formats(0), do: ""
  defp formats(n), do: <<1::16-big, formats(n-1)::binary>>

  defp parse_data_row(<<_::16-signed-big, rest::binary>>, columns) do
    parse_data_row(rest, columns, [])
  end
  defp parse_data_row(<<>>, [], acc), do: acc
  defp parse_data_row(<<-1::32-signed-big, rest::binary>>, [_|cols], acc) do
    parse_data_row(rest, cols, [nil|acc])
  end
  defp parse_data_row(<<len::32-signed-big, value::binary-size(len), rest::binary>>, [{type, _col}|cols], acc) do
    parse_data_row(rest, cols, [decode_column(type, value)|acc])
  end

  defp decode_column({:array, type}, <<count::32-signed-big, _len::32-signed-big, _null_flag::32-signed-big, rest::binary>>) do
    decode_array(rest, count, type, [])
  end
  defp decode_column({:composite, count}, bin), do: decode_composite(bin, count, [])
  defp decode_column(:jsonb, bin), do: :json.decode(bin)
  defp decode_column(16, <<0>>), do: false
  defp decode_column(16, <<1>>), do: true
  defp decode_column(21, <<val::signed-16-big>>), do: val
  defp decode_column(23, <<val::signed-32-big>>), do: val
  defp decode_column(20, <<val::signed-64-big>>), do: val
  defp decode_column(700, <<val::float-32-big>>), do: val
  defp decode_column(701, <<val::float-64-big>>), do: val
  defp decode_column(25, bin), do: bin
  defp decode_column(1043, bin), do: bin
  defp decode_column(1082, <<days::signed-32-big>>), do: Date.add(@epoch_date, days)
  defp decode_column(1114, <<micros::signed-64-big>>), do: NaiveDateTime.add(@epoch_naive, micros, :microsecond)
  defp decode_column(1184, <<micros::signed-64-big>>), do: DateTime.from_unix!(micros + @epoch_unix_seconds * 1_000_000, :microsecond)
  defp decode_column(1700, <<ndigits::16-big, weight::16-signed-big, sign::16-big, dscale::16-big, rest::binary>>) do
    int_len = max(weight + 1, 0) * 4
    frac_len = min(max(ndigits * 4-int_len, 0), dscale)
    acc = if sign == 0x4000, do: [?-], else: []
    Enum.reverse(decode_numeric(rest, ndigits, 0, int_len, frac_len, acc))
  end
  defp decode_column(:numeric, <<ndigits::16-big, weight::16-signed-big, sign::16-big, dscale::16-big, rest::binary>>) do
    int_len = max(weight + 1, 0) * 4
    frac_len = min(max(ndigits * 4-int_len, 0), dscale)
    acc = if sign == 0x4000, do: [?-], else: []
    Enum.reverse(decode_numeric(rest, ndigits, 0, int_len, frac_len, acc))
  end
  defp decode_column(~c"float4", <<val::float-32-big>>), do: val
  defp decode_column(~c"float8", <<val::float-64-big>>), do: val
  defp decode_column(:numeric, <<val::signed-16-big>>), do: val
  defp decode_column(:numeric, <<val::signed-32-big>>), do: val
  defp decode_column(:numeric, <<val::signed-64-big>>), do: val
  defp decode_column(_, bin), do: bin


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

  defp decode_array(<<>>, 0, _type, acc), do: Enum.reverse(acc)
  defp decode_array(<<-1::32-signed-big, rest::binary>>, count, type, acc) do
    decode_array(rest, count-1, type, [nil|acc])
  end
  defp decode_array(<<len::32-big, bin::binary-size(len), rest::binary>>, count, type, acc) do
    decode_array(rest, count-1, type, [decode_column(type, bin) | acc])
  end

  defp decode_composite(<<>>, 0, acc), do: List.to_tuple(Enum.reverse(acc))
  defp decode_composite(<<-1::32-signed-big, rest::binary>>, count, acc) do
    decode_composite(rest, count-1, [nil | acc])
  end
  defp decode_composite(<<len::32-big, bin::binary-size(len), rest::binary>>, count, acc) do
    decode_composite(rest, count-1, [bin | acc])
  end

  defp encode_param({:array, type}, list) do
    elements = for el <- list, into: <<>>, do: encode_param(type, el)
    header = <<1::32-big, length(list)::32-signed-big, 0::32-signed-big>>
    <<byte_size(header)+byte_size(elements)::32-big, header::binary, elements::binary>>
  end
  defp encode_param({:composite, count}, tuple) do
    elements = for i <- 0..(count-1), into: <<>>, do: encode_param(:dynamic, elem(tuple, i))
    <<byte_size(elements)::32-big, elements::binary>>
  end
  defp encode_param(:jsonb, value) do
    bin = :json.encode(value)
    <<1+byte_size(bin)::32-big, 1, bin::binary>>
  end
  defp encode_param(_, nil), do: <<-1::32-big>>
  defp encode_param(16, true), do: <<1::32-big, 1>>
  defp encode_param(16, false), do: <<1::32-big, 0>>
  defp encode_param(20, v), do: <<8::32-big, v::signed-64-big>>
  defp encode_param(21, v), do: <<2::32-big, v::signed-16-big>>
  defp encode_param(23, v), do: <<4::32-big, v::signed-32-big>>
  defp encode_param(700, v), do: <<4::32-big, v::float-32-big>>
  defp encode_param(701, v), do: <<8::32-big, v::float-64-big>>
  defp encode_param(25, b), do: <<byte_size(b)::32-big, b::binary>>
  defp encode_param(_, b), do: encode_param(25, to_string(b))

  for {type, oid} <- [bool: 16,
                      bytea: 17,
                      char: 18,
                      name: 19,
                      int8: 20,
                      int2: 21,
                      int2vector: 22,
                      int4: 23,
                      regproc: 24,
                      text: 25,
                      oid: 26,
                      tid: 27,
                      xid: 28,
                      cid: 29,
                      oidvector: 30,
                      ddl_command: 32,
                      type: 71,
                      attribute: 75,
                      proc: 81,
                      class: 83,
                      json: 114,
                      xml: 142,
                      node_tree: 194,
                      smgr: 210,
                      point: 600,
                      lseg: 601,
                      path: 602,
                      box: 603,
                      polygon: 604,
                      line: 628,
                      cidr: 650,
                      float4: 700,
                      float8: 701,
                      abstime: 702,
                      reltime: 703,
                      tinterval: 704,
                      unknown: 705,
                      circle: 718,
                      money: 790,
                      macaddr: 829,
                      inet: 869,
                      aclitem: 1033,
                      bpchar: 1042,
                      varchar: 1043,
                      date: 1082,
                      time: 1083,
                      timestamp: 1114,
                      timestamptz: 1184,
                      interval: 1186,
                      timetz: 1266,
                      bit: 1560,
                      varbit: 1562,
                      numeric: 1700,
                      refcursor: 1790,
                      regprocedure: 2202,
                      regoper: 2203,
                      regoperator: 2204,
                      regclass: 2205,
                      regtype: 2206,
                      record: 2249,
                      cstring: 2275,
                      any: 2266,
                      anyarray: 2277,
                      void: 2278,
                      trigger: 2279,
                      language_handler: 2280,
                      internal: 2281,
                      opaque: 2282,
                      anyelement: 2283,
                      anynonarray: 2776,
                      anyenum: 3500,
                      fdw_handler: 3115,
                      tsvector: 3614,
                      tsquery: 3615,
                      gtsvector: 3642,
                      regconfig: 3734,
                      regdictionary: 3769,
                      jsonb: 3802,
                      int4range: 3904,
                      numrange: 3906,
                      tsrange: 3908,
                      tstzrange: 3910,
                      daterange: 3912,
                      int8range: 3926,
                      uuid: 2950,
                      lsn: 3220,
                      txid_snapshot: 2970,
                      snapshot: 5038,
                      xid8: 5069,
                      macaddr8: 774,
                      regdatabase: 8326,
                      anycompatible: 5077,
                      anycompatiblearray: 5078,
                      anycompatiblenonarray: 5079,
                      anycompatiblerange: 5080,
                      anymultirange: 4537,
                      table_am_handler: 269,
                      index_am_handler: 325
                      ] do
    defp oid(unquote(type)), do: unquote(<<oid::32-big>>)
  end
  defp oid(_), do: <<0::32-big>>
end
