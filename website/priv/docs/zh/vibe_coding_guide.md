# AI 辅助开发 (Vibe Coding)

Nex 不仅仅是一个框架，它更是一套为 **Vibe Coding**（意图驱动开发）量身定制的架构协议。在 Nex 中，AI 不再是代码的补全者，而是功能的构建者。

## 1. 为什么 Nex 是 AI 的最佳搭档？

### 行为局部性 (Locality of Behavior)
Nex 强制将逻辑与 UI 耦合。在一个 `.ex` 文件中，你可以看清一个功能的全部：
*   `mount/1`：数据从哪来。
*   `render/1`：UI 长什么样。
*   `Action` 函数：交互逻辑是什么。
**对 AI 的价值**：AI 只需要读取一个文件的上下文，就能生成或修改完整的功能，彻底解决了在 Controller、Router、Template 之间来回跳跃导致的“上下文丢失”问题。

### 文件系统路由 (Zero-Config Routing)
**对 AI 的价值**：路径即路由。AI 不需要猜测 `routes.ex` 是如何配置的。只要它在 `src/pages/users/[id].ex` 写下代码，它就确信对应的 URL 是 `/users/123`。这种确定性极大地降低了 AI 生成幻觉代码的概率。

### 声明式交互 (HTMX/Datastar)
**对 AI 的价值**：生成 HTML 属性（Attribute）比生成复杂的 JavaScript 异步流程（Promise/Async）要稳健得多。AI 编写声明式代码的正确率接近 100%。

---

## 2. 开发者工具最佳实践

为了让 **Cursor**、**Windsurf**、**Claude Code** 等 AI 工具更精准地指导 Nex 开发，建议在项目根目录配置规则文件。

### A. Cursor 配置 (.cursorrules)
在项目根目录创建 `.cursorrules`，贴入以下内容：

```markdown
You are an expert Nex framework developer. Follow these rules:
1. Locality: Keep UI and logic in the same file (src/pages or src/api).
2. Routing: Files in src/pages/ are GET routes. [id].ex is dynamic. [...path].ex is catch-all.
3. Actions: Handle POST/PUT/DELETE by defining functions in the same module. Use hx-post="/func_name" for single-path.
4. State: Use Nex.Store.get/put/update(key, default, fun) for page-level state.
5. API 2.0: API modules must return Nex.Response (use Nex.json/2).
6. Layout: Layouts must have <body> tag. Use {raw(@inner_content)} to render page.
```

### B. Windsurf / Codex 提示词
在对话开始时，可以先发送以下“框架画像”：

> "这是一个 Nex 项目。它使用文件系统路由（src/pages 为 GET，src/api 为 JSON）。交互采用声明式 Action，即在页面模块内定义函数并由 HTMX 的 hx-post 调用。状态管理使用基于 Page ID 的 Nex.Store。请始终保持代码的局部性。"

---

## 3. 编写高效的 Prompt 模式

### 场景一：创建一个新功能页面
> "在 `src/pages` 下创建一个 `counter.ex`。页面中央显示数字，下方有加减按钮。点击按钮通过 `hx-post` 调用同模块内的 `inc` 和 `dec` 函数。使用 `Nex.Store` 存储数值。"

### 场景二：添加复杂交互
> "为当前的 `user_list` 每一行添加一个删除按钮。使用 `hx-delete` 调用 `remove` Action。删除成功后，后端返回 `:empty` 并让 HTMX 自动移除该行 DOM。"

---

## 4. 常见陷阱与 AI 纠偏

当 AI 表现得像在写传统的 Phoenix 或 React 时，请及时纠正：

*   **纠偏 1**：“Nex 不需要 Router 文件，请直接在 `src/pages` 下创建文件。”
*   **纠偏 2**：“不要引入额外的 JavaScript 库，优先使用 HTMX 或 Alpine.js 属性解决。”
*   **纠偏 3**：“状态不要存在内存变量里，请使用 `Nex.Store` 确保跨交互持久化。”

## 5. 结语

在 Nex 中，你的角色是**架构师**和**意图描述者**。通过利用 Nex 的架构确定性，你可以让 AI 释放出前所未有的生产力。
