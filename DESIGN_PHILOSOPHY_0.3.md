# Nex 0.3.0 设计理念：一次翻天覆地的重构

> 从 0.2.x 到 0.3.0 - 为什么我们要做这些看似激进的改变？

---

## 🎯 核心问题：框架的本质是什么？

在开发 Nex 0.2.x 的过程中，我逐渐意识到一个问题：**我们在模仿 Phoenix，但这真的是 Nex 应该走的路吗？**

### 0.2.x 的困境

```elixir
# 0.2.x 的代码
defmodule MyApp.Pages.Index do
  use Nex.Page  # 为什么需要 Nex.Page？
end

defmodule MyApp.Api.Users do
  use Nex.Api  # 为什么需要 Nex.Api？
end

defmodule MyApp.Partials.Card do
  use Nex.Partial  # 为什么需要 Nex.Partial？
end

defmodule MyApp.Api.Stream do
  use Nex.SSE  # 为什么需要 Nex.SSE？
end
```

**问题在哪里？**

1. **认知负担过重**: 开发者需要记住 4 个不同的 `use` 语句
2. **违背 DRY 原则**: 每个模块类型都有自己的 `use` 语句，但本质上做的事情类似
3. **不符合 Nex 定位**: Nex 的目标是"极简"，但这种设计并不简单
4. **缺乏一致性**: 为什么 Page 需要 `use Nex.Page`，但 Layout 不需要？

### 灵感来源：Next.js 的零配置哲学

我重新审视了 Next.js 的设计：

```javascript
// Next.js - 没有 use 语句，没有配置
// pages/index.js
export default function Home() {
  return <h1>Hello</h1>
}

// pages/api/users.js
export default function handler(req, res) {
  res.json({ users: [] })
}
```

**Next.js 做对了什么？**

- ✅ **约定优于配置**: 通过文件路径自动识别类型
- ✅ **零样板代码**: 不需要任何 import 或 use 语句
- ✅ **认知负担最小**: 开发者只需关注业务逻辑

**这就是 Nex 应该追求的！**

---

## 💡 设计决策 1：统一 `use Nex` 接口

### 问题分析

在 0.2.x 中，我们有 4 个不同的模块：

```elixir
# framework/lib/nex/page.ex
defmodule Nex.Page do
  defmacro __using__(_opts) do
    quote do
      import Phoenix.Component
      import Nex.CSRF
    end
  end
end

# framework/lib/nex/api.ex
defmodule Nex.Api do
  defmacro __using__(_opts) do
    quote do
      # 什么都不导入
    end
  end
end

# framework/lib/nex/partial.ex
defmodule Nex.Partial do
  defmacro __using__(_opts) do
    quote do
      import Phoenix.Component
      import Nex.CSRF
    end
  end
end

# framework/lib/nex/sse.ex
defmodule Nex.SSE do
  defmacro __using__(_opts) do
    quote do
      def __sse_endpoint__, do: true
    end
  end
end
```

**发现了什么？**

1. `Nex.Page` 和 `Nex.Partial` **完全一样**！
2. `Nex.Api` 什么都不做，只是一个空壳
3. `Nex.SSE` 只是加了一个标记函数

**这是巨大的浪费！**

### 解决方案：路径检测

既然模块类型可以通过路径判断，为什么不自动检测？

```elixir
# framework/lib/nex.ex
defmodule Nex do
  defmacro __using__(_opts) do
    module_name = __CALLER__.module |> to_string()

    cond do
      # Pages, Components, Layouts - 需要 HEEx
      String.contains?(module_name, ".Pages.") or
      String.contains?(module_name, ".Components.") or
      String.ends_with?(module_name, ".Layouts") ->
        quote do
          import Phoenix.Component, only: [sigil_H: 2]
          import Nex.CSRF
        end

      # API - 什么都不导入
      String.contains?(module_name, ".Api.") ->
        quote do
          # Pure functions
        end

      true ->
        quote do
          # Default: nothing
        end
    end
  end
end
```

**优势**:

