# 路由

Nex 采用**文件即路由**的设计，文件路径直接映射为 URL 路径，无需手动配置路由表。

## 基本规则

### Pages 路由

| 文件路径 | URL | HTTP 方法 |
|---------|-----|----------|
| `src/pages/index.ex` | `/` | GET |
| `src/pages/about.ex` | `/about` | GET |
| `src/pages/contact.ex` | `/contact` | GET |
| `src/pages/blog/index.ex` | `/blog` | GET |
| `src/pages/blog/[slug].ex` | `/blog/:slug` | GET |

### API 路由

| 文件路径 | URL | HTTP 方法 |
|---------|-----|----------|
| `src/api/todos/index.ex` | `/api/todos` | GET, POST, PUT, DELETE |
| `src/api/users/[id].ex` | `/api/users/:id` | GET, POST, PUT, DELETE |

### Partials

`src/partials/` 目录下的文件**没有路由**，它们是纯组件。

## 动态路由

使用方括号 `[]` 定义动态参数：

### 单参数

```
src/pages/users/[id].ex → /users/:id
```

```elixir
# src/pages/users/[id].ex
defmodule MyApp.Pages.Users.Id do
  use Nex.Page

  def mount(params) do
    user_id = params["id"]  # 从 URL 获取 id
    user = fetch_user(user_id)
    %{title: user.name, user: user}
  end
end
```

访问 `/users/123` 时，`params["id"]` 的值为 `"123"`。

### 多级动态路由

```
src/pages/blog/[year]/[month]/[slug].ex → /blog/:year/:month/:slug
```

```elixir
def mount(params) do
  year = params["year"]
  month = params["month"]
  slug = params["slug"]
  # ...
end
```

### 捕获所有路由

使用 `[...param]` 捕获剩余路径：

```
src/pages/docs/[...path].ex → /docs/*path
```

```elixir
def mount(params) do
  path = params["path"]  # 例如 "guide/getting-started"
  # ...
end
```

访问 `/docs/guide/getting-started` 时，`params["path"]` 的值为 `"guide/getting-started"`。

## Index 路由

`index.ex` 文件对应目录的根路径：

| 文件 | URL |
|-----|-----|
| `src/pages/index.ex` | `/` |
| `src/pages/blog/index.ex` | `/blog` |
| `src/api/todos/index.ex` | `/api/todos` |

## Action 路由

页面模块中的函数可以处理 POST 请求：

```elixir
# src/pages/index.ex
defmodule MyApp.Pages.Index do
  use Nex.Page

  # GET / → 渲染页面
  def render(assigns), do: ~H"..."

  # POST /create_todo → 调用此函数
  def create_todo(params), do: ...

  # POST /delete_todo → 调用此函数
  def delete_todo(params), do: ...
end
```

### Action 路由规则

| POST URL | 调用的函数 |
|----------|----------|
| `POST /create_todo` | `Index.create_todo/1` |
| `POST /todos/toggle` | `Todos.Index.toggle/1` |
| `POST /todos/123/delete` | `Todos.Id.delete/1` |

## 路由优先级

当多个路由可能匹配时，按以下优先级：

1. **精确匹配** — `about.ex` 优先于 `[slug].ex`
2. **Index 文件** — `todos/index.ex` 优先于 `todos.ex`
3. **动态路由** — `[id].ex` 最后匹配

示例：

```
src/pages/
├── blog/
│   ├── index.ex      # /blog (优先)
│   ├── new.ex        # /blog/new (精确匹配优先)
│   └── [slug].ex     # /blog/:slug (动态路由)
```

访问 `/blog/new` 会匹配 `new.ex`，而不是 `[slug].ex`。

## API 方法映射

API 模块根据 HTTP 方法调用对应函数：

```elixir
# src/api/todos/index.ex
defmodule MyApp.Api.Todos.Index do
  use Nex.Api

  def get, do: ...      # GET /api/todos
  def post(params), do: ...    # POST /api/todos
  def put(params), do: ...     # PUT /api/todos
  def delete(params), do: ...  # DELETE /api/todos
end
```

### 带参数和不带参数

API 函数可以有 0 个或 1 个参数：

```elixir
# 不需要参数
def get do
  %{data: fetch_all()}
end

# 需要参数
def get(params) do
  page = params["page"] || "1"
  %{data: fetch_page(page)}
end
```

框架会自动选择正确的函数版本。

## 查询参数

查询参数通过 `params` 传递：

```
GET /todos?page=2&limit=10
```

```elixir
def mount(params) do
  page = params["page"] || "1"
  limit = params["limit"] || "20"
  # ...
end
```

## 下一步

- [Pages](./pages.md) - 页面模块详解
- [API](./api.md) - API 模块详解
