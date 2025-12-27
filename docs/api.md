# API

API 模块用于构建 JSON 接口，返回结构化数据而不是 HTML。

## 基本结构

```elixir
defmodule MyApp.Api.Todos.Index do
  use Nex.Api

  def get do
    %{data: fetch_todos()}
  end

  def post(%{"text" => text}) do
    todo = create_todo(text)
    {201, %{data: todo}}
  end
end
```

## HTTP 方法映射

API 模块根据 HTTP 方法调用对应函数：

| HTTP 方法 | 函数 |
|----------|------|
| GET | `get/0` 或 `get/1` |
| POST | `post/1` |
| PUT | `put/1` |
| PATCH | `patch/1` |
| DELETE | `delete/0` 或 `delete/1` |

## 函数参数

API 函数可以有 0 个或 1 个参数：

```elixir
# 不需要参数
def get do
  %{data: fetch_all()}
end

# 需要参数
def get(params) do
  page = params["page"] || "1"
  limit = params["limit"] || "20"
  %{data: fetch_page(page, limit)}
end
```

框架会自动选择正确的版本：
- 如果定义了 `get/1`，优先调用
- 如果只定义了 `get/0`，调用无参版本

## 返回值

### 成功响应

```elixir
# 200 OK
def get do
  %{data: todos}
end

# 自定义状态码
def post(params) do
  todo = create(params)
  {201, %{data: todo}}
end

# 204 No Content
def delete(_params) do
  :empty
end
```

### 错误响应

```elixir
def post(%{"text" => ""}) do
  {:error, 400, "text is required"}
end

def get(params) do
  case fetch_user(params["id"]) do
    nil -> {:error, 404, "User not found"}
    user -> %{data: user}
  end
end
```

### 返回值对照表

| 返回值 | HTTP 状态码 | 响应体 |
|-------|------------|--------|
| `%{data: ...}` | 200 | `{"data": ...}` |
| `{201, %{data: ...}}` | 201 | `{"data": ...}` |
| `{:error, 400, "msg"}` | 400 | `{"error": "msg"}` |
| `{:error, 404, "msg"}` | 404 | `{"error": "msg"}` |
| `:empty` | 204 | 空 |

## 完整示例

### RESTful CRUD API

```elixir
# src/api/todos/index.ex
defmodule MyApp.Api.Todos.Index do
  use Nex.Api

  # GET /api/todos
  def get do
    todos = Nex.Store.get(:todos, [])
    %{data: todos}
  end

  # POST /api/todos
  def post(%{"text" => text}) when text != "" do
    todo = %{
      id: System.unique_integer([:positive]),
      text: text,
      completed: false
    }
    Nex.Store.update(:todos, [], &[todo | &1])
    {201, %{data: todo}}
  end

  def post(_params) do
    {:error, 400, "text is required"}
  end
end
```

```elixir
# src/api/todos/[id].ex
defmodule MyApp.Api.Todos.Id do
  use Nex.Api

  # GET /api/todos/:id
  def get(params) do
    id = String.to_integer(params["id"])
    todos = Nex.Store.get(:todos, [])
    
    case Enum.find(todos, &(&1.id == id)) do
      nil -> {:error, 404, "Todo not found"}
      todo -> %{data: todo}
    end
  end

  # PUT /api/todos/:id
  def put(params) do
    id = String.to_integer(params["id"])
    
    Nex.Store.update(:todos, [], fn todos ->
      Enum.map(todos, fn todo ->
        if todo.id == id do
          %{todo | text: params["text"] || todo.text}
        else
          todo
        end
      end)
    end)

    todo = Nex.Store.get(:todos, []) |> Enum.find(&(&1.id == id))
    %{data: todo}
  end

  # DELETE /api/todos/:id
  def delete(params) do
    id = String.to_integer(params["id"])
    Nex.Store.update(:todos, [], &Enum.reject(&1, fn t -> t.id == id end))
    :empty
  end
end
```

### 带分页的 API

```elixir
def get(params) do
  page = String.to_integer(params["page"] || "1")
  limit = String.to_integer(params["limit"] || "20")
  
  all_todos = Nex.Store.get(:todos, [])
  total = length(all_todos)
  
  todos = all_todos
    |> Enum.drop((page - 1) * limit)
    |> Enum.take(limit)

  %{
    data: todos,
    meta: %{
      page: page,
      limit: limit,
      total: total,
      total_pages: ceil(total / limit)
    }
  }
end
```

### 带验证的 API

```elixir
def post(params) do
  with {:ok, text} <- validate_text(params["text"]),
       {:ok, todo} <- create_todo(text) do
    {201, %{data: todo}}
  else
    {:error, reason} -> {:error, 400, reason}
  end
end

defp validate_text(nil), do: {:error, "text is required"}
defp validate_text(""), do: {:error, "text cannot be empty"}
defp validate_text(text) when byte_size(text) > 500, do: {:error, "text too long"}
defp validate_text(text), do: {:ok, text}
```

## 与 Pages 的区别

| 特性 | Pages | API |
|-----|-------|-----|
| 返回格式 | HTML | JSON |
| 模板 | HEEx (~H) | 无 |
| mount/1 | ✅ | ❌ |
| render/1 | ✅ | ❌ |
| HTTP 方法 | GET + POST | GET/POST/PUT/DELETE |

## 下一步

- [Store](./store.md) - 状态管理
- [错误处理](./error-handling.md) - 错误响应
