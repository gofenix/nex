defmodule AlpineShowcase.MixProject do
  use Mix.Project

  def project do
    [
      app: :alpine_showcase,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: ["src"],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {AlpineShowcase.Application, []}
    ]
  end

  defp deps do
    [
      {:nex_core, path: "../../framework"},
      {:jason, "~> 1.2"}
      {:jason, "~> 1.2"}
    ]
  end
end
