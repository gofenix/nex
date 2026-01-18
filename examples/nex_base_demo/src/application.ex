defmodule NexBaseDemo.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      NexBaseDemo.Repo
    ]

    opts = [strategy: :one_for_one, name: NexBaseDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
