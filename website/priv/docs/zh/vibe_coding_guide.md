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

### 函数签名规范 (重要)
**对 AI 的价值**：AI 经常混淆页面 Action 和 API 处理函数的参数签名。
*   **页面 Action** (在 `src/pages/` 中)：接收一个平铺的 **Map**（合并了路径、查询和 Body 参数）。
    *   *示例*：`def add_item(%{"id" => id})`
*   **API 处理函数** (在 `src/api/` 中)：接收一个 **`Nex.Req` 结构体**（需通过 `req.query` 或 `req.body` 访问）。
    *   *示例*：`def get(req)`
明确这一区别能防止 AI 生成无法编译的代码。

### 状态管理与单向真理流
AI 应遵循：**接收意图 -> 修改 Store/DB -> 渲染最新状态**。
*   **Nex.Store**：是服务端会话状态，随页面刷新清除。
*   **真理流**：严禁直接根据请求参数渲染 UI，必须始终通过 `Nex.Store.update` 更新状态后，再渲染页面。

### 实时流与 SSE 体验
当使用 **`Nex.stream/1`** 进行流式响应（如 AI 聊天）时，AI 应始终先渲染一个初始占位符或“正在输入”状态，以确保即时反馈。

---

## 2. 开发者工具最佳实践 (AI 工具链配置)

Nex 提倡“架构即规则”。当你使用 `mix nex.new` 创建新项目时，框架会自动生成核心规则文件，确保 AI 助手从第一行代码开始就符合 Nex 的设计哲学。

### A. 核心规则文件
新项目中包含以下关键文件：
*   **`AGENTS.md`**：**最高宪法**。定义了框架的核心原则（行为局部性、文件系统路由、声明式交互、状态管理）。它是所有 AI 工具（如 Cursor, Windsurf, Claude Code）的基础参考。
*   **`CLAUDE.md`**：针对 Claude Code 等工具的极简引导，确保它们优先查阅 `AGENTS.md`。

### B. 如何使用这些规则？
1.  **统一真理源**：无论你使用哪种 AI 工具，请引导它首先阅读根目录下的 **`AGENTS.md`**。
2.  **Cursor 用户**：建议在 `.cursor/rules/` 目录下放置针对项目的特定指令，并让其参考 `AGENTS.md`。
3.  **其他工具**：你可以直接将 `AGENTS.md` 的内容贴给任何 AI 助手（如 Windsurf, GPT-4o, Claude 3.5 Sonnet），作为它的系统提示词（System Prompt）。

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
*   **纠偏 2**：“不要引入额外的 JavaScript 库，优先使用内置的 HTMX。”
*   **纠偏 3**：“这是一个 API 模块，请使用 `def get(req)` 签名。对于页面 Action，请使用 `def action_name(params)` 签名。”
*   **纠偏 4**：“在表单中请使用 `{csrf_csrf_input_tag()}`。”

## 5. 结语

在 Nex 中，你的角色是**架构师**和**意图描述者**。通过利用 Nex 的架构确定性，你可以让 AI 释放出前所未有的生产力。