- ✅ **一个接口统治所有**: 只需要 `use Nex`
- ✅ **自动类型检测**: 框架智能识别模块类型
- ✅ **零认知负担**: 开发者不需要记住不同的 `use` 语句
- ✅ **完美对齐 Next.js**: 约定优于配置

### 心路历程

**最初的犹豫**:
> "这样做会不会太激进？用户可能习惯了 Phoenix 的 `use MyAppWeb, :controller` 模式。"

**转折点**:
> "等等，Nex 的目标用户是谁？是 Phoenix 的重度用户吗？不，是想要快速原型、简单工具的开发者。他们需要的是 Next.js 级别的简单，而不是 Phoenix 级别的灵活。"

**最终决定**:
> "删掉所有 `Nex.Page/Api/Partial/SSE` 模块，统一使用 `use Nex`。这是 Breaking Change，但这是正确的方向。"

---

## 💡 设计决策 2：`partials/` → `components/`

### 问题分析

在 0.2.x 中，我们使用 `partials/` 作为组件目录：

```
src/
├── pages/
├── api/
└── partials/  # ❓ 为什么叫 partials？
```

**这个命名的问题**:

1. **不符合现代前端习惯**: React、Vue、Svelte 都用 `components`
2. **语义不清**: "partial" 是 Rails 的术语，但 Nex 不是 Rails
3. **学习曲线**: 前端开发者需要重新学习一个新术语
4. **Phoenix 1.7 也改了**: Phoenix 1.7+ 也从 `templates` 改为 `components`

### 行业调研

| 框架 | 组件目录 | 说明 |
|------|---------|------|
| React | `components/` | 行业标准 |
| Vue | `components/` | 行业标准 |
| Svelte | `components/` | 行业标准 |
| Next.js | `components/` | 行业标准 |
| Phoenix 1.7+ | `components/` | Elixir 生态标准 |
| Rails | `partials/` | 传统 MVC 框架 |
| Laravel | `partials/` | 传统 MVC 框架 |
| **Nex 0.2.x** | `partials/` | ❌ 过时 |

**结论**: 只有传统 MVC 框架还在用 `partials`，现代框架都用 `components`。

### 解决方案

```bash
# 重命名
src/partials/ → src/components/
MyApp.Partials.* → MyApp.Components.*
```

**优势**:

- ✅ **对齐行业标准**: 与 React/Vue/Phoenix 一致
- ✅ **降低学习成本**: 前端开发者零学习成本
- ✅ **语义清晰**: "component" 比 "partial" 更直观
- ✅ **未来友好**: 符合现代框架发展趋势

### 心路历程

**最初的想法**:
> "Rails 用 partials，我们也用 partials，这样 Rails 开发者会觉得熟悉。"

**反思**:
> "但 Nex 的目标用户真的是 Rails 开发者吗？我们的 HTMX + HEEx 组合，更像是 React 的服务端渲染版本。为什么不对齐 React 生态？"

**数据支持**:
> "查看 GitHub 趋势：React 有 220k stars，Rails 有 55k stars。前端开发者是后端开发者的 4 倍。我们应该服务更大的市场。"

**最终决定**:
> "改！即使这是 Breaking Change，也要改。长痛不如短痛。"

---

## 💡 设计决策 3：API 请求对象完全对齐 Next.js

### 问题分析

在 0.2.x 中，我们的 API 请求对象是这样的：

```elixir
# 0.2.x
%Nex.Req{
  params: %{},        # Nex 特有
  path_params: %{},   # Nex 特有
  query_params: %{},  # Nex 特有
  body_params: %{},   # Nex 特有
  method: "GET",
  headers: %{},
  cookies: %{}
}
```

**问题在哪里？**

1. **不符合 Next.js**: Next.js 只有 `req.query` 和 `req.body`
2. **过度设计**: 4 个参数字段，但用户只需要 2 个
3. **认知负担**: 用户需要理解 `params` vs `path_params` vs `query_params`
4. **违背初衷**: Nex 的目标是"像 Next.js 一样简单"

