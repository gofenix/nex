defmodule AgentDemo.MixProject do
  use Mix.Project

  def project do
    [
      app: :agent_demo,
      version: "0.1.0",
      elixir: "~> 1.18",
      deps: deps()
    ]
  end

  defp deps do
    [
      {:nex_agent, path: "../../nex_agent"},
      {:nex_core, path: "../../framework"}
      {:nex_core, "~> 0.3.9"}
    ]
  end
end
