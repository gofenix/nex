锐评一下：# Nex Framework 技术设计文档

## 1. 设计哲学

Nex 是一个激进极简主义的 Elixir Web 框架。

### 核心理念

- **消除样板代码**：无 JS，无 node_modules
- **HTMX 驱动交互**：无客户端状态管理，纯服务端渲染
- **HEEx 模板引擎**：无 JSX 或 EEx 等模板语言
- **无路由管理**：文件即路由，每个文件就是一个路由，文件路径就是路由路径
- **环境隔离**：`.env` 文件管理环境变量

### 核心优势

```
┌─────────────────────────────────────────────────────┐
│                    Browser (HTMX)                    │
└─────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│                    Nex Server                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
│  │   Pages     │  │ Components  │  │     API      │  │
│  └─────────────┘  └─────────────┘  └─────────────┘  │
│         │                │                │         │
│         └────────────────┼────────────────┘         │
│                          ▼                          │
│              ┌─────────────────────┐                │
│              │   Nex.Core.Router   │                │
│              └─────────────────────┘                │
│                          │                          │
│                          ▼                          │
│              ┌─────────────────────┐                │
│              │      Bandit         │                │
│              └─────────────────────┘                │
└─────────────────────────────────────────────────────┘
```

## 2. 项目结构

```
my_app/
├── mix.exs                 # 项目配置
├── .env                    # 环境变量（所有配置）
├── src/                    # 业务代码根目录
│   ├── pages/              # 页面路由（返回完整 HTML，带 Layout）
│   │   ├── index.ex        # → GET /
│   │   ├── about.ex        # → GET /about
│   │   └── todos/
│   │       └── [id].ex     # → GET /todos/:id
│   ├── api/                # JSON API
│   │   └── todos/
│   │       ├── index.ex    # → GET/POST /api/todos
│   │       └── [id].ex     # → GET/PATCH/DELETE /api/todos/:id
│   └── partials/           # HTML 片段（HTMX 端点 + 可复用组件）
│       └── todos/
│           ├── list.ex     # → GET /partials/todos/list
│           ├── item.ex     # → GET /partials/todos/item (也可作为组件复用)
│           └── [id]/
│               ├── toggle.ex # → PATCH /partials/todos/:id/toggle
│               └── delete.ex # → DELETE /partials/todos/:id/delete
├── priv/                   # 私有资源
│   └── static/             # 静态资源（CSS、JS、图片等）
└── layouts.ex              # 根布局（HTML 骨架、HTMX、Tailwind）
```

### 自动路由发现

Nex 采用**文件即路由**设计，无需手动注册。

| 目录 | 返回类型 | 函数签名 | 说明 |
|-----|---------|---------|------|
| `pages/` | 完整 HTML | `render/1` | 带 Layout 的页面 |
| `api/` | JSON | `get/2`, `post/2`... | 纯数据 API |
| `partials/` | HTML 片段 | `get/3`, `post/3`... | HTMX 端点 + 可复用组件 |

**路由映射规则**：
- 文件路径 = URL 路径（无需 `route.ex`，文件名即路由）
- `[param]` 目录/文件 = 动态参数（如 `[id].ex` → `:id`）
- `[...param]` = Catch-all 参数
- 函数名 = HTTP 方法（`get`, `post`, `patch`, `delete`）

**Partials 双重身份**：
- 作为 **HTTP 端点**：被 HTMX 请求调用
- 作为 **组件**：被其他模块 import 调用

**注意**：
- `api/` 函数是 **2 参数**（`conn`, `params`）
- `partials/` 函数是 **3 参数**（`conn`, `params`, `assigns`）

### 环境配置

Nex 不使用 `config/` 目录下的配置文件，所有配置通过 `.env` 文件管理。

**`.env` 文件示例**：
```bash
# 数据库配置
DATABASE_URL=postgresql://user:pass@localhost/my_app
DB_POOL_SIZE=10

# Redis 配置
REDIS_URL=redis://localhost:6379

# 应用配置
PORT=4000
HOST=localhost
SECRET_KEY=your-secret-key-here

# 外部服务
API_BASE_URL=https://api.example.com
```

