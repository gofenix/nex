defmodule NexValidatorExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :nex_validator_example,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: ["src"],
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
      {:nex_core, path: "../../framework"}
    ]
  end
end
