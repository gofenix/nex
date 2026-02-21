defmodule AuthDemo.Application do
  use Application

  @impl true
  def start(_type, _args) do
    # Register auth middleware before starting
    Application.put_env(:nex_core, :plugs, [
      AuthDemo.Plugs.RequireAuth
    ])

    children = []
    opts = [strategy: :one_for_one, name: AuthDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
