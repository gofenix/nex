defmodule DatastarDemo.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Bandit, plug: Nex.Handler, scheme: :http, port: 4000}
    ]

    opts = [strategy: :one_for_one, name: DatastarDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
