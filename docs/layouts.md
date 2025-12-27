# Layouts

Layouts 是包装所有页面内容的根模板，用于定义 HTML 结构、引入 CSS/JS、设置通用导航等。

## 基本结构

```elixir
# src/layouts.ex
defmodule MyApp.Layouts do
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
        {raw(@inner_content)}
      </body>
    </html>
    """
  end
end
```

## 可用变量

Layout 的 `render/1` 接收以下 assigns：

| 变量 | 说明 |
|-----|------|
| `@title` | 页面标题，来自 Page 的 `mount/1` 返回值 |
| `@inner_content` | 页面内容 HTML 字符串 |

## 插入页面内容

使用 `raw(@inner_content)` 插入页面内容：

```elixir
<body>
  {raw(@inner_content)}
</body>
```

**为什么用 `raw/1`？**

`@inner_content` 已经是渲染好的 HTML 字符串，使用 `raw/1` 避免二次转义。

## 完整示例

### 带导航的布局

```elixir
defmodule MyApp.Layouts do
  use Nex.Page

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="zh-CN">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>{@title} - MyApp</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <script src="https://unpkg.com/htmx.org@2.0.4"></script>
      </head>
      <body class="bg-gray-100 min-h-screen">
        <nav class="bg-white shadow">
          <div class="container mx-auto px-4 py-3 flex justify-between items-center">
            <a href="/" class="text-xl font-bold text-blue-600">MyApp</a>
            <div class="space-x-4">
              <a href="/" class="text-gray-600 hover:text-blue-600">首页</a>
              <a href="/about" class="text-gray-600 hover:text-blue-600">关于</a>
            </div>
          </div>
        </nav>
        
        <main class="container mx-auto px-4 py-8">
          {raw(@inner_content)}
        </main>
        
        <footer class="bg-white border-t mt-auto">
          <div class="container mx-auto px-4 py-4 text-center text-gray-500">
            © 2024 MyApp. All rights reserved.
          </div>
        </footer>
      </body>
    </html>
    """
  end
end
```

### 带 DaisyUI 的布局

```elixir
defmodule MyApp.Layouts do
  use Nex.Page

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="zh-CN" data-theme="light">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>{@title}</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <link href="https://cdn.jsdelivr.net/npm/daisyui@4/dist/full.min.css" rel="stylesheet" />
        <script src="https://unpkg.com/htmx.org@2.0.4"></script>
      </head>
      <body class="min-h-screen bg-base-200">
        <div class="navbar bg-base-100 shadow-lg">
          <div class="flex-1">
            <a href="/" class="btn btn-ghost text-xl">MyApp</a>
          </div>
          <div class="flex-none">
            <ul class="menu menu-horizontal px-1">
              <li><a href="/">首页</a></li>
              <li><a href="/about">关于</a></li>
            </ul>
          </div>
        </div>
        
        <main class="container mx-auto p-4">
          {raw(@inner_content)}
        </main>
      </body>
    </html>
    """
  end
end
```

## 必需的脚本

### HTMX

HTMX 是 Nex 交互的核心，必须引入：

```html
<script src="https://unpkg.com/htmx.org@2.0.4"></script>
```

### CSS 框架（可选）

推荐使用 Tailwind CSS：

```html
<script src="https://cdn.tailwindcss.com"></script>
```

或者 DaisyUI：

```html
<script src="https://cdn.tailwindcss.com"></script>
<link href="https://cdn.jsdelivr.net/npm/daisyui@4/dist/full.min.css" rel="stylesheet" />
```

## 框架注入的脚本

Nex 会自动在页面内容后注入以下脚本：

```html
<script>
  // 设置 page_id 用于状态隔离
  document.body.setAttribute('hx-vals', JSON.stringify({_page_id: "..."}));
  
  // Live reload（开发环境）
  // ...
</script>
```

你不需要手动处理这些。

## 没有 Layout 时

如果项目没有 `src/layouts.ex`，页面内容会直接返回，不包装任何 HTML 结构。

这在返回 HTML 片段时很有用，但通常你需要一个 Layout。

## 多布局（未来功能）

当前版本只支持单一根布局。未来可能支持：

```elixir
# 在 Page 中指定布局
def layout, do: MyApp.Layouts.Admin
```

## 下一步

- [Pages](./pages.md) - 页面模块
- [HTMX 集成](./htmx.md) - 交互模式
