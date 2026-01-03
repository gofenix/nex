# Datastar 集成

Datastar 是一个超轻量级的声明式前端增强库。它通过 `data-star`（或更现代的 `data-signals`）属性提供了一种极其精简的方式来管理前端状态，并与 Nex 的 Action 机制完美配合。

## 1. 核心理念

Datastar 的核心在于 **信号 (Signals)**。它不使用虚拟 DOM，而是通过扫描 HTML 属性来建立响应式绑定。

*   **零构建**：无需 Node.js，直接通过 CDN 引入。
*   **极致透明**：状态直接声明在 HTML 标签上。
*   **Nex 协同**：利用 `@get` 和 `@post` 表达式直接调用 Nex 的 Action，实现局部 DOM 刷新（Morphing）。

## 2. 集成方式

在 `src/layouts.ex` 中引入 Datastar 脚本：

```html
<script type="module" src="https://cdn.jsdelivr.net/gh/starfederation/datastar/dist/datastar.js"></script>
```

## 3. 核心应用模式

### A. 响应式信号 (Signals) 与绑定
使用 `data-signals` 定义状态，`data-bind` 实现双向绑定，`data-text` 显示值。

```elixir
~H"""
<div data-signals="{ name: 'Nex' }">
  <input type="text" data-bind:name class="border p-2">
  <p class="mt-2">你好，<span data-text="$name"></span>！</p>
</div>
"""
```

### B. 后端请求与 Morphing (重点)
Datastar 允许在 `data-on` 属性中使用 `@get` 或 `@post` 发起异步请求。你可以传递信号值作为参数。Nex 会返回包含匹配 `id` 的 HTML 片段，Datastar 自动执行 Morph 更新。

```elixir
# 页面模块
~H"""
<div data-signals="{ inputValue: '' }">
  <input type="text" data-bind:inputValue class="border">
  <!-- 发送带参数的 POST 请求 -->
  <button data-on:click="@post('/process', { text: $inputValue })" class="btn">
    处理
  </button>
  <div id="result" class="mt-4 p-4 bg-gray-50">等待结果...</div>
</div>
"""
```

### C. 列表合并策略 (Merge Strategies)
通过 `data-merge` 属性控制后端返回的内容如何合并到现有 DOM 中。

*   **morph** (默认)：智能差异比较更新。
*   **append**: 追加到末尾。
*   **prepend**: 插入到开头。

```elixir
~H"""
<div id="logs" data-merge="append" class="space-y-2">
  <button data-on:click="@post('/add_log')">新增日志</button>
  <div class="text-sm text-gray-500 italic">日志列表将在此追加...</div>
</div>
"""
```

### D. JavaScript 表达式
Datastar 支持在属性中直接编写标准的 JavaScript 表达式。你可以利用这一点处理复杂的字符串拼接、数学运算或数组操作。

```elixir
~H"""
<div data-signals="{ x: 5, y: 3, text: 'hello' }">
  <!-- 数学运算 -->
  <div data-text="$x + $y"></div>
  
  <!-- 字符串操作 -->
  <div data-text="$text.toUpperCase()"></div>
  
  <!-- 三元运算 -->
  <div data-text="$x > $y ? 'X 更大' : 'Y 更大'"></div>
</div>
"""
```

## 4. Datastar 之道 (The Tao)

在 Nex 中集成 Datastar 时，请遵循以下原则：

1.  **超媒体优先**：尽可能让服务器返回 HTML 片段，而不是 JSON。
2.  **前端响应式**：对于不需要持久化的 UI 状态（如 Tab 切换、模态框显隐），优先使用 Datastar 信号。
3.  **最小化 JavaScript**：利用 `data-*` 属性声明行为，避免编写命令式的 JS 代码。
4.  **智能 Morphing**：利用 Datastar 的 Morphing 机制（通过 `id` 匹配），只更新 DOM 中发生变化的部分，保留表单焦点和动画。

## 5. Datastar 指令速查表

| 指令 | 说明 |
| :--- | :--- |
| `data-signals` | 定义响应式状态（JSON 格式）。 |
| `data-text` | 将元素的文本内容绑定到表达式结果。 |
| `data-bind` | 在输入框和信号之间建立双向绑定。 |
| `data-on` | 监听事件并执行表达式（支持 `@get`, `@post` 等）。 |
| `data-show` | 根据表达式结果决定元素是否可见。 |
| `data-class` | 根据信号动态添加或移除 CSS 类。 |
| `data-attr` | 绑定 HTML 属性（如 `disabled`）。 |
| `data-computed` | 定义派生信号（计算属性）。 |
| `data-merge` | 定义后端响应的合并策略（morph, append, prepend）。 |

## 6. 完整示例项目：Datastar 教程

我们提供了一个完整的、由浅入深的教程项目，涵盖了从基础绑定到 AI 流式对话的所有核心场景：

**[GitHub: Datastar Demo](https://github.com/gofenix/nex/tree/main/examples/datastar_demo)**

### 教程内容与特性分布：

#### 📍 基础篇 (Lesson 1-3)
*   **快速入门 (`index.ex`)**：学习 `data-on` 监听事件及简单的 `@post` 后端 Morphing 更新。
*   **响应式信号 (`signals.ex`)**：掌握 `data-signals` (状态定义)、`data-bind` (双向绑定)、`data-show` (显隐) 和 `data-computed` (计算属性)。
*   **JS 表达式 (`expressions.ex`)**：展示如何在属性中直接使用 JS 处理字符串、数组和逻辑运算。

#### 📍 进阶篇 (Lesson 4-5)
*   **请求与合并 (`requests.ex`)**：深入了解 `@get`/`@post` 传参方式，以及 `data-merge="append"` 等列表合并策略。
*   **Datastar 之道 (`tao.ex`)**：总结超媒体优先、后端为真理源等 6 大设计原则。

#### 📍 实战篇 (Advanced & Apps)
*   **高级特性 (`advanced.ex`)**：
    *   `data-init`: 页面加载时自动执行（如初始化长连接）。
    *   `data-on-intersect`: 滚动进入视口触发（实现**无限滚动/懒加载**）。
    *   `data-indicator`: 全自动的请求加载状态显示。
    *   `data-ref`: 直接引用 DOM 元素实现复杂交互（如自动聚焦）。
*   **AI 聊天机器人 (`chat.ex`)**：结合 Nex 的 `{:stream, fun}` 返回值，实现 **AI 逐字流式回复**。
*   **实时表单验证 (`form.ex`)**：纯前端信号驱动的复杂校验逻辑，无需后端往返。
*   **Todo MVC (`todos.ex`)**：综合展示 CRUD 操作、客户端列表过滤和动态样式切换。

## 7. 最佳实践 (Nex + Datastar)

1.  **细粒度更新**：利用 Datastar 的 Morphing 特性，只返回需要变动的极小 HTML 片段。
2.  **避免状态冗余**：对于纯 UI 交互（如开关、输入预览），优先使用 Datastar 信号；对于业务数据（如保存到 DB），使用 `@post` 调用 Nex Action。
3.  **计算属性**：在 `data-text` 中直接使用简单的 JavaScript 表达式进行逻辑组合。

## 6. Datastar vs Alpine.js

*   **Alpine.js**：更适合处理传统的 UI 交互（模态框、折叠菜单、简单的逻辑）。
*   **Datastar**：在处理跨组件的大规模状态共享和复杂的前端业务逻辑时更具优势。

在 Nex 项目中，你可以根据团队习惯选择其中之一。Nex 的文件系统路由和 Action 机制可以与这两者完美配合。
