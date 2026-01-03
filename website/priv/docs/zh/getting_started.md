# 快速开始

只需 5 分钟，你就能搭建并运行一个 Nex 应用。

## 🛠️ 安装 Nex

目前 Nex 建议通过源码安装命令行工具：

1.  **克隆 Nex 仓库**：
    ```bash
    git clone https://github.com/gofenix/nex.git
    cd nex/installer
    ```

2.  **编译并安装存档**：
    ```bash
    mix do deps.get, compile, archive.install
    ```

## 📦 创建新项目

运行 `nex.new` 任务来创建一个新的项目目录：

```bash
mix nex.new my_app
cd my_app
mix deps.get
```

## 🚀 5 分钟 Hello World

1.  **创建你的第一个页面**：
    Nex 使用文件系统路由。在 `src/pages/index.ex` 中写入：

    ```elixir
    defmodule MyApp.Pages.Index do
      use Nex

      def mount(_params) do
        %{message: "Hello, Nex!"}
      end

      def render(assigns) do
        ~H"""
        <div class="p-8 text-center">
          <h1 class="text-4xl font-bold text-indigo-600">{@message}</h1>
          <p class="mt-4 text-gray-600">欢迎来到极简的服务端驱动 Web 世界。</p>
          <button hx-post="/say_hi"
                  hx-target="#response"
                  class="mt-6 px-4 py-2 bg-indigo-500 text-white rounded">
            点我交互
          </button>
          <div id="response" class="mt-4 font-semibold text-green-600"></div>
        </div>
        """
      end

      def say_hi(_params) do
        "你好！这是一个通过声明式交互返回的 HTML 片段。"
      end
    end
    ```

2.  **运行开发服务器**：
    ```bash
    mix nex.dev
    ```

3.  **访问页面**：
    打开浏览器访问 `http://localhost:4000`。尝试点击按钮，感受无需手动编写 JS 的交互体验。

## 📁 项目结构

Nex 的目录结构遵循“约定优于配置”，旨在消除一切不必要的工程复杂性：

*   `src/`：**业务核心代码**
    *   `pages/`：存放页面模块（GET 请求，自动映射 URL）。
    *   `api/`：存放 JSON API 模块。
    *   `components/`：存放可复用的 Partial 组件。
    *   `layouts.ex`：应用的整体 HTML 模板（必须包含 `<body>` 标签）。
*   `lib/`：存放通用的业务逻辑（如数据库模型、外部集成）。
*   `.env`：环境变量配置文件（自动加载）。
*   `mix.exs`：项目依赖管理。
