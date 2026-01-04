# Action 路由机制 ⭐ Nex 核心创新

Nex 提供了一套极其智能且简约的 Action 路由方案，旨在彻底消除传统 Web 开发中繁琐的路由配置。

## 1. 核心理念：行为局部性 (LoB)

在 Nex 中，处理交互的函数（Action）与其对应的 UI（HEEx）紧密耦合在同一个 Elixir 模块中。这种设计不仅提高了代码的可维护性，还让 AI 辅助编程变得更加高效。

## 2. 单路径 Action (Referer-based)

这是 Nex 的默认行为，也是最强大的特性。

### 工作原理
当你发送一个 POST/PUT/DELETE 请求到特定的 Action 路径（如 `hx-post="/increment"`）时：
1.  **识别来源**：Nex 查看 HTTP 请求头中的 `Referer`（例如 `http://localhost:4000/todos`）。
2.  **定位模块**：根据 `Referer` 路径 `/todos` 找到对应的页面模块 `MyApp.Pages.Todos.Index`。
3.  **执行函数**：在找到的模块中执行与路径名同名的函数 `increment/1`。

### 优势
*   **极致简化**：你不需要在 `hx-post` 中写出完整的页面路径。
*   **逻辑复用**：如果你在不同的页面调用同名的 `/add`，它们会自动路由到各自页面定义的 `add` 函数。

## 3. 多路径 Action (Path-based)

当你需要操作特定的资源（如删除、编辑）或者构建符合 REST 风格的 API 时，可以使用多路径 Action。

### 示例
路径：`POST /users/123/delete`

### 解析规则
1.  **路径前缀解析**：Nex 将 `/users/123` 解析为 `MyApp.Pages.Users.Id` 模块（假设对应文件是 `src/pages/users/[id].ex`）。
2.  **提取参数**：自动提取 `id: "123"`。
3.  **执行动作**：解析路径最后一段 `delete`，并调用该模块中的 `delete(%{"id" => "123"})` 函数。

## 4. 原子级安全性 (Atom Safety)

传统的路由系统往往容易受到“原子溢出”攻击（恶意构造大量请求导致 Erlang 原子表耗尽）。Nex 的路由机制天然防御此类攻击：

*   **编译时绑定**：路由解析仅会尝试寻找**已经编译存在**的模块和函数。
*   **拒绝动态生成**：Nex 不会在运行时根据未知的字符串动态创建原子。

## 5. 自动 CSRF 与状态追踪

所有通过 Nex 路由的 Action 请求都会自动享受以下保护：
*   **CSRF 验证**：脚本自动注入 `X-CSRF-Token`，服务端强制验证。
*   **Page ID 自动携带**：脚本自动注入 `X-Nex-Page-Id`，确保 `Nex.Store` 状态隔离生效。

## 6. 常见返回模式

| 返回值 | 说明 |
| :--- | :--- |
| `~H"""..."""` | 返回 HTML 片段，用于局部更新。 |
| `:empty` | 执行逻辑成功，但不返回内容（通常配合 `hx-swap="none"` 使用）。 |
| `{:redirect, "/path"}` | 让 HTMX 进行客户端跳转（HX-Redirect）。 |
| `{:refresh}` | 强制浏览器刷新当前页面（HX-Refresh）。 |
| `Nex.stream(fn -> ... end}` | 启动 SSE 实时流。 |
