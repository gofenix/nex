# 示例项目

本文档介绍 Nex 框架的示例项目。

## Todo 应用

一个完整的 Todo 应用，展示了 Nex 的核心功能。

### 位置

```
examples/todos/
```

### 运行

```bash
cd examples/todos
mix deps.get
mix nex.dev
```

访问 http://localhost:4000

### 功能

- 添加 Todo
- 切换完成状态
- 删除 Todo
- 使用 Nex.Store 管理状态
- HTMX 无刷新交互

### 代码结构

```
examples/todos/
├── src/
│   ├── pages/
│   │   ├── index.ex      # 主页面
│   │   └── about.ex      # 关于页面
│   ├── api/
│   │   └── todos/
│   │       └── index.ex  # Todo API
│   ├── partials/
│   │   └── todos/
│   │       └── item.ex   # Todo 项组件
│   └── layouts.ex        # 根布局
├── mix.exs
└── README.md
```

### 核心代码

#### 页面模块

```elixir
# src/pages/index.ex
defmodule Todos.Pages.Index do
  use Nex.Page
  import Todos.Partials.Todos.Item

  def mount(_params) do
    %{
      title: "Todo App",
      todos: Nex.Store.get(:todos, [])
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto">
      <h1 class="text-3xl font-bold mb-6">Todo List</h1>

      <form hx-post="/create_todo"
            hx-target="#todo-list"
            hx-swap="beforeend"
            hx-on::after-request="this.reset()">
        <input name="text" placeholder="新任务..." required />
        <button type="submit">添加</button>
      </form>

      <ul id="todo-list">
        <.todo_item :for={todo <- @todos} todo={todo} />
      </ul>
    </div>
    """
  end

  def create_todo(%{"text" => text}) do
    todo = %{
      id: System.unique_integer([:positive]),
      text: text,
      completed: false
    }
    Nex.Store.update(:todos, [], &[todo | &1])
    assigns = %{todo: todo}
    ~H"<.todo_item todo={@todo} />"
  end

  def toggle_todo(%{"id" => id}) do
    id = String.to_integer(id)
    Nex.Store.update(:todos, [], fn todos ->
      Enum.map(todos, fn todo ->
        if todo.id == id, do: %{todo | completed: !todo.completed}, else: todo
      end)
    end)
    todo = Nex.Store.get(:todos, []) |> Enum.find(&(&1.id == id))
    assigns = %{todo: todo}
    ~H"<.todo_item todo={@todo} />"
  end

  def delete_todo(%{"id" => id}) do
    id = String.to_integer(id)
    Nex.Store.update(:todos, [], &Enum.reject(&1, fn t -> t.id == id end))
    :empty
  end
end
```

#### 组件

```elixir
# src/partials/todos/item.ex
defmodule Todos.Partials.Todos.Item do
  use Nex.Partial

  def todo_item(assigns) do
    ~H"""
    <li id={"todo-#{@todo.id}"} class="flex items-center gap-3 p-3 bg-white rounded-lg">
      <input type="checkbox"
             checked={@todo.completed}
             hx-post="/toggle_todo"
             hx-vals={Jason.encode!(%{id: @todo.id})}
             hx-target={"#todo-#{@todo.id}"}
             hx-swap="outerHTML" />
      <span class={if @todo.completed, do: "line-through"}>
        {@todo.text}
      </span>
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

#### API

```elixir
# src/api/todos/index.ex
defmodule Todos.Api.Todos.Index do
  use Nex.Api

  def get do
    %{data: Nex.Store.get(:todos, [])}
  end

  def post(%{"text" => text}) do
    todo = %{
      id: System.unique_integer([:positive]),
      text: text,
      completed: false
    }
    Nex.Store.update(:todos, [], &[todo | &1])
    {201, %{data: todo}}
  end
end
```

#### 布局

```elixir
# src/layouts.ex
defmodule Todos.Layouts do
  use Nex.Page

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="zh-CN">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>{@title}</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <script src="https://unpkg.com/htmx.org@2.0.4"></script>
      </head>
      <body class="bg-gray-100 min-h-screen">
        <div class="container mx-auto px-4 py-8">
          {raw(@inner_content)}
        </div>
      </body>
    </html>
    """
  end
end
```

## 创建自己的示例

### 1. 创建项目

```bash
mix new my_example
cd my_example
```

### 2. 添加依赖

```elixir
# mix.exs
defp deps do
  [
    {:nex, path: "../../framework"}
  ]
end
```

### 3. 配置编译路径

```elixir
# mix.exs
def project do
  [
    # ...
    elixirc_paths: ["lib", "src"]
  ]
end
```

### 4. 创建页面

```elixir
# src/pages/index.ex
defmodule MyExample.Pages.Index do
  use Nex.Page

  def render(assigns) do
    ~H"""
    <h1>Hello, World!</h1>
    """
  end
end
```

### 5. 创建布局

```elixir
# src/layouts.ex
defmodule MyExample.Layouts do
  use Nex.Page

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html>
      <head>
        <title>{@title || "My Example"}</title>
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

### 6. 运行

```bash
mix deps.get
mix nex.dev
```

## 下一步

- [快速开始](./getting-started.md) - 从头创建应用
- [Pages](./pages.md) - 页面模块详解
- [HTMX 集成](./htmx.md) - 交互模式
