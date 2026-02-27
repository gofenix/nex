defmodule NexEnv.MixProject do
  use Mix.Project

  def project do
    [
      app: :nex_env,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Environment variable management for Nex projects",
      package: package(),
      test_coverage: [summary: [threshold: 0]]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:dotenvy, "~> 0.9"},
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
end
