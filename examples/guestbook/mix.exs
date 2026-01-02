defmodule Guestbook.MixProject do
  use Mix.Project

  def project do
    [
      app: :guestbook,
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
      mod: {Guestbook.Application, []}
    ]
  end

  defp deps do
    [
      {:nex_core, path: "../../framework"}
    ]
  end
end
