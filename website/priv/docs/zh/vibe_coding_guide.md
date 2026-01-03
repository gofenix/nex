# AI 辅助开发 (Vibe Coding)

Nex 是专门为 **AI 辅助开发**优化的框架。我们选择极简的架构（行为局部性、文件系统路由）并押注声明式交互（如 HTMX），是为了让 AI 能够更精准地理解和生成完整的业务逻辑。

## 1. 为什么 Nex 的架构适合 AI 开发？

### 行为局部性 (Locality of Behavior)
在 Nex 中，一个页面的数据加载 (`mount`)、UI 定义 (`render`) 和 交互逻辑 (`Action`) 全部集中在一个文件中。对于 AI 来说，这意味着它只需要理解当前文件的上下文，就能生成或修改一个完整的功能，而不需要在路由表、控制器、视图和模板之间跳跃。

### 约定优于配置
AI 不需要去猜测你的路由是怎么配置的。只要它知道你在 `src/pages/users/[id].ex` 创建了文件，它就能确信 URL 是 `/users/123`。这种确定性极大地降低了 AI 生成错误代码的概率。

### 声明式交互的优势
Nex 押注 HTMX 这一类声明式工具，是因为它们将复杂的异步逻辑浓缩为简单的 HTML 属性。对于 AI 来说，生成属性（Attribute）比生成复杂的 JavaScript 异步流程（Promise, Async/Await）要稳健得多。

## 2. 编写高效的 Prompt

当你告诉 AI 编写 Nex 代码时，可以遵循以下模式：

### 描述功能模块
> "在 `src/pages` 下创建一个 `todos.ex` 页面。首页显示待办列表，支持添加新的待办。使用 `Nex.Store` 存储列表，并在添加成功后使用 HTMX 局部刷新列表部分。"

### 描述交互细节
> "为删除按钮添加 `hx-delete`，调用名为 `remove` 的 Action。在 `remove` 函数中，从 `Nex.Store` 移除对应 ID 的项，并返回 `:empty`。"

## 3. 常见 AI 提示词模板

### 基础页面模板
```markdown
请使用 Nex 框架创建一个 [功能名] 页面：
1. 文件位置：src/pages/[文件名].ex
2. mount：初始化 [数据名] 数据。
3. render：使用 Tailwind CSS 渲染 [UI 描述]。
```

### 交互 Action 模板
```markdown
在现有的 Nex 页面中添加交互：
1. 添加一个名为 [action_name] 的函数。
2. 处理来自 [hx-post/hx-put/...] 的请求。
3. 更新 `Nex.Store` 中的 [状态名]。
4. 返回 [HTML 片段/刷新指令]。
```

## 4. 常见陷阱与修正

AI 有时会惯性地使用其他框架的模式，你需要及时纠正：

*   **陷阱**：AI 尝试在项目根目录寻找 `router.ex`。
    *   **修正**：告知 AI "Nex 没有全局路由文件，请直接在 `src/pages` 下创建文件"。
*   **陷阱**：AI 尝试引入大型 JS 库。
    *   **修正**：要求 AI "优先使用 HTMX 或 Alpine.js 解决交互问题，不要引入复杂的构建工具"。
*   **陷阱**：AI 忘记在 Action 中使用 `Nex.Store`。
    *   **修正**：提醒 AI "使用 `Nex.Store.get/put/update` 来保持交互过程中的临时状态"。

## 5. 结语

Nex 的目标是让开发者的角色从“代码搬运工”转变为“意图描述者”。通过利用 Nex 的架构优势，你可以大幅提升 Vibe Coding 的体验。
