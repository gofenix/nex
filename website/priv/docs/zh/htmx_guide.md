# Nex 框架 HTMX 集成指南

Nex 框架从设计之初就是围绕 HTMX 构建的。本指南介绍如何在 Nex 中使用 HTMX 来构建动态的、服务端驱动的用户界面。

## 目录

- [核心概念](#核心概念)
- [基本交互](#基本交互)
- [参数传递](#参数传递)
- [表单处理](#表单处理)
- [状态保持 (Nex.Store)](#状态保持-nexstore)
- [CSRF 保护](#csrf-保护)
- [Action 返回值详解](#action-返回值详解)
- [实时流式响应 (SSE)](#实时流式响应-sse)

---

## 核心概念

在 Nex 中，HTMX 的使用模式非常直接：

1.  **触发**：前端使用 `hx-post="/action_name"` 触发请求。
2.  **处理**：后端 Page 模块中定义同名的公共函数 `def action_name(params)`。
3.  **更新**：函数返回 HEEx 模板片段，前端通过 `hx-target` 和 `hx-swap` 将其插入到 DOM 中。

**不需要编写 API 路由**，也不需要编写 JSON 序列化逻辑，一切都是 HTML 片段的交换。

---

## 基本交互

### 示例：计数器

**前端 (src/pages/index.ex):**
```elixir
<div id="counter">{@count}</div>

<button hx-post="/increment"
        hx-target="#counter"
        hx-swap="outerHTML">
  +1
</button>
```

**后端 (src/pages/index.ex):**
```elixir
def increment(_params) do
  # 1. 更新状态
  new_count = Nex.Store.update(:count, 0, &(&1 + 1))
  
  # 2. 构造 assigns (Action 函数不自动继承旧 assigns)
  assigns = %{count: new_count}
  
  # 3. 返回更新后的 HTML 片段
  ~H"<div id=\"counter\">{@count}</div>"
end
```

---

## 参数传递

除了表单输入，你可以通过 `hx-vals` 传递额外参数。

**前端:**
```elixir
<button hx-post="/delete_item"
        hx-vals={Jason.encode!(%{id: @item.id, type: "pro"})}
        hx-target={"#item-#{@item.id}"}
        hx-swap="outerHTML">
  Delete
</button>
```

**后端:**
```elixir
def delete_item(%{"id" => id, "type" => type}) do
  # id 和 type 都可以从 params 中获取
  delete_db_item(id, type)
  :empty
end
```

---

## 表单处理

对于表单提交，使用标准 `hx-post`。

**前端:**
```elixir
<form hx-post="/add_todo"
      hx-target="#todo-list"
      hx-swap="beforeend"
      hx-on::after-request="this.reset()">
  <input type="text" name="text" required />
  <button>Add</button>
</form>

<ul id="todo-list">
  <!-- 列表内容 -->
</ul>
```

**后端:**
```elixir
def add_todo(%{"text" => text}) do
  todo = create_todo(text)
  assigns = %{todo: todo}
  
  # 只返回新添加的 li 元素，将被 append 到 ul 中
  ~H"<li>{@todo.text}</li>"
end
```

---

## 状态保持 (Nex.Store)

Nex 提供了页面级（Page-Scoped）的状态管理。

*   **Page ID**: 框架会自动为每个页面生成唯一的 Page ID。
*   **自动传递**: 框架会自动拦截所有 HTMX 请求，并在 Header 中注入 `X-Nex-Page-Id`。
*   **后端获取**: 后端根据 Page ID 恢复当前页面的状态。

这意味你可以在多次 HTMX 交互中保持状态（例如计数器的值、购物车内容），而不需要在 URL 或 Hidden Input 中手动传递状态。

**使用示例:**
```elixir
def mount(_params) do
  # 初始化状态
  %{count: Nex.Store.get(:count, 0)}
end

def increment(_params) do
  # 获取并更新当前页面的状态
  new_count = Nex.Store.update(:count, 0, &(&1 + 1))
  # ...
end
```

---

## CSRF 保护

Nex 框架内置了针对 HTMX 的 CSRF 保护机制。

*   **自动注入**: 页面加载时，框架会注入一段 JavaScript。
*   **监听事件**: 监听 `htmx:configRequest` 事件。
*   **设置 Header**: 自动将 CSRF Token 放入 `X-CSRF-Token` 请求头中。

**开发者只需要做一件事**:
在编写 `hx-post` 请求时，**不需要**手动添加 `_csrf_token` 参数或 hidden input。得益于 Nex 的自动脚本，你不需要在 HTMX 表单中手动添加 `_csrf_token` 字段。框架会自动将 Token 注入请求头。

---

## Action 返回值详解

Action 函数可以返回以下几种类型，框架会自动处理响应头：

| 返回值 | HTTP 状态码 | 行为 | 典型场景 |
| :--- | :--- | :--- | :--- |
| `~H"..."` (HEEx) | 200 | 返回 HTML 片段 | 局部更新 UI |
| `:empty` | 200 (空 Body) | 不更新任何内容 | 删除元素 (配合 `hx-swap="delete"`) |
| `{:redirect, path}` | 200 | 触发前端跳转 | 登录成功、操作完成跳转 |
| `{:refresh, opts}` | 200 | 触发前端刷新 | 重置页面状态 |

**代码示例**:

```elixir
# 1. 返回 HTML
def update(params), do: ~H"..."

# 2. 删除 (前端配合 hx-target="#id" hx-swap="outerHTML" 使用)
# 注意：如果是为了移除元素，通常返回空字符串或使用 hx-swap="delete"
def delete(_params), do: :empty

# 3. 重定向 (设置 HX-Redirect 头)
def login(_params), do: {:redirect, "/dashboard"}

# 4. 刷新页面 (设置 HX-Refresh 头)
def reset(_params), do: {:refresh, []}
```

---

## 实时流式响应 (SSE)

Nex 结合 HTMX 的 SSE 扩展 (`hx-ext="sse"`) 可以实现类似 ChatGPT 的打字机效果。

**前端:**
```elixir
<!-- 连接 SSE 端点 -->
<div hx-ext="sse" sse-connect="/api/sse/stream?message=hello" sse-swap="message">
  <!-- 服务器推送的内容将在这里更新 -->
</div>
```

**后端 (SSE 端点):**
在 `src/api/sse/stream.ex` 中：
```elixir
defmodule MyApp.Api.Sse.Stream do
  use Nex

  def stream(params, send_fn) do
    # 模拟流式推送
    send_fn.(%{event: "message", data: "He"})
    Process.sleep(100)
    send_fn.(%{event: "message", data: "llo"})
    :ok
  end
end
```

**注意**:
*   SSE 端点需要实现 `stream/2` 回调。
*   HTMX 的 SSE 扩展会自动处理连接和消息接收。
