# 快速开始

本指南将帮助你在 5 分钟内创建第一个 Nex 应用。

## 前置要求

- Elixir 1.18+
- Erlang/OTP 27+

## 创建项目

### 1. 创建 Mix 项目

```bash
mix new my_app
cd my_app
```

### 2. 添加 Nex 依赖

编辑 `mix.exs`：

```elixir
defp deps do
  [
    {:nex, "~> 0.1"}
  ]
end
```

### 3. 配置编译路径

在 `mix.exs` 的 `project/0` 中添加 `src` 目录：

```elixir
def project do
  [
    app: :my_app,
    version: "0.1.0",
    elixir: "~> 1.18",
    elixirc_paths: ["lib", "src"],  # 添加这行
    deps: deps()
  ]
end
```

### 4. 获取依赖

```bash
mix deps.get
```

## 创建第一个页面

### 1. 创建页面文件

```elixir
# src/pages/index.ex
defmodule MyApp.Pages.Index do
  use Nex.Page

  def mount(_params) do
    %{
      title: "Welcome",
      message: "Hello, Nex!"
    }
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-8">
      <h1 class="text-4xl font-bold text-blue-600 mb-4">
        {@message}
      </h1>
      <p class="text-gray-600">
        欢迎使用 Nex 框架。这是一个极简的 Elixir Web 框架。
      </p>
    </div>
    """
  end
end
```

### 2. 创建布局文件

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

## 启动开发服务器

```bash
mix nex.dev
```

你会看到：

```
🚀 Nex dev server starting...

   App module: MyApp
   URL: http://localhost:4000
   Hot reload: enabled

Press Ctrl+C to stop.
```

打开浏览器访问 http://localhost:4000，你应该能看到 "Hello, Nex!" 页面。

## 添加交互

让我们添加一个简单的计数器来体验 HTMX 交互。

### 1. 更新页面

```elixir
# src/pages/index.ex
defmodule MyApp.Pages.Index do
  use Nex.Page

  def mount(_params) do
    %{
      title: "Counter",
      count: Nex.Store.get(:count, 0)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-8 text-center">
      <h1 class="text-6xl font-bold text-blue-600 mb-8">
        {@count}
      </h1>
      
      <div class="space-x-4">
        <button hx-post="/decrement"
                hx-target="#counter"
                hx-swap="innerHTML"
                class="px-6 py-3 bg-red-500 text-white rounded-lg text-xl">
          -
        </button>
        
        <button hx-post="/increment"
                hx-target="#counter"
                hx-swap="innerHTML"
                class="px-6 py-3 bg-green-500 text-white rounded-lg text-xl">
          +
        </button>
      </div>
      
      <div id="counter" class="mt-8 text-4xl font-bold">
        {@count}
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

### 2. 测试交互

刷新页面，点击 + 和 - 按钮，计数器会实时更新，无需页面刷新。

## 下一步

- [项目结构](./project-structure.md) - 了解目录组织
- [Pages](./pages.md) - 深入了解页面模块
- [HTMX 集成](./htmx.md) - 学习更多交互模式