### Next.js 的设计

```javascript
// Next.js API Routes
export default function handler(req, res) {
  // GET /api/users/123?page=2
  req.query.id    // => "123" (from path)
  req.query.page  // => "2"   (from query string)
  
  // POST /api/users
  req.body.name   // => "Alice"
  req.body.email  // => "alice@example.com"
}
```

**Next.js 做对了什么？**

- ✅ **只有 2 个字段**: `req.query` 和 `req.body`
- ✅ **语义清晰**: query 是 GET 参数，body 是 POST 参数
- ✅ **自动合并**: 路径参数和查询参数自动合并到 `req.query`
- ✅ **优先级明确**: 路径参数优先于查询参数

### 解决方案

```elixir
# 0.3.0
%Nex.Req{
  query: %{},      # 路径参数 + 查询参数（路径优先）
  body: %{},       # 请求体参数
  method: "GET",
  headers: %{},
  cookies: %{},
  # 内部字段
  path: "/api/users/123",
  private: %{}
}
```

**实现细节**:

```elixir
# framework/lib/nex/req.ex
def from_plug_conn(%Plug.Conn{} = conn, path_params \\ %{}) do
  # Next.js style: path params override query params
  query = Map.merge(conn.query_params, path_params)
  
  %__MODULE__{
    query: query,
    body: body_params,
    method: conn.method,
    headers: Map.new(conn.req_headers),
    cookies: conn.cookies,
    path: conn.request_path,
    private: conn.private
  }
end
```

**优势**:

- ✅ **完全对齐 Next.js**: 字段名、行为、优先级都一致
- ✅ **降低学习成本**: 熟悉 Next.js 的开发者零学习成本
- ✅ **简化 API**: 从 4 个字段减少到 2 个
- ✅ **语义清晰**: GET 用 `query`，POST 用 `body`

### 心路历程

**最初的设计**:
> "Elixir 开发者习惯 Phoenix 的 `conn.params`，我们也提供 `req.params` 吧。"

**问题暴露**:
> "用户反馈：我应该用 `req.params` 还是 `req.query_params`？路径参数在哪里？"

**深度思考**:
> "为什么 Next.js 不需要这么多字段？因为他们把复杂性隐藏在了自动合并逻辑里。用户只需要知道：GET 用 query，POST 用 body。"

**最终决定**:
> "删掉所有 Nex 特有字段，完全对齐 Next.js。即使这意味着 Breaking Change。"

---

## 💡 设计决策 4：SSE 流式响应的革命

### 问题分析

在 0.2.x 中，SSE 端点需要特殊标记：

```elixir
# 0.2.x
defmodule MyApp.Api.Stream do
  use Nex.SSE  # 特殊标记

  def stream(params, send) do
    send.("Hello")
  end
end
```

**问题在哪里？**

1. **需要特殊模块**: `use Nex.SSE` 是一个单独的模块
2. **路由复杂**: 需要检查 `__sse_endpoint__` 函数
3. **不够灵活**: 不能在普通 API 端点返回流式响应
4. **与统一接口冲突**: 违背了 `use Nex` 的统一理念

### AI 时代的需求

2024-2025 年，AI 应用爆发：

- OpenAI ChatGPT
- Anthropic Claude
- Google Gemini
- 本地 LLM (Ollama, LM Studio)

**所有 AI API 都支持流式响应！**

```python
# Python - OpenAI SDK
for chunk in openai.chat.completions.create(
    model="gpt-4",
    messages=[{"role": "user", "content": "Hello"}],
    stream=True
):
    print(chunk.choices[0].delta.content)
```

**Nex 必须原生支持流式响应！**

### 解决方案：`Nex.stream/1`

```elixir
# 0.3.0
defmodule MyApp.Api.Chat do
  use Nex  # 统一接口

  def get(req) do
    message = req.query["message"]
    
    Nex.stream(fn send ->
      # 真正的流式响应
      Finch.build(:post, "https://api.openai.com/v1/chat/completions", ...)
      |> Finch.stream(MyApp.Finch, nil, fn
        {:data, chunk}, acc ->
          # 解析并立即发送
          send.(parse_chunk(chunk))
          acc
      end)
    end)
  end
end
```

