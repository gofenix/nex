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
      {:nex_core, path: "../../framework"},
      {:nex_base, path: "../../nex_base"},
      {:nex_env, path: "../../nex_env"},
      {:jason, "~> 1.4"},
      {:req, "~> 0.5"},
      {:earmark, "~> 1.4"},
      {:openai, "~> 0.6"}
    ]
  end
end
