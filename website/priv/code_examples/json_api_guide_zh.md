# Nex JSON API 开发指南

Nex 内置了对 JSON API 的支持，方便为移动端或第三方服务提供数据接口。

## 目录

- [路由规则](#路由规则)
- [请求处理](#请求处理)
- [返回值格式](#返回值格式)

---

## 路由规则

API 路由文件位于 `src/api/` 目录下，所有 URL 自动添加 `/api/` 前缀。

| 文件路径 | HTTP URL |
| :--- | :--- |
| `src/api/users.ex` | `/api/users` |
| `src/api/posts/[id].ex` | `/api/posts/123` |

---

## 请求处理

API 模块需要 `use Nex.Api`。你需要定义与 HTTP 方法同名的函数（`get`, `post`, `put`, `delete` 等）。

*   **无参数**: 定义 `def get do ... end`
*   **有参数**: 定义 `def post(params) do ... end`

```elixir
defmodule MyApp.Api.Todos.Index do
  use Nex.Api

  # GET /api/todos
  def get do
    todos = Nex.Store.get(:todos, [])
    %{data: todos}
  end

  # POST /api/todos
  def post(%{"text" => text}) do
    todo = %{id: System.unique_integer(), text: text}
    Nex.Store.update(:todos, [], &[todo | &1])
    
    # 返回自定义状态码
    {201, %{data: todo}}
  end
  
  # 参数验证示例
  def post(_params) do
    {:error, 400, "Missing text parameter"}
  end
end
```

---

## 返回值格式

`Nex.Api` 会自动将返回值序列化为 JSON，并设置 `Content-Type: application/json`。

| 返回值 (Elixir) | HTTP 状态码 | JSON Body | 说明 |
| :--- | :--- | :--- | :--- |
| `%{key: "val"}` | 200 | `{"key": "val"}` | 默认成功响应 |
| `{201, %{...}}` | 201 | `{"..."}` | 自定义状态码 |
| `{:error, 404, "msg"}` | 404 | `{"error": "msg"}` | 错误响应简写 |
| `:empty` | 204 | (无内容) | 无内容成功响应 |
| `:method_not_allowed` | 405 | `{"error": "Method Not Allowed"}` | 方法不支持 |
