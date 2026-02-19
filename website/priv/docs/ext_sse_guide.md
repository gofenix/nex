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

Use the native browser `EventSource` API on the client side:
```javascript
var es = new EventSource('/api/chat_stream');
var done = false;

es.onmessage = function(e) {
  document.getElementById('output').innerHTML += e.data;
};

es.addEventListener('done', function(e) {
  if (!done) { done = true; es.close(); }
});

es.onerror = function() {
  if (!done) { done = true; es.close(); }
};
```

> **Avoid the HTMX SSE extension** (`hx-ext="sse"`). It has an auto-reconnect bug that causes infinite loops when the stream ends. Always use the native `EventSource` API instead.

## 4. Pros and Cons

*   **Pros**:
    *   **Extremely Simple**: Intuitive `send` callback pattern, automatic connection lifecycle management.
    *   **AI Friendly**: Perfect for streaming outputs from APIs like OpenAI or Anthropic.
    *   **Auto Reconnect**: Built-in browser support, no need for manual reconnection logic.
*   **Cons**:
    *   **Unidirectional**: Server-to-client only. For bidirectional needs, combine with regular HTMX requests.
    *   **Connection Limits**: HTTP/1.1 has concurrent connection limits. It is highly recommended to use HTTP/2 in production.