**在代码中获取配置**：
```elixir
# 基础用法
port = Nex.Env.get(:PORT, 4000)
host = Nex.Env.get(:HOST, "localhost")

# 带类型转换
pool_size = Nex.Env.get(:DB_POOL_SIZE, 10) |> String.to_integer()

# 必需配置（未设置时抛出异常）
database_url = Nex.Env.get!(:DATABASE_URL)
```

**环境隔离**：
```bash
# .env.development（开发环境）
DATABASE_URL=postgresql://dev:dev@localhost/my_app_dev

# .env.production（生产环境）
DATABASE_URL=postgresql://prod:prod@myapp.internal/my_app_prod
```

## 3. 函数类型定义

Nex 框架定义了三类核心函数，每类都有明确的职责和签名规范。

### 3.1 组件函数 (Component Functions)

**用途**：渲染 UI 片段，可在其他组件或页面中调用。

**签名**：
```elixir
def function_name(assigns) do
  ~H"""..."""
end
```

**特征**：
- 参数是 `assigns` 映射
- 返回 HEEx 模板字符串
- 可以使用 `:if`、`:for` 等指令
- 纯展示逻辑，无副作用

**示例**：
```elixir
defmodule MyApp.Components.Card do
  use Nex.View

  def card(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body">
        <h2 class="card-title">{@title}</h2>
        <p>{@body}</p>
        <div class="card-actions justify-end">
          {@actions}
        </div>
      </div>
    </div>
    """
  end

  def button(assigns) do
    ~H"""
    <button class={@class} {@rest}>
      {@content}
    </button>
    """
  end
end
```

### 3.2 事件处理函数 (Event Handlers)

**用途**：处理用户交互（点击、提交表单等），更新状态并返回新 HTML 片段。

**签名**：
```elixir
def function_name(conn, params) do
  {conn, %{updates}}
end
```

**特征**：
- 参数是 `conn` 和 `params`
- 返回 `{conn, assigns}` 元组
- 通过 `@var` 读取当前状态
- 返回值中的 `assigns` 用于更新状态

**示例**：
```elixir
defmodule MyApp.Components.Todo do
  use Nex.View

  def create_todo(conn, params) do
    todo = %{
      id: System.unique_integer([:positive]),
      text: params["text"],
      completed: false
    }
    {conn, %{todos: [todo | @todos]}}
  end

  def toggle_todo(conn, %{id: id}) do
    updated = Enum.map(@todos, fn t ->
      if t.id == id, do: %{t | completed: !t.completed}, else: t
    end)
    {conn, %{todos: updated}}
  end

  def delete_todo(conn, %{id: id}) do
    updated = Enum.filter(@todos, fn t -> t.id != id end)
    {conn, %{todos: updated}}
  end
end
```

### 3.3 Mount 函数 (Initialization)

**用途**：页面加载时初始化状态变量。

**签名**：
```elixir
def mount(conn, params) do
  {conn, %{state}}
end
```

**特征**：
- 页面首次加载时自动调用
- 返回初始状态
- 可以从数据库、API 获取数据
- 接收 URL 参数

**示例**：
```elixir
defmodule MyApp.Pages.Index do
  use Nex.View

  def mount(conn, _params) do
    {conn, %{
      title: "Todo App",
      todos: [],
      filter: "all"
    }}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>{@title}</h1>
      <.todo_list todos={@todos} />
    </div>
    """
  end
end
```

## 4. 组件调用规范

### 4.1 同文件内调用

使用 `<.component_name />` 语法调用同一模块内的组件：

```elixir
defmodule MyApp.Components.Card do
  use Nex.View

  def card(assigns) do
    ~H"""
    <div class="card">
      <div class="card-header">
        {@title}
      </div>
      <div class="card-body">
        <.card_content content={@content} />
      </div>
      <div class="card-footer">
        {@actions}
      </div>
    </div>
    """
  end

  def card_content(assigns) do
    ~H"""<div class="content">{@content}</div>"""
  end
end
```

### 4.2 跨文件调用

使用完整模块路径调用其他模块的组件：

