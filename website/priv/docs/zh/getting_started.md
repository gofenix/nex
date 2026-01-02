# 快速开始

Nex 提供了一个便捷的安装程序来快速启动新项目。

## 1. 安装安装程序

```bash
mix archive.install hex nex_new
```

## 2. 创建新项目

运行 `nex.new` Mix 任务来创建一个新的项目目录。

```bash
mix nex.new my_app
cd my_app
```

## 3. 理解项目结构

每个 Nex 项目都遵循一个简单、基于约定的结构。

```text
my_app/
├── src/
│   ├── pages/           # 页面模块 (自动路由)
│   │   ├── index.ex     # GET /
│   │   └── [id].ex      # GET /id (动态路由)
│   ├── api/             # JSON API 端点
│   │   └── todos/
│   │       └── index.ex # GET/POST /api/todos
│   ├── components/      # 可复用组件
│   └── layouts.ex       # 布局模板
├── mix.exs
└── Dockerfile           # 生产环境部署
```

**核心概念** - 只需在 `src/pages/` 中放入一个文件，它就会自动成为一个路由。无需路由器配置！

## 4. 运行开发模式

Nex 包含一个内置的开发服务器，默认启用了热重载。你的代码更改会立即反映出来。

```bash
mix nex.dev
```

在浏览器中打开 `http://localhost:4000`。你应该能看到你的新 Nex 应用正在运行！

## 5. 构建你的第一个页面

创建一个带有 HTMX 处理程序的新页面。页面只是渲染 HTML 的 Elixir 模块。

> 查看 examples 目录，获取包含 HTMX 处理程序、实时流式传输等功能的完整工作示例。

## 6. 使用 Docker 部署

每个 Nex 项目都包含一个 Dockerfile。可以部署到任何支持容器的平台。

```bash
docker build -t my_app .
docker run -p 4000:4000 my_app
```

### 常用部署平台

*   **Railway** - 连接你的 GitHub 仓库并自动部署
*   **Fly.io** - 使用 `fly launch` (自动检测 Dockerfile)
*   **Render** - 从你的仓库创建一个新的 Web Service

## 下一步

*   [路由系统](/docs/zh/routing_guide)
*   [HTMX 集成](/docs/zh/htmx_guide)
*   [状态管理](/docs/zh/state_management)
