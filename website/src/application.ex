defmodule NexWebsite.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    # Website-specific application processes (if any)
    children = []

    opts = [strategy: :one_for_one, name: NexWebsite.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
