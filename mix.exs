# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :sql,
      version: @version,
      elixir: "~> 1.18",
      deps: deps(),
      description: "Bring's an extensiable SQL parser and sigil to Elixir, confidently write SQL with automatic parameterized queries.",
      name: "SQL",
      docs: docs(),
      package: package()
    ]
  end

  defp package do
    %{
      licenses: ["Apache-2.0"],
      maintainers: ["Benjamin Schultzer"],
      links: %{"GitHub" => "https://github.com/elixir-dbvisor/sql"}
    }
  end

  defp docs do
      [
        main: "readme",
        api_reference: false,
        source_ref: "v#{@version}",
        canonical: "https://hexdocs.pm/sql",
        extras: ["CHANGELOG.md", "README.md", "LICENSE"]
      ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.37", only: :dev},
      {:ecto_sql, "~> 3.12", only: [:dev, :test]},
      {:postgrex, ">= 0.0.0", only: [:dev, :test]},
    ]
  end
end
