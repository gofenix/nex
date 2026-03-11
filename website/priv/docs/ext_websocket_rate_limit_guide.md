# WebSockets & Rate Limiting

Nex provides built-in support for WebSockets and Rate Limiting to help you build real-time, resilient applications.

## WebSockets (Nex.WebSocket)

Nex supports user-level WebSockets via the `Nex.WebSocket` module. You can define a WebSocket handler in `src/api/` and it will automatically be mounted at `/ws/*`.

### Defining a Handler

Create a file like `src/api/chat.ex`:

```elixir
defmodule MyApp.Api.Chat do
  use Nex.WebSocket

  # Optional: Initial state when connection is upgraded
  def initial_state(req) do
    %{user_id: req.cookies["user_id"] || "anonymous"}
  end

  # Called when a client connects
  def handle_connect(state) do
    # Subscribe to a pubsub topic
    Nex.WebSocket.subscribe("chat_room:general")
    {:ok, state}
  end

  # Called when a message is received from the client
  def handle_message({:text, message}, state) do
    # Broadcast to all subscribers
    Nex.WebSocket.broadcast("chat_room:general", {:text, "\#{state.user_id}: \#{message}"})
    {:ok, state}
  end

  # Called when the client disconnects
  def handle_disconnect(_state) do
    :ok
  end
end
```

### Client-Side Connection

Connect from the browser:

```javascript
const ws = new WebSocket("ws://localhost:4000/ws/chat");
ws.onmessage = (event) => console.log("Received:", event.data);
ws.send("Hello world!");
```

## Rate Limiting (Nex.RateLimit)

Nex includes an ETS-based sliding window rate limiter to protect your endpoints.

### Configuration

In your `application.ex` or `config/config.exs`:

```elixir
Application.put_env(:nex_core, :rate_limit, max: 100, window: 60)
# Allows 100 requests per 60 seconds per IP
```

### Using Rate Limiting as Middleware

The easiest way to use the rate limiter is by adding `Nex.RateLimit.Plug` to your middleware pipeline:

```elixir
Application.put_env(:nex_core, :plugs, [
  Nex.RateLimit.Plug,
  MyApp.Plugs.Auth
])
```

When the limit is exceeded, the plug automatically halts the request and returns an HTTP 429 status with `X-RateLimit-Limit` and `X-RateLimit-Remaining` headers.

### Manual Rate Limiting

You can also use the rate limiter manually in your actions or APIs:

```elixir
def login(req) do
  client_ip = req.remote_ip |> :inet.ntoa() |> to_string()
  
  # Allow 5 login attempts per 15 minutes per IP
  case Nex.RateLimit.check({:login_attempt, client_ip}, max: 5, window: 900) do
    :ok ->
      # Process login
      
    {:error, :rate_limited} ->
      Nex.Flash.put(:error, "Too many login attempts. Please try again later.")
      {:redirect, "/login"}
  end
end
```
