defmodule AgentConsole.WebSocketHandler do
  @moduledoc """
  WebSocket handler for real-time agent communication.
  Uses Bandit WebSocket API.
  """
  require Logger

  def init(conn) do
    # Get session_id from query params
    session_id =
      case Plug.Conn.fetch_query_params(conn) do
        %{query_params: %{"session_id" => id}} -> id
        _ -> "main"
      end

    state = %{session_id: session_id}

    Logger.info("[WebSocket] Init: #{session_id}")
    {:ok, state}
  end

  def handle_in({:text, message}, state) do
    Logger.debug("[WebSocket] Received: #{message}")

    case AgentConsole.Channels.AgentSocket.handle_incoming(message, %{
           assigns: %{session_id: state.session_id}
         }) do
      {:ok, _socket} ->
        {:ok, state}

      _ ->
        {:ok, state}
    end
  end

  def handle_in(_message, state) do
    {:ok, state}
  end

  def handle_info({:text, json}, state) do
    {:reply, {:text, json}, state}
  end

  def handle_info(_info, state) do
    {:ok, state}
  end

  def terminate(_reason, state) do
    Logger.info("[WebSocket] Terminated: #{state.session_id}")
    :ok
  end
end
