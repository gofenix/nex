# Nex 官网技术实施方案

## 1. 项目概述

基于 Nex 极简 Elixir Web 框架，参考 Phoenix Framework 官网设计风格，构建 Nex 官网。官网作为仓库的一部分放在 `website/` 目录。

**设计目标**：
- **Claude 配色风格**：采用 Claude 标志性的米色/奶油色背景（`#FBF9F1`），深炭黑色文字（`#1A1A1A`），紫色（`#7B61FF`）和金色作为点缀色。
- **DaisyUI 驱动**：利用框架内置的 DaisyUI 提供的 UI 组件，结合 Tailwind CSS。
- **内容导向**：从代码中提取 Nex 的核心价值：文件系统路由、HTMX 原生集成、极简 API、实时热重载。
- **极简结构**：移除博客和搜索功能，专注于核心功能的展示。

---

## 2. 参考设计：Phoenix 官网特点

### 2.1 布局结构
- **顶部导航栏**：固定定位，包含 Logo、文档、社区、源码、博客入口
- **Hero 区域**：醒目的价值主张 + 代码示例
- **功能特性区**：图标 + 标题 + 描述的卡片矩阵
- **代码演示区**：突出 LiveView/HTMX 声明式编程范式
- **用户案例区**：知名客户 Logo 信任背书
- **页脚**：链接矩阵、社交媒体、版权信息

### 2.2 配色方案
- 主色调：橙色系（`#F58426` 或 Nex 品牌色）
- 大量留白，灰色文字
- 支持亮/暗色模式切换

### 2.3 交互特点
- 平滑的滚动动画
- 悬停效果
- 移动端汉堡菜单

---

## 3. 网站结构

```
website/
├── src/
│   ├── layouts.ex              # 主布局（DaisyUI Navbar + Footer）
│   ├── pages/
│   │   ├── index.ex            # 首页 /
│   │   ├── features.ex         # 特性详解 /features
│   │   └── getting_started.ex  # 快速入门 /getting-started
│   └── partials/
│       ├── nav.ex              # 导航栏组件
│       ├── footer.ex           # 页脚组件
│       ├── hero.ex             # Hero 区域组件
│       └── code_showcase.ex    # 代码演示组件
├── priv/
│   └── static/                 # 静态资源
├── mix.exs                     # 项目配置（依赖本地 ../framework）
└── .env
```

---

## 4. 页面规划

### 4.1 首页 (`/`)
| 区块 | 内容 |
|------|------|
| Hero | Nex Logo + "The minimalist way to build Elixir apps" + 快速安装 |
| 核心优势 | 三大支柱：Zero Config (File-based), HTMX Powered, Elixir Performance |
| 代码演示 | 一个完整的计数器或简单的 API 示例 |
| 为什么选择 Nex | 简单优于复杂，适合快速原型和现代 Web 开发 |

### 4.2 特性详解 (`/features`)
- **文件系统路由**：`src/pages/index.ex` -> `/`
- **HTMX 原生集成**：无需 JS 即可实现动态交互
- **状态管理**：`Nex.Store` 处理页面间和进程内的状态
- **API 支持**：简单定义的函数即是 REST 端点

### 4.3 快速入门 (`/getting-started`)
- 安装命令行工具
- `nex new my_app`
- `mix nex.dev`
- 你的第一个页面

---

## 5. 技术实现方案

### 5.1 布局系统 (DaisyUI + Claude Colors)

```elixir
defmodule NexWebsite.Layouts do
  use Nex.Page

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="zh-CN" data-theme="cupcake">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>{@title}</title>
        <script src="https://cdn.tailwindcss.com?plugins=typography,forms,aspect-ratio"></script>
        <link href="https://cdn.jsdelivr.net/npm/daisyui@4.12.23/dist/full.min.css" rel="stylesheet" type="text/css" />
        <style>
          :root {
            --claude-bg: #FBF9F1;
            --claude-text: #1A1A1A;
            --claude-purple: #7B61FF;
          }
          body { background-color: var(--claude-bg); color: var(--claude-text); }
        </style>
      </head>
      <body>
        <.nav />
        <main class="min-h-screen">
          {raw(@inner_content)}
        </main>
        <.footer />
      </body>
    </html>
    """
  end
end
```

### 5.2 导航栏 (DaisyUI)

```elixir
defmodule NexWebsite.Partials.Nav do
  use Nex.Page

  def render(assigns) do
    ~H"""
    <div class="navbar bg-base-100 shadow-sm sticky top-0 z-50">
      <div class="flex-1">
        <a href="/" class="btn btn-ghost text-xl font-bold tracking-tighter">Nex</a>
      </div>
      <div class="flex-none">
        <ul class="menu menu-horizontal px-1">
          <li><a href="/features">Features</a></li>
          <li><a href="/getting-started">Get Started</a></li>
          <li><a href="https://github.com/fenix/nex">GitHub</a></li>
        </ul>
      </div>
    </div>
    """
  end
end
```

