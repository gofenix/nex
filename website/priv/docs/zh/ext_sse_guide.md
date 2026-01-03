# SSE 实时推送 (Server-Sent Events)

Nex 内置了对 Server-Sent Events (SSE) 的原生支持，允许服务器向浏览器推送实时更新。这在构建聊天应用、通知系统或实时监控仪表盘时非常有用。

## 1. 核心概念

SSE 是一种单向推送协议，相比 WebSocket，它更轻量、对防火墙更友好，并且在 Nex 中几乎是零转换使用的。

*   **Action 模式**：通过 `hx-ext="sse"` 插件或直接在 Action 中返回 `{:stream, fun}`。
*   **零转换推送**：你可以推送字符串、Map、List，甚至 HEEx 片段，Nex 会自动处理序列化。

## 2. 在 Action 中使用 SSE

最简单的方法是在 Action 函数中返回一个流。

### 示例：实时聊天室机器人

```elixir
def chat(%{"message" => msg}) do
  {:stream, fn send_fn ->
    # 推送正在输入的提示
    send_fn.("机器人正在思考...")
    
    # 模拟处理延迟
    Process.sleep(1000)
    
    # 推送最终回复
    send_fn.(~H"<div class='p-2 bg-blue-100 rounded'>这是对 #{msg} 的回复</div>")
  end}
end
```

## 3. SSE 模块协议

Nex 支持将 Map 或带 `event` 键的 Map 自动转换为标准 SSE 协议：

```elixir
send_fn.(%{event: "update", data: "新消息内容"})
```

浏览器端的 HTMX 会自动根据事件名处理更新：
```html
<div hx-ext="sse" sse-connect="/api/chat_stream" sse-swap="update">
  内容将在此处更新...
</div>
```

## 4. 优势与局限

*   **优势**：
    *   **极致简单**：无需管理连接池（Nex 自动处理）。
    *   **自动重连**：浏览器会自动重连断开的 SSE 连接。
    *   **HEEx 支持**：直接推送渲染后的 HTML 片段。
*   **局限**：
    *   **单向性**：仅支持服务器到客户端。
    *   **连接数限制**：HTTP/1.1 下浏览器对同一域名的 SSE 连接有限制（建议使用 HTTP/2）。
