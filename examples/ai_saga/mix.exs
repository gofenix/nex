defmodule AiSaga.MixProject do
  use Mix.Project

  def project do
    [
      app: :ai_saga,
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
      Keyword.put(base, :mod, {AiSaga.Application, []})
    end
  end

  defp deps do
    [
      {:nex_core, path: "../../framework"},
      {:nex_base, path: "../../nex_base"},
      {:nex_env, path: "../../nex_env"},
      {:jason, "~> 1.4"},
      {:req, "~> 0.5"},
      {:ecto_sqlite3, "~> 0.17"},
      {:earmark, "~> 1.4"},
      {:openai, "~> 0.6"},
      {:nex_examples_test_support, path: "../test_support", only: :test, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["src", "lib", "test/support"]
  defp elixirc_paths(_env), do: ["src", "lib"]
end
