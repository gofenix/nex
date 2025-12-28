# Deploying Nex Website to Railway

本文档描述如何将 Nex Website 部署到 [Railway](https://railway.app/)。

## 项目概述

- **语言**: Elixir 1.18
- **Web 服务器**: Bandit
- **端口**: 4000
- **依赖**: `{:nex_core, "~> 0.1"}` (Hex 包)

## Railway 部署架构

Railway 支持 Elixir 部署，使用 Buildpacks 自动构建和部署应用。

## 前置条件

1. [Railway 账户](https://railway.app/)
2. GitHub 账户（用于连接代码仓库）
3. Nex 项目代码仓库

## 部署步骤

### 方案选择

由于依赖已改为 Hex 包 `{:nex_core, "~> 0.1"}`，有两种部署方案：

| 方案 | 优点 | 缺点 |
|------|------|------|
| **Nix Packs** (推荐) | 配置简单，自动检测 Elixir | 稍慢，需等 buildpack 检测 |
| Dockerfile | 完全控制构建过程 | 需要维护 Dockerfile |

### 方案 A: Nix Packs 部署（推荐）

Railway 会自动检测 `mix.exs` 并使用 Nix Packs 构建。

#### 添加 Release 配置

修改 `website/mix.exs` 添加 release 配置：

```elixir
defmodule NexWebsite.MixProject do
  use Mix.Project

  def project do
    [
      app: :nex_website,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: ["src"],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # 添加 release 配置
      releases: [
        nex_website: [
          version: "0.1.0",
          applications: [
            nex_website: :permanent,
            nex: :permanent
          ]
        ]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {NexWebsite.Application, []}
    ]
  end

  defp deps do
    [
      {:nex_core, "~> 0.1"},
      # 确保 Bandit 被包含（nex 的传递依赖）
      {:bandit, "~> 1.0"}
    ]
  end
end
```

#### 创建 `railway.json`（可选）

在 `website/` 目录下创建：

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "buildCommand": "mix do compile, release"
  },
  "deploy": {
    "startCommand": "_build/prod/rel/nex_website/bin/nex_website start"
  }
}
```

### 方案 B: Dockerfile 部署

如果需要更多控制，可以使用 Dockerfile：

在 `website/` 目录下创建 `Dockerfile`：

```dockerfile
# -------- Build stage --------
FROM elixir:1.18-alpine AS build

# Install build dependencies
RUN apk add --no-cache build-base git

# Set mix environment
ENV MIX_ENV=prod

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

WORKDIR /app

# Copy mix files
COPY mix.exs mix.lock ./

# Install dependencies
RUN mix deps.get --only prod

# Copy source code
COPY src/ ./src/
COPY priv/ ./priv/

# Build the application
RUN mix compile
RUN mix release

# -------- Run stage --------
FROM alpine:3.19

# Install runtime dependencies
RUN apk add --no-cache openssl ncurses-libs libstdc++

WORKDIR /app

# Copy built application from build stage
COPY --from=build /app/_build/prod/rel/nex_website ./

# Set environment variables
ENV PORT=4000
ENV MIX_ENV=prod
ENV ERL_AFLAGS="-detached"

# Expose port
EXPOSE 4000

