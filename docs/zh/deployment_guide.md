# Nex 应用部署指南

本指南涵盖了如何将 Nex 应用（无论是 Web 页面还是 JSON API）部署到生产环境。

由于 Nex 采用了统一的架构，Web 页面和 API 运行在同一个 Elixir 进程中，因此它们的部署方式完全相同。

## 目录

- [开发 vs 生产](#开发-vs-生产)
- [静态资源策略](#静态资源策略)
- [启动命令](#启动命令)
- [环境变量](#环境变量)
- [Docker 部署](#docker-部署)

---

## 开发 vs 生产

Nex 提供了两个 distinct 的 Mix 任务来运行应用：

### 开发模式 (`mix nex.dev`)
*   开启热重载（Live Reload）：修改文件自动刷新浏览器。
*   显示详细错误页面。
*   默认端口：4000

### 生产模式 (`mix nex.start`)
*   **禁用热重载**：优化性能。
*   仅显示简洁的错误信息。
*   加载 `.env` 文件（如果存在）。
*   **自动编译**：启动前会自动确保代码已编译。

---

## 静态资源策略

**重要：Nex 框架不提供本地静态文件服务。**

为了保持框架的极简和高性能，Nex 移除了 `Plug.Static`。这意味着你不能将图片、CSS 或 JS 文件放在 `priv/static` 目录下并期望通过 URL 访问它们。

### 如何处理静态资源？

1.  **CSS/JS**: 使用 CDN。
    *   Tailwind CSS 和 DaisyUI 默认通过 CDN 加载（见 `src/layouts.ex`）。
    *   如果需要自定义脚本，直接在 Layout 中引用外部 URL。

2.  **图片/媒体文件**:
    *   **推荐**: 上传到对象存储（如 AWS S3, Cloudflare R2, 阿里云 OSS）并获取公共 URL。
    *   **内联**: 对于极小的图标（SVG），直接将代码内联到 HEEx 模板中。

### 为什么没有构建步骤？

Nex 采用了 **No-Build** 策略。
*   没有 Webpack/Vite/Esbuild。
*   没有 `node_modules`。
*   没有 `npm run build`。

这意味着你的“前端部署”实际上就是部署 Elixir 后端代码。

---

## 启动命令

在生产环境中，使用以下命令启动服务：

```bash
mix nex.start
```

该命令会自动：
1.  设置应用环境为 `:prod`。
2.  启动 Web 服务器 (Bandit)。
3.  初始化应用监督树。

---

## 环境变量

Nex 尊重 [12-Factor App](https://12factor.net/) 原则，通过环境变量进行配置。

| 变量名 | 默认值 | 说明 |
| :--- | :--- | :--- |
| `PORT` | `4000` | HTTP 监听端口 |
| `HOST` | `0.0.0.0` | 绑定 IP 地址 |

你可以在项目根目录创建 `.env` 文件，`mix nex.start` 会自动加载它：

```bash
# .env
PORT=8080
SECRET_KEY=...
```

---

## Docker 部署

这是推荐的生产部署方式。每个 Nex 项目在创建时都会生成一个生产就绪的 `Dockerfile`。

### 1. 构建镜像

```bash
docker build -t my_app .
```

### 2. 运行容器

```bash
docker run -p 4000:4000 -e PORT=4000 my_app
```

### Dockerfile 解析

Nex 的 Dockerfile 基于 `elixir:1.18-alpine`，体积小且安全。

```dockerfile
FROM elixir:1.18-alpine

# 安装运行时依赖
RUN apk add --no-cache build-base git openssl ncurses-libs

WORKDIR /app

# 安装 Hex 和 Rebar
RUN mix local.hex --force && mix local.rebar --force

# 复制项目文件
COPY . .

# 获取依赖
RUN mix deps.get

# 暴露端口
EXPOSE 4000

# 启动命令
CMD ["mix", "nex.start"]
```

### 部署平台适配

*   **Fly.io / Railway / Render**: 这些平台会自动检测 Dockerfile。只需连接 GitHub 仓库即可自动构建和部署。
*   **Kubernetes / VPS**: 使用上述 Docker 流程即可。
