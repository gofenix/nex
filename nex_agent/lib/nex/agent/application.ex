defmodule Nex.Agent.Application do
  @moduledoc """
  OTP Application for Nex Agent.

  Supervision tree (:rest_for_one):

      Application Supervisor
      ├── Finch (HTTP client)
      ├── SystemPrompt (cache)
      ├── SessionManager
      ├── MessageBus
      ├── TaskSupervisor (for fire-and-forget tasks)
      ├── InfrastructureSupervisor (:one_for_one)
      │   ├── Bus
      │   ├── Tool.Registry
      │   ├── Memory.Index
      │   ├── Cron
      │   └── Heartbeat
      ├── WorkerSupervisor (:one_for_one)
      │   ├── InboundWorker
      │   ├── Subagent
      │   └── Harness
      ├── ChannelSupervisor (DynamicSupervisor)
      └── Gateway (channel orchestrator)

  :rest_for_one ensures that if InfrastructureSupervisor restarts (e.g. Bus dies),
  downstream WorkerSupervisor/ChannelSupervisor/Gateway also restart so workers
  can re-subscribe to the Bus.
  """

  use Application

  def start(_type, _args) do
    children =
      maybe_finch() ++
        [
          Nex.Agent.SystemPrompt,
          Nex.Agent.SessionManager,
          Nex.Agent.MessageBus,
          {Task.Supervisor, name: Nex.Agent.TaskSupervisor},
          Nex.Agent.InfrastructureSupervisor,
          Nex.Agent.WorkerSupervisor,
          {DynamicSupervisor, name: Nex.Agent.ChannelSupervisor, strategy: :one_for_one},
          Nex.Agent.Gateway
        ]

    Supervisor.start_link(children, strategy: :rest_for_one, name: Nex.Agent.Supervisor)
  end

  defp maybe_finch do
    case Process.whereis(Req.Finch) do
      nil -> [{Finch, name: Req.Finch}]
      _pid -> []
    end
  end
end