# Start the application
CMD ["bin/nex_website", "start"]
```

### 2. 在 Railway 创建新项目

1. 登录 [Railway Dashboard](https://railway.app/)
2. 点击 **New Project**
3. 选择 **Deploy from GitHub repo**
4. 选择你的 nex 仓库
5. Railway 会自动检测并创建服务

### 3. 配置服务

#### Nix Packs 部署

1. 在 Railway 项目设置中：
   - Root Directory: `website/`
   - 选择 **Nix Packs**（会自动检测 `mix.exs`）

2. 配置环境变量：

| 变量名 | 值 | 说明 |
|--------|-----|------|
| `PORT` | `4000` | Railway 默认会注入此变量 |
| `MIX_ENV` | `prod` | 生产环境 |
| `SECRET_KEY_BASE` | `(自动生成)` | 运行 `openssl rand -base64 48` 获取 |
| `HOST` | `(你的域名)` | 可选，用于生成 URL |

3. 设置健康检查：

```bash
# Health Check
GET /
Timeout: 30s
Interval: 60s
```

#### Dockerfile 部署

1. Root Directory: `website/`
2. 选择 **Dockerfile**
3. 环境变量配置同上

### 4. 域名配置（可选）

Railway 会自动生成一个 `.railway.app` 域名。

#### 自定义域名：

1. 进入项目 Settings → Domains
2. 点击 **Generate Domain** 或添加自定义域名
3. 配置 DNS 记录（CNAME）
4. 配置 SSL（Railway 自动处理）

### 5. 环境变量说明

| 变量 | 必需 | 默认值 | 说明 |
|------|------|--------|------|
| `PORT` | 否 | `4000` | HTTP 监听端口 |
| `MIX_ENV` | 否 | `prod` | Mix 环境 |
| `SECRET_KEY_BASE` | 是 | - | 加密密钥，用于 session/cookies |
| `HOST` | 否 | - | 应用主机名 |

### 6. 部署验证

部署完成后，检查：

1. **日志**: Railway Dashboard → Logs
2. **健康检查**: 访问生成的域名
3. **Metrics**: 查看内存、CPU 使用情况

## 常见问题

### Q: Hex 依赖版本冲突

**A**: 确保 `mix.lock` 被提交到仓库，锁定依赖版本：

```bash
git add mix.lock
git commit -m "chore: lock dependency versions"
```

### Q: 端口无法访问

**A**: 确认 `PORT` 环境变量正确，且 Bandit 使用该端口：

```elixir
port = System.get_env("PORT", "4000") |> String.to_integer()
{Bandit, plug: Nex.Router, scheme: :http, port: port}
```

### Q: 构建时间过长

**A**: 使用 Railway 的缓存层，或考虑使用 Docker 缓存挂载。

### Q: 静态文件无法加载

**A**: 确保在 `mix.exs` 中配置了 `priv` 目录，且 release 包含静态文件：

```elixir
releases: [
  nex_website: [
    include_executables_for: [:unix],
    applications: [...],
    steps: [:assemble, &copy_static_files/1]
  ]
]

defp copy_static_files(release) do
  File.cp_r!("priv/static", Path.join([release.path, "priv", "static"]))
  release
end
```

## 成本估算

Railway 按使用量计费：

| 计划 | 价格 | 包含 |
|------|------|------|
| Free Trial | $5/月 | 512MB RAM, $5 免费额度 |
| Pay As You Go | 按使用 | $0.0023/GB-hour RAM |

估算 Elixir 应用：
- ~100-300MB RAM 基础运行
- 月成本约 $0.20 - $2（取决于流量）

## 持续集成

Railway 自动配置 CI/CD：
- 推送到 `main` 分支 → 自动部署
- PR → 预览部署（可选）

配置分支部署：

1. Settings → New Service → Select Branch
2. 为 `staging`、`develop` 等分支创建独立环境

## 回滚

如需回滚：

1. 进入 Deployments 标签
2. 选择之前的成功部署
3. 点击 **Redeploy**

## 监控和日志

- **实时日志**: Dashboard → Logs
- **指标**: Dashboard → Metrics
- **告警**: Settings → Notifications 配置 Discord/Email/Slack

## 安全建议

1. 使用 Railway 的 **Private Services** 保护敏感端点
2. 配置 `SECRET_KEY_BASE` 等敏感变量
3. 启用 Railway 的 **VPC** 需要付费计划
4. 定期更新依赖

## 参考资源

- [Railway Elixir Guide](https://docs.railway.app/deploy/elixir)
- [Railway Docker Guide](https://docs.railway.app/deploy/dockerfiles)
- [Elixir Releases](https://hexdocs.pm/mix/Mix.Tasks.Release.html)
- [Bandit Documentation](https://hexdocs.pm/bandit)

## 快速命令参考

```bash
# 本地测试 release 构建
mix release
_build/prod/rel/nex_website/bin/nex_website start

# 本地测试 Docker 构建
docker build -t nex-website .
docker run -p 4000:4000 nex-website

# 生成 secret key
mix phx.gen.secret  # 或 openssl rand -base64 48
```
