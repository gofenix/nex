defmodule ShoppingCart.MixProject do
  use Mix.Project

  def project do
    [
      app: :shopping_cart,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: ["src"],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ShoppingCart.Application, []}
    ]
  end

  defp deps do
    [
      {:nex_core, path: "../../framework"}
    ]
  end
end
