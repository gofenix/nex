# 什么是 Nex？

Nex 是一个为 **HTMX** 时代量身定制的极致简约 Elixir Web 框架。它的核心目标是：**消除前端开发的复杂性，让 Web 开发重回“服务端驱动”的快乐。**

## 🚀 框架定位

Nex 不是 Phoenix 的替代品，而是针对特定场景的**轻量化选择**。

*   **极简主义**：没有繁琐的配置文件，没有复杂的 JavaScript 构建流程（No Node.js, No Webpack/Esbuild）。
*   **HTMX 原生**：将 HTMX 作为交互的第一公民，通过简单的 HTML 属性实现复杂的异步交互。
*   **Vibe Coding 友好**：专门为 AI 辅助编程优化，代码结构极其局部化（Locality of Behavior）。

## ✨ 核心特性

### 1. HTMX 驱动
无需编写一行 JavaScript，通过 `hx-post`、`hx-target` 等属性，直接从服务端获取 HTML 片段并更新页面。Nex 会自动处理 CSRF 保护和 Page ID 追踪。

### 2. 文件系统路由
项目结构即路由。
*   `src/pages/index.ex` -> `/`
*   `src/pages/users/[id].ex` -> `/users/123`
*   `src/api/login.ex` -> `/api/login`

### 3. 服务端状态管理 (`Nex.Store`)
Nex 提供了一个极其简单、基于页面的状态存储机制。状态在页面刷新时自动重置，在异步交互中持续保持，完美解决 HTMX 场景下的临时状态存储问题。

### 4. 智能错误处理
Nex 会根据请求类型自动选择最佳的错误展示方式：
*   **HTMX 请求**：返回红色错误片段，不破坏页面布局。
*   **API 请求**：返回标准 JSON 错误格式。
*   **浏览器导航**：返回带 Stacktrace 的全屏错误页（开发模式下）。

## 🎯 适用场景

| 适合使用 Nex | 不适合使用 Nex |
| :--- | :--- |
| 内部管理系统、后台看板 | 复杂的实时多人协作工具（建议使用 LiveView） |
| CRUD 类应用、原型快速开发 | 极其重度的客户端动画/交互 |
| 追求极致开发效率的个人项目 | 需要高度自定义 Webhook 处理的底层服务 |
| 配合 AI 快速生成功能的场景 | 大型、超长期维护的企业级遗留系统 |

## ⚖️ 框架对比

| 特性 | Nex | Phoenix | React/Vue |
| :--- | :--- | :--- | :--- |
| **学习曲线** | 极低（只需 HTML/Elixir） | 中/高 | 高（需要掌握 JS 生态） |
| **构建工具** | 无 | Esbuild/Tailwind CLI | Vite/Webpack |
| **状态同步** | 自动 (HTMX + Store) | 强 (LiveView) | 手动 (API + State) |
| **JS 代码量** | 接近 0 | 少量 | 100% |
| **AI 编写难度** | 极易 | 一般 | 较难（上下文散乱） |
