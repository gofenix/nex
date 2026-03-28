defmodule RatelimitExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :ratelimit_example,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {RatelimitExample.Application, []}
    ]
  end

  defp deps do
    [
      {:nex_core, path: "../../framework"},
      {:nex_examples_test_support, path: "../test_support", only: :test, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["src", "test/support"]
  defp elixirc_paths(_env), do: ["src"]
end
