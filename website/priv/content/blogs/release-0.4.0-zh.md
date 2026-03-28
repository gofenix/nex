# Nex 0.4.0 发布：面向 AI 时代的极简 Elixir Web 框架

今天，我们非常高兴地宣布 **Nex 0.4.0** 正式发布！

在介绍新特性之前，让我们先退一步看看：Nex 到底是什么？我们为什么要构建它？

## 什么是 Nex？

**Nex** 是一个基于 HTMX 的极简 Elixir Web 框架，专为快速原型开发、独立开发者（Indie Hackers）以及 AI 时代而设计。

虽然 Phoenix 是 Elixir 企业级应用当之无愧的王者，但它也带来了陡峭的学习曲线和大量的样板代码。Nex 采取了完全不同的方法，它深受 Next.js 等现代元框架的启发，但建立在坚如磐石的 Erlang 虚拟机（BEAM）基础之上。

我们的核心理念是：**约定优于配置，零样板代码（Zero Boilerplate）**。

### Nex 的核心特性

*   **文件系统路由**：你的文件系统就是你的路由器。只需在 `src/pages/` 目录下创建一个文件，你立刻就获得了一个路由。它支持静态路由（`index.ex`）、动态参数（`[id].ex`）以及全捕获路由（`[...path].ex`）。
*   **Action 交互（零 JS）**：由 HTMX 提供动力支持。你可以在 Page 模块中直接编写诸如 `def increment(req)` 这样的函数，然后在 HTML 中通过 `hx-post="/increment"` 直接调用它。无需定义单独的 API 端点，也完全不需要写客户端 JavaScript。
*   **原生实时推送（SSE & WebSockets）**：原生的 Server-Sent Events（`Nex.stream/1`）和 WebSockets 支持，让你只需几行代码就能轻松构建 AI 流式响应或实时聊天应用。
*   **瞬态状态管理**：内置基于 ETS 内存表的状态存储（`Nex.Store` 和 `Nex.Session`）。状态通过 `page_id` 进行隔离，完美解决了传统 Session 机制中常见的“脏状态”残留问题。
*   **为 AI 而生（Vibe Coding）**：我们设计的框架非常容易被 LLM（大语言模型）理解。你完全可以对 AI 说：“用 Nex 给我建一个 Todo 应用”，它就能为你生成一个完全可用的、单文件形式的 Page 模块。

---

## Nex 0.4.0 带来了什么？

随着 Nex 的成长，为了安全高效地处理真实世界中的用户交互，同时又保持我们极简的开发体验，我们在 0.4.0 中引入了几个非常关键的特性。

### 🛡️ 声明式数据验证（`Nex.Validator`）

安全地处理用户输入是 Web 应用的核心需求。在 0.4.0 中，我们引入了 `Nex.Validator`，这是一个内置的模块，用于提供干净、声明式的参数验证和类型转换。

你不再需要手动从 `req.body` 中解析和转换字符串，现在可以定义简洁的验证规则：

```elixir
def create_user(req) do
  rules = [
    name: [required: true, type: :string, min: 3],
    age: [required: true, type: :integer, min: 18],
    email: [required: true, type: :string, format: ~r/@/]
  ]

  case Nex.Validator.validate(req.body, rules) do
    {:ok, valid_params} ->
      # valid_params.age 已经被安全地转换成了整数！
      DB.insert_user(valid_params)
      Nex.redirect("/dashboard")
      
    {:error, errors} ->
      # errors 是一个 Map: %{age: ["must be at least 18"]}
      render(%{errors: errors})
  end
end
```

### 📁 安全的文件上传（`Nex.Upload`）

框架现在开箱即用地提供了对 `multipart/form-data` 的完全支持。全新的 `Nex.Upload` 模块允许你直接从 `req.body` 中获取上传的文件（解析为 `%Plug.Upload{}` 结构体），并内置了安全验证（文件大小、扩展名类型）以及防止路径遍历攻击的安全保存工具。

```elixir
def upload_avatar(req) do
  upload = req.body["avatar"]

  rules = [
    max_size: 5 * 1024 * 1024, # 限制 5MB
    allowed_types: ["image/jpeg", "image/png"]
  ]

  with :ok <- Nex.Upload.validate(upload, rules),
       {:ok, _path} <- Nex.Upload.save(upload, "priv/static/uploads", unique_name()) do
    
    Nex.Flash.put(:success, "头像更新成功！")
    {:redirect, "/profile"}
  else
    {:error, reason} -> 
      Nex.Flash.put(:error, reason)
      {:redirect, "/profile"}
  end
end
```

### 🎨 自定义错误页面

在开发环境中，Nex 默认提供了一个清晰的代码调用栈页面；但在生产环境中，你往往希望错误页面（如 404 或 500）能符合你网站自身的 UI 风格。

现在，你可以在 `application.ex` 中配置自定义的错误模块：

```elixir
Application.put_env(:nex_core, :error_page_module, MyApp.ErrorPages)
```

只需在你的模块中实现 `render_error/4` 函数，你就能完全控制当错误发生时用户将看到什么样的页面。

### 🔧 底层改进与修复

*   **限流器内存泄漏修复**：在 `Nex.RateLimit` 中添加了定期清理过期 ETS 记录的机制，防止内存无限增长。
*   **安装器增强**：修复了 `mix nex.new` 生成器中的命令注入漏洞，并处理了参数解析的边缘情况。
*   **开发体验（DX）提升**：修复了编译期错误，优化了 `Nex.Session` 和 `Nex.CSRF` 的日志输出。

---

## 快速开始 & 升级指南

如果你想第一次尝试 Nex，只需不到 2 分钟的时间：

```bash
mix archive.install hex nex_new
mix nex.new my_app
cd my_app
mix nex.dev
```

如果你要将现有的 Nex 应用升级到 0.4.0，只需更新你的 `mix.exs`：

```elixir
defp deps do
  [
    {:nex_core, "~> 0.4.0"}
  ]
end
```

查看最新的[官方文档](https://github.com/gofenix/nex)，或者浏览我们的[示例项目仓库](https://github.com/gofenix/nex/tree/main/examples)，看看用 Nex 都能构建些什么吧。

Happy shipping! 🚀