```elixir
defmodule MyApp.Pages.Index do
  use Nex.View

  def render(assigns) do
    ~H"""
    <div class="container">
      <MyApp.Components.Header.header />
      <MyApp.Components.Todo.todo_list todos={@todos} />
    </div>
    """
  end
end
```

### 4.3 组件组合示例

```elixir
defmodule MyApp.Components.Todo do
  use Nex.View

  def todo_list(assigns) do
    ~H"""
    <div id="todo-container">
      <MyApp.Components.TodoIntro.intro />
      <form hx-post="/api/todos" hx-target="#todo-list">
        <input name="text" required />
        <button type="submit">添加</button>
      </form>
      <ul id="todo-list">
        <.todo_item :for={todo <- @todos} todo={todo} />
      </ul>
    </div>
    """
  end

  def todo_item(assigns) do
    ~H"""
    <li id={"todo-#{@todo.id}"}>
      <input type="checkbox"
             checked={@todo.completed}
             hx-patch={"/api/todos/#{@todo.id}/toggle"}
             hx-target={"#todo-#{@todo.id}"}
             hx-swap="outerHTML" />
      <span class={if @todo.completed, do: "line-through"}>
        {@todo.text}
      </span>
      <button hx-delete={"/api/todos/#{@todo.id}"}
              hx-target={"#todo-#{@todo.id}"}
              hx-swap="outerHTML">
        删除
      </button>
    </li>
    """
  end
end
```

## 5. 文件即路由

### 5.1 页面路由 (`pages/`)

`pages/` 目录下的每个文件对应一个页面路由，文件路径即为路由路径。

```
src/pages/index.ex           → GET /
src/pages/about.ex           → GET /about
src/pages/posts/index.ex     → GET /posts
src/pages/posts/show.ex      → GET /posts/:id
```

**页面文件模板**：
```elixir
defmodule MyApp.Pages.Index do
  use Nex.View

  def mount(conn, params) do
    {conn, %{
      title: "首页",
      data: fetch_data(params)
    }}
  end

  def render(assigns) do
    ~H"""
    <div class="page">
      <h1>{@title}</h1>
      {@data}
    </div>
    """
  end

  defp fetch_data(params) do
    # 初始化逻辑
  end
end
```

### 5.2 API 路由 (`api/`)

`api/` 目录下的每个函数对应一个 HTTP 路由，函数名即为路由路径。

```
src/api/todos.ex → POST /todos (create_todo 函数)
                 → GET /todos (list_todos 函数)

src/api/todos.ex → PATCH /todos/:id/toggle (toggle_todo 函数)
                 → DELETE /todos/:id (delete_todo 函数)
```

**API 文件模板**：
```elixir
defmodule MyApp.Api.Todos do
  use Nex.View

  def list_todos(conn, params) do
    todos = Database.all(:todos)
    {conn, %{todos: todos}}
  end

  def create_todo(conn, params) do
    todo = insert_todo(params)
    {conn, %{todo: todo}}
  end

  def toggle_todo(conn, %{id: id}) do
    todo = update_todo(id, completed: !current_status(id))
    {conn, %{todo: todo}}
  end

  def delete_todo(conn, %{id: id}) do
    delete_todo(id)
    {conn, %{}}
  end

  defp insert_todo(params) do
    # 插入逻辑
  end
end
```

## 6. HEEx 模板语法

Nex 使用 HEEx (HTML-embedded Elixir) 作为模板语言。

### 6.1 变量插入

```elixir
<h1>{@title}</h1>
<p>{@description}</p>
<span class={@class_name}>内容</span>
```

### 6.2 条件渲染

```elixir
<div :if={@visible}>显示内容</div>
<div :if={@count > 0}>有 {@count} 项</div>
<div :if={@error != nil} class="error">{@error}</div>
```

### 6.3 循环渲染

```elixir
<ul>
  <li :for={item <- @items}>{item.name}</li>
</ul>

<table>
  <tr :for={user <- @users}>
    <td>{user.name}</td>
    <td>{user.email}</td>
  </tr>
</table>
```

### 6.4 动态属性

```elixir
<div id={"item-#{@id}"}>...</div>
<input class={if @active, do: "active", else: ""} />
<button disabled={@disabled}>点击</button>
<a href={"/posts/#{@post.id}">{@post.title}</a>
```

