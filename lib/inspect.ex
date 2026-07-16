# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Inspect do
  @moduledoc false

  @error IO.ANSI.red()
  @reset IO.ANSI.reset()

  defimpl Inspect, for: SQL do
    def inspect(%{inspect: nil, tokens: tokens, context: context}, _opts) do
      {:current_stacktrace, stack} = Process.info(self(), :current_stacktrace)
      SQL.Inspect.to_string(tokens, context, hd(stack))
    end
    def inspect(%{inspect: inspect}, _opts), do: inspect
  end

  @doc false
  def to_string(tokens, %{errors: errors}=context, stack) do
    inspect = IO.iodata_to_binary([@reset, "~SQL\"\"\""|[SQL.Format.to_iodata(tokens, context, 0, true)|~c"\n\"\"\""]])
    case errors do
      [] -> inspect
      errors ->
        {:current_stacktrace, [_|t]} = Process.info(self(), :current_stacktrace)
        IO.warn([?\n,format_error(errors), IO.iodata_to_binary([@reset, "  ~SQL\"\"\""|[SQL.Format.to_iodata(tokens, context, 1, true)|~c"\n  \"\"\""]])], [stack|t])
        inspect
    end
  end

  def format_error(errors) do
    errors
    |> Enum.group_by(&elem(&1, 2))
    |> Enum.reduce([], fn
      {k, [{:special, _, _}]}, acc -> [acc|["  the operator", @error,k,@reset, " is invalid, did you mean any of #{suggest(k)}\n"]]
      {k, [{:special, _, _}|_]=v}, acc -> [acc|["  the operator ",@error,k,@reset," is mentioned #{length(v)} times but is invalid, did you mean any of #{suggest(k)}\n"]]
      {k, [_]}, acc -> [acc|["  the relation ",@error,k,@reset," does not exist\n"]]
      {k, v}, acc -> [acc|["  the relation ",@error,k,@reset," is mentioned #{length(v)} times but does not exist\n"]]
    end)
  end

  defp suggest(k), do: Enum.join(SQL.Lexer.suggest_operator(:erlang.iolist_to_binary(k)), ", ")
end
