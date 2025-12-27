# 项目结构

Nex 采用约定优于配置的方式组织项目。文件的位置决定了它的功能和路由。

## 目录结构

```
my_app/
├── src/                    # 应用源码
│   ├── pages/              # 页面模块
│   │   ├── index.ex        # → GET /
│   │   ├── about.ex        # → GET /about
│   │   └── todos/
│   │       ├── index.ex    # → GET /todos
│   │       └── [id].ex     # → GET /todos/:id
│   ├── api/                # API 模块
│   │   └── todos/
│   │       └── index.ex    # → GET/POST /api/todos
│   ├── partials/           # 可复用组件
│   │   └── todos/
│   │       └── item.ex     # 无路由，纯组件
│   └── layouts.ex          # 根布局
├── lib/                    # 业务逻辑
│   └── my_app/
│       └── ...
├── priv/                   # 静态资源
│   └── static/
├── mix.exs                 # 项目配置
├── .env                    # 环境变量
└── .env.dev                # 开发环境变量
```

## 目录说明

### `src/pages/`

页面模块目录。每个文件对应一个 URL 路由。

| 文件 | 路由 | 说明 |
|-----|------|------|
| `index.ex` | `/` | 首页 |
| `about.ex` | `/about` | 关于页面 |
| `todos/index.ex` | `/todos` | Todo 列表页 |
| `todos/[id].ex` | `/todos/:id` | Todo 详情页（动态路由） |

页面模块处理两种请求：
- **GET** — 调用 `mount/1` + `render/1` 渲染页面
- **POST** — 调用对应的 action 函数处理 HTMX 请求

### `src/api/`

API 模块目录。返回 JSON 数据。

| 文件 | 路由 | 说明 |
|-----|------|------|
| `todos/index.ex` | `/api/todos` | Todo API |
| `users/[id].ex` | `/api/users/:id` | 用户 API（动态路由） |

API 模块根据 HTTP 方法调用对应函数：
- `get/0` 或 `get/1` — 处理 GET 请求
- `post/1` — 处理 POST 请求
- `put/1` — 处理 PUT 请求
- `delete/1` — 处理 DELETE 请求

### `src/partials/`

可复用组件目录。**没有 HTTP 路由**，只能被其他模块导入使用。

```elixir
# src/partials/todos/item.ex
defmodule MyApp.Partials.Todos.Item do
  use Nex.Partial
  
  def todo_item(assigns) do
    ~H"""
    <li>{@todo.text}</li>
    """
  end
end
```

在页面中使用：

```elixir
import MyApp.Partials.Todos.Item

def render(assigns) do
  ~H"""
  <.todo_item todo={todo} />
  """
end
```

### `src/layouts.ex`

根布局文件。所有页面都会被包装在这个布局中。

```elixir
defmodule MyApp.Layouts do
  use Nex.Page

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html>
      <head>
        <title>{@title}</title>
      </head>
      <body>
        {raw(@inner_content)}
      </body>
    </html>
    """
  end
end
```

### `lib/`

业务逻辑目录。放置与 Web 无关的代码，如：
- 数据库操作
- 业务规则
- 工具函数

### `priv/static/`

静态资源目录（如果需要）。

## 模块命名约定

Nex 根据文件路径自动推断模块名：

| 文件路径 | 模块名 |
|---------|--------|
| `src/pages/index.ex` | `MyApp.Pages.Index` |
| `src/pages/about.ex` | `MyApp.Pages.About` |
| `src/pages/todos/index.ex` | `MyApp.Pages.Todos.Index` |
| `src/pages/todos/[id].ex` | `MyApp.Pages.Todos.Id` |
| `src/api/todos/index.ex` | `MyApp.Api.Todos.Index` |
| `src/partials/todos/item.ex` | `MyApp.Partials.Todos.Item` |

**注意**：模块名必须与文件路径匹配，否则路由无法正确解析。

## 动态路由

使用方括号 `[]` 定义动态路由参数：

| 文件 | 路由 | 参数 |
|-----|------|------|
| `[id].ex` | `/:id` | `params["id"]` |
| `[slug].ex` | `/:slug` | `params["slug"]` |
| `[...path].ex` | `/*path` | `params["path"]`（捕获所有） |

示例：

```elixir
# src/pages/todos/[id].ex
defmodule MyApp.Pages.Todos.Id do
  use Nex.Page

  def mount(params) do
    id = params["id"]
    todo = fetch_todo(id)
    %{title: todo.text, todo: todo}
  end
end
```

## 下一步

- [路由](./routing.md) - 深入了解路由系统
- [Pages](./pages.md) - 页面模块详解
