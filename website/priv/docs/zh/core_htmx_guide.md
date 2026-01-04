# 声明式交互与核心协议

Nex 选择 **HTMX** 作为默认的交互驱动，是因为其声明式的风格完美契合了我们对“简单性”的追求。Nex 不仅仅是返回 HTML 的后台，它还通过一套私有协议扩展了底层交互，提供了自动化的安全和状态管理。

## 1. 为什么押注声明式交互？

在主流的 Web 开发中，前端状态管理和 API 同步占据了巨大的工作量。我们相信：
*   **局部性 (Locality of Behavior)**：交互逻辑应当直接写在 HTML 元素上。
*   **服务端驱动**：复杂的业务状态应当保留在服务端，前端只负责渲染和触发动作。
*   **消除胶水代码**：通过 HTML 属性直接定义异步行为，消除了数千行的 JavaScript 模板代码。

## 2. 自动安全保障 (CSRF)

Nex 强制要求所有的非 GET 请求都必须通过 CSRF 校验。

### 自动化流程
1.  **令牌生成**：每次初始渲染页面时，Nex 会为当前会话生成一个强加密的 CSRF Token。
2.  **脚本注入**：Nex 自动在页面底部注入一段名为 `nex_script` 的轻量级 JS。
3.  **请求拦截**：这段脚本会自动监听所有的 HTMX 请求（`htmx:configRequest` 事件），并将 Token 放入 `X-CSRF-Token` 请求头中。
4.  **服务端验证**：Nex 的处理器会自动拦截并验证该 Header。如果验证失败，请求将被拒绝（403 Forbidden）。

> **全自动处理**：Nex 会自动为页面中所有的 `<form method="post">`（以及 PUT/PATCH/DELETE）标签注入隐藏的 CSRF 令牌，并为所有异步 HTMX 请求自动添加安全请求头。开发者无需手动编写任何安全相关的样板代码。

## 2. 状态隔离 (Page ID)

为了让 `Nex.Store` 能够区分不同的页面实例，Nex 引入了 `page_id` 概念。

*   **唯一性**：每次全页加载都会获得一个新的 `page_id`。
*   **自动传递**：注入的 JS 脚本会自动将当前页面的 `page_id` 放入 `X-Nex-Page-Id` 请求头中。
*   **作用**：服务端通过此 ID 隔离 ETS 中的存储空间，确保 A 标签页的购物车不会影响到 B 标签页。

## 3. 智能错误响应 (Smart Error Handling)

Nex 处理器能够识别请求的意图，并返回最适合的错误响应：

*   **HTMX 场景**：返回一个带样式的红色错误提示片段。这保证了即使后端崩溃，你的页面布局（导航栏、侧边栏）依然完整，只有请求的那部分会显示错误。
*   **API 场景**：返回标准的 `{"error": "..."}` JSON 格式。
*   **直接访问**：返回带 Stacktrace 的全屏 HTML 错误页。

## 4. 响应类型控制

在 Action 中，你可以返回不同的指令来控制 HTMX 的行为：

| 返回值类型 | HTTP Header | 浏览器行为 |
| :--- | :--- | :--- |
| **HEEx / String** | `Content-Type: text/html` | 局部替换指定 DOM |
| **`:empty`** | - | 无任何 DOM 变化 |
| **`{:redirect, url}`** | `HX-Redirect` | 客户端强制跳转到新 URL |
| **`{:refresh}`** | `HX-Refresh` | 客户端强制刷新当前页面 |
| **`Nex.stream/1`** | `Content-Type: text/event-stream` | 开启 SSE 监听 |
