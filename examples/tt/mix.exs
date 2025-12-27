defmodule Tt.MixProject do
  use Mix.Project

  def project do
    [
      app: :tt,
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
      mod: {Tt.Application, []}
    ]
  end
  defp deps do
    [      {:nex, path: "../../framework"}

    ]
  end
end
