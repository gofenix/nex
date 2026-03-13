defmodule RateLimitExample.Application do
  use Application

  def start(_type, _args) do
    # Configure rate limiting: 5 requests per 60 seconds
    Application.put_env(:nex_core, :rate_limit, max: 5, window: 60)

    # Add rate limiting plug to the pipeline
    Application.put_env(:nex_core, :plugs, [Nex.RateLimit.Plug])

    children = []
    Supervisor.start_link(children, strategy: :one_for_one, name: RateLimitExample.Supervisor)
  end
end
