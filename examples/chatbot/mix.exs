defmodule Chatbot.MixProject do
  use Mix.Project

  def project do
    [
      app: :chatbot,
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
      mod: {Chatbot.Application, []}
    ]
  end

  defp deps do
    [
      {:nex_core, path: "../../framework"},
      {:req, "~> 0.5"}  # Elixir HTTP client (includes Finch)
    ]
  end
end
