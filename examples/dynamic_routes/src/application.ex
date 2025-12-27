defmodule DynamicRoutes.Application do
  @moduledoc """
  The DynamicRoutes application.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Add supervised processes here
    ]

    opts = [strategy: :one_for_one, name: DynamicRoutes.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
