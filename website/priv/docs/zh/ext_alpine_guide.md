# Alpine.js 集成

虽然 Nex 倡导“服务端驱动”和“极简交互”，但在处理纯客户端逻辑（如动画、过渡、复杂的模态框状态）时，Alpine.js 是 Nex 的完美拍档。

## 1. 为什么使用 Alpine.js？

Nex 处理的是 **服务器通信**，而 Alpine.js 处理的是 **本地 UI 逻辑**。

*   **轻量级**：没有虚拟 DOM，直接操作现有 HTML。
*   **声明式**：通过 `x-data`, `x-show`, `x-on` 等属性直接在 HTML 中编写逻辑。
*   **零构建**：直接通过 CDN 引入，符合 Nex 的开发哲学。

## 2. 集成方式

在你的 `src/layouts.ex` 的 `<head>` 标签中引入（建议使用 `defer`）：

```html
<script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
```

## 3. 核心应用模式

### A. 全局状态与持久化
你可以在 `<body>` 标签上定义全局状态，并利用 `localStorage` 实现持久化（如主题切换）。

```elixir
# src/layouts.ex
<body
  x-data="{ theme: localStorage.getItem('theme') || 'light' }"
  x-init="$watch('theme', val => localStorage.setItem('theme', val))"
  x-bind:data-theme="theme"
>
  <button @click="theme = theme === 'light' ? 'dark' : 'light'">切换主题</button>
  {raw(@inner_content)}
</body>
```

### B. 局部 UI 状态 (Tabs & Modals)
利用 Alpine 处理不需要服务器参与的 UI 切换，保持极速响应。

```elixir
~H"""
<div x-data="{ currentTab: 'users', modalOpen: false }">
  <!-- Tab 切换 -->
  <div class="tabs">
    <a :class="{ 'active': currentTab === 'users' }" @click="currentTab = 'users'">用户列表</a>
    <a :class="{ 'active': currentTab === 'settings' }" @click="currentTab = 'settings'">设置</a>
  </div>

  <div x-show="currentTab === 'users'">
    <button @click="modalOpen = true; $nextTick(() => $refs.nameInput.focus())">新增用户</button>
  </div>

  <!-- 模态框 -->
  <div x-show="modalOpen" class="modal">
    <div @click.away="modalOpen = false">
      <input x-ref="nameInput" placeholder="输入姓名...">
      <button @click="modalOpen = false">关闭</button>
    </div>
  </div>
</div>
"""
```

### C. 全局通知 (Toasts)
利用 Alpine 的事件系统处理跨组件通知。

```elixir
# 布局中的 Toast 容器
<div x-data="{ show: false, message: '' }"
     x-on:show-toast.window="show = true; message = $event.detail; setTimeout(() => show = false, 3000)"
     x-show="show">
  <span x-text="message"></span>
</div>

# 触发通知
<button @click="$dispatch('show-toast', '操作成功！')">点我</button>
```

## 4. 与 Nex Action 协同工作

### 请求后重置状态
你可以监听 HTMX 的生命周期事件来重置 Alpine 状态。

```elixir
~H"""
<div x-data="{ comment: '' }">
  <form hx-post="/add_comment" @htmx:after-request="comment = ''">
    <textarea x-model="comment" name="text"></textarea>
    <button type="submit">发送</button>
  </form>
</div>
"""
```

### 局部刷新保持状态
当 Nex Action 返回 HTML 片段并更新 DOM 时，如果父元素带有 `x-data`，Alpine 会自动重新初始化新插入的元素。

## 6. 完整示例项目

想要深入学习 Alpine.js 与 Nex 的集成，请参考我们的官方示例项目：

**[GitHub: Alpine Showcase](https://github.com/gofenix/nex/tree/main/examples/alpine_showcase)**

### 该示例包含的特性：
*   **主题切换**：在 `layouts.ex` 中使用 Alpine 管理深色/浅色模式，并同步到 `localStorage`。
*   **客户端 Tab 切换**：无需服务器参与的快速视图切换。
*   **响应式模态框**：包含自动聚焦 (`$refs`) 和点击外部关闭等交互。
*   **全局通知系统 (Toasts)**：利用 Alpine 事件系统实现的跨页面通知。
*   **复杂表单交互**：结合 Nex Action 的异步提交与前端状态即时重置。
