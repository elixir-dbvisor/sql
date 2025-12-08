# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.MixProject do
  use Mix.Project

  @version "0.5.0"

  def project do
    [
      app: :sql,
      version: @version,
      elixir: "~> 1.19",
      deps: deps(),
      description: "Brings an extensible SQL parser and sigil to Elixir, confidently write SQL with automatic parameterized queries.",
      name: "SQL",
      docs: docs(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: ["sql.bench": "run benchmarks/bench.exs"]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_), do: ["lib"]

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
      {:benchee, "~> 1.3", only: :dev},
      {:ecto_sql, "~> 3.12", only: :dev},
      {:ex_doc, "~> 0.37", only: :dev},
      {:postgrex, ">= 0.0.0", only: :dev},
      {:tds, ">= 0.0.0", only: :dev},
      {:myxql, ">= 0.0.0", only: :dev},
      {:yamerl, ">= 0.0.0", only: :dev},
      {:unicode_set, "~> 1.0"}
    ]
  end
end
