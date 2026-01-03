# Alpine.js 集成

虽然 Nex 倡导“服务端驱动”和“极简交互”，但在处理纯客户端逻辑（如动画、过渡、复杂的模态框状态）时，Alpine.js 是 Nex 的完美拍档。

## 1. 为什么使用 Alpine.js？

Nex 处理的是 **服务器通信**，而 Alpine.js 处理的是 **本地 UI 逻辑**。

*   **轻量级**：没有虚拟 DOM，直接操作现有 HTML。
*   **声明式**：通过 `x-data`, `x-show`, `x-on` 等属性直接在 HTML 中编写逻辑。
*   **零构建**：直接通过 CDN 引入，符合 Nex 的开发哲学。

## 2. 集成方式

在你的 `src/layouts.ex` 的 `<head>` 标签中引入：

```html
<script defer src="https://unpkg.com/alpinejs@3.x.x/dist/cdn.min.js"></script>
```

## 3. 常见用法示例

### 模态框控制
利用 Alpine.js 管理显示状态，而不需要向服务器发送请求。

```elixir
~H"""
<div x-data="{ open: false }">
  <button @click="open = true" class="...">打开模态框</button>

  <div x-show="open" @click.away="open = false" class="fixed inset-0 bg-black/50">
    <div class="bg-white p-8 rounded">
      <h3>这是一个模态框</h3>
      <button @click="open = false">关闭</button>
    </div>
  </div>
</div>
"""
```

### 与 Nex Action 配合
你可以让 Alpine.js 监听 HTMX 的生命周期事件。例如，当 Nex 的 Action 成功返回后，清空一个输入框：

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

## 4. 最佳实践

*   **职责划分**：
    *   **Nex**：处理表单提交、数据库更新、页面跳转、全局状态存储。
    *   **Alpine**：处理下拉菜单、Tab 切换、实时搜索过滤（仅前端）、复杂的 CSS 动画。
*   **Locality of Behavior (LoB)**：Nex 的 `hx-*` 属性和 Alpine 的 `x-*` 属性共存于同一个标签中，这正是 Vibe Coding 最喜欢的模式——在一个地方看清所有交互逻辑。
