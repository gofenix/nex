defmodule NexValidatorExample.Application do
  use Application

  def start(_type, _args) do
    # No supervision tree required for this static example.
    children = []
    opts = [strategy: :one_for_one, name: NexValidatorExample.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
