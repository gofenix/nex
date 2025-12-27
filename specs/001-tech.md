# Nex Framework 技术规范（MVP）

本文档定义 Nex 框架的核心技术实现。

## 1. 项目结构

```
my_app/
├── mix.exs                 # 项目配置
├── .env                    # 环境变量
├── src/
│   ├── pages/              # 页面 + HTMX 处理函数
│   │   ├── index.ex        # GET / + POST /create_todo 等
│   │   ├── about.ex        # GET /about
│   │   └── todos/
│   │       └── [id].ex     # GET /todos/:id
│   ├── partials/           # 纯组件（无 HTTP 路由）
│   │   └── todos/
│   │       └── item.ex     # 组件函数，被 pages 调用
│   └── api/                # JSON API
│       └── todos/
│           ├── index.ex    # GET/POST /api/todos
│           └── [id].ex     # GET/PATCH/DELETE /api/todos/:id
├── priv/static/            # 静态资源
└── layouts.ex              # 根布局
```

## 2. 三类目录职责

| 目录 | 职责 | 路由 | 返回类型 |
|-----|------|------|---------|
| `pages/` | 页面渲染 + HTMX 处理 | 有 | HTML |
| `partials/` | 纯组件复用 | **无** | - |
| `api/` | JSON API | 有 | JSON |

## 3. Pages 规范

### 3.1 路由规则

```
src/pages/index.ex      → GET /
src/pages/about.ex      → GET /about
src/pages/todos/[id].ex → GET /todos/:id
```

**函数路由**：
- `render/1` → GET 请求（渲染页面）
- 其他公开函数 → POST 请求（HTMX 调用）

```
def render(assigns)     → GET /
def create_todo(conn, params) → POST /create_todo
def delete_todo(conn, params) → POST /delete_todo
```

### 3.2 示例

```elixir
# src/pages/index.ex
defmodule MyApp.Pages.Index do
  use Nex.Page

  def mount(_conn, _params) do
    %{
      title: "Todo App",
      todos: fetch_todos()
    }
  end

  def render(assigns) do
    ~H"""
    <div class="container">
      <h1>{@title}</h1>
      
      <form hx-post="/create_todo" hx-target="#todo-list" hx-swap="beforeend">
        <input name="text" placeholder="新任务..." required />
        <button type="submit">添加</button>
      </form>
      
      <ul id="todo-list">
        <.todo_item :for={todo <- @todos} todo={todo} />
      </ul>
    </div>
    """
  end

  # POST /create_todo → 返回 HTML 片段
  def create_todo(conn, params) do
    todo = insert_todo(params["text"])
    render_fragment(conn, ~H"<.todo_item todo={todo} />")
  end

  # POST /toggle_todo → 返回更新后的 HTML 片段
  def toggle_todo(conn, %{"id" => id}) do
    todo = toggle_todo_status(id)
    render_fragment(conn, ~H"<.todo_item todo={todo} />")
  end

  # POST /delete_todo → 返回空（删除元素）
  def delete_todo(conn, %{"id" => id}) do
    delete_todo_by_id(id)
    empty(conn)
  end

  # 私有组件
  defp todo_item(assigns) do
    ~H"""
    <li id={"todo-#{@todo.id}"}>
      <input type="checkbox" 
             checked={@todo.completed}
             hx-post="/toggle_todo"
             hx-vals={Jason.encode!(%{id: @todo.id})}
             hx-target={"#todo-#{@todo.id}"}
             hx-swap="outerHTML" />
      <span class={if @todo.completed, do: "line-through"}>{@todo.text}</span>
      <button hx-post="/delete_todo"
              hx-vals={Jason.encode!(%{id: @todo.id})}
              hx-target={"#todo-#{@todo.id}"}
              hx-swap="outerHTML">删除</button>
    </li>
    """
  end
end
```

### 3.3 Nex.Page 模块

