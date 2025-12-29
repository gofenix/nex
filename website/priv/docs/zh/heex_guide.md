# Nex 框架 HEEx 模板使用指南

Nex 框架使用 Phoenix 的 HEEx (HTML + EEx) 模板引擎，提供类型安全的 HTML 模板编写方式。

## 目录

- [基础语法](#基础语法)
- [变量输出](#变量输出)
- [条件渲染](#条件渲染)
- [循环渲染](#循环渲染)
- [组件调用](#组件调用)
- [属性绑定](#属性绑定)
- [事件处理](#事件处理)
- [Slots 插槽](#slots-插槽)
- [内联 Elixir](#内联-elixir)
- [Layout 与 页面结构](#layout-与-页面结构)
- [CSRF 保护](#csrf-保护)

---

## 基础语法

HEEx 模板使用 `~H"""..."""` 分界符。在 Nex 中，主要在 `render/1` 函数和 Action 函数中使用。

```elixir
def render(assigns) do
  ~H"""
  <div class="container">
    <h1>Hello, World!</h1>
  </div>
  """
end
```

---

## 变量输出

### Assigns 变量 (`@`) 与 普通变量

在 HEEx 模板中，有两种类型的变量：

#### 1. Assigns 变量 (`@name`)
*   **语法**：`{@name}` 或 `@name`
*   **作用域**：全局（在当前渲染上下文中）。
*   **来源**：从 `mount/1` 或 action 函数通过 `assigns` map 传递。
*   **本质**：`@name` 是 `assigns.name` 的简写。

#### 2. 普通变量 (Local Variables)
*   **语法**：`{name}`
*   **作用域**：局部（仅在定义它的代码块内有效）。
*   **来源**：通常在推导式（`:for`）、`let` 绑定或内联 Elixir 代码块中定义。
*   **注意**：不要给普通变量加 `@` 前缀。

```elixir
# 在 mount 中初始化变量
def mount(_params) do
  %{
    title: "My Page",   # assigns 变量
    items: [            # assigns 变量
    %{name: "Apple"},
    %{name: "Banana"}
    ]
  }
end

def render(assigns) do
  ~H"""
  <!-- 使用 assigns 变量 -->
  <h1>{@title}</h1>
  
  <ul>
    <!-- item 是局部普通变量，由 :for 定义 -->
    <li :for={item <- @items}>
      <!-- 访问普通变量，不需要 @ -->
      {item.name}
    </li>
  </ul>
  """
end
```

**注意**：在 Action 函数中（如处理 POST 请求的函数），如果需要返回模板，你需要手动构造 `assigns` map，因为 Action 函数没有自动接收之前的 assigns。

```elixir
def increment(_params) do
  count = Nex.Store.update(:count, 0, &(&1 + 1))
  # 必须构造 assigns，否则模板中无法访问 @count
  assigns = %{count: count}
  ~H"<div>{@count}</div>"
end
```

---

## 条件渲染

使用 `:if` 和 `:else` 属性进行条件渲染：

```elixir
def render(assigns) do
  ~H"""
  <div>
    <button :if={@count > 0} class="btn-primary">Decrease</button>
    <button :if={@count == 0} class="btn-disabled">Zero</button>
    <!-- 不支持 :else-if，需使用多个 :if -->
  </div>
  """
end
```

在属性中使用 Elixir 表达式进行条件判断：

```elixir
def render(assigns) do
  ~H"""
  <div class={"p-4 #{if @active, do: "bg-blue-500", else: "bg-gray-200"}"}>
    Content
  </div>
  """
end
```

---

## 循环渲染

使用 `:for` 属性遍历列表：

```elixir
def render(assigns) do
  ~H"""
  <ul>
    <!-- 遍历列表 -->
    <li :for={item <- @items} id={"item-#{item.id}"}>
      {item.name}
    </li>
    
    <!-- 带索引的遍历 -->
    <li :for={{item, index} <- Enum.with_index(@items)}>
      #{index + 1}. {item.name}
    </li>
  </ul>
  """
end
```

---

## 组件调用

### 调用 Partial 组件

组件通常定义在 `src/partials/` 目录下。Nex 推荐使用 `import` 方式调用组件。

#### 使用 `import`

在 Page 模块中导入组件模块，然后使用 `<.函数名 />` 语法调用。注意函数名前的点号 `.` 是必须的。

```elixir
defmodule MyApp.Pages.Index do
  use Nex.Page
  # 1. 导入组件模块
  import MyApp.Partials.Button

  def render(assigns) do
    ~H"""
    <!-- 2. 使用 <.函数名 /> 调用 -->
    <.button label="Click me" />
    """
  end
end
```

**组件定义示例**：

```elixir
# src/partials/button.ex
defmodule MyApp.Partials.Button do
  use Nex.Partial

  def button(assigns) do
    ~H"""
    <button class={@class}>
      {@label}
    </button>
    """
  end
end
```

---

## 属性绑定

### 动态属性值

使用 `{}` 绑定动态值：

```elixir
<div id={"user-#{@user.id}"} class={@css_class}>
  {@user.name}
</div>
```

### 布尔属性

```elixir
<input type="checkbox" checked={@completed} disabled={@readonly} />
```

当值为 `true` 时属性存在，为 `false` 时属性不存在。

### 属性透传 (Global Attributes)

可以将 map 中的所有键值对作为属性传递给标签：

```elixir
<div {@rest}>...</div>
```

---

## 事件处理 (HTMX)

Nex 深度集成 HTMX。你可以直接使用 HTMX 属性。

### 点击事件

```elixir
<button hx-post="/increment"
        hx-target="#counter"
        hx-swap="outerHTML">
  +1
</button>
```

### 表单提交

```elixir
<form hx-post="/submit"
      hx-target="#result"
      hx-swap="innerHTML">
  <input type="text" name="content" />
  <button type="submit">Submit</button>
</form>
```

### 传递参数

除了表单输入，还可以使用 `hx-vals` 传递额外参数：

```elixir
<button hx-post="/delete"
        hx-vals={Jason.encode!(%{id: @todo.id})}
        hx-target={"#todo-#{@todo.id}"}
        hx-swap="outerHTML">
  Delete
</button>
```

---

## Slots 插槽

Partial 组件支持插槽，用于包裹内容。

**定义组件**：
```elixir
def card(assigns) do
  ~H"""
  <div class="card">
    <div class="card-header">{@title}</div>
    <div class="card-body">
      <!-- 渲染默认插槽内容 -->
      {render_slot(@inner_block)}
    </div>
  </div>
  """
end
```

**使用组件**：
```elixir
<.card title="My Card">
  <p>This is the card content.</p>
</.card>
```

---

## Layout 与 页面结构

### Layout

Layout 定义在 `src/layouts.ex`。Nex 自动将 Page 的渲染结果注入到 Layout 的 `@inner_content` 变量中。

```elixir
# src/layouts.ex
def render(assigns) do
  ~H"""
  <!DOCTYPE html>
  <html>
    <head>...</head>
    <body>
      <main>
        <!-- 必须包含 raw(@inner_content) -->
        {raw(@inner_content)}
      </main>
    </body>
  </html>
  """
end
```

**注意**：不要在 Layout 中移除 `raw(@inner_content)`，因为框架会自动注入必要的脚本（用于 CSRF 处理和热重载）。

---

## CSRF 保护

#### CSRF Token 处理

Nex 会自动为所有 POST/PUT/DELETE 请求处理 CSRF Token 的传递。
在编写 Form 时，你不需要手动添加隐藏域，因为 Nex 的前端脚本会自动拦截 HTMX 请求并注入 `X-CSRF-Token` 头。

> **注意**：目前 Nex 主要负责 Token 的生成与传递。服务端验证逻辑依赖于无状态 Token 校验（但在当前版本中，默认校验逻辑较为宽松）。

1.  **自动注入 HTMX Headers**：框架会自动注入脚本，监听 `htmx:configRequest` 事件，为所有 HTMX 请求（如 `hx-post`）自动添加 `X-CSRF-Token` 头。
    *   **意味着**：你在编写 `hx-post` 表单或按钮时，**不需要**手动添加 CSRF token 参数。

2.  **普通表单处理**：对于非 HTMX 的普通 HTML 表单（即传统的 `<form method="post">`），你需要手动添加 hidden input。

```elixir
<!-- 普通表单需要这个 -->
<form method="post" action="/login">
  {csrf_input_tag()}
  <input type="text" name="username" />
  <button>Login</button>
</form>

<!-- HTMX 表单不需要手动添加，框架会自动处理 -->
<form hx-post="/api/login">
  <input type="text" name="username" />
  <button>Login</button>
</form>
```

### 手动获取 Token

如果需要在 JavaScript 或其他地方使用 token：

```elixir
# 输出 token 字符串
{csrf_token()}

# 输出 hidden input 标签
{csrf_input_tag()}
```

---

## Action 函数与返回值

Action 函数（处理 POST/PUT 等请求的函数）只接收 `params` 参数。根据不同的需求，可以返回不同类型的值：

### 1. 返回 HEEx 模板 (局部更新)
这是最常用的方式，配合 `hx-swap` 更新页面的一部分。**注意必须构造 `assigns`**。

```elixir
def create_todo(params) do
  # ... 业务逻辑 ...
  assigns = %{todo: new_todo}
  ~H"<.todo_item todo={@todo} />"
end
```

### 2. 返回 `:empty` (无内容)
用于删除操作等不需要返回内容的情况。通常配合 `hx-target` 删除元素。

```elixir
def delete_todo(%{"id" => id}) do
  # ... 删除逻辑 ...
  :empty # 返回 200 OK 但无内容
end
```

### 3. 重定向 `{:redirect, path}`
用于操作完成后跳转页面。Nex 会通过 `HX-Redirect` 头通知前端跳转。

```elixir
def login(params) do
  # ... 登录逻辑 ...
  {:redirect, "/dashboard"}
end
```

### 4. 刷新页面 `{:refresh, _}`
强制前端刷新当前页面。

```elixir
def reset(_params) do
  {:refresh, []}
end
```

---

## 最佳实践

### 1. Action 函数中必须构造 assigns
Action 函数不接收 `conn` 或旧的 `assigns`。如果你在 Action 中使用 `~H` 模板并引用了变量（如 `{@count}`），你必须在函数内显式定义 `assigns` 变量。

### 2. Partial 组件中的 Helper 使用
`use Nex.Page` 会自动导入 `csrf_input_tag` 等辅助函数。但在 `use Nex.Partial` 的组件中，这些辅助函数不可用。
*   **推荐**：在 Partial 中使用全名调用，如 `Nex.CSRF.input_tag()`。
*   **或者**：通过 `assigns` 传递需要的值。

### 3. 保持模板简洁

尽量避免在模板中编写复杂的 Elixir 逻辑。
*   **推荐**：将逻辑提取到私有函数中。
*   **原因**：模板应该专注于展示，复杂的逻辑会降低可读性。

```elixir
# 不推荐
<div class={if @user.role == "admin" && @user.active, do: "bg-red-500", else: "bg-gray-200"}>

# 推荐
<div class={user_class(@user)}>

defp user_class(user) do
  if user.role == "admin" && user.active do
    "bg-red-500"
  else
    "bg-gray-200"
  end
end
```

### 4. Partial 组件命名
通常与文件名保持一致，例如 `src/partials/ui/button.ex` 对应 `MyApp.Partials.Ui.Button`。这将有助于代码组织和查找。
