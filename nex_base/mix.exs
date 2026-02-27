defmodule NexBase.MixProject do
  use Mix.Project

  def project do
    [
      app: :nex_base,
      version: "0.3.4",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "A fluent, Supabase-inspired database query builder for Elixir.",
      package: package(),
      docs: docs(),
      test_coverage: [summary: [threshold: 0]]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.10"},
      {:postgrex, "~> 0.19"},
      {:ecto_sqlite3, "~> 0.17", optional: true},
      {:jason, "~> 1.4"},
      {:mox, "~> 1.1", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["fenix"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/gofenix/nex"},
      files: ~w(lib mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [main: "readme", extras: ["README.md"]]
  end
end
