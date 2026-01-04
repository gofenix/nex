# SSE 实时推送 (Server-Sent Events)

Nex 内置了对 Server-Sent Events (SSE) 的原生支持，允许服务器向浏览器推送实时更新。这在构建聊天应用、通知系统或 AI 实时流式输出时非常有用。

## 1. 核心概念

SSE 是一种单向推送协议，相比 WebSocket，它更轻量、对防火墙更友好，并且在 Nex 中是零转换使用的。

*   **`Nex.stream/1`**：统一的流式响应接口。
*   **零转换推送**：你可以推送字符串、Map、List，Nex 会自动处理序列化并遵循 SSE 协议格式。

## 2. 在 Action 中使用 SSE

在 Page 的 Action 或 API 的处理函数中调用 `Nex.stream/1` 即可启动流。

### 示例：AI 聊天流 (模拟)

```elixir
def chat(%{"message" => msg}) do
  Nex.stream(fn send ->
    # 推送正在输入的提示
    send.("AI 正在思考...")
    
    # 模拟流式生成
    "这是对 #{msg} 的流式回复内容。"
    |> String.graphemes()
    |> Enum.each(fn char ->
      send.(char)
      Process.sleep(50)
    end)
  end)
end
```

## 3. SSE 协议细节

`send` 函数支持多种数据格式：

*   **纯文本**：`send.("hello")` -> `data: hello\n\n`
*   **JSON 对象**：`send.(%{id: 1, status: "ok"})` -> `data: {"id":1,"status":"ok"}\n\n`
*   **自定义事件**：`send.(%{event: "my_event", data: "payload"})` -> `event: my_event\ndata: payload\n\n`

浏览器端的 HTMX 可以轻松配合：
```html
<div hx-ext="sse" sse-connect="/api/chat_stream" sse-swap="message">
  内容将在此处实时追加...
</div>
```

## 4. 优势与局限

*   **优势**：
    *   **极致简单**：符合直觉的 `send` 回调模式，自动处理连接生命周期。
    *   **AI 友好**：完美契合 OpenAI/Anthropic 等流式 API 的输出模式。
    *   **自动重连**：浏览器内置支持，无需手动实现重连逻辑。
*   **局限**：
    *   **单向性**：仅支持服务器到客户端。若需双向实时，请结合 HTMX 的常规请求。
    *   **连接数限制**：HTTP/1.1 下有并发连接限制，生产环境强烈建议开启 HTTP/2。