### 6.5 事件属性

```elixir
<button hx-post="/api/submit" hx-target="#result">
  提交
</button>

<form hx-post="/api/todos"
     hx-target="#todo-list"
     hx-swap="beforeend">
  <input type="text" name="text" required />
  <button type="submit">添加</button>
</form>
```

## 7. HTMX 集成

### 7.1 基本交互模式

| 交互类型 | HTMX 属性 | 示例 |
|---------|----------|------|
| 点击加载 | `hx-get` | `<button hx-get="/api/data">加载</button>` |
| 表单提交 | `hx-post` | `<form hx-post="/api/todos">...</form>` |
| 部分更新 | `hx-patch` | `<input hx-patch="/api/items/#{@id}">` |
| 删除 | `hx-delete` | `<button hx-delete="/api/items/#{@id}">` |

### 7.2 目标与交换

```elixir
# 指定更新目标
hx-target="#result"           # ID 选择
hx-target="closest .card"     # 最近父元素
hx-target="this"              # 自身

# 交换模式
hx-swap="innerHTML"           # 替换内容（默认）
hx-swap="outerHTML"           # 替换自身
hx-swap="beforeend"           # 插入末尾（新增列表项）
hx-swap="afterbegin"          # 插入开头
hx-swap="none"                # 不替换
```

### 7.3 完整示例

```elixir
defmodule MyApp.Components.TodoItem do
  use Nex.View

  def todo_item(assigns) do
    ~H"""
    <li id={"todo-#{@todo.id}"} class={if @todo.completed, do: "completed"}>
      <input type="checkbox"
             checked={@todo.completed}
             hx-patch={"/api/todos/#{@todo.id}/toggle"}
             hx-target={"#todo-#{@todo.id}"}
             hx-swap="outerHTML" />
      <span>{@todo.text}</span>
      <button class="btn-delete"
              hx-delete={"/api/todos/#{@todo.id}"}
              hx-target={"#todo-#{@todo.id}"}
              hx-swap="outerHTML"
              hx-confirm="确定删除?">
        删除
      </button>
    </li>
    """
  end
end
```

## 8. 布局系统

### 8.1 根布局 (`layouts.ex`)

根布局定义页面的 HTML 结构，包含 `<head>`、HTMX 引入、Tailwind CSS 等。

```elixir
defmodule MyApp.Layouts do
  use Nex.View

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="zh-CN">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>{@title}</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <script src="https://unpkg.com/htmx.org@1.9.10"></script>
      </head>
      <body class="bg-gray-100">
        {@inner_content}
      </body>
    </html>
    """
  end
end
```

### 8.2 页面布局

页面使用 Layouts 模块：

```elixir
defmodule MyApp.Pages.Index do
  use Nex.View

  def mount(conn, _params) do
    {conn, %{
      title: "我的应用"
    }}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-4">
      <h1 class="text-2xl font-bold">{@title}</h1>
      <p>欢迎使用 Nex 框架！</p>
    </div>
    """
  end
end
```

## 9. 状态管理

### 9.1 本地状态

状态通过 `mount/2` 初始化，通过事件处理函数更新。

```elixir
defmodule MyApp.Pages.Todos do
  use Nex.View

  def mount(conn, _params) do
    {conn, %{
      todos: [],
      filter: "all",
      new_todo: ""
    }}
  end

  def add_todo(conn, params) do
    todo = %{
      id: System.unique_integer([:positive]),
      text: params["text"],
      completed: false
    }
    {conn, %{todos: [@todo | @todos]}}
  end

  def filter_todos(conn, %{filter: filter}) do
    {conn, %{filter: filter}}
  end
end
```

### 9.2 状态访问

在组件和事件处理函数中，通过 `@var` 访问当前状态：

```elixir
def todo_list(assigns) do
  ~H"""
  <div>
    <form>
      <input name="filter"
             value={@filter}
             hx-get="/api/filter"
             hx-trigger="keyup changed" />
    </form>
    <ul>
      <.todo_item :for={todo <- filtered_todos(@todos, @filter)} todo={todo} />
    </ul>
  </div>
  """
end

defp filtered_todos(todos, filter) do
  case filter do
    "completed" -> Enum.filter(todos, & &1.completed)
    "active" -> Enum.reject(todos, & &1.completed)
    _ -> todos
  end
end
```

