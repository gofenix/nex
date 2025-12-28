defmodule NexWebsite.MixProject do
  use Mix.Project

  def project do
    [
      app: :nex_website,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: ["src"],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {NexWebsite.Application, []}
    ]
  end

  defp deps do
    [
      {:nex_core, "~> 0.1.6"}
    ]
  end
end
