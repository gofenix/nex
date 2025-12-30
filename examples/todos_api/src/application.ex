defmodule TodosApi.Application do
  @moduledoc """
  The TodosApi application.

  This module demonstrates the architecture where:
  - HTMX sends HTTP requests to API endpoints
  - API modules handle business logic
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch, name: TodosApi.Finch},
      {Task.Supervisor, name: TodosApi.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: TodosApi.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
