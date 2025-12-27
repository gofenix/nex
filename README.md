# Nex

**A minimalist Elixir web framework powered by HTMX.**

Nex 是一个极简主义的 Elixir Web 框架，专注于服务端渲染和 HTMX 驱动的交互。无需 JavaScript 构建工具，无需复杂的前端框架，只需要 Elixir 和 HEEx 模板。

## 核心理念

- **极简** — 最少的概念，最少的样板代码
- **服务端优先** — 状态和渲染都在服务端，HTMX 处理交互
- **文件即路由** — 文件路径就是 URL 路径，无需手动注册
- **零 JS 构建** — 不需要 Node.js、Webpack、Vite 等

## 快速开始

### 1. 创建项目

```bash
mix new my_app
cd my_app
```

### 2. 添加依赖

```elixir
# mix.exs
defp deps do
  [
    {:nex, path: "../nex/framework"}  # 或发布后使用 {:nex, "~> 0.1"}
  ]
end
```

### 3. 配置项目

```elixir
# mix.exs
def project do
  [
    # ...
    elixirc_paths: ["lib", "src"]  # 添加 src 目录
  ]
end
```

### 4. 创建页面

```elixir
# src/pages/index.ex
defmodule MyApp.Pages.Index do
  use Nex.Page

  def mount(_params) do
    %{title: "Home"}
  end

  def render(assigns) do
    ~H"""
    <h1>Hello, Nex!</h1>
    """
  end
end
```

### 5. 创建布局

```elixir
# src/layouts.ex
defmodule MyApp.Layouts do
  use Nex.Page

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html>
      <head>
        <title>{@title}</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <script src="https://unpkg.com/htmx.org@2.0.4"></script>
      </head>
      <body>
        {raw(@inner_content)}
      </body>
    </html>
    """
  end
end
```

### 6. 启动开发服务器

```bash
mix nex.dev
```

访问 http://localhost:4000

---

## 项目结构

```
my_app/
├── src/
│   ├── pages/          # 页面模块 (GET 渲染, POST 处理 HTMX)
│   │   ├── index.ex    # → GET /
│   │   ├── about.ex    # → GET /about
│   │   └── todos/
│   │       └── [id].ex # → GET /todos/:id
│   ├── api/            # JSON API 模块
│   │   └── todos/
│   │       └── index.ex # → GET/POST /api/todos
│   ├── partials/       # 可复用组件 (无路由)
│   │   └── todos/
│   │       └── item.ex
│   └── layouts.ex      # 根布局
├── mix.exs
└── .env                # 环境变量 (可选)
```

---

## 核心概念

### Pages (页面)

页面模块处理 HTTP 请求，渲染 HTML。

```elixir
defmodule MyApp.Pages.Index do
  use Nex.Page

  # GET 请求时调用，返回初始数据
  def mount(params) do
    %{
      title: "Todo App",
      todos: Nex.Store.get(:todos, [])
    }
  end

  # 渲染 HEEx 模板
  def render(assigns) do
    ~H"""
    <h1>{@title}</h1>
    <ul>
      <li :for={todo <- @todos}>{todo.text}</li>
    </ul>
    """
  end

  # HTMX POST 处理器: POST /create_todo
  def create_todo(%{"text" => text}) do
    todo = %{id: unique_id(), text: text}
    Nex.Store.update(:todos, [], &[todo | &1])
    ~H"<li>{todo.text}</li>"
  end

  # 返回空响应
  def delete_todo(%{"id" => id}) do
    Nex.Store.update(:todos, [], &Enum.reject(&1, fn t -> t.id == id end))
    :empty
  end
end
```

#### 路由规则

| 文件路径 | URL |
|---------|-----|
| `src/pages/index.ex` | `GET /` |
| `src/pages/about.ex` | `GET /about` |
| `src/pages/todos/index.ex` | `GET /todos` |
| `src/pages/todos/[id].ex` | `GET /todos/:id` |

#### Action 返回值

| 返回值 | HTTP 响应 |
|-------|----------|
| `~H"<div>...</div>"` | 200 + HTML 片段 |
| `:empty` | 200 + 空响应 |
| `{:redirect, "/path"}` | HX-Redirect 头 |
| `{:refresh, _}` | HX-Refresh 头 |

---

### API (JSON 接口)

API 模块返回 JSON 数据。

```elixir
defmodule MyApp.Api.Todos.Index do
  use Nex.Api

  # GET /api/todos
  def get do
    %{data: Nex.Store.get(:todos, [])}
  end

  # POST /api/todos
  def post(%{"text" => text}) do
    todo = %{id: unique_id(), text: text}
    Nex.Store.update(:todos, [], &[todo | &1])
    {201, %{data: todo}}
  end

  # 错误处理
  def post(%{"text" => ""}) do
    {:error, 400, "text is required"}
  end
end
```

#### 返回值

| 返回值 | HTTP 响应 |
|-------|----------|
| `%{data: ...}` | 200 + JSON |
| `{201, %{data: ...}}` | 201 + JSON |
| `{:error, 400, "message"}` | 400 + `{"error": "message"}` |
| `:empty` | 204 No Content |

---

### Partials (组件)

可复用的 UI 组件，没有 HTTP 路由。

