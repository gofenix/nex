defmodule FileUpload.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Add supervised processes here
    ]

    opts = [strategy: :one_for_one, name: FileUpload.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
