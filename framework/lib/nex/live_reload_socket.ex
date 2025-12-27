defmodule Nex.LiveReloadSocket do
  @moduledoc """
  WebSocket handler for live reload functionality.
  Uses Phoenix.PubSub to receive file change notifications.
  """

  @behaviour WebSock

  require Logger

  @impl true
  def init(_opts) do
    # Subscribe to live reload events
    Phoenix.PubSub.subscribe(Nex.PubSub, "live_reload")
    {:ok, %{}}
  end

  @impl true
  def handle_in({_msg, _opts}, state) do
    # Ignore incoming messages from client
    {:ok, state}
  end

  @impl true
  def handle_info({:reload, _path}, state) do
    # Send reload message to client
    msg = Jason.encode!(%{reload: true})
    {:push, {:text, msg}, state}
  end

  def handle_info(_msg, state) do
    {:ok, state}
  end

  @impl true
  def terminate(_reason, _state) do
    :ok
  end
end
