defmodule NexAI.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    NexAI.Supervisor.start_link(name: NexAI.Supervisor)
  end
end
