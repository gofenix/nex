# SSE Real-Time Push (Server-Sent Events)

Nex includes native support for Server-Sent Events (SSE), allowing the server to push real-time updates to the browser. This is extremely useful for building chat applications, notification systems, or real-time monitoring dashboards.

## 1. Core Concepts

SSE is a unidirectional push protocol. Compared to WebSockets, it's more lightweight, firewall-friendly, and used with almost zero conversion in Nex.

*   **Action Mode**: Via the `hx-ext="sse"` plugin or by returning `{:stream, fun}` directly in an Action.
*   **Zero-Conversion Push**: You can push strings, Maps, Lists, or even HEEx fragments, and Nex automatically handles serialization.

## 2. Using SSE in an Action

The easiest way is to return a stream in an Action function.

### Example: Real-Time Chatbot

```elixir
def chat(%{"message" => msg}) do
  {:stream, fn send_fn ->
    # Push typing indicator
    send_fn.("Bot is thinking...")
    
    # Simulate processing delay
    Process.sleep(1000)
    
    # Push final reply
    send_fn.(~H"<div class='p-2 bg-blue-100 rounded'>This is a reply to #{msg}</div>")
  end}
end
```

## 3. SSE Module Protocol

Nex supports automatic conversion of Maps or Maps with an `event` key to the standard SSE protocol:

```elixir
send_fn.(%{event: "update", data: "New message content"})
```

HTMX on the browser side will automatically handle the update based on the event name:
```html
<div hx-ext="sse" sse-connect="/api/chat_stream" sse-swap="update">
  Content will update here...
</div>
```

## 4. Advantages and Limitations

*   **Advantages**:
    *   **Extremely Simple**: No need to manage connection pools (Nex handles it automatically).
    *   **Auto-Reconnect**: Browsers automatically reconnect dropped SSE connections.
    *   **HEEx Support**: Directly push rendered HTML fragments.
*   **Limitations**:
    *   **Unidirectional**: Only supports server-to-client.
    *   **Connection Limit**: HTTP/1.1 has browser limits on concurrent SSE connections to the same domain (HTTP/2 recommended).
