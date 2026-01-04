# 添加交互 (Action)

Action 是 Nex 的核心创新之一。它允许你直接在页面模块中定义处理异步请求（POST, PUT, DELETE）的函数，而无需离开当前文件的上下文。

## 1. Action 是什么？

在传统的 Web 开发中，处理按钮点击或表单提交通常需要定义路由、控制器和响应逻辑。在 Nex 中，这一切都被简化为 **Action 函数**。

*   **局部性**：交互逻辑与 UI 定义在同一个文件中。
*   **声明式交互**：Action 默认通过 HTMX 等声明式工具发送异步请求，无需编写 JavaScript。
*   **无需 mount**：Action 直接被调用，不需要重新执行页面的 `mount` 或全屏渲染。

## 2. 单路径 Action (Referer-based)

这是最常用的 Action 模式。你只需在 HTML 中指定 `hx-post="/函数名"`，Nex 会自动根据请求来源（Referer）找到对应的页面模块并执行该函数。

### 示例：计数器

创建 `src/pages/counter.ex`：

```elixir
defmodule MyApp.Pages.Counter do
  use Nex

  def mount(_params) do
    # 从状态中获取当前数值，默认为 0
    %{count: Nex.Store.get(:count, 0)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-8 border rounded shadow">
      <h2 class="text-xl">当前计数: <span id="count">{@count}</span></h2>
      
      <!-- 点击按钮将发送 POST 请求到 /increment -->
      <button hx-post="/increment"
              hx-target="#count"
              class="mt-4 px-4 py-2 bg-blue-500 text-white rounded">
        增加 +1
      </button>
    </div>
    """
  end

  # 定义与 hx-post 路径同名的函数
  def increment(_params) do
    # 更新服务端状态
    new_count = Nex.Store.update(:count, 0, &(&1 + 1))
    
    # 直接返回一个字符串或 HEEx 片段，它将替换 hx-target 指定的内容
    "#{new_count}"
  end
end
```

## 3. 多路径 Action (Path-based)

如果你需要更符合 RESTful 风格的路径，或者需要在 URL 中传递 ID，可以使用多路径 Action。

### 示例：删除留言

路径：`POST /messages/123/delete`

Nex 会按以下规则解析：
1.  找到 `src/pages/messages/[id].ex` (或 `src/pages/messages/index.ex`)。
2.  提取参数 `id: "123"`。
3.  调用该模块中的 `delete/1` 函数。

```elixir
def delete(%{"id" => id}) do
  # 执行删除逻辑
  # ...
  :empty  # 返回 :empty 表示执行成功但不更新任何 DOM 元素
end
```

## 4. Action 的返回值类型

Action 可以返回多种类型的值，Nex 会根据返回值自动处理 HTTP 响应：

| 返回值类型 | 效果 | 状态码 |
| :--- | :--- | :--- |
| **String / HEEx** | 返回 HTML 片段，用于局部更新 | 200 OK |
| **`:empty`** | 返回空内容，不更新任何 DOM | 200 OK |
| **`{:redirect, url}`** | 让 HTMX 进行客户端跳转 | 200 OK + HX-Redirect |
| **`{:refresh}`** | 让整个页面重新加载 | 200 OK + HX-Refresh |
| **`Nex.stream(fn)`** | 开启 SSE 流式响应 | 200 OK + SSE |

## 练习：计数器进阶

在计数器页面添加一个“重置”按钮：
1.  使用 `hx-post="/reset"`。
2.  在模块中定义 `reset/1` 函数。
3.  函数逻辑：将 `Nex.Store.put(:count, 0)`。
4.  返回值：使用 `{:refresh}` 观察整个页面如何刷新。
