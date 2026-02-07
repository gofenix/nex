defmodule BestofEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :bestof_ex,
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
      mod: {BestofEx.Application, []}
    ]
  end

  defp deps do
    [
      {:nex_core, path: "../../framework"},
      {:nex_base, "~> 0.1.1"}
    ]
  end
end