```elixir
# src/partials/todos/item.ex
defmodule MyApp.Partials.Todos.Item do
  use Nex.Partial

  def todo_item(assigns) do
    ~H"""
    <li id={"todo-#{@todo.id}"}>
      <span>{@todo.text}</span>
      <button hx-post="/delete_todo"
              hx-vals={Jason.encode!(%{id: @todo.id})}
              hx-target={"#todo-#{@todo.id}"}
              hx-swap="outerHTML">
        删除
      </button>
    </li>
    """
  end
end
```

在 Page 中使用：

```elixir
defmodule MyApp.Pages.Index do
  use Nex.Page
  import MyApp.Partials.Todos.Item

  def render(assigns) do
    ~H"""
    <ul>
      <.todo_item :for={todo <- @todos} todo={todo} />
    </ul>
    """
  end
end
```

---

### Store (状态管理)

`Nex.Store` 提供页面级的内存状态管理，类似 React/Vue 的 state。

```elixir
# 读取状态
todos = Nex.Store.get(:todos, [])

# 写入状态
Nex.Store.put(:todos, [todo | todos])

# 更新状态
Nex.Store.update(:todos, [], fn todos -> [todo | todos] end)

# 删除状态
Nex.Store.delete(:todos)
```

#### 特性

- **页面隔离** — 每个页面视图有独立的状态
- **刷新即清空** — 刷新页面状态重置（类似 React）
- **自动清理** — 1 小时后自动清理过期状态
- **跨请求共享** — 同一页面的 HTMX 请求共享状态

---

### Layouts (布局)

根布局包装所有页面内容。

```elixir
# src/layouts.ex
defmodule MyApp.Layouts do
  use Nex.Page

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html>
      <head>
        <title>{@title}</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <script src="https://unpkg.com/htmx.org@2.0.4"></script>
      </head>
      <body class="bg-gray-100">
        <nav>...</nav>
        <main>
          {raw(@inner_content)}
        </main>
        <footer>...</footer>
      </body>
    </html>
    """
  end
end
```

**注意**: 使用 `{raw(@inner_content)}` 插入页面内容，因为内容已经是 HTML。

---

## HTMX 集成

Nex 天然支持 HTMX。页面模块中的函数可以直接处理 HTMX 请求。

### 示例：添加 Todo

```html
<form hx-post="/create_todo"
      hx-target="#todo-list"
      hx-swap="beforeend">
  <input name="text" />
  <button type="submit">添加</button>
</form>

<ul id="todo-list">
  <!-- todos 会被插入这里 -->
</ul>
```

```elixir
# POST /create_todo 会调用这个函数
def create_todo(%{"text" => text}) do
  todo = %{id: unique_id(), text: text}
  Nex.Store.update(:todos, [], &[todo | &1])
  ~H"<li>{todo.text}</li>"  # 返回 HTML 片段
end
```

### 示例：删除 Todo

```html
<button hx-post="/delete_todo"
        hx-vals='{"id": 123}'
        hx-target="#todo-123"
        hx-swap="outerHTML">
  删除
</button>
```

```elixir
def delete_todo(%{"id" => id}) do
  Nex.Store.update(:todos, [], &Enum.reject(&1, fn t -> t.id == id end))
  :empty  # 返回空，元素被移除
end
```

---

## 环境变量

Nex 自动加载 `.env` 和 `.env.{MIX_ENV}` 文件。

```bash
# .env
PORT=4000
DATABASE_URL=postgres://localhost/myapp
```

```elixir
# 使用
port = Nex.Env.get(:PORT, "4000")
port = Nex.Env.get_integer(:PORT, 4000)
debug = Nex.Env.get_boolean(:DEBUG, false)
```

---

## 开发服务器

```bash
# 启动开发服务器
mix nex.dev

# 指定端口
mix nex.dev --port 3000
```

### 特性

- **热重载** — 修改 `.ex` 文件自动重新编译
- **Live Reload** — 编译后浏览器自动刷新
- **错误页面** — 友好的 404/500 错误页面

---

## 错误处理

Nex 提供统一的错误处理：

- **404** — 页面/API 不存在
- **500** — 代码异常（开发环境显示堆栈）
- **HTMX 错误** — 返回红色错误提示框

---

## 完整示例

查看 `examples/todos` 目录获取完整的 Todo 应用示例。

```bash
cd examples/todos
mix deps.get
mix nex.dev
```

---

## 与其他框架对比

| 特性 | Nex | Phoenix | Phoenix LiveView |
|-----|-----|---------|------------------|
| 学习曲线 | 低 | 中 | 高 |
| 实时交互 | HTMX | 需要 JS | WebSocket |
| 状态管理 | Nex.Store | 自行实现 | Socket assigns |
| 文件路由 | ✅ | ❌ | ❌ |
| JS 构建 | ❌ | 可选 | 需要 |

---

## 设计哲学

1. **约定优于配置** — 文件路径即路由，无需配置
2. **显式优于隐式** — 函数参数清晰，返回值明确
3. **组合优于继承** — 使用 `use` 和 `import` 组合功能
4. **服务端优先** — 状态在服务端，HTMX 处理交互

---

## License

MIT
