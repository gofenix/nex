# Store

`Nex.Store` 提供页面级的内存状态管理，类似 React/Vue 的 state，但运行在服务端。

## 核心概念

- **页面隔离** — 每个页面视图有独立的状态
- **刷新即清空** — 刷新页面状态重置（类似 React）
- **跨请求共享** — 同一页面的 HTMX 请求共享状态
- **自动清理** — 1 小时后自动清理过期状态

## 基本用法

### 读取状态

```elixir
# 获取值，不存在返回 nil
todos = Nex.Store.get(:todos)

# 获取值，不存在返回默认值
todos = Nex.Store.get(:todos, [])
count = Nex.Store.get(:count, 0)
```

### 写入状态

```elixir
# 设置值
Nex.Store.put(:todos, [todo | todos])
Nex.Store.put(:count, 10)
```

### 更新状态

```elixir
# 使用函数更新
Nex.Store.update(:count, 0, &(&1 + 1))
Nex.Store.update(:todos, [], &[new_todo | &1])

# 复杂更新
Nex.Store.update(:todos, [], fn todos ->
  Enum.map(todos, fn todo ->
    if todo.id == id, do: %{todo | completed: true}, else: todo
  end)
end)
```

### 删除状态

```elixir
Nex.Store.delete(:todos)
```

## 完整示例

### Todo 应用

```elixir
defmodule MyApp.Pages.Todos do
  use Nex.Page

  def mount(_params) do
    %{
      title: "Todos",
      todos: Nex.Store.get(:todos, [])
    }
  end

  def render(assigns) do
    ~H"""
    <form hx-post="/create" hx-target="#list" hx-swap="beforeend">
      <input name="text" placeholder="新任务..." />
      <button>添加</button>
    </form>
    <ul id="list">
      <li :for={todo <- @todos}>{todo.text}</li>
    </ul>
    """
  end

  def create(%{"text" => text}) do
    todo = %{
      id: System.unique_integer([:positive]),
      text: text,
      completed: false
    }
    
    # 更新状态
    Nex.Store.update(:todos, [], &[todo | &1])
    
    ~H"<li>{todo.text}</li>"
  end

  def toggle(%{"id" => id}) do
    id = String.to_integer(id)
    
    Nex.Store.update(:todos, [], fn todos ->
      Enum.map(todos, fn todo ->
        if todo.id == id do
          %{todo | completed: !todo.completed}
        else
          todo
        end
      end)
    end)
    
    todo = Nex.Store.get(:todos, []) |> Enum.find(&(&1.id == id))
    ~H"<li class={if todo.completed, do: \"line-through\"}>{todo.text}</li>"
  end

  def delete(%{"id" => id}) do
    id = String.to_integer(id)
    
    Nex.Store.update(:todos, [], fn todos ->
      Enum.reject(todos, &(&1.id == id))
    end)
    
    :empty
  end
end
```

### 计数器

```elixir
defmodule MyApp.Pages.Counter do
  use Nex.Page

  def mount(_params) do
    %{count: Nex.Store.get(:count, 0)}
  end

  def render(assigns) do
    ~H"""
    <div class="text-center">
      <span id="count" class="text-4xl">{@count}</span>
      <div class="mt-4 space-x-2">
        <button hx-post="/decrement" hx-target="#count">-</button>
        <button hx-post="/increment" hx-target="#count">+</button>
      </div>
    </div>
    """
  end

  def increment(_params) do
    count = Nex.Store.update(:count, 0, &(&1 + 1))
    assigns = %{count: count}
    ~H"{@count}"
  end

  def decrement(_params) do
    count = Nex.Store.update(:count, 0, &(&1 - 1))
    assigns = %{count: count}
    ~H"{@count}"
  end
end
```

## 工作原理

### Page ID

每次页面加载时，框架生成一个唯一的 `page_id`：

1. **GET 请求** — 生成新的 `page_id`，状态为空
2. **HTMX POST** — 携带 `page_id`，访问同一状态
3. **刷新页面** — 新的 `page_id`，状态重置

```
用户打开页面 → page_id: "abc123" → 状态: {}
点击添加按钮 → page_id: "abc123" → 状态: {todos: [...]}
点击删除按钮 → page_id: "abc123" → 状态: {todos: [...]}
刷新页面     → page_id: "xyz789" → 状态: {}  (新的 page_id)
```

### 自动清理

为防止内存泄漏，Nex.Store 会自动清理过期状态：

- **TTL**: 1 小时（默认）
- **清理间隔**: 5 分钟
- **续期**: 每次请求自动续期

## 与数据库的关系

`Nex.Store` 适用于**临时状态**，不适合持久化数据：

| 场景 | 使用 |
|-----|------|
| 表单草稿 | Nex.Store |
| 筛选条件 | Nex.Store |
| 购物车（临时） | Nex.Store |
| 用户数据 | 数据库 |
| 订单数据 | 数据库 |
| 需要持久化的数据 | 数据库 |

## 与 React/Vue 的对比

| 特性 | React useState | Vue ref | Nex.Store |
|-----|---------------|---------|-----------|
| 运行位置 | 客户端 | 客户端 | 服务端 |
| 刷新后 | 清空 | 清空 | 清空 |
| 跨组件 | Context/Redux | Pinia | 同一 page_id |
| 多标签页 | 独立 | 独立 | 独立 |

## API 参考

### Nex.Store.get/2

```elixir
@spec get(key :: atom(), default :: any()) :: any()
```

获取状态值，不存在返回默认值。

### Nex.Store.put/2

```elixir
@spec put(key :: atom(), value :: any()) :: any()
```

设置状态值，返回设置的值。

### Nex.Store.update/3

```elixir
@spec update(key :: atom(), default :: any(), fun :: (any() -> any())) :: any()
```

使用函数更新状态值，返回更新后的值。

### Nex.Store.delete/1

```elixir
@spec delete(key :: atom()) :: :ok
```

删除状态值。

## 下一步

- [Pages](./pages.md) - 页面模块
- [HTMX 集成](./htmx.md) - 交互模式