```elixir
defmodule Nex.Page do
  defmacro __using__(_opts) do
    quote do
      import Phoenix.Component, only: [sigil_H: 2]
      import Nex.Page.Helpers
    end
  end
end

defmodule Nex.Page.Helpers do
  import Plug.Conn

  @doc "渲染 HTML 片段（HTMX 响应）"
  def render_fragment(conn, heex) do
    html = heex |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end

  @doc "返回空响应（用于删除）"
  def empty(conn) do
    send_resp(conn, 200, "")
  end

  @doc "HTMX 重定向"
  def hx_redirect(conn, to) do
    conn
    |> put_resp_header("hx-redirect", to)
    |> send_resp(200, "")
  end
end
```

## 4. Partials 规范（纯组件）

Partials **没有 HTTP 路由**，只是可复用的组件函数。

### 4.1 示例

```elixir
# src/partials/todos/item.ex
defmodule MyApp.Partials.Todos.Item do
  use Nex.Partial

  def todo_item(assigns) do
    ~H"""
    <li id={"todo-#{@todo.id}"}>
      <span>{@todo.text}</span>
    </li>
    """
  end

  def todo_list(assigns) do
    ~H"""
    <ul id="todo-list">
      <.todo_item :for={todo <- @todos} todo={todo} />
    </ul>
    """
  end
end
```

### 4.2 在 Pages 中使用

```elixir
# src/pages/index.ex
defmodule MyApp.Pages.Index do
  use Nex.Page
  alias MyApp.Partials.Todos.Item, as: TodoItem

  def render(assigns) do
    ~H"""
    <div>
      <TodoItem.todo_list todos={@todos} />
    </div>
    """
  end
end
```

### 4.3 Nex.Partial 模块

```elixir
defmodule Nex.Partial do
  defmacro __using__(_opts) do
    quote do
      import Phoenix.Component, only: [sigil_H: 2]
    end
  end
end
```

## 5. API 规范（JSON）

### 5.1 路由规则

```
src/api/todos/index.ex  → GET/POST /api/todos
src/api/todos/[id].ex   → GET/PATCH/DELETE /api/todos/:id
```

函数名 = HTTP 方法：`get/2`, `post/2`, `patch/2`, `delete/2`

### 5.2 示例

```elixir
# src/api/todos/index.ex
defmodule MyApp.Api.Todos.Index do
  use Nex.Api

  def get(conn, _params) do
    todos = fetch_todos()
    json(conn, %{data: todos})
  end

  def post(conn, params) do
    case create_todo(params) do
      {:ok, todo} -> json(conn, %{data: todo}, status: 201)
      {:error, err} -> json(conn, %{error: err}, status: 422)
    end
  end
end

# src/api/todos/[id].ex
defmodule MyApp.Api.Todos.Id do
  use Nex.Api

  def get(conn, %{"id" => id}) do
    todo = get_todo!(id)
    json(conn, %{data: todo})
  end

  def patch(conn, %{"id" => id} = params) do
    todo = update_todo!(id, params)
    json(conn, %{data: todo})
  end

  def delete(conn, %{"id" => id}) do
    delete_todo!(id)
    empty(conn, 204)
  end
end
```

### 5.3 Nex.Api 模块

```elixir
defmodule Nex.Api do
  defmacro __using__(_opts) do
    quote do
      import Nex.Api.Helpers
    end
  end
end

defmodule Nex.Api.Helpers do
  import Plug.Conn

  def json(conn, data, opts \\ []) do
    status = Keyword.get(opts, :status, 200)
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end

  def empty(conn, status \\ 204) do
    send_resp(conn, status, "")
  end

  def error(conn, message, status \\ 400) do
    json(conn, %{error: message}, status: status)
  end
end
```

## 6. 路由编译

### 6.1 Pages 路由发现

