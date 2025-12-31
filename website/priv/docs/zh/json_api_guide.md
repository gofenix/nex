# JSON API 指南

Nex 提供了一个 **100% 对齐 Next.js API Routes** 的 JSON API 系统，让来自 JavaScript 生态系统的开发者感到熟悉，同时充分利用 Elixir 的强大功能。

## 目录

- [快速开始](#快速开始)
- [Next.js API Routes 对齐](#nextjs-api-routes-对齐)
- [路由](#路由)
- [请求对象](#请求对象)
- [响应辅助函数](#响应辅助函数)
- [HTTP 方法](#http-方法)
- [动态路由](#动态路由)
- [错误处理](#错误处理)
- [完整示例](#完整示例)

---

## 快速开始

在 `src/api/hello.ex` 中创建一个 API 端点：

```elixir
defmodule MyApp.Api.Hello do
  use Nex.Api

  def get(req) do
    name = req.query["name"] || "World"
    Nex.json(%{message: "Hello, #{name}!"})
  end

  def post(req) do
    name = req.body["name"]
    
    if is_nil(name) or name == "" do
      Nex.json(%{error: "Name is required"}, status: 400)
    else
      Nex.json(%{message: "Hello, #{name}!"}, status: 201)
    end
  end
end
```

测试：

```bash
# GET 请求
curl http://localhost:4000/api/hello?name=Alice
# {"message":"Hello, Alice!"}

# POST 请求
curl -X POST http://localhost:4000/api/hello \
  -H "Content-Type: application/json" \
  -d '{"name":"Bob"}'
# {"message":"Hello, Bob!"}
```

---

## Next.js API Routes 对齐

Nex 的 JSON API 设计完全匹配 Next.js API Routes 的行为：

### 对比表

| 功能 | Next.js | Nex |
|------|---------|-----|
| 请求查询参数 | `req.query.id` | `req.query["id"]` |
| 请求体 | `req.body.name` | `req.body["name"]` |
| 路径参数 | 合并到 `req.query` | 合并到 `req.query` |
| JSON 响应 | `res.json({data})` | `Nex.json(%{data: ...})` |
| 状态码 | `res.status(201).json(...)` | `Nex.json(..., status: 201)` |
| 文本响应 | `res.send("text")` | `Nex.text("text")` |
| 空响应 | `res.status(204).end()` | `Nex.status(204)` |

### 核心原则

1. **`req.query`** - 合并路径参数和查询字符串（路径参数优先）
2. **`req.body`** - 始终是 Map，永远不是 `nil` 或 `Unfetched`
3. **无 Nex 特定字段** - 仅标准字段：`query`、`body`、`method`、`headers`、`cookies`、`path`

---

## 路由

`src/api/` 中的 API 文件自动映射到 `/api/*` 路由：

| 文件路径 | 路由 | 示例 |
|---------|------|------|
| `src/api/hello.ex` | `/api/hello` | `/api/hello?name=World` |
| `src/api/users/index.ex` | `/api/users` | `/api/users?limit=10` |
| `src/api/users/[id].ex` | `/api/users/:id` | `/api/users/123` |
| `src/api/posts/[id]/comments.ex` | `/api/posts/:id/comments` | `/api/posts/456/comments` |

---

## 请求对象

`req` 参数提供对请求数据的访问：

### 可用字段

```elixir
def get(req) do
  # 查询参数（路径参数 + 查询字符串）
  req.query         # %{"id" => "123", "filter" => "active"}
  
  # 请求体（始终是 Map）
  req.body          # %{"name" => "Alice", "email" => "alice@example.com"}
  
  # HTTP 方法
  req.method        # "GET", "POST", "PUT", "DELETE" 等
  
  # 请求头
  req.headers       # %{"content-type" => "application/json", ...}
  
  # Cookies
  req.cookies       # %{"session_id" => "abc123"}
  
  # 请求路径
  req.path          # "/api/users/123"
  
  # 私有数据（内部使用）
  req.private       # %{...}
end
```

### 查询参数

查询参数合并路径参数和查询字符串，**路径参数优先**：

```elixir
# 路由: /api/users/[id]
# 请求: GET /api/users/123?id=456&filter=active

def get(req) do
  req.query["id"]      # "123" (来自路径，而不是查询中的 "456")
  req.query["filter"]  # "active"
end
```

### 请求体

请求体始终是 Map，自动从 JSON 解析：

```elixir
# 请求: POST /api/users
# Body: {"name": "Alice", "email": "alice@example.com"}

def post(req) do
  name = req.body["name"]    # "Alice"
  email = req.body["email"]  # "alice@example.com"
  
  # req.body 永远不是 nil，始终是 Map
  # 空请求体: req.body == %{}
end
```

---

## 响应辅助函数

Nex 提供类似 Next.js 的响应辅助函数：

### `Nex.json/2` - JSON 响应

```elixir
# 基本 JSON 响应（200 OK）
Nex.json(%{data: users})

# 自定义状态码
Nex.json(%{data: user}, status: 201)

# 自定义响应头
Nex.json(%{data: user}, status: 200, headers: %{"X-Custom" => "value"})

# 错误响应
Nex.json(%{error: "Not found"}, status: 404)
```

### `Nex.text/2` - 文本响应

```elixir
# 纯文本响应
Nex.text("Hello, World!")

# 自定义状态码
Nex.text("Created", status: 201)
```

### `Nex.html/2` - HTML 响应

```elixir
# HTML 响应（对 HTMX 有用）
Nex.html("<div>Hello</div>")

# 自定义状态码
Nex.html("<div>Error</div>", status: 400)
```

### `Nex.status/1` - 仅状态码

```elixir
# 204 No Content（成功删除）
Nex.status(204)

# 304 Not Modified
Nex.status(304)
```

### `Nex.redirect/2` - 重定向

```elixir
# 临时重定向（302）
Nex.redirect("/login")

# 永久重定向（301）
Nex.redirect("/new-url", status: 301)
```

---

## HTTP 方法

为不同的 HTTP 方法定义处理函数：

```elixir
defmodule MyApp.Api.Users do
  use Nex.Api

  # GET /api/users
  def get(req) do
    users = get_all_users()
    Nex.json(%{data: users})
  end

  # POST /api/users
  def post(req) do
    user = create_user(req.body)
    Nex.json(%{data: user}, status: 201)
  end

  # PUT /api/users（批量更新）
  def put(req) do
    updated = update_users(req.body)
    Nex.json(%{data: updated})
  end

  # DELETE /api/users（批量删除）
  def delete(req) do
    delete_users(req.body["ids"])
    Nex.status(204)
  end

  # PATCH /api/users（部分更新）
  def patch(req) do
    updated = patch_users(req.body)
    Nex.json(%{data: updated})
  end
end
```

---

## 动态路由

使用 `[param]` 语法定义动态路由段：

### 单个参数

```elixir
# src/api/users/[id].ex
defmodule MyApp.Api.Users.Id do
  use Nex.Api

  # GET /api/users/123
  def get(req) do
    id = req.query["id"]  # "123"
    
    case find_user(id) do
      nil -> Nex.json(%{error: "User not found"}, status: 404)
      user -> Nex.json(%{data: user})
    end
  end

  # PUT /api/users/123
  def put(req) do
    id = req.query["id"]
    attrs = req.body
    
    case update_user(id, attrs) do
      {:ok, user} -> Nex.json(%{data: user})
      {:error, reason} -> Nex.json(%{error: reason}, status: 400)
    end
  end

  # DELETE /api/users/123
  def delete(req) do
    id = req.query["id"]
    delete_user(id)
    Nex.status(204)
  end
end
```

### 嵌套参数

```elixir
# src/api/posts/[post_id]/comments/[id].ex
defmodule MyApp.Api.Posts.PostId.Comments.Id do
  use Nex.Api

  # GET /api/posts/456/comments/789
  def get(req) do
    post_id = req.query["post_id"]    # "456"
    comment_id = req.query["id"]      # "789"
    
    comment = find_comment(post_id, comment_id)
    Nex.json(%{data: comment})
  end
end
```

---

## 错误处理

### 验证错误

```elixir
def post(req) do
  name = req.body["name"]
  email = req.body["email"]
  
  cond do
    is_nil(name) or name == "" ->
      Nex.json(%{error: "Name is required"}, status: 400)
    
    is_nil(email) or not valid_email?(email) ->
      Nex.json(%{error: "Valid email is required"}, status: 400)
    
    true ->
      user = create_user(%{name: name, email: email})
      Nex.json(%{data: user}, status: 201)
  end
end
```

### 未找到

```elixir
def get(req) do
  id = req.query["id"]
  
  case find_user(id) do
    nil -> Nex.json(%{error: "User not found"}, status: 404)
    user -> Nex.json(%{data: user})
  end
end
```

### 未授权

```elixir
def delete(req) do
  token = req.headers["authorization"]
  
  if not valid_token?(token) do
    Nex.json(%{error: "Unauthorized"}, status: 401)
  else
    delete_resource()
    Nex.status(204)
  end
end
```

### 内部服务器错误

```elixir
def post(req) do
  try do
    result = perform_operation(req.body)
    Nex.json(%{data: result}, status: 201)
  rescue
    e ->
      # 记录错误
      Logger.error("Operation failed: #{inspect(e)}")
      Nex.json(%{error: "Internal server error"}, status: 500)
  end
end
```

---

## 完整示例

这是一个管理 todos 的完整 RESTful API：

### 集合端点

```elixir
# src/api/todos/index.ex
defmodule MyApp.Api.Todos.Index do
  @moduledoc """
  Todos 集合 API - Next.js 风格。
  
  端点：
  - GET /api/todos - 列出带过滤的 todos
  - POST /api/todos - 创建新 todo
  """
  use Nex.Api

  # GET /api/todos?completed=false&limit=10
  def get(req) do
    completed_filter = req.query["completed"]
    limit = req.query["limit"]
    
    todos = Nex.Store.get(:todos, [])
    |> filter_by_completed(completed_filter)
    |> limit_results(limit)
    
    Nex.json(%{
      data: todos,
      count: length(todos)
    })
  end

  # POST /api/todos
  # Body: {"text": "Buy groceries", "completed": false}
  def post(req) do
    text = req.body["text"]
    completed = req.body["completed"] || false
    
    cond do
      is_nil(text) or text == "" ->
        Nex.json(%{error: "Text is required"}, status: 400)
      
      true ->
        todo = %{
          id: System.unique_integer([:positive, :monotonic]),
          text: text,
          completed: completed,
          created_at: DateTime.utc_now() |> DateTime.to_iso8601()
        }
        
        Nex.Store.update(:todos, [], &[todo | &1])
        
        Nex.json(%{data: todo}, status: 201)
    end
  end
  
  # 私有辅助函数
  
  defp filter_by_completed(todos, nil), do: todos
  defp filter_by_completed(todos, "true"), do: Enum.filter(todos, & &1.completed)
  defp filter_by_completed(todos, "false"), do: Enum.filter(todos, &(not &1.completed))
  defp filter_by_completed(todos, _), do: todos
  
  defp limit_results(todos, nil), do: todos
  defp limit_results(todos, limit_str) do
    case Integer.parse(limit_str) do
      {limit, _} -> Enum.take(todos, limit)
      :error -> todos
    end
  end
end
```

### 资源端点

```elixir
# src/api/todos/[id].ex
defmodule MyApp.Api.Todos.Id do
  @moduledoc """
  单个 todo API - Next.js 风格。
  
  端点：
  - GET /api/todos/:id - 获取特定 todo
  - PUT /api/todos/:id - 更新 todo
  - DELETE /api/todos/:id - 删除 todo
  """
  use Nex.Api

  # GET /api/todos/123
  def get(req) do
    id = req.query["id"]
    
    case find_todo(id) do
      nil ->
        Nex.json(%{error: "Todo not found"}, status: 404)
      
      todo ->
        Nex.json(%{data: todo})
    end
  end

  # PUT /api/todos/123
  # Body: {"text": "Updated text", "completed": true}
  def put(req) do
    id = req.query["id"]
    text = req.body["text"]
    completed = req.body["completed"]
    
    case find_todo(id) do
      nil ->
        Nex.json(%{error: "Todo not found"}, status: 404)
      
      todo ->
        updated_todo = todo
        |> update_if_present(:text, text)
        |> update_if_present(:completed, completed)
        
        Nex.Store.update(:todos, [], fn todos ->
          Enum.map(todos, fn t ->
            if t.id == todo.id, do: updated_todo, else: t
          end)
        end)
        
        Nex.json(%{data: updated_todo})
    end
  end

  # DELETE /api/todos/123
  def delete(req) do
    id = req.query["id"]
    
    case find_todo(id) do
      nil ->
        Nex.json(%{error: "Todo not found"}, status: 404)
      
      _todo ->
        Nex.Store.update(:todos, [], fn todos ->
          Enum.reject(todos, &(&1.id == parse_id(id)))
        end)
        
        Nex.status(204)
    end
  end
  
  # 私有辅助函数
  
  defp find_todo(id_str) do
    case parse_id(id_str) do
      nil -> nil
      id ->
        Nex.Store.get(:todos, [])
        |> Enum.find(&(&1.id == id))
    end
  end
  
  defp parse_id(id_str) when is_binary(id_str) do
    case Integer.parse(id_str) do
      {id, _} -> id
      :error -> nil
    end
  end
  defp parse_id(_), do: nil
  
  defp update_if_present(map, _key, nil), do: map
  defp update_if_present(map, key, value), do: Map.put(map, key, value)
end
```

---

## 最佳实践

### 1. 使用正确的 HTTP 状态码

```elixir
# 200 OK - 成功的 GET、PUT、PATCH
Nex.json(%{data: resource})

# 201 Created - 成功的 POST
Nex.json(%{data: new_resource}, status: 201)

# 204 No Content - 成功的 DELETE
Nex.status(204)

# 400 Bad Request - 验证错误
Nex.json(%{error: "Invalid input"}, status: 400)

# 404 Not Found - 资源未找到
Nex.json(%{error: "Not found"}, status: 404)

# 401 Unauthorized - 需要身份验证
Nex.json(%{error: "Unauthorized"}, status: 401)

# 403 Forbidden - 权限不足
Nex.json(%{error: "Forbidden"}, status: 403)

# 500 Internal Server Error - 服务器错误
Nex.json(%{error: "Internal error"}, status: 500)
```

### 2. 一致的响应格式

```elixir
# 成功响应
%{data: resource}
%{data: resources, count: 10, page: 1}

# 错误响应
%{error: "Error message"}
%{error: "Error message", details: %{field: "is invalid"}}
```

### 3. 输入验证

```elixir
def post(req) do
  with {:ok, name} <- validate_required(req.body["name"], "Name"),
       {:ok, email} <- validate_email(req.body["email"]) do
    user = create_user(%{name: name, email: email})
    Nex.json(%{data: user}, status: 201)
  else
    {:error, message} ->
      Nex.json(%{error: message}, status: 400)
  end
end

defp validate_required(nil, field), do: {:error, "#{field} is required"}
defp validate_required("", field), do: {:error, "#{field} is required"}
defp validate_required(value, _field), do: {:ok, value}

defp validate_email(email) when is_binary(email) do
  if String.contains?(email, "@") do
    {:ok, email}
  else
    {:error, "Invalid email format"}
  end
end
defp validate_email(_), do: {:error, "Email is required"}
```

### 4. 错误日志

```elixir
require Logger

def post(req) do
  try do
    result = perform_operation(req.body)
    Nex.json(%{data: result}, status: 201)
  rescue
    e ->
      Logger.error("Operation failed: #{inspect(e)}\nStacktrace: #{Exception.format_stacktrace()}")
      Nex.json(%{error: "Internal server error"}, status: 500)
  end
end
```

---

## 从旧 API 迁移

如果你正在从旧版本的 Nex 升级，以下是变化的内容：

### 已移除的字段

这些字段**不再可用**：

- ❌ `req.params` - 改用 `req.query`
- ❌ `req.path_params` - 已合并到 `req.query`
- ❌ `req.query_params` - 改用 `req.query`
- ❌ `req.body_params` - 改用 `req.body`

### 迁移示例

**旧代码：**

```elixir
def get(req) do
  id = req.path_params["id"]
  filter = req.query_params["filter"]
  # ...
end

def post(req) do
  name = req.body_params["name"]
  # ...
end
```

**新代码：**

```elixir
def get(req) do
  id = req.query["id"]       # 路径参数合并到 query
  filter = req.query["filter"]
  # ...
end

def post(req) do
  name = req.body["name"]    # 直接访问 body
  # ...
end
```

---

## 总结

Nex 的 JSON API 系统提供：

- ✅ **100% Next.js API Routes 对齐** - 对 JavaScript 开发者友好
- ✅ **简单路由** - `src/api/` 中基于文件的路由
- ✅ **清晰的请求对象** - `req.query` 和 `req.body`
- ✅ **灵活的响应** - `Nex.json/2`、`Nex.text/2`、`Nex.html/2` 等
- ✅ **动态路由** - 路径参数的 `[param]` 语法
- ✅ **类型安全** - 利用 Elixir 的模式匹配和守卫

更多示例，请查看 Nex 仓库中的 `examples/todos_api` 项目。
