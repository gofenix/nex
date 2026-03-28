defmodule E2E.WebSocketClient do
  use WebSockex

  def start_link(url, caller) do
    WebSockex.start_link(url, __MODULE__, %{caller: caller})
  end

  def send_text(pid, text) do
    WebSockex.send_frame(pid, {:text, text})
  end

  def close(pid) do
    WebSockex.cast(pid, :close)
  end

  @impl true
  def handle_connect(_conn, state) do
    send(state.caller, {:ws_connected, self()})
    {:ok, state}
  end

  @impl true
  def handle_frame({:text, payload}, state) do
    send(state.caller, {:ws_text, payload})
    {:ok, state}
  end

  @impl true
  def handle_disconnect(reason, state) do
    send(state.caller, {:ws_disconnected, reason})
    {:ok, state}
  end

  @impl true
  def handle_cast(:close, state) do
    {:close, state}
  end
end
