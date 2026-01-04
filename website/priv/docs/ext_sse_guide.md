# Server-Sent Events (SSE)

Nex provides native support for Server-Sent Events (SSE), allowing the server to push real-time updates to the browser. This is extremely useful for building chat applications, notification systems, or AI streaming responses.

## 1. Core Concepts

SSE is a unidirectional push protocol. Compared to WebSockets, it is more lightweight, firewall-friendly, and can be used with zero configuration in Nex.

*   **`Nex.stream/1`**: The unified interface for streaming responses.
*   **Zero-transform Push**: You can push strings, Maps, or Lists. Nex automatically handles serialization and follows the SSE protocol format.

## 2. Using SSE in Actions

Call `Nex.stream/1` within a Page Action or an API handler to start a stream.

### Example: AI Chat Stream (Mock)

```elixir
def chat(%{"message" => msg}) do
  Nex.stream(fn send ->
    # Push a "thinking" indicator
    send.("AI is thinking...")
    
    # Simulate streaming generation
    "This is a streaming response to: #{msg}."
    |> String.graphemes()
    |> Enum.each(fn char ->
      send.(char)
      Process.sleep(50)
    end)
  end)
end
```

## 3. SSE Protocol Details

The `send` function supports multiple data formats:

*   **Plain Text**: `send.("hello")` -> `data: hello\n\n`
*   **JSON Object**: `send.(%{id: 1, status: "ok"})` -> `data: {"id":1,"status":"ok"}\n\n`
*   **Custom Events**: `send.(%{event: "my_event", data: "payload"})` -> `event: my_event\ndata: payload\n\n`

HTMX on the client side can easily integrate with SSE:
```html
<div hx-ext="sse" sse-connect="/api/chat_stream" sse-swap="message">
  Content will be appended here in real-time...
</div>
```

## 4. Pros and Cons

*   **Pros**:
    *   **Extremely Simple**: Intuitive `send` callback pattern, automatic connection lifecycle management.
    *   **AI Friendly**: Perfect for streaming outputs from APIs like OpenAI or Anthropic.
    *   **Auto Reconnect**: Built-in browser support, no need for manual reconnection logic.
*   **Cons**:
    *   **Unidirectional**: Server-to-client only. For bidirectional needs, combine with regular HTMX requests.
    *   **Connection Limits**: HTTP/1.1 has concurrent connection limits. It is highly recommended to use HTTP/2 in production.