```elixir
defmodule Nex.Router.Compiler do
  def discover_pages do
    "src/pages"
    |> Path.join("**/*.ex")
    |> Path.wildcard()
    |> Enum.flat_map(&parse_page_file/1)
  end

  defp parse_page_file(path) do
    module = path_to_module(path)
    base_path = file_to_route_path(path, "src/pages")
    
    routes = []
    
    # render/1 → GET
    if function_exported?(module, :render, 1) do
      routes = [{:get, base_path, module, :render} | routes]
    end
    
    # 其他公开函数 → POST
    module.__info__(:functions)
    |> Enum.filter(fn {name, arity} -> 
      arity == 2 and name not in [:mount, :render]
    end)
    |> Enum.each(fn {name, _} ->
      routes = [{:post, "/#{name}", module, name} | routes]
    end)
    
    routes
  end

  defp file_to_route_path(path, base) do
    path
    |> String.replace_prefix(base, "")
    |> String.replace_suffix(".ex", "")
    |> String.replace("/index", "")
    |> String.replace(~r/\[([^\]]+)\]/, ":\\1")
    |> case do
      "" -> "/"
      p -> p
    end
  end
end
```

### 6.2 API 路由发现

```elixir
defp discover_api do
  "src/api"
  |> Path.join("**/*.ex")
  |> Path.wildcard()
  |> Enum.flat_map(&parse_api_file/1)
end

defp parse_api_file(path) do
  module = path_to_module(path)
  route_path = file_to_route_path(path, "src/api") |> prefix("/api")
  
  [:get, :post, :put, :patch, :delete]
  |> Enum.filter(&function_exported?(module, &1, 2))
  |> Enum.map(fn method -> {method, route_path, module, method} end)
end
```

## 7. 请求处理流程

### 7.1 Page GET 请求

```
1. GET / → 匹配 Pages.Index
2. 调用 mount(conn, params) → 返回 assigns
3. 调用 render(assigns) → 返回 HEEx
4. 包装 Layout → 返回完整 HTML
```

### 7.2 Page POST 请求（HTMX）

```
1. POST /create_todo → 匹配 Pages.Index.create_todo
2. 调用 create_todo(conn, params)
3. 返回 HTML 片段（无 Layout）
```

### 7.3 API 请求

```
1. GET /api/todos → 匹配 Api.Todos.Index.get
2. 调用 get(conn, params)
3. 返回 JSON
```

## 8. Handler 实现

```elixir
defmodule Nex.Handler do
  import Plug.Conn

  def handle_page_render(conn, module) do
    params = fetch_params(conn)
    
    assigns = if function_exported?(module, :mount, 2) do
      module.mount(conn, params)
    else
      %{}
    end
    
    content = module.render(assigns)
    
    html = MyApp.Layouts.render(%{
      inner_content: content,
      title: assigns[:title] || "Nex App"
    })
    
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, Phoenix.HTML.Safe.to_iodata(html) |> IO.iodata_to_binary())
  end

  def handle_page_action(conn, module, action) do
    params = fetch_params(conn)
    apply(module, action, [conn, params])
  end

  def handle_api(conn, module, method) do
    params = fetch_params(conn)
    apply(module, method, [conn, params])
  end
end
```

## 9. 依赖

```elixir
def deps do
  [
    {:bandit, "~> 1.5"},
    {:plug, "~> 1.15"},
    {:phoenix_html, "~> 4.1"},
    {:phoenix_live_view, "~> 0.20"},  # 仅用于 ~H sigil
    {:jason, "~> 1.4"},
    {:dotenvy, "~> 0.8"}
  ]
end
```

## 10. 设计决策摘要

| 问题 | 决策 |
|-----|------|
| Pages 路由 | `render/1` = GET，其他函数 = POST |
| Partials | 纯组件，无 HTTP 路由 |
| API | 函数名 = HTTP 方法 |
| HTMX 处理 | 在 Page 文件中定义，POST 调用 |
| 组件复用 | Partials 被 Pages import |

---

## 下一步

实现框架核心：
1. `Nex.Router` — 路由分发
2. `Nex.Handler` — 请求处理
3. `mix nex.dev` — 开发服务器
