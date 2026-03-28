defmodule NexExamplesE2E.MixProject do
  use Mix.Project

  def project do
    [
      app: :nex_examples_e2e,
      version: "0.1.0",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:crypto, :inets, :logger, :ssl]
    ]
  end

  defp deps do
    [
      {:floki, "~> 0.37"},
      {:jason, "~> 1.4"},
      {:mint, "~> 1.7"},
      {:req, "~> 0.5.15"},
      {:websockex, "~> 0.4.3"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
