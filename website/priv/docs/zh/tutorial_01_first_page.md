# 创建第一个页面

在 Nex 中，创建一个页面非常直观。你只需要在 `src/pages/` 目录下创建一个 Elixir 模块，并遵循 `mount` 和 `render` 的约定。

## 1. 页面基本结构

一个典型的 Nex 页面由两部分组成：

1.  **`mount/1`**：处理业务逻辑，初始化数据，返回一个 Map 作为 `assigns`。
2.  **`render/1`**：定义 UI，使用 HEEx 模板。

### 示例：Hello World

创建 `src/pages/hello.ex`：

```elixir
defmodule MyApp.Pages.Hello do
  use Nex

  # 1. 初始化数据
  def mount(_params) do
    %{
      name: "世界",
      time: Time.utc_now()
    }
  end

  # 2. 渲染模板
  def render(assigns) do
    ~H"""
    <div class="p-10 shadow-lg rounded-xl bg-white">
      <h1 class="text-3xl font-bold">你好，{@name}！</h1>
      <p class="text-gray-500 mt-2">当前服务器时间：{@time}</p>
    </div>
    """
  end
end
```

## 2. 核心函数解析

### `mount(params)`
*   **输入**：包含 URL 路径参数和 Query 参数的 Map。
*   **输出**：必须返回一个 Map。这个 Map 中的所有键都会自动在 `render` 模板中作为变量可用（例如 `{@name}`）。

### `render(assigns)`
*   **输入**：由 `mount` 返回的 `assigns`。
*   **语法**：使用 `~H` 签名，内部支持标准 HTML 和 HEEx 语法（如 `{@var}` 插值，`<%= if ... %>` 控制流）。

## 3. Layout (布局) 约束

Nex 会自动将你的页面内容包裹在 `src/layouts.ex` 定义的布局中。

**重要规则**：
Layout 模板中必须包含 `<body>` 标签。Nex 的自动化脚本（如 CSRF 保护、热重载、状态追踪）依赖于在 `</body>` 前自动注入必要的钩子。

## 练习：个人名片

尝试创建一个 `src/pages/about.ex`，显示你的名字、职业和一段简介。

1.  在 `mount` 中定义你的信息。
2.  在 `render` 中使用 Tailwind CSS 美化样式。
3.  访问 `http://localhost:4000/about` 查看效果。
