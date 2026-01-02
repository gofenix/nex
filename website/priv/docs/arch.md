# Nex 架构分析文档

## 1. 概述

Nex 是一个基于 Elixir 的极简 Web 框架，专为 HTMX 驱动的应用设计。其核心理念是利用 Elixir 的高并发能力和 HTMX 的前端交互能力，提供一种无需复杂 JavaScript 构建流程的现代 Web 开发体验。

Nex 框架主要由两部分组成：
1.  **Framework Core (`framework/`)**: 运行时核心，包含路由、请求处理、状态管理、组件模型等。
2.  **Installer (`installer/`)**: 项目生成器，用于快速搭建 Nex 项目。

## 2. 核心架构 (Framework Core)

Nex 的核心架构围绕着 Plug、HTMX 和 Elixir 的 OTP 模型构建。

### 2.1 请求处理生命周期 (Request Lifecycle)

Nex 使用 `Plug.Router` 作为入口，但将大部分路由逻辑委托给 `Nex.Handler` 进行动态分发。

```mermaid
graph TD
    Client[Client (Browser/HTMX)] -->|HTTP Request| Router[Nex.Router]
    Router -->|Plug Pipeline| Parsers[Plug.Parsers]
    Parsers -->|Dispatch| Handler[Nex.Handler]
    
    Handler -->|Analysis| RouteType{Route Type}
    
    RouteType -->|/nex/live-reload-ws| WS[WebSockAdapter]
    RouteType -->|/api/*| API[API Handler]
    RouteType -->|/sse/*| SSE[SSE Handler]
    RouteType -->|/*| Page[Page Handler]
    
    Page -->|Route Discovery| Discovery[Nex.RouteDiscovery]
    Discovery -->|Find Module| PageModule[User Page Module]
    
    PageModule -->|mount/1| Assigns[Assigns]
    Assigns -->|render/1| HEEx[HEEx Template]
    HEEx -->|Layout Injection| Layout[Layout Module]
    Layout -->|HTML Response| Client
```

### 2.2 文件系统路由 (Route Discovery)

Nex 采用文件系统路由（File-system Routing），通过 `Nex.RouteDiscovery` 模块在运行时或编译时扫描 `src/` 目录。

*   **Pages (`src/pages/`)**: 映射到 Web 页面路由。
*   **API (`src/api/`)**: 映射到 JSON API 路由。

支持的路由模式：
*   **静态路由**: `src/pages/users.ex` -> `/users`
*   **动态路由**: `src/pages/users/[id].ex` -> `/users/123`
*   **Catch-all 路由**: `src/pages/docs/[...path].ex` -> `/docs/getting-started/installation`

路由发现机制会将路径段解析为模块名，例如 `/users/123` 会尝试匹配 `MyApp.Pages.Users.Id` 模块，并将 `123` 作为参数传递。

### 2.3 组件模型 (Component Model)

Nex 提供了两种主要的 UI 组件类型：

1.  **Nex (`use Nex`)** - 统一模块类型，可用于 Page、Api、SSE:
    *   **有状态**: 通过 `Nex.Store` 维持页面级状态。
    *   **路由映射**: 直接对应 URL 路由。
    *   **生命周期**: `mount/1` (初始化数据), `render/1` (渲染 UI), Action Functions (处理 POST 请求)。
    *   **HTMX 集成**: 自动处理 CSRF Token 和 Page ID。

2.  **Nex (`use Nex`) - Partial 组件**:
    *   **无状态**: 纯函数组件。
    *   **无路由**: 仅供 Page 调用。
    *   **复用性**: 用于构建可复用的 UI 元素（如按钮、列表项）。

### 2.4 状态管理 (Nex.Store)

Nex 引入了 **Page-scoped State** 的概念，旨在模拟类似于 React/Vue 组件的状态体验，但运行在服务器端。

*   **Page ID**: 每个页面渲染时生成唯一的 `_page_id`。
*   **Storage**: 使用 `ETS` 表存储状态，键为 `{page_id, key}`。
*   **生命周期**: 状态随页面刷新而重置（Ephemeral）。
*   **TTL**: 默认 1 小时过期，由 `Nex.Store` GenServer 定期清理。

### 2.5 监督树 (Supervision Tree)

Nex 框架自身维护一个监督树，确保核心服务的稳定性。

```mermaid
graph TD
    AppSup[User App Supervisor] --> NexSup[Nex.Supervisor]
    
    NexSup --> PubSub[Phoenix.PubSub]
    NexSup --> Store[Nex.Store (GenServer + ETS)]
    NexSup --> Reloader[Nex.Reloader (Dev Only)]
    
    subgraph "Framework Internal"
        PubSub -->|Broadcast| ReloadWS[Live Reload WebSocket]
        Store -->|State Mgmt| Pages[Page Processes]
        Reloader -->|File Watch| FileSystem[File System]
    end
```

*   **Phoenix.PubSub**: 用于开发环境下的热重载通知。
*   **Nex.Store**: 管理页面状态的存储和清理。
*   **Nex.Reloader**: 监听文件变化并触发重编译和浏览器刷新。

### 2.6 Server-Sent Events (SSE)

Nex 通过 `Nex.SSE` 模块提供对 SSE 的原生支持。
*   **定义**: 通过 `use Nex` 定义流式端点。
*   **实现**: `Nex.Handler` 识别 SSE 端点，设置正确的 Headers (`text/event-stream`)，并建立长连接。
*   **回调**: 支持 `stream/2` 回调模式，允许实时推送数据。

## 3. 安装器架构 (Installer)

`installer` 目录包含 `mix nex.new` 任务的实现。

*   **模板生成**: 通过内嵌的字符串模版（Heredocs）生成项目脚手架。
*   **依赖管理**: 自动运行 `mix deps.get` 安装依赖。
*   **目录结构**:
    *   `src/pages`: 页面代码
    *   `src/api`: API 代码
    *   `src/components`: 组件代码
    *   `src/layouts.ex`: 布局定义
    *   `mix.exs`: 项目配置
    *   `Dockerfile`: 容器化部署支持

## 4. 总结

Nex 的架构设计极其精简，通过以下方式降低复杂度：
1.  **去中心化路由**: 无需维护 `router.ex` 文件，利用文件系统结构。
2.  **统一处理流**: `Nex.Handler` 统一处理所有类型的请求，简化了中间件链。
3.  **服务器端状态**: `Nex.Store` 使得在服务端维护 UI 状态变得简单，配合 HTMX 可实现复杂的交互而无需客户端状态管理。
