defmodule AgentConsole.MixProject do
  use Mix.Project

  def project do
    [
      app: :agent_console,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {AgentConsole.Application, []}
    ]
  end

  defp deps do
    [
      {:nex_core, path: "../../framework"},
      {:nex_base, path: "../../nex_base"},
      {:nex_env, path: "../../nex_env"},
      {:jason, "~> 1.4"},
      {:req, "~> 0.5"},
      {:nex_examples_test_support, path: "../test_support", only: :test, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["src", "lib", "test/support"]
  defp elixirc_paths(_env), do: ["src", "lib"]
end
