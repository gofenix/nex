defmodule NexNew.MixProject do
  use Mix.Project

  @version File.read!("../VERSION") |> String.trim()

  def project do
    [
      app: :nex_new,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Nex project generator"
    ]
  end

  def application do
    [extra_applications: [:eex]]
  end

  defp deps do
    []
  end
end
