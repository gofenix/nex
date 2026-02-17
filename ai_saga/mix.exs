defmodule AiSaga.MixProject do
  use Mix.Project

  def project do
    [
      app: :ai_saga,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: ["src", "lib"],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {AiSaga.Application, []}
    ]
  end

  defp deps do
    [
      {:nex_core, "~> 0.3.3"},
      {:nex_base, "~> 0.3.2"},
      {:jason, "~> 1.4"},
      {:req, "~> 0.5"},
      {:earmark, "~> 1.4"},
      {:openai, "~> 0.6"}
    ]
  end
end
