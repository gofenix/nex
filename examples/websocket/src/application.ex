defmodule NexWsExample.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Nex.WebSocket, [handler: NexWsExample.Chat]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: NexWsExample.Supervisor)
  end
end
