defmodule NexWebsocketExample.Api.Chat do
  @moduledoc """
  WebSocket chat handler demonstrating Nex.WebSocket features.
  """

  use Nex.WebSocket

  @impl true
  def initial_state(req) do
    query = req[:query] || %{}

    %{
      username: query["username"] || "Anonymous",
      room: query["room"] || "lobby"
    }
  end

  @impl true
  def handle_connect(state) do
    # Subscribe to room topic
    Nex.WebSocket.subscribe(state.room)

    # Broadcast join message
    broadcast(state.room, "System", "#{state.username} joined #{state.room}")

    {:ok, state}
  end

  @impl true
  def handle_message(text, state) do
    # Broadcast message to all users in the room
    broadcast(state.room, state.username, text)
    {:ok, state}
  end

  @impl true
  def handle_disconnect(state) do
    broadcast(state.room, "System", "#{state.username} left #{state.room}")
    :ok
  end

  defp broadcast(room, user, text) do
    Nex.WebSocket.broadcast(
      room,
      Jason.encode!(%{
        user: user,
        text: text,
        timestamp: :os.system_time(:millisecond)
      })
    )
  end
end
