defmodule NexNew.MixProject do
  use Mix.Project

  def project do
    [
      app: :nex_new,
      version: "0.2.2",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Nex project generator",
      package: package()
    ]
  end

  def application do
    [extra_applications: [:eex]]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["fenix"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/gofenix/nex"},
      files: ~w(lib mix.exs README.md VERSION)
    ]
  end
end
