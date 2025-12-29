# Nex (HTMX) vs Phoenix LiveView

Nex 和 Phoenix LiveView 都是在 Elixir 生态中构建 Web 应用的优秀选择，但它们采用了截然不同的架构模型。了解这些差异有助于你为项目选择正确的工具。

## 核心区别摘要

| 特性 | Nex (HTMX) | Phoenix LiveView |
| :--- | :--- | :--- |
| **通信协议** | **HTTP** (无状态请求/响应) | **WebSocket** (有状态长连接) |
| **状态位置** | **客户端/临时** (ETS 缓存，刷新即逝) | **服务端进程** (GenServer，持续存在) |
| **并发模型** | 每次交互都是独立进程 (Plug 模型) | 每个用户对应一个长期运行的进程 |
| **部署成本** | 低 (无状态，易于水平扩展) | 中/高 (需维护大量长连接，内存占用较高) |
| **适用场景** | CRUD 应用、管理后台、内容型网站 | 实时协作、游戏、高频数据更新面板 |

---

## 1. 通信模型

### Nex: HTTP First
Nex 的核心是 `Nex.Handler`，它是一个标准的 Plug 管道。
*   **交互**：点击按钮 -> 发送 HTTP POST -> 服务器返回 HTML 片段 -> HTMX 更新 DOM。
*   **优势**：符合传统 Web 及其缓存机制；网络不稳定时表现更好（标准的 HTTP 重试）；对服务器资源占用是瞬时的。
*   **代码证据**：`Nex.Handler` 处理 `post` 请求并返回 `send_resp(200, html)`。

### LiveView: WebSocket First
LiveView 在页面加载后建立 WebSocket 连接。
*   **交互**：点击按钮 -> 通过 WS 发送消息 -> 服务器进程处理 -> 通过 WS 推送 Diff -> JS 更新 DOM。
*   **优势**：极低的延迟；可以向客户端主动推送消息（PubSub）。

---

## 2. 状态管理

### Nex: 页面级临时状态 (Page-Scoped State)
Nex 使用 `Nex.Store` (基于 ETS) 来模拟状态。
*   **生命周期**：状态绑定到 `page_id`。刷新页面会生成新 ID，旧状态丢失。
*   **无连接**：你不需要维持连接来保持状态。状态通过 HTTP Header 中的 `X-Nex-Page-Id` 在请求间传递。
*   **代码证据**：`Nex.Store.put/2` 和 `Nex.Handler` 中的 `get_page_id_from_request/1`。

### LiveView: 进程状态 (Process State)
LiveView 的状态保存在 GenServer 进程的内存中 (`socket.assigns`)。
*   **生命周期**：只要 WebSocket 连接存在，状态就存在。
*   **崩溃恢复**：如果进程崩溃，状态丢失，客户端尝试重连。

---

## 3. 为什么选择 Nex?

### ✅ 简单性 (Simplicity)
Nex 移除了 LiveView 的复杂性（挂载生命周期、变更追踪、临时分配等）。你只需要编写简单的函数接收参数并返回 HTML。

### ✅ 易于扩展 (Scalability)
由于是基于 HTTP 的短连接，Nex 应用更容易在 Serverless 平台（如 AWS Lambda, Fly.io Machines）上部署和自动伸缩，不需要担心 WebSocket 连接断开或重新路由的问题。

### ✅ 渐进式增强
Nex 本质上是服务端渲染的 HTML。这使得它对 SEO 更友好，且更容易与现有的 HTTP 生态系统（负载均衡、CDN 缓存）集成。

---

## 4. 什么时候使用 LiveView?

*   你拥有 **极高频率** 的 UI 更新（如即时多人游戏、股票K线图）。
*   你需要 **服务器主动推送** 变更到客户端（虽然 Nex 支持 SSE，但 LiveView 的 PubSub 更无缝）。
*   你需要复杂的 **客户端-服务端状态同步**，且不能容忍任何 HTTP 开销。

## 总结

*   **Nex** 是 "Elixir 版的 Rails + Hotwire" 或 "PHP Laravel + HTMX"。适合 90% 的 Web 应用。
*   **LiveView** 是追求极致交互体验的 SPA 替代方案。