### 5.3 HTMX 交互

```elixir
defmodule NexWebsite.Pages.Index do
  use Nex.Page

  def mount(_params) do
    %{
      title: "Nex - 极简 Elixir Web 框架",
      active: "home",
      features: [
        %{icon: "📁", title: "基于文件路由", desc: "自动发现路由，零配置"},
        %{icon: "⚡", title: "HTMX 集成", desc: "服务端渲染，零 JS"},
        %{icon: "🔥", title: "热重载", desc: "开发环境即时生效"},
        %{icon: "🔒", title: "CSRF 保护", desc: "开箱即用的安全"}
      ]
    }
  end

  def render(assigns) do
    ~H"""
    <div class="home-page">
      <section class="hero py-20 text-center">
        <h1 class="text-5xl font-bold mb-6">
          极简而强大的 <span class="text-orange-500">Elixir</span> Web 框架
        </h1>
        <p class="text-xl text-gray-600 mb-8">
          基于 HTMX 的服务端渲染，无需编写客户端 JavaScript
        </p>
        <div class="flex justify-center gap-4">
          <a href="/getting-started" class="btn-primary">快速开始</a>
          <a href="/docs" class="btn-secondary">阅读文档</a>
        </div>
      </section>

      <section class="features py-16 bg-gray-50">
        <div class="max-w-7xl mx-auto px-4">
          <h2 class="text-3xl font-bold text-center mb-12">核心特性</h2>
          <div class="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
            <NexWebsite.Partials.FeatureCard.render
              :for={{feature, i} <- Enum.with_index(@features)}
              feature={feature}
            />
          </div>
        </div>
      </section>
    </div>
    """
  end
end
```

### 5.4 博客系统

```elixir
defmodule NexWebsite.Pages.Blog do
  use Nex.Page

  def mount(_params) do
    %{
      title: "博客",
      posts: [
        %{slug: "v0.1.2-released", title: "v0.1.2 发布", date: "2024-12-28"},
        %{slug: "introducing-htmx", title: "介绍 HTMX 集成", date: "2024-12-15"},
        %{slug: "file-based-routing", title: "基于文件路由详解", date: "2024-12-01"}
      ]
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-4 py-12">
      <h1 class="text-4xl font-bold mb-8">博客</h1>
      <div class="space-y-6">
        <article :for={post <- @posts} class="border rounded-lg p-6 hover:shadow-lg">
          <span class="text-gray-500 text-sm">{post.date}</span>
          <h2 class="text-2xl font-semibold mt-2">
            <a href={"/blog/" <> post.slug} class="hover:text-orange-500">
              {post.title}
            </a>
          </h2>
        </article>
      </div>
    </div>
    """
  end
end
```

### 5.5 样式方案

使用 Tailwind CSS 类名，通过 CDN 或构建工具引入：

```html
<!-- 基础样式约定 -->
.btn-primary {
  @apply bg-orange-500 text-white px-6 py-3 rounded-lg hover:bg-orange-600 transition;
}
.btn-secondary {
  @apply border border-gray-300 px-6 py-3 rounded-lg hover:border-orange-500 transition;
}
.feature-card {
  @apply bg-white p-6 rounded-xl shadow-sm hover:shadow-md transition;
}
```

---

## 6. 部署方案

### 6.1 开发环境
```bash
mix nex.dev
```

### 6.2 生产构建
```bash
mix nex.release
```

### 6.3 部署平台
- **Fly.io**：官方推荐，Elixir 友好
- **Railway**：简单部署
- **Docker**：自托管

---

## 7. TODO 列表

- [ ] 创建 `website/` 目录并配置 `mix.exs`
- [ ] 编写 `NexWebsite.Layouts` (Claude 配色)
- [ ] 实现首页 `Index`
- [ ] 实现 `Features` 页面
- [ ] 实现 `GettingStarted` 页面
- [ ] 整合 DaisyUI 组件
- [ ] 提取并整理框架核心文档作为页面内容

---

## 8. 待确认事项

1. **品牌配色**：Nex 的主色调是什么？（橙色？蓝色？）
2. **Logo**：是否有官方 Logo 文件？
3. **内容来源**：文档内容是否从框架 README 同步？
4. **博客系统**：是否需要 Markdown 渲染支持？
5. **搜索功能**：是否需要全文搜索？

---

*方案版本：v1.0*
*创建时间：2024-12-28*
