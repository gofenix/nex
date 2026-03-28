defmodule NexValidatorExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :nex_validator_example,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Nex.Validator example app for Nex 0.4",
      package: [maintainers: ["ByteDance"], licenses: ["MIT"]]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {NexValidatorExample.Application, []}
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
