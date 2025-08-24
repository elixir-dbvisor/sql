# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.MixProject do
  use Mix.Project

  @version "0.4.0"

  def project do
    [
      app: :sql,
      version: @version,
      elixir: "~> 1.18",
      deps: deps(),
      description: "Brings an extensible SQL parser and sigil to Elixir, confidently write SQL with automatic parameterized queries.",
      name: "SQL",
      docs: docs(),
      package: package(),
      aliases: ["sql.bench": "run bench.exs"]
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
      {:benchee, "~> 1.3", only: :dev},
      {:ecto_sql, "~> 3.12", only: [:dev, :test]},
      {:ex_doc, "~> 0.37", only: :dev},
      {:postgrex, ">= 0.0.0", only: [:dev, :test]},
      {:tds, ">= 0.0.0", only: [:dev, :test]},
      {:myxql, ">= 0.0.0", only: [:dev, :test]},
      {:yamerl, ">= 0.0.0", only: [:dev, :test]},
      {:unicode_set, "~> 1.0"}
    ]
  end
end
