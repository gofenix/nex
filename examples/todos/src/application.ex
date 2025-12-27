defmodule Todos.Application do
  @moduledoc """
  The Todos application.

  This module defines the application supervision tree.
  Add any supervised processes (like database connections, HTTP clients, etc.) here.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Add supervised processes here
      # Example: {MyWorker, arg}
    ]

    opts = [strategy: :one_for_one, name: Todos.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