**设计理念**:

1. **统一接口**: 不需要 `use Nex.SSE`
2. **返回值**: 返回 `%Nex.Response{content_type: "text/event-stream"}`
3. **回调函数**: 类似 Python 的 generator 和 Next.js 的 ReadableStream
4. **真正流式**: 使用 `Finch.stream` 实现边接收边发送

**对比其他框架**:

```python
# Python FastAPI - 7 lines
from fastapi.responses import StreamingResponse

def generate():
    yield "Hello"
    yield "World"

@app.get("/stream")
def stream():
    return StreamingResponse(generate(), media_type="text/event-stream")
```

```javascript
// Next.js - 15 lines
export async function GET() {
  const encoder = new TextEncoder()
  
  const stream = new ReadableStream({
    start(controller) {
      controller.enqueue(encoder.encode("Hello"))
      controller.enqueue(encoder.encode("World"))
      controller.close()
    }
  })
  
  return new Response(stream, {
    headers: { 'Content-Type': 'text/event-stream' }
  })
}
```

```elixir
# Nex 0.3.0 - 5 lines
def get(req) do
  Nex.stream(fn send ->
    send.("Hello")
    send.("World")
  end)
end
```

**Nex 是最简单的！**

### 心路历程

**最初的实现**:
> "参考 Phoenix LiveView 的 stream 实现，使用 `use Nex.SSE` 标记。"

**问题发现**:
> "用户反馈：为什么 SSE 需要特殊模块？为什么不能在普通 API 返回流式响应？"

**AI 时代的启发**:
> "看到 OpenAI 的流式 API，我意识到：流式响应不应该是特殊功能，而应该是一等公民。"

**Python 的启发**:
> "FastAPI 的 `StreamingResponse` 非常优雅，只需要一个 generator 函数。我们也可以做到！"

**最终设计**:
> "删掉 `use Nex.SSE`，提供 `Nex.stream/1` 函数。任何 API 端点都可以返回流式响应。"

---

## 🎨 设计哲学的演进

### 0.1.x - 0.2.x：集百家之长，原型验证

**思路**: "快速验证想法，从成熟框架中汲取灵感。"

**借鉴的框架**:
- **Phoenix**: LiveView 的组件系统、Plug 的中间件架构
- **Next.js**: 文件系统路由、API Routes 的简洁性
- **Rails**: Partials 的命名、约定优于配置的理念
- **HTMX**: 服务端渲染的现代化方案
- **FastAPI**: SSE 流式响应的优雅实现

**结果**:
- ✅ 快速实现了基本功能
- ✅ 验证了 HTMX + Elixir 的可行性
- ✅ 积累了真实的用户反馈
- ⚠️ 但也暴露了问题：缺乏统一的设计理念

**关键发现**:
> "集成了很多好的想法，但没有形成自己的特色。用户反馈：'Nex 到底是什么？是简化版的 Phoenix 还是 Elixir 版的 Next.js？'"

### 0.3.0：回归本质，确立身份

**思路**: "Nex 不是 Phoenix，Nex 是 Elixir 版的 Next.js。"

**核心理念**:

1. **约定优于配置** (Convention over Configuration)
   - 通过文件路径自动识别模块类型
   - 零配置，开箱即用

2. **极简主义** (Minimalism)
   - 一个 `use Nex` 统治所有
   - 只保留必要的 API

3. **对齐 Next.js** (Next.js Alignment)
   - API 请求对象完全一致
   - 开发体验完全一致

4. **AI 原生** (AI-First)
   - 原生支持流式响应
   - 完美支持 AI 应用

### 设计原则

**1. 简单胜于复杂**
```elixir
# ❌ 复杂
use Nex.Page
use Nex.Api
use Nex.Partial

# ✅ 简单
use Nex
```

