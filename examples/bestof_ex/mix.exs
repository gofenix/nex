defmodule BestofEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :bestof_ex,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  def application do
    base = [extra_applications: [:logger]]

    if Mix.env() == :test do
      base
    else
      Keyword.put(base, :mod, {BestofEx.Application, []})
    end
  end

  defp deps do
    [
      {:nex_core, path: "../../framework"},
      {:nex_base, path: "../../nex_base"},
      {:req, "~> 0.5"},
      {:ecto_sqlite3, "~> 0.17"},
      {:nex_examples_test_support, path: "../test_support", only: :test, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["src", "test/support"]
  defp elixirc_paths(_env), do: ["src"]
end
