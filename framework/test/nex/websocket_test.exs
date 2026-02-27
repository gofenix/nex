defmodule Nex.WebSocketTest do
  use ExUnit.Case, async: true

  # Mock handlers for testing
  defmodule TestHandler do
    use Nex.WebSocket

    def handle_connect(state) do
      {:ok, Map.put(state, :connected, true)}
    end

    def handle_message("ping", state) do
      {:reply, "pong", state}
    end

    def handle_message(msg, state) do
      {:reply, "echo: " <> msg, state}
    end

    def handle_disconnect(state) do
      {:ok, Map.put(state, :disconnected, true)}
    end

    def initial_state(_req) do
      %{user_id: "test-user"}
    end
  end

  defmodule TestHandlerNoReply do
    use Nex.WebSocket

    def handle_message(_msg, state) do
      {:ok, state}
    end
  end

  defmodule TestHandlerStop do
    use Nex.WebSocket

    def handle_message("stop", state) do
      {:stop, :normal, state}
    end
  end

  defmodule TestHandlerStopConnect do
    use Nex.WebSocket
    def handle_connect(_state), do: {:stop, :normal, %{}}
    def handle_message(_msg, state), do: {:ok, state}
  end

  defmodule TestHandlerTerminate do
    use Nex.WebSocket

    def handle_disconnect(state) do
      send(self(), {:disconnect_called, state})
      {:ok, state}
    end

    def handle_message(_msg, state), do: {:ok, state}
  end

  describe "Nex.WebSocket module" do
    test "module loads correctly" do
      assert Code.ensure_loaded?(Nex.WebSocket)
    end

    test "has broadcast/2 function" do
      assert function_exported?(Nex.WebSocket, :broadcast, 2)
    end

    test "has subscribe/1 function" do
      assert function_exported?(Nex.WebSocket, :subscribe, 1)
    end

    test "__using__ macro defines default callbacks" do
      defmodule DefaultWS do
        use Nex.WebSocket
      end

      assert function_exported?(DefaultWS, :handle_connect, 1)
      assert function_exported?(DefaultWS, :handle_disconnect, 1)
      assert function_exported?(DefaultWS, :initial_state, 1)
    end

    test "__using__ macro allows overriding callbacks" do
      assert function_exported?(TestHandler, :handle_connect, 1)
      assert function_exported?(TestHandler, :handle_message, 2)
      assert function_exported?(TestHandler, :handle_disconnect, 1)
      assert function_exported?(TestHandler, :initial_state, 1)
    end
  end

  describe "Nex.WebSocket.Handler callback module" do
    test "module loads correctly" do
      assert Code.ensure_loaded?(Nex.WebSocket.Handler)
    end

    test "has callbacks defined" do
      callbacks = Nex.WebSocket.Handler.behaviour_info(:callbacks)
      assert is_list(callbacks)
      assert {:handle_connect, 1} in callbacks
    end

    test "defines all required callbacks" do
      callbacks = Nex.WebSocket.Handler.behaviour_info(:callbacks)
      assert {:handle_connect, 1} in callbacks
      assert {:handle_message, 2} in callbacks
      assert {:handle_disconnect, 1} in callbacks
      assert {:initial_state, 1} in callbacks
    end
  end

  describe "Nex.WebSocket.Adapter" do
    test "module loads correctly" do
      assert Code.ensure_loaded?(Nex.WebSocket.Adapter)
    end

    test "init/1 calls handle_connect and returns ok tuple" do
      result = Nex.WebSocket.Adapter.init({TestHandler, %{test: "state"}})

      assert {:ok, {TestHandler, %{connected: true, test: "state"}}} = result
    end

    test "init/1 with handle_connect returning stop" do
      result = Nex.WebSocket.Adapter.init({TestHandlerStopConnect, %{}})
      assert {:stop, :normal, %{}} = result
    end

    test "handle_in/2 with text opcode calls handle_message and returns reply" do
      state = {TestHandler, %{connected: true, user_id: "test-user"}}
      result = Nex.WebSocket.Adapter.handle_in({"hello", [opcode: :text]}, state)

      assert {:reply, :ok, {:text, "echo: hello"}, {TestHandler, _new_state}} = result
    end

    test "handle_in/2 with ping returns pong" do
      state = {TestHandler, %{connected: true}}
      result = Nex.WebSocket.Adapter.handle_in({"ping", [opcode: :text]}, state)

      assert {:reply, :ok, {:text, "pong"}, {TestHandler, _new_state}} = result
    end

    test "handle_in/2 with no reply returns ok without reply" do
      state = {TestHandlerNoReply, %{}}
      result = Nex.WebSocket.Adapter.handle_in({"test", [opcode: :text]}, state)

      assert {:ok, {TestHandlerNoReply, _new_state}} = result
    end

    test "handle_in/2 with stop returns stop" do
      state = {TestHandlerStop, %{}}
      result = Nex.WebSocket.Adapter.handle_in({"stop", [opcode: :text]}, state)

      assert {:stop, :normal, {TestHandlerStop, _new_state}} = result
    end

    test "handle_in/2 with non-text opcode returns ok" do
      state = {TestHandler, %{}}
      result = Nex.WebSocket.Adapter.handle_in({"binary", [opcode: :binary]}, state)

      assert {:ok, _state} = result
    end

    test "handle_info/2 with ws_broadcast sends message to client" do
      state = {TestHandler, %{}}
      result = Nex.WebSocket.Adapter.handle_info({:ws_broadcast, "broadcast message"}, state)

      assert {:reply, :ok, {:text, "broadcast message"}, {TestHandler, _}} = result
    end

    test "handle_info/2 with other message returns ok" do
      state = {TestHandler, %{}}
      result = Nex.WebSocket.Adapter.handle_info(:some_other_message, state)

      assert {:ok, _state} = result
    end

    test "handle_info/2 with tuple message returns ok" do
      state = {TestHandler, %{}}
      result = Nex.WebSocket.Adapter.handle_info({:timeout}, state)

      assert {:ok, _state} = result
    end

    test "terminate/2 calls handle_disconnect" do
      state = {TestHandlerTerminate, %{test: true}}
      result = Nex.WebSocket.Adapter.terminate(:normal, state)

      assert :ok = result
      assert_received {:disconnect_called, %{test: true}}
    end

    test "terminate/2 handles different reasons" do
      state = {TestHandler, %{}}

      # Normal termination
      assert :ok = Nex.WebSocket.Adapter.terminate(:normal, state)

      # Error termination
      assert :ok = Nex.WebSocket.Adapter.terminate({:error, :closed}, state)
    end
  end
end