**2. 约定胜于配置**
```elixir
# ❌ 需要配置
defmodule MyApp.Pages.Index do
  use Nex.Page  # 手动指定类型
end

# ✅ 自动识别
defmodule MyApp.Pages.Index do
  use Nex  # 框架自动识别是 Page
end
```

**3. 对齐胜于创新**
```elixir
# ❌ Nex 特有
req.params["id"]
req.path_params["id"]
req.query_params["page"]

# ✅ 对齐 Next.js
req.query["id"]
req.query["page"]
req.body["name"]
```

**4. 一等公民胜于特殊处理**
```elixir
# ❌ 特殊处理
use Nex.SSE
def stream(params, send)

# ✅ 一等公民
use Nex
def get(req) do
  Nex.stream(fn send -> ... end)
end
```

---

## 🚀 未来展望

### 0.3.0 只是开始

这次重构不仅仅是 API 的改变，更是**设计哲学的转变**：

**从"Elixir 的 Phoenix"到"Elixir 的 Next.js"**

### 下一步计划

1. **更好的 TypeScript 支持**
   - 自动生成 API 类型定义
   - 前后端类型安全

2. **更强的 AI 集成**
   - 内置 AI SDK
   - 流式响应优化

3. **更简单的部署**
   - 一键部署到 Fly.io/Railway
   - 自动 Docker 优化

4. **更完善的生态**
   - 官方组件库
   - 插件系统

### 核心不变

无论如何演进，Nex 的核心理念不会变：

- ✅ **极简**: 最少的代码，最大的生产力
- ✅ **现代**: 对齐现代框架的最佳实践
- ✅ **实用**: 解决真实世界的问题

---

## 💭 写给开发者的话

### 为什么要做 Breaking Changes？

我知道 Breaking Changes 会给用户带来迁移成本，但我相信：

**短期的痛苦，换来长期的收益。**

如果我们不在 0.3.0 做这些改变，那么：

1. **技术债会越积越多**: 4 个 `use` 语句会一直存在
2. **新用户会更困惑**: "为什么 Nex 这么复杂？"
3. **生态会分裂**: 一部分人用旧 API，一部分人用新 API
4. **框架会失去竞争力**: 无法与 Next.js 竞争

**现在是最好的时机**:

- ✅ 用户基数还不大，迁移成本可控
- ✅ 框架还在快速迭代期，可以大胆改进
- ✅ AI 时代刚开始，现在布局正当时

### 给迁移用户的承诺

1. **详细的迁移指南**: 我们提供了完整的升级文档
2. **批量迁移脚本**: 大部分修改可以自动完成
3. **长期支持**: 0.3.x 将是一个长期稳定版本
4. **更好的未来**: 迁移后，你会发现代码更简洁、更易维护

### 给新用户的承诺

1. **极简的 API**: 只需要学习 `use Nex` 和几个响应函数
2. **零学习成本**: 如果你会 Next.js，你就会 Nex
3. **完善的文档**: 从入门到精通的完整教程
4. **活跃的社区**: 我们会持续改进和支持

---

## 🙏 致谢

感谢所有在 0.2.x 阶段提供反馈的用户，你们的意见让 Nex 变得更好。

特别感谢：

- **Next.js 团队**: 提供了极简框架的最佳实践
- **Phoenix 团队**: 提供了 Elixir Web 开发的基础
- **HTMX 社区**: 证明了服务端渲染的现代化可能性
- **AI 社区**: 推动了流式响应的普及

---

## 📚 延伸阅读

- [UPGRADE_GUIDE.md](./UPGRADE_GUIDE.md) - 详细的升级指南
- [CHANGELOG.md](./CHANGELOG.md) - 完整的变更日志
- [README.md](./README.md) - 项目介绍
- [Next.js Documentation](https://nextjs.org/docs) - Next.js 官方文档
- [Phoenix Documentation](https://hexdocs.pm/phoenix) - Phoenix 官方文档

---

**Nex 0.3.0 - 极简、现代、实用的 Elixir Web 框架**

让我们一起构建更好的 Web 应用！🚀
