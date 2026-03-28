defmodule Mix.Tasks.E2e.Example do
  use Mix.Task

  @shortdoc "Run E2E coverage for one example"

  @impl true
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [name: :string])

    case opts[:name] do
      nil ->
        Mix.raise("Usage: mix e2e.example --name <example>")

      name ->
        E2E.Runner.run_example!(name)
    end
  end
end
