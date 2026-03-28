defmodule Mix.Tasks.E2e.Examples do
  use Mix.Task

  @shortdoc "Run E2E coverage for all examples"

  @impl true
  def run(_args) do
    E2E.Runner.run_all!()
  end
end
