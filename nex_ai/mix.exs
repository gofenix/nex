defmodule NexAI.MixProject do
  use Mix.Project

  def project do
    [
      app: :nex_ai,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {NexAI.Application, []}
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:req, "~> 0.5"},
      {:multipart, "~> 0.4.0"}
    ]
  end
end
