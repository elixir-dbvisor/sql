# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule Mix.Tasks.Compile.Sql do
  @moduledoc """
  A SQL compiler for sql files.

  You must add it to your `mix.exs` as:

      compilers: [:sql] ++ Mix.compilers()

  """
  use Mix.Task.Compiler

  @doc false
  def run(_args) do
    Mix.Task.Compiler.after_compiler(:elixir, fn
      {:noop, diagnostics} ->
        decoders()
        {:noop, diagnostics}
      {status, diagnostics} ->
        compile()
        decoders()
        {status, diagnostics}
    end)
  end

  def compile(files \\ files(), sql_files \\ [])
  def compile([path|rest], sql_files) do
    case {File.dir?(path), String.ends_with?(path, ".sql")} do
      {true, false} -> compile(rest, compile(files(path), sql_files))
      {false, true} -> compile(rest, [{path, do_compile(path)}|sql_files])
      {false, false} -> compile(rest, sql_files)
    end
  end
  def compile([], sql_files), do: sql_files

  def do_compile(path) do
    {:ok, context, tokens} = SQL.Lexer.lex(File.read!(path), path)
    {:ok, context, tokens} = SQL.Parser.parse(tokens, context)
    SQL.__inspect__(tokens, context, {nil, nil, 0, [file: Path.relative_to_cwd(path), line: 1]})
  end

  def files(path \\ File.cwd!) do
    for file <- File.ls!(path), do: Path.join(path, file)
  end

  def decoders() do
    :dets.open_file(:sql, [type: :set, ram_file: true])
    :dets.traverse(:sql, fn record ->
      case record do
        {module, t, mod, loc} ->
          path = Path.join(Mix.Project.compile_path(), "#{module}.beam")
          case Code.ensure_compiled(module) do
            {:module, _} -> :continue
            {:error, _} ->
              {:module, ^module, binary, _term} = Module.create(module, mod.build_decoder(t), loc)
              File.write!(path, binary)
          end
        _ -> :continue
      end
    end)
    :ok
  end
end
