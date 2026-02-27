defmodule Nex.WebSocketCompleteTest do
  use ExUnit.Case, async: true

  describe "Nex.WebSocket full integration" do
    test "creating and using WebSocket handlers" do
      # Test that we can define and use a complete WebSocket handler
      defmodule CompleteWS do
        use Nex.WebSocket

        def initial_state(req) do
          %{path: req[:path] || "/", started_at: DateTime.utc_now()}
        end

        def handle_connect(state) do
          {:ok, Map.put(state, :connected, true)}
        end

        def handle_message("echo", state) do
          {:reply, "echo", state}
        end

        def handle_message("reply", state) do
          {:reply, "response", state}
        end

        def handle_message("ok", state) do
          {:ok, state}
        end

        def handle_message("stop", state) do
          {:stop, :normal, state}
        end

        def handle_message(msg, state) do
          {:reply, "got: #{msg}", state}
        end

        def handle_disconnect(state) do
          {:ok, Map.put(state, :connected, false)}
        end
      end

      # Test initial state
      state = CompleteWS.initial_state(%{path: "/ws/chat"})
      assert state.path == "/ws/chat"

      # Test connect
      {:ok, connected} = CompleteWS.handle_connect(state)
      assert connected.connected == true

      # Test various message types
      {:reply, "echo", _} = CompleteWS.handle_message("echo", connected)
      {:reply, "response", _} = CompleteWS.handle_message("reply", connected)
      {:ok, _} = CompleteWS.handle_message("ok", connected)
      {:stop, :normal, _} = CompleteWS.handle_message("stop", connected)

      # Test disconnect
      {:ok, disconnected} = CompleteWS.handle_disconnect(connected)
      assert disconnected.connected == false
    end

    test "using default callbacks" do
      # Test that default implementations work
      defmodule MinimalWS do
        use Nex.WebSocket
      end

      # Default initial_state returns empty map
      assert MinimalWS.initial_state(%{}) == %{}

      # Default handle_connect returns ok with state
      {:ok, state} = MinimalWS.handle_connect(%{test: true})
      assert state == %{test: true}

      # Default handle_disconnect returns ok
      {:ok, _} = MinimalWS.handle_disconnect(%{})
    end
  end
end
