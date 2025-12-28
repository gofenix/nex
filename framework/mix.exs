defmodule Nex.MixProject do
  use Mix.Project

  def project do
    [
      app: :nex_core,
      version: "0.2.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "A minimalist Elixir web framework powered by HTMX",
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:bandit, "~> 1.9"},
      {:plug, "~> 1.19"},
      {:phoenix_html, "~> 4.3"},
      {:phoenix_live_view, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:dotenvy, "~> 0.9"},
      {:file_system, "~> 1.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["fenix"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/gofenix/nex"},
      files: ~w(lib mix.exs README.md CHANGELOG.md VERSION)
    ]
  end
end