## 10. 最佳实践

### 10.1 组件设计原则

- **单一职责**：每个组件只负责一个 UI 片段
- **可复用性**：避免硬编码内容，使用 props 传递
- **组合优于继承**：通过组件嵌套实现复杂 UI

### 10.2 状态管理原则

- **状态本地化**：相关状态放在同一模块
- **最小化状态**：只存储必要的状态
- **不可变更新**：使用函数式更新模式

### 10.3 性能优化

- **减少 DOM 交换**：使用 `hx-swap="none"` 避免不必要的更新
- **使用增量更新**：列表新增使用 `hx-swap="beforeend"`
- **懒加载**：按需加载组件和数据

### 10.4 代码组织

```
src/
├── pages/                  # 页面路由
│   ├── index.ex           # 首页
│   ├── todos/             # 多个文件可同名
│   │   ├── index.ex
│   │   └── show.ex
│   └── posts/
│       └── index.ex
├── components/            # 可复用组件
│   ├── ui/                # 基础 UI 组件
│   │   ├── button.ex
│   │   ├── modal.ex
│   │   └── card.ex
│   └── todos/             # 业务组件
│       ├── todo_item.ex
│       └── todo_list.ex
└── api/                   # API 路由
    ├── todos.ex
    └── posts.ex
```

## 11. 快速开始

### 11.1 创建项目

```bash
mix new my_app
cd my_app
```

### 11.2 添加依赖

```elixir
def deps do
  [
    {:bandit, "~> 1.5"},
    {:tailwind, "~> 0.2", runtime: Mix.env() == :dev}
  ]
end
```

### 11.3 创建目录结构

```bash
mkdir -p src/pages src/components src/api priv/static
```

### 11.4 编写页面

创建 `src/pages/index.ex`：

```elixir
defmodule MyApp.Pages.Index do
  use Nex.View

  def mount(conn, _params) do
    {conn, %{
      title: "欢迎",
      message: "Hello, Nex!"
    }}
  end

  def render(assigns) do
    ~H"""
    <div class="container">
      <h1>{@title}</h1>
      <p>{@message}</p>
    </div>
    """
  end
end
```

### 11.5 运行

```bash
mix deps.get
mix run --no-halt
```

访问 `http://localhost:4000` 查看效果。


# 框架开发应该怎么做

是采用哪种方式组织项目会更好？

问题1，这种怎么样？
- framework
    - lib/
    - mix.exs
    - README.md
- examples
    - todos
        - src/
        - mix.exs
        - README.md
    - blog
        - src/
        - mix.exs
        - README.md

问题2：怎么开发框架的同时，又能验证框架的正确性？
实际开发的时候，我们需要在framework里面编写好代码，mix compile并生成一个可执行文件，然后在examples的项目中，通过mix nex.dev启动吗？
我们需要在mix.exs里面，显示的声明nex的依赖，然后通过mix nex.dev启动？这个原理我不知道，他是本地的deps触发执行的，还是通过全局local hex触发执行的？


# 问题

既然我们想不清楚partial的路由，那就直接简单一些。

pages 就是页面路由
    里面就是render函数，通过hx-post="/xxx函数"来触发获取
partials 就是htmx的片段

api 就是json api

我们先实现这个mvp，再说其他的


# 你的todos项目实现有问题

我在之前强调过，在todos里面，逻辑代码都是在src里面，包括layout.ex也是，这个是很关键的。
你放在了lib中，这个不可接受

你要怎么对待partials中的代码，现在我看还没有任何的实现。

所以，在你的理解里面

<.todo_item todo={@todo} /> 是同一个模块的

<xxx.todo_item.render(assign) /> 是跨模块的。

但是，我们都已经通过alias Todos.Partials.Todos.Item, as: todo_item
来实现跨模块的调用，那么也应该采用
<.todo_item todo={@todo} /> ，只不过 Nex 框架帮你自动处理了 alias 的问题。