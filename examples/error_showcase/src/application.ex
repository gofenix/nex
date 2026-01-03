defmodule ErrorShowcase.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Add supervised processes here
    ]

    opts = [strategy: :one_for_one, name: ErrorShowcase.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
