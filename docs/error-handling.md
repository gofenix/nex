# 错误处理

Nex 提供统一的错误处理机制，包括友好的错误页面和异常捕获。

## 错误页面

### 404 Not Found

当请求的页面或 API 不存在时，Nex 返回 404 错误页面：

- **页面请求** — 显示友好的 404 HTML 页面
- **API 请求** — 返回 `{"error": "Not Found"}`
- **HTMX 请求** — 返回红色错误提示框

### 500 Internal Server Error

当代码抛出异常时，Nex 返回 500 错误页面：

- **开发环境** — 显示错误详情和堆栈信息
- **生产环境** — 只显示友好的错误消息

## API 错误响应

在 API 模块中返回错误：

```elixir
defmodule MyApp.Api.Users.Id do
  use Nex.Api

  def get(params) do
    case fetch_user(params["id"]) do
      nil -> {:error, 404, "User not found"}
      user -> %{data: user}
    end
  end

  def post(params) do
    case validate(params) do
      {:ok, data} -> 
        user = create_user(data)
        {201, %{data: user}}
      {:error, errors} -> 
        {:error, 422, errors}
    end
  end
end
```

### 错误返回值

| 返回值 | HTTP 状态码 | 响应体 |
|-------|------------|--------|
| `{:error, 400, "message"}` | 400 | `{"error": "message"}` |
| `{:error, 401, "message"}` | 401 | `{"error": "message"}` |
| `{:error, 403, "message"}` | 403 | `{"error": "message"}` |
| `{:error, 404, "message"}` | 404 | `{"error": "message"}` |
| `{:error, 422, errors}` | 422 | `{"error": errors}` |
| `{:error, 500, "message"}` | 500 | `{"error": "message"}` |

## Page Action 错误

在 Page action 中，异常会被自动捕获：

```elixir
def create_todo(%{"text" => text}) do
  # 如果这里抛出异常，会返回 500 错误页面
  todo = create!(text)
  ~H"<li>{todo.text}</li>"
end
```

### HTMX 错误响应

对于 HTMX 请求，错误会返回一个红色提示框：

```html
<div class="p-4 bg-red-100 border border-red-400 text-red-700 rounded">
  <strong>Error 500:</strong> Internal Server Error
</div>
```

## 异常处理

### 自动捕获

Nex 在顶层捕获所有未处理的异常：

```elixir
# 框架内部
def handle(conn) do
  try do
    # 处理请求
  rescue
    e ->
      Logger.error("Unhandled error: #{inspect(e)}")
      send_error_page(conn, 500, "Internal Server Error", e)
  end
end
```

### 手动处理

在你的代码中处理特定异常：

```elixir
def get(params) do
  try do
    user = fetch_user!(params["id"])
    %{data: user}
  rescue
    Ecto.NoResultsError ->
      {:error, 404, "User not found"}
  end
end
```

### 使用 with 语句

推荐使用 `with` 语句处理多步骤操作：

```elixir
def post(params) do
  with {:ok, data} <- validate(params),
       {:ok, user} <- create_user(data),
       {:ok, _} <- send_welcome_email(user) do
    {201, %{data: user}}
  else
    {:error, :validation, errors} -> {:error, 422, errors}
    {:error, :duplicate} -> {:error, 409, "User already exists"}
    {:error, _} -> {:error, 500, "Something went wrong"}
  end
end
```

## 开发环境错误详情

在开发环境（`MIX_ENV=dev`），错误页面会显示：

- 错误类型和消息
- 完整的堆栈跟踪
- 请求信息

```
┌────────────────────────────────────────┐
│              500                       │
│     Internal Server Error              │
│                                        │
│     ← Back to Home                     │
│                                        │
│ ┌────────────────────────────────────┐ │
│ │ %RuntimeError{                     │ │
│ │   message: "something went wrong"  │ │
│ │ }                                  │ │
│ │                                    │ │
│ │ Stacktrace:                        │ │
│ │   (my_app) lib/pages/index.ex:42   │ │
│ │   ...                              │ │
│ └────────────────────────────────────┘ │
└────────────────────────────────────────┘
```

## 生产环境

在生产环境，错误详情会被隐藏：

```
┌────────────────────────────────────────┐
│              500                       │
│     Internal Server Error              │
│                                        │
│     ← Back to Home                     │
└────────────────────────────────────────┘
```

## 日志

所有错误都会记录到日志：

```elixir
[error] Unhandled error: %RuntimeError{message: "..."}
  (my_app) lib/pages/index.ex:42: MyApp.Pages.Index.create_todo/1
  ...
```

## 自定义错误页面（未来功能）

未来版本可能支持自定义错误页面：

```elixir
# src/pages/errors/404.ex
defmodule MyApp.Pages.Errors.NotFound do
  use Nex.Page

  def render(assigns) do
    ~H"""
    <div class="text-center">
      <h1>页面不存在</h1>
      <a href="/">返回首页</a>
    </div>
    """
  end
end
```

## 下一步

- [开发工具](./development.md) - 开发服务器
- [API](./api.md) - API 模块
