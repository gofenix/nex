defmodule ChatbotSse.Application do
  @moduledoc """
  The ChatbotSse application.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch, name: MyFinch},
      {Task.Supervisor, name: ChatbotSse.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: ChatbotSse.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
