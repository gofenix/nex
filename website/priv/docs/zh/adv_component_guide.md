# 组件化开发

Nex 支持强大的组件化开发模式，帮助你构建可维护、可复用的 UI 界面。

## 1. Partial 组件 (局部组件)

Partial 组件是 Nex 中最基础的复用单元。它们通常存放在 `src/components/` 目录下，但实际上你可以在任何模块中定义它们。

### 定义组件
组件就是一个接收 `assigns` 并返回 `~H` 模板的普通函数。

```elixir
defmodule MyApp.Components.Buttons do
  use Nex

  def primary_button(assigns) do
    ~H"""
    <button class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition">
      {render_slot(@inner_block)}
    </button>
    """
  end
end
```

### 使用组件
在页面中，你可以使用 `<.component_name />` 语法调用。

```elixir
def render(assigns) do
  ~H"""
  <div class="p-4">
    <MyApp.Components.Buttons.primary_button>
      提交申请
    </MyApp.Components.Buttons.primary_button>
  </div>
  """
end
```

## 2. 插槽 (Slots)

插槽允许你向组件传递复杂的 HTML 内容。

*   **默认插槽**：通过 `{@inner_block}` 获取并使用 `render_slot/1` 渲染。
*   **具名插槽**：使用 `<:slot_name>` 语法传递，通过 `{@slot_name}` 获取。

```elixir
def card(assigns) do
  ~H"""
  <div class="border rounded shadow">
    <div class="p-4 border-b font-bold bg-gray-50">
      {render_slot(@header)}
    </div>
    <div class="p-4">
      {render_slot(@inner_block)}
    </div>
  </div>
  """
end

# 使用
~H"""
<.card>
  <:header>卡片标题</:header>
  这是卡片的主体内容。
</.card>
"""
```

## 3. Layout (布局) 合同

`src/layouts.ex` 是应用的顶层容器。它必须遵循一套“合同”来确保框架功能正常。

### 核心变量
*   **`@inner_content`**：必须渲染，代表页面的核心 HTML。使用 `{raw(@inner_content)}` 渲染。
*   **`@title`**：页面标题，由页面模块的 `mount/1` 返回（默认为 "Nex App"）。

### 布局示例
```elixir
defmodule MyApp.Layouts do
  use Nex

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html>
      <head>
        <title>{@title}</title>
        <script src="https://cdn.tailwindcss.com"></script>
      </head>
      <body>
        <nav>...</nav>
        <main>
          {raw(@inner_content)}
        </main>
      </body>
    </html>
    """
  end
end
```

## 4. 组件复用模式

1.  **单文件组件**：对于仅在当前页面使用的 UI 片段，可以直接在页面模块底部定义私有函数（如 `defp my_widget(assigns)`）。
2.  **全局库**：将通用的基础组件（按钮、输入框、卡片）集中在 `src/components/`。
3.  **零配置导入**：由于 `use Nex` 会自动为你导入必要的宏，你无需手动 `import` Phoenix.Component。
