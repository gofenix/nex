defmodule NexAI.Supervisor do
  @moduledoc "Supervision tree for NexAI."
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {Task.Supervisor, name: NexAI.TaskSupervisor}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
