defmodule BestofEx.Application do
  @moduledoc """
  The BestofEx application.
  """

  use Application

  @impl true
  def start(_type, _args) do
    Nex.Env.init()
    NexBase.init(url: Nex.Env.get(:database_url))

    children = [
      {NexBase.Repo, []},
      {BestofEx.Scheduler, []}
    ]
    Supervisor.start_link(children, strategy: :one_for_one, name: BestofEx.Supervisor)
  end
end
