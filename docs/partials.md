# Partials

Partials 是可复用的 UI 组件，没有 HTTP 路由，只能被其他模块导入使用。

## 基本结构

```elixir
# src/partials/todos/item.ex
defmodule MyApp.Partials.Todos.Item do
  use Nex.Partial

  def todo_item(assigns) do
    ~H"""
    <li id={"todo-#{@todo.id}"}>
      {@todo.text}
    </li>
    """
  end
end
```

## 使用组件

### 导入并使用

```elixir
defmodule MyApp.Pages.Index do
  use Nex.Page
  import MyApp.Partials.Todos.Item

  def render(assigns) do
    ~H"""
    <ul>
      <.todo_item todo={@todo} />
    </ul>
    """
  end
end
```

### 列表渲染

```elixir
~H"""
<ul>
  <.todo_item :for={todo <- @todos} todo={todo} />
</ul>
"""
```

## 组件参数

### 必需参数

```elixir
def todo_item(assigns) do
  ~H"""
  <li>{@todo.text}</li>
  """
end
```

调用时必须传递 `todo`：

```heex
<.todo_item todo={todo} />
```

### 可选参数

使用 `Map.get/3` 或 `assigns[:key]` 处理可选参数：

```elixir
def button(assigns) do
  type = assigns[:type] || "button"
  class = assigns[:class] || ""
  
  assigns = Map.merge(assigns, %{type: type, class: class})
  
  ~H"""
  <button type={@type} class={"btn #{@class}"}>
    {@inner_content}
  </button>
  """
end
```

### 内容插槽

使用 `@inner_content` 接收子内容：

```elixir
def card(assigns) do
  ~H"""
  <div class="card">
    <div class="card-header">{@title}</div>
    <div class="card-body">
      {@inner_content}
    </div>
  </div>
  """
end
```

使用：

```heex
<.card title="My Card">
  <p>这是卡片内容</p>
</.card>
```

## 完整示例

### Todo Item 组件

```elixir
# src/partials/todos/item.ex
defmodule MyApp.Partials.Todos.Item do
  use Nex.Partial

  def todo_item(assigns) do
    ~H"""
    <li id={"todo-#{@todo.id}"}
        class={"flex items-center gap-3 p-3 bg-white rounded-lg shadow #{if @todo.completed, do: "opacity-60"}"}>
      
      <input type="checkbox"
             checked={@todo.completed}
             hx-post="/toggle_todo"
             hx-vals={Jason.encode!(%{id: @todo.id})}
             hx-target={"#todo-#{@todo.id}"}
             hx-swap="outerHTML"
             class="w-5 h-5" />
      
      <span class={"flex-1 #{if @todo.completed, do: "line-through text-gray-400"}"}>
        {@todo.text}
      </span>
      
      <button hx-post="/delete_todo"
              hx-vals={Jason.encode!(%{id: @todo.id})}
              hx-target={"#todo-#{@todo.id}"}
              hx-swap="outerHTML"
              class="text-red-500 hover:text-red-700">
        删除
      </button>
    </li>
    """
  end
end
```

### Button 组件

```elixir
# src/partials/common/button.ex
defmodule MyApp.Partials.Common.Button do
  use Nex.Partial

  def button(assigns) do
    type = assigns[:type] || "button"
    variant = assigns[:variant] || "primary"
    size = assigns[:size] || "md"
    disabled = assigns[:disabled] || false

    base_class = "rounded-lg font-medium transition-colors"
    
    variant_class = case variant do
      "primary" -> "bg-blue-500 text-white hover:bg-blue-600"
      "secondary" -> "bg-gray-200 text-gray-800 hover:bg-gray-300"
      "danger" -> "bg-red-500 text-white hover:bg-red-600"
      _ -> "bg-blue-500 text-white hover:bg-blue-600"
    end

    size_class = case size do
      "sm" -> "px-3 py-1.5 text-sm"
      "md" -> "px-4 py-2"
      "lg" -> "px-6 py-3 text-lg"
      _ -> "px-4 py-2"
    end

    class = "#{base_class} #{variant_class} #{size_class} #{assigns[:class] || ""}"
    
    assigns = Map.merge(assigns, %{type: type, class: class, disabled: disabled})

    ~H"""
    <button type={@type} class={@class} disabled={@disabled}>
      {@inner_content}
    </button>
    """
  end
end
```

使用：

```heex
<.button>默认按钮</.button>
<.button variant="danger" size="lg">删除</.button>
<.button type="submit" disabled={@loading}>提交</.button>
```

### Modal 组件

```elixir
# src/partials/common/modal.ex
defmodule MyApp.Partials.Common.Modal do
  use Nex.Partial

  def modal(assigns) do
    ~H"""
    <div id={@id} class="fixed inset-0 z-50 hidden">
      <div class="fixed inset-0 bg-black/50" onclick={"document.getElementById('#{@id}').classList.add('hidden')"}></div>
      <div class="fixed inset-0 flex items-center justify-center p-4">
        <div class="bg-white rounded-lg shadow-xl max-w-md w-full">
          <div class="flex justify-between items-center p-4 border-b">
            <h3 class="text-lg font-semibold">{@title}</h3>
            <button onclick={"document.getElementById('#{@id}').classList.add('hidden')"} 
                    class="text-gray-500 hover:text-gray-700">
              ✕
            </button>
          </div>
          <div class="p-4">
            {@inner_content}
          </div>
        </div>
      </div>
    </div>
    """
  end
end
```

## 组件组织

建议按功能组织 Partials：

```
src/partials/
├── common/           # 通用组件
│   ├── button.ex
│   ├── modal.ex
│   └── card.ex
├── todos/            # Todo 相关组件
│   ├── item.ex
│   └── form.ex
└── users/            # 用户相关组件
    ├── avatar.ex
    └── profile.ex
```

## use Nex.Partial 提供的功能

`use Nex.Partial` 会自动导入：

- `~H` sigil — HEEx 模板

**注意**：Partial 不导入 `raw/1`，如果需要请手动导入：

```elixir
defmodule MyApp.Partials.Common.Html do
  use Nex.Partial
  import Phoenix.HTML, only: [raw: 1]

  def raw_html(assigns) do
    ~H"""
    <div>{raw(@html)}</div>
    """
  end
end
```

## 与 Pages 的区别

| 特性 | Pages | Partials |
|-----|-------|----------|
| HTTP 路由 | ✅ | ❌ |
| mount/1 | ✅ | ❌ |
| render/1 | ✅ | ❌ |
| Action 函数 | ✅ | ❌ |
| 组件函数 | ✅ | ✅ |
| 可被导入 | ✅ | ✅ |

## 下一步

- [Pages](./pages.md) - 页面模块
- [Layouts](./layouts.md) - 布局
