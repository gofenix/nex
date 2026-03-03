defmodule AgentConsole.Channels.AgentSocket do
  @moduledoc """
  WebSocket channel for real-time agent interaction.
  """
  require Logger
  alias AgentConsole.SessionTracker
  alias Nex.Agent.Runner

  def init(socket, _opts) do
    {:ok, socket}
  end

  def handle_incoming(message, socket) do
    session_id = socket.assigns[:session_id]
    Logger.info("[AgentSocket] Message for session: #{session_id}")

    case Jason.decode(message) do
      {:ok, data} ->
        msg_type = Map.get(data, "type")
        handle_message(msg_type, data, session_id, socket)

      _ ->
        send(socket, {:text, Jason.encode!(%{"type" => "error", "message" => "Invalid message"})})
        {:ok, socket}
    end
  end

  defp handle_message("prompt", data, session_id, socket) do
    prompt = Map.get(data, "content")
    handle_prompt(session_id, prompt, socket)
  end

  defp handle_message("stop", _data, _session_id, socket) do
    send(socket, {:text, Jason.encode!(%{"type" => "stopped"})})
    {:ok, socket}
  end

  defp handle_message("reset", _data, session_id, socket) do
    handle_reset(session_id, socket)
  end

  defp handle_message(_type, _data, _session_id, socket) do
    send(
      socket,
      {:text, Jason.encode!(%{"type" => "error", "message" => "Unknown message type"})}
    )

    {:ok, socket}
  end

  defp handle_prompt(session_id, prompt, socket) do
    agent = SessionTracker.get_or_create(session_id)

    send(socket, {:text, Jason.encode!(%{"type" => "start"})})

    case Runner.run(agent.session, prompt,
           provider: agent.provider,
           model: agent.model,
           api_key: agent.api_key,
           cwd: agent.cwd,
           max_iterations: agent.max_iterations,
           channel: "console",
           chat_id: session_id
         ) do
      {:ok, result, session} ->
        Nex.Agent.SessionManager.save(session)
        updated_agent = %{agent | session: session}
        SessionTracker.update(session_id, updated_agent)

        send(
          socket,
          {:text,
           Jason.encode!(%{
             "type" => "message",
             "content" => result,
             "role" => "assistant"
           })}
        )

        {:ok, socket}

      {:error, reason, session} ->
        Nex.Agent.SessionManager.save(session)

        send(
          socket,
          {:text,
           Jason.encode!(%{
             "type" => "error",
             "error" => inspect(reason)
           })}
        )

        {:ok, socket}
    end
  end

  defp handle_reset(session_id, socket) do
    key = "console:#{session_id}"
    new_session = Nex.Agent.Session.new(key)
    Nex.Agent.SessionManager.save(new_session)

    agent = SessionTracker.get(session_id)

    if agent do
      SessionTracker.update(session_id, %{agent | session: new_session})
    end

    send(socket, {:text, Jason.encode!(%{"type" => "reset", "message" => "Session reset"})})
    {:ok, socket}
  end
end
