# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.MixProject do
  use Mix.Project

  @version "0.6.0-dev"

  def project do
    [
      app: :sql,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "SQL provides state-of-the-art, high-performance SQL integration for Elixir, built to handle extreme concurrency with unmatched expressiveness and ergonomic query composition. Write safe, composable, parameterized queries directly, without translating to Ecto or any ORM.",
      name: "SQL",
      docs: docs(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: [test: ["sql.create --quiet", "test"]]
    ]
  end

  def application do
    [
      mod: {SQL.Application, []}
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
      {:ex_doc, "~> 0.40.3", only: :dev},
      {:yamerl, ">= 0.0.0", only: [:dev, :test]},
      {:unicode_set, "~> 1.7"}
    ]
  end
end
