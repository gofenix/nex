defmodule AiSaga.Application do
  use Application

  @impl true
  def start(_type, _args) do
    Nex.Env.init()
    conn = NexBase.init(url: Nex.Env.get(:database_url))

    children = [
      {NexBase.Repo, conn}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: AiSaga.Supervisor)
  end
end
