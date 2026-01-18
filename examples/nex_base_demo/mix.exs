defmodule NexBaseDemo.MixProject do
  use Mix.Project

  def project do
    [
      app: :nex_base_demo,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: ["src"],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {NexBaseDemo.Application, []}
    ]
  end

  defp deps do
    [
      {:nex_core, path: "../../framework"},
      {:nex_base, path: "../../nex_base"},
      {:dotenvy, "~> 0.9"}
    ]
  end
end
