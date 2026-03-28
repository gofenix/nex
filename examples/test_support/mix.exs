defmodule NexExamplesTestSupport.MixProject do
  use Mix.Project

  def project do
    [
      app: :nex_examples_test_support,
      version: "0.1.0",
      elixir: "~> 1.14",
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
end
