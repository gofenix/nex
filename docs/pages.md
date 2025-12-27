# Pages

Pages 是 Nex 的核心概念，负责渲染 HTML 页面和处理 HTMX 交互。

## 基本结构

```elixir
defmodule MyApp.Pages.Index do
  use Nex.Page

  def mount(params) do
    %{title: "Home", data: fetch_data()}
  end

  def render(assigns) do
    ~H"""
    <h1>{@title}</h1>
    """
  end
end
```

## 生命周期

### 1. mount/1

当用户访问页面（GET 请求）时，框架首先调用 `mount/1`：

```elixir
def mount(params) do
  %{
    title: "Todo List",
    todos: Nex.Store.get(:todos, []),
    user: params["user"]
  }
end
```

**参数**：
- `params` — 包含 URL 参数和查询参数的 Map

**返回值**：
- 返回一个 Map，作为 `assigns` 传递给 `render/1`

**可选**：如果不需要初始化数据，可以省略 `mount/1`，框架会使用空 Map。

### 2. render/1

`mount/1` 返回后，框架调用 `render/1` 渲染页面：

```elixir
def render(assigns) do
  ~H"""
  <div>
    <h1>{@title}</h1>
    <ul>
      <li :for={todo <- @todos}>{todo.text}</li>
    </ul>
  </div>
  """
end
```

**参数**：
- `assigns` — `mount/1` 返回的 Map，加上框架注入的 `@_page_id`

**返回值**：
- HEEx 模板（`~H` sigil）

## HEEx 模板

Nex 使用 Phoenix 的 HEEx 模板引擎：

### 插值

```heex
<h1>{@title}</h1>
<p>Count: {1 + 1}</p>
```

### 条件渲染

```heex
<div :if={@show}>显示内容</div>

<div :if={@user}>
  欢迎, {@user.name}
</div>
<div :if={!@user}>
  请登录
</div>
```

### 列表渲染

```heex
<ul>
  <li :for={item <- @items}>{item.name}</li>
</ul>

<!-- 带索引 -->
<ul>
  <li :for={{item, index} <- Enum.with_index(@items)}>
    {index + 1}. {item.name}
  </li>
</ul>
```

### 动态属性

```heex
<div class={@class}>...</div>
<div class={"base #{if @active, do: "active"}"}>...</div>
<input disabled={@disabled} />
```

### 组件调用

```heex
<.todo_item todo={todo} />
<.button type="submit">提交</.button>
```

## Action 函数

页面模块可以定义 action 函数来处理 HTMX POST 请求：

```elixir
defmodule MyApp.Pages.Index do
  use Nex.Page

  def render(assigns), do: ~H"..."

  # POST /create_todo
  def create_todo(%{"text" => text}) do
    todo = %{id: unique_id(), text: text}
    Nex.Store.update(:todos, [], &[todo | &1])
    ~H"<li>{todo.text}</li>"
  end

  # POST /delete_todo
  def delete_todo(%{"id" => id}) do
    Nex.Store.update(:todos, [], &Enum.reject(&1, fn t -> t.id == id end))
    :empty
  end
end
```

### Action 参数

Action 函数接收一个 `params` Map，包含：
- 表单数据
- `hx-vals` 中的数据
- URL 查询参数
- `_page_id`（框架注入，用于状态隔离）

### Action 返回值

| 返回值 | HTTP 响应 | 说明 |
|-------|----------|------|
| `~H"<div>...</div>"` | 200 + HTML | 返回 HTML 片段 |
| `:empty` | 200 + 空 | 用于删除操作 |
| `{:redirect, "/path"}` | HX-Redirect | 重定向 |
| `{:refresh, _}` | HX-Refresh | 刷新整个页面 |

### 示例：完整的 CRUD

```elixir
defmodule MyApp.Pages.Todos do
  use Nex.Page
  import MyApp.Partials.Todos.Item

  def mount(_params) do
    %{
      title: "Todos",
      todos: Nex.Store.get(:todos, [])
    }
  end

  def render(assigns) do
    ~H"""
    <form hx-post="/create" hx-target="#list" hx-swap="beforeend">
      <input name="text" />
      <button>添加</button>
    </form>
    <ul id="list">
      <.todo_item :for={todo <- @todos} todo={todo} />
    </ul>
    """
  end

  def create(%{"text" => text}) do
    todo = %{id: System.unique_integer([:positive]), text: text, done: false}
    Nex.Store.update(:todos, [], &[todo | &1])
    assigns = %{todo: todo}
    ~H"<.todo_item todo={@todo} />"
  end

  def toggle(%{"id" => id}) do
    id = String.to_integer(id)
    Nex.Store.update(:todos, [], fn todos ->
      Enum.map(todos, fn t ->
        if t.id == id, do: %{t | done: !t.done}, else: t
      end)
    end)
    todo = Nex.Store.get(:todos, []) |> Enum.find(&(&1.id == id))
    assigns = %{todo: todo}
    ~H"<.todo_item todo={@todo} />"
  end

  def delete(%{"id" => id}) do
    id = String.to_integer(id)
    Nex.Store.update(:todos, [], &Enum.reject(&1, fn t -> t.id == id end))
    :empty
  end
end
```

## 导入组件

使用 `import` 导入 Partial 组件：

```elixir
defmodule MyApp.Pages.Index do
  use Nex.Page
  import MyApp.Partials.Todos.Item
  import MyApp.Partials.Common.Button

  def render(assigns) do
    ~H"""
    <.todo_item todo={@todo} />
    <.button type="submit">提交</.button>
    """
  end
end
```

## use Nex.Page 提供的功能

`use Nex.Page` 会自动导入：

- `~H` sigil — HEEx 模板
- `raw/1` — 插入原始 HTML（不转义）

```elixir
def render(assigns) do
  ~H"""
  <div>{@title}</div>           <!-- 自动转义 -->
  <div>{raw(@html_content)}</div> <!-- 不转义 -->
  """
end
```

## 下一步

- [Partials](./partials.md) - 可复用组件
- [Store](./store.md) - 状态管理
- [HTMX 集成](./htmx.md) - 深入 HTMX
