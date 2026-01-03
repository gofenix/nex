# 构建 JSON API (API 2.0)

Nex 不仅擅长生成 HTML，也是构建高性能 JSON API 的理想选择。Nex API 2.0 规范强制执行了一套标准，以确保 API 的响应一致性、健壮性和良好的开发者体验。

## 1. API 路由与结构

API 文件存放在 `src/api/` 目录下。URL 路径会自动加上 `/api` 前缀。

*   `src/api/users.ex` -> `/api/users`
*   `src/api/products/[id].ex` -> `/api/products/123`

## 2. API 2.0 强制规范

在 Nex API 2.0 中，为了统一响应格式，我们制定了以下强制规则：

1.  **必须返回 `Nex.Response` 结构体**：Action 函数不能再返回原始的 Map 或 List。
2.  **使用辅助函数**：必须使用 `Nex.json/2`, `Nex.text/2`, `Nex.redirect/2` 等辅助函数来构建响应。
3.  **函数签名**：API 处理函数接收一个 `Nex.Req` 结构体，其中包含 `body`, `query`, `params` 等字段。

### 正确示例

```elixir
defmodule MyApp.Api.Todos do
  use Nex

  # GET /api/todos
  def get(req) do
    todos = MyApp.Repo.all_todos()
    Nex.json(todos) # 返回 Nex.Response 结构体
  end

  # POST /api/todos
  def post(req) do
    # 使用 req.body 获取提交的数据
    case MyApp.Repo.create_todo(req.body) do
      {:ok, todo} -> 
        Nex.json(todo, status: 201)
      {:error, reason} -> 
        Nex.json(%{error: reason}, status: 422)
    end
  end
end
```

## 3. Nex.Req 结构解析

`req` 参数提供了对请求数据的统一访问：

*   **`req.body`**：POST/PUT 请求的 Body 内容（通常是解析后的 Map）。
*   **`req.query`**：URL 中的查询参数（如 `?search=nex`）。
*   **`req.params`**：URL 路径中的动态参数（如 `[id]`）。
*   **`req.headers`**：请求头信息。

## 4. 智能错误处理机制

当你的 API 代码抛出异常或返回格式不正确时，Nex 的 `Handler` 会介入并提供有价值的反馈：

*   **开发模式 (`:dev`)**：返回包含详细错误描述、堆栈追踪以及“期望响应格式”提示的 JSON。
*   **生产模式 (`:prod`)**：返回通用的错误信息，确保安全性。

### 示例错误响应
```json
{
  "error": "Internal Server Error: API signature mismatch",
  "expected": "Nex.Response struct (e.g., Nex.json(%{data: ...}))",
  "details": "..."
}
```

## 5. 响应辅助函数参考

| 函数 | 说明 |
| :--- | :--- |
| `Nex.json(data, opts)` | 返回 JSON 响应。`opts` 可包含 `:status`。 |
| `Nex.text(string, opts)` | 返回纯文本响应。 |
| `Nex.html(content, opts)` | 返回 HTML 响应（Content-Type 为 text/html）。 |
| `Nex.redirect(to, opts)` | 发送标准 302 重定向。 |
| `Nex.status(code)` | 仅返回指定的 HTTP 状态码。 |
