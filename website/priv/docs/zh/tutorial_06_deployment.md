# 部署上线

Nex 应用是标准的 Elixir 应用，推荐通过容器化方式在各种平台上运行。

## 🐳 Docker 部署 (推荐)

每个通过 `mix nex.new` 创建的项目都包含一个优化过的 `Dockerfile`。

1.  **构建镜像**：
    ```bash
    docker build -t my_nex_app .
    ```

2.  **运行容器**：
    ```bash
    docker run -p 4000:4000 -e SECRET_KEY_BASE=your_secret my_nex_app
    ```

## 🚀 云平台部署

### Railway (最快)
1.  连接你的 GitHub 仓库。
2.  Railway 会自动检测 `Dockerfile` 并开始构建。
3.  在变量设置中添加 `SECRET_KEY_BASE`（可通过 `mix phx.gen.secret` 生成）。

### Fly.io
1.  安装 `flyctl`。
2.  运行 `fly launch`。
3.  Fly.io 会自动检测 Elixir 项目并引导你完成部署。

### Render
1.  创建新的 "Web Service"。
2.  连接你的仓库，选择环境为 "Docker"。
3.  配置端口为 4000。

## 📋 部署检查清单

*   [ ] **SECRET_KEY_BASE**：确保在环境变量中设置了该密钥。
*   [ ] **静态资源**：虽然 Nex 支持基础的静态文件服务，但在高负载下建议使用 CDN。
*   [ ] **健康检查**：配置负载均衡器检查 `/` 路径，状态码 200 表示应用正常。
