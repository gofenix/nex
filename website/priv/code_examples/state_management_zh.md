# Nex 状态管理指南

Nex 采用独特的**页面级状态 (Page-Scoped State)** 机制，结合了服务端渲染的无状态特性和 SPA 的有状态体验。

## 目录

- [核心概念](#核心概念)
- [状态生命周期](#状态生命周期)
- [Nex.Store API](#nexstore-api)
- [状态清理机制](#状态清理机制)
- [最佳实践](#最佳实践)

---

## 核心概念

传统的服务端渲染 Web 框架通常是无状态的（Stateless），每次请求都是独立的。而 LiveView 等技术则在服务器端维护长连接进程状态。

Nex 选择了中间路线：**基于 ETS 的临时页面状态**。

1.  **Page ID**: 每个页面加载时，框架生成一个唯一的 `_page_id`。
2.  **自动传递**: 这个 ID 通过 HTMX 自动在每次请求中传递 (`X-Nex-Page-Id` 头)。
3.  **独立存储**: 状态存储在内存中 (ETS)，以 `page_id` 为命名空间隔离。

这意味着：
*   **刷新即重置**: 刷新浏览器会生成新的 `page_id`，旧状态丢失。
*   **多标签页隔离**: 同一个 URL 在两个标签页中打开，状态互不干扰。
*   **无长连接**: 不需要 WebSocket 维持状态，更适合 Serverless 环境。

---

## 状态生命周期

1.  **创建**: 首次 GET 请求访问页面时，生成 `page_id`。
2.  **使用**: 页面上的 HTMX 交互（点击、表单）携带 `page_id`，后端通过 `Nex.Store` 读写状态。
3.  **过期**: 状态设有 TTL (默认 1 小时)。每次访问会刷新 TTL。
4.  **销毁**: 超过 TTL 未访问，或服务器重启，状态被清除。

---

## Nex.Store API

Nex 提供了简单的 Key-Value API 来管理状态。

### 获取状态 `get/2`

```elixir
# 获取值，如果不存在返回默认值
count = Nex.Store.get(:count, 0)
```

### 设置状态 `put/2`

```elixir
Nex.Store.put(:user, %{name: "Alice"})
```

### 更新状态 `update/3`

原子更新操作，避免并发竞争。

```elixir
# update(key, default_value, update_function)
Nex.Store.update(:count, 0, fn count -> count + 1 end)
# 简写
Nex.Store.update(:count, 0, &(&1 + 1))
```

### 删除状态 `delete/1`

```elixir
Nex.Store.delete(:temp_data)
```

---

## 状态清理机制

Nex 内部启动了一个 GenServer 定期清理过期状态，防止内存泄漏。

*   **默认 TTL**: 1 小时 (`:timer.hours(1)`)
*   **清理间隔**: 5 分钟 (`:timer.minutes(5)`)
*   **触达机制**: 每次 `Nex.Store` 操作（读或写）都会“触达 (touch)”当前页面，重置其 TTL。

**注意**: 由于状态存储在内存 (ETS) 中，如果应用部署在多节点且没有开启粘性会话 (Sticky Sessions)，或者应用重启，状态将会丢失。Nex 适用于存储**临时 UI 状态**（如表单步骤、UI 开关、即时计数器），持久化数据应始终存入数据库。

---

## 最佳实践

1.  **区分状态类型**:
    *   **临时 UI 状态** -> `Nex.Store` (如：下拉菜单展开/收起、未保存的表单草稿)
    *   **业务数据** -> 数据库 (Postgres/SQLite)

2.  **不要滥用 Store**:
    不要在 Store 中存储大量数据（如整个用户列表），这会消耗服务器内存。应该存 ID，需要时从数据库查。

3.  **初始化**:
    始终在 `mount/1` 函数中初始化页面所需的 Store 状态，或者处理 `get/2` 返回 `nil` 的情况。

```elixir
def mount(_params) do
  # 推荐：在页面加载时初始化
  %{
    count: Nex.Store.get(:count, 0),
    items: fetch_items_from_db() # 业务数据直接查库
  }
end
```
