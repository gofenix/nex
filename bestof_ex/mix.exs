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
      {:nex_core, "~> 0.3.3"},
      {:nex_base, "~> 0.3.2"},
      {:ecto_sqlite3, "~> 0.17"},
      {:req, "~> 0.5"}
    ]
  end
end
