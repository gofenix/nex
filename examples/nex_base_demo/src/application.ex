defmodule NexBaseDemo.Application do
  use Application

  @impl true
  def start(_type, _args) do
    Nex.Env.init()
    NexBase.init(url: Nex.Env.get(:database_url), ssl: true)

    children = [{NexBase.Repo, []}]
    Supervisor.start_link(children, strategy: :one_for_one, name: NexBaseDemo.Supervisor)
  end
end
