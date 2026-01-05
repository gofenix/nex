defmodule NexAIDemo.MixProject do
  use Mix.Project

  def project do
    [
      app: :nex_ai_demo,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: ["src"],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:nex_core, path: "../../framework"},
      {:nex_ai, path: "../../nex_ai"},
      {:req, "~> 0.5"},
      {:dotenvy, "~> 0.9"}
    ]
  end
end
