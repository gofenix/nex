defmodule AgentConsole.Application do
  use Application

  def start(_type, _args) do
    Nex.Env.init()

    # Initialize Agent services
    :ok = Nex.Agent.Onboarding.ensure_initialized()
    :ok = Nex.Agent.Skills.load()

    children = [
      Nex.Agent.SessionManager,
      AgentConsole.SessionTracker
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: AgentConsole.Supervisor)
  end
end
