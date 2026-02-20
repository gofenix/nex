defmodule Nex.WebSocket do
  @moduledoc """
  User-level WebSocket support for Nex applications.

  Provides bidirectional real-time communication via WebSocket connections.
  Built on top of `WebSockAdapter` (already a framework dependency).

  ## Usage

  Define a WebSocket handler in `src/api/` using `Nex.WebSocket`:

      defmodule MyApp.Api.Chat do
        use Nex.WebSocket

        def handle_connect(state) do
          {:ok, state}
        end

        def handle_message("ping", state) do
          {:reply, "pong", state}
        end

        def handle_message(msg, state) do
          {:reply, "echo: " <> msg, state}
        end

        def handle_disconnect(state) do
          {:ok, state}
        end
      end

  The module is automatically routed to `/ws/chat` (mirrors the API path convention).
  Connect from the browser:

      const ws = new WebSocket("ws://localhost:4000/ws/chat");
      ws.onmessage = (e) => console.log(e.data);
      ws.send("ping");

  ## Callbacks

    * `handle_connect/1` — called when a client connects. Return `{:ok, state}`.
    * `handle_message/2` — called for each incoming message. Return:
      - `{:reply, message, state}` — send a message back to the client
      - `{:ok, state}` — no reply
      - `{:stop, reason, state}` — close the connection
    * `handle_disconnect/1` — called when the client disconnects. Return `{:ok, state}`.

  ## Initial State

  Override `initial_state/1` to set per-connection state from the request:

      def initial_state(req) do
        %{user_id: Nex.Session.get(:user_id), joined_at: DateTime.utc_now()}
      end

  ## Broadcasting

  Use `Nex.WebSocket.broadcast/2` to send messages to all connected clients
  on a named topic (requires Phoenix.PubSub, already a framework dependency):

      Nex.WebSocket.broadcast("chat", "New message!")

  Subscribe in `handle_connect/1`:

      def handle_connect(state) do
        Nex.WebSocket.subscribe("chat")
        {:ok, state}
      end
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Nex.WebSocket.Handler

      def handle_connect(state), do: {:ok, state}
      def handle_disconnect(state), do: {:ok, state}
      def initial_state(_req), do: %{}

      defoverridable handle_connect: 1, handle_disconnect: 1, initial_state: 1
    end
  end

  @doc """
  Broadcasts a message to all subscribers on the given topic.
  """
  def broadcast(topic, message) do
    Phoenix.PubSub.broadcast(Nex.PubSub, "ws:#{topic}", {:ws_broadcast, message})
  end

  @doc """
  Subscribes the current WebSocket process to a topic.
  Call from within `handle_connect/1`.
  """
  def subscribe(topic) do
    Phoenix.PubSub.subscribe(Nex.PubSub, "ws:#{topic}")
  end
end

defmodule Nex.WebSocket.Handler do
  @moduledoc false

  @callback handle_connect(state :: map()) :: {:ok, map()}
  @callback handle_message(message :: String.t(), state :: map()) ::
              {:reply, String.t(), map()} | {:ok, map()} | {:stop, term(), map()}
  @callback handle_disconnect(state :: map()) :: {:ok, map()}
  @callback initial_state(req :: map()) :: map()
end

defmodule Nex.WebSocket.Adapter do
  @moduledoc false
  # WebSock behaviour implementation that bridges to user-defined handler modules.

  @behaviour WebSock

  @impl WebSock
  def init({handler_module, initial_state}) do
    case handler_module.handle_connect(initial_state) do
      {:ok, state} -> {:ok, {handler_module, state}}
      other -> other
    end
  end

  @impl WebSock
  def handle_in({text, [opcode: :text]}, {handler_module, state}) do
    case handler_module.handle_message(text, state) do
      {:reply, reply, new_state} ->
        {:reply, :ok, {:text, reply}, {handler_module, new_state}}

      {:ok, new_state} ->
        {:ok, {handler_module, new_state}}

      {:stop, reason, new_state} ->
        {:stop, reason, {handler_module, new_state}}
    end
  end

  def handle_in({_data, _opts}, state), do: {:ok, state}

  @impl WebSock
  def handle_info({:ws_broadcast, message}, {handler_module, state}) do
    {:reply, :ok, {:text, message}, {handler_module, state}}
  end

  def handle_info(_msg, state), do: {:ok, state}

  @impl WebSock
  def terminate(_reason, {handler_module, state}) do
    handler_module.handle_disconnect(state)
    :ok
  end
end
