defmodule Nex.Agent.Application do
  @moduledoc """
  OTP Application for Nex Agent.
  """

  use Application

  def start(_type, _args) do
    children =
      case Process.whereis(Req.Finch) do
        nil ->
          [
            # Start Finch for HTTP requests
            {Finch, name: Req.Finch},
            # SystemPrompt cache
            Nex.Agent.SystemPrompt,
            # Session manager
            Nex.Agent.SessionManager,
            # Message bus
            Nex.Agent.MessageBus
          ]

        _pid ->
          [
            Nex.Agent.SystemPrompt,
            Nex.Agent.SessionManager,
            Nex.Agent.MessageBus
          ]
      end

    Supervisor.start_link(children, strategy: :one_for_one, name: Nex.Agent.Supervisor)
  end
end
