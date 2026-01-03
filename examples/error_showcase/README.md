# Error Handling Showcase

完整的错误处理演示，展示 Nex 如何根据请求类型智能地返回不同的错误响应。

## 核心特性

- ✅ **HTMX 错误** - 返回 HTML 片段（不破坏页面布局）
- ✅ **API 错误** - 返回标准 JSON 错误响应
- ✅ **浏览器错误** - 返回完整的 HTML 错误页面
- ✅ **开发模式** - 包含详细的错误信息和堆栈跟踪
- ✅ **动态路由** - 使用 `[code]` 动态参数处理不同的错误码

## 学习要点

### 1. 智能错误响应（Smart Error Handling）

Nex 框架在 `Handler.ex` 中自动检测请求类型，并返回最合适的错误响应：

```elixir
# Handler.ex:403-458 中的逻辑
defp send_error_page(conn, status, message, error) do
  is_htmx = get_req_header(conn, "hx-request") != []
  is_json = match?(["api" | _], conn.path_info) or
            get_req_header(conn, "accept") |> Enum.any?(&String.contains?(&1, "application/json"))

  cond do
    is_json ->
      # 返回 JSON 错误
      send_json_error(conn, status, message)

    is_htmx ->
      # 返回 HTML 片段（不破坏布局）
      html = "<div class=\"error\">Error #{status}: #{message}</div>"
      send_resp(conn, status, html)

    true ->
      # 返回完整的 HTML 错误页面
      send_full_error_page(conn, status, message)
  end
end
```

### 2. 三种错误响应类型

#### A. HTMX 请求错误

当 HTMX 发起请求时，Nex 检测到 `hx-request` 头，返回 HTML 片段：

```html
<!-- 请求 -->
<button hx-get="/error/404" hx-target="#result">Trigger 404</button>

<!-- 响应：只是一个 HTML 片段，不会破坏页面布局 -->
<div class="error">Error 404: Not Found</div>
```

**优势**：不会替换整个页面，用户体验流畅。

#### B. API 请求错误

当客户端请求 JSON（`Accept: application/json`），Nex 返回标准 JSON 错误：

```javascript
// 请求
fetch('/api/error/404', {
  headers: { 'Accept': 'application/json' }
})

// 响应
{
  "error": true,
  "code": 404,
  "message": "Not Found",
  "description": "The requested resource does not exist.",
  "timestamp": "2024-01-03T20:30:00Z"
}
```

**优势**：API 客户端可以解析错误并相应处理。

#### C. 浏览器导航错误

当用户直接导航到错误 URL 时，Nex 返回完整的 HTML 错误页面：

```html
<!-- 用户访问 /error/404 -->
<!-- 响应：完整的 HTML 页面，带有 Tailwind 样式 -->
<!DOCTYPE html>
<html>
  <head>
    <title>404 - Not Found</title>
    <script src="https://cdn.tailwindcss.com"></script>
  </head>
  <body>
    <div class="text-center">
      <h1 class="text-6xl">404</h1>
      <p>The page you're looking for doesn't exist.</p>
    </div>
  </body>
</html>
```

**优势**：用户看到美观的错误页面，而不是浏览器默认的错误。

### 3. 动态路由处理错误码

使用 `[code]` 动态参数创建通用的错误处理页面：

```elixir
# src/pages/error/[code].ex
def mount(%{"code" => code_str}) do
  code = String.to_integer(code_str)
  %{
    code: code,
    message: get_error_message(code),
    description: get_error_description(code)
  }
end

# src/api/error/[code].ex
def get(%{"code" => code_str}) do
  code = String.to_integer(code_str)
  Nex.json(%{error: true, code: code, ...}, status: code)
end
```

### 4. 开发模式详细错误

在 `:dev` 环境中，Nex 返回详细的错误信息：

```elixir
# Handler.ex:428-432
error_detail = if error && Mix.env() == :dev do
  "<pre>#{inspect(error, pretty: true)}</pre>"
else
  ""
end
```

## 运行

```bash
cd examples/error_showcase
mix deps.get
mix phx.server
```

访问 http://localhost:4000

## 交互演示

### 1. HTMX 错误
点击"Trigger 404 (HTMX)"按钮，看到 HTML 片段错误响应，页面不会刷新。

### 2. API 错误
点击"Trigger 404 (JSON)"按钮，看到 JSON 错误响应。

### 3. 浏览器错误
点击"Navigate to 404 Page"链接，看到完整的 HTML 错误页面。

## 文件结构

```
error_showcase/
├── src/
│   ├── pages/
│   │   ├── index.ex              # 主演示页面
│   │   └── error/
│   │       └── [code].ex         # 动态错误页面
│   ├── api/
│   │   └── error/
│   │       └── [code].ex         # 动态 API 错误端点
│   └── layouts.ex                # 全局布局
├── mix.exs
└── README.md
```

## 关键概念

| 概念 | 说明 |
|-----|-----|
| **智能错误路由** | Nex 自动检测请求类型并返回最合适的错误响应 |
| **HTMX 友好** | 返回 HTML 片段而不是完整页面，保持用户体验 |
| **API 标准** | 返回标准的 JSON 错误响应，便于客户端处理 |
| **用户友好** | 返回美观的 HTML 错误页面而不是浏览器默认错误 |
| **开发友好** | 开发模式下包含详细的错误信息用于调试 |

## 扩展思考

1. **自定义错误页面**：如何为不同的错误码创建自定义页面？
2. **错误日志**：如何记录所有错误到日志系统？
3. **错误监控**：如何集成 Sentry 等错误监控服务？
4. **错误恢复**：如何在错误后自动重试？
5. **国际化**：如何支持多语言错误消息？

---

**这个示例展示了 Nex 的智能错误处理，是 HTMX 集成的最佳实践。**
