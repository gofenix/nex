# Nex 0.3.0 升级指南

从 0.2.x 升级到 0.3.0 - 重大架构升级

---

## 📋 升级概览

Nex 0.3.0 是一个**重大版本升级**，带来了革命性的 API 简化和现代化改进。本次升级包含多个 **Breaking Changes**，需要手动迁移代码。

### 🎯 核心理念

- **极致简化**: 统一 `use Nex` 接口，告别 `use Nex.Page/Api/Partial/SSE`
- **现代化**: `partials/` → `components/`，对齐 React/Vue/Phoenix 生态
- **AI 原生**: 原生 SSE 流式响应，完美支持 AI 应用
- **Next.js 对齐**: API 请求对象完全对齐 Next.js 标准

### ⚠️ Breaking Changes 总览

| 变化 | 影响范围 | 迁移难度 |
|------|---------|---------|
| 统一 `use Nex` 接口 | 所有模块 | ⭐⭐ 简单 |
| `partials/` → `components/` | 组件模块 | ⭐⭐ 简单 |
| API 请求对象重设计 | API 模块 | ⭐⭐⭐ 中等 |
| 移除 `Nex.SSE` | SSE 端点 | ⭐⭐ 简单 |

---

## 🚀 快速迁移清单

### 1️⃣ 更新所有 `use` 语句（必须）

**查找所有需要修改的文件**:
```bash
# 查找所有使用旧 API 的文件
grep -r "use Nex\." src/
```

**批量替换**:
```bash
# 替换 use Nex.Page
find src/ -name "*.ex" -exec sed -i '' 's/use Nex\.Page/use Nex/g' {} +

# 替换 use Nex.Api
find src/ -name "*.ex" -exec sed -i '' 's/use Nex\.Api/use Nex/g' {} +

# 替换 use Nex.Partial
find src/ -name "*.ex" -exec sed -i '' 's/use Nex\.Partial/use Nex/g' {} +

# 替换 use Nex.SSE
find src/ -name "*.ex" -exec sed -i '' 's/use Nex\.SSE/use Nex/g' {} +
```

### 2️⃣ 重命名 `partials/` 为 `components/`（必须）

**重命名目录**:
```bash
# 重命名目录
mv src/partials src/components
```

**更新模块命名空间**:
```bash
# 替换模块名
find src/ -name "*.ex" -exec sed -i '' 's/defmodule \(.*\)\.Partials\./defmodule \1.Components./g' {} +

# 替换模块引用
find src/ -name "*.ex" -exec sed -i '' 's/\([^.]\)Partials\./\1Components./g' {} +
```

### 3️⃣ 更新 API 请求参数访问（如有 API）

**查找需要修改的代码**:
```bash
# 查找所有使用 req.params 的地方
grep -r "req\.params" src/api/
```

**迁移规则**:
- `req.params["id"]` → `req.query["id"]` (路径参数或查询参数)
- `req.params["name"]` → `req.body["name"]` (POST 请求体参数)
- `req.path_params` → 删除，使用 `req.query`
- `req.query_params` → 删除，使用 `req.query`
- `req.body_params` → 删除，使用 `req.body`

### 4️⃣ 更新依赖版本

**更新 `mix.exs`**:
```elixir
defp deps do
  [
    {:nex_core, "~> 0.3.0"}  # 或使用 path 依赖
  ]
end
```

**安装依赖**:
```bash
mix deps.get
mix deps.compile
```

### 5️⃣ 编译验证

```bash
# 编译检查
mix compile

# 运行开发服务器
mix nex.dev
```

---

## 📖 详细迁移指南

### 1. 统一 `use Nex` 接口

#### 🎯 变化说明

所有 `use Nex.*` 模块已被移除，统一使用 `use Nex`。框架会根据模块路径自动检测类型：

- `.Pages.*` → 自动导入 HEEx + CSRF
- `.Api.*` → 纯函数，无自动导入
- `.Components.*` → 自动导入 HEEx + CSRF
- `.Layouts` → 自动导入 HEEx + CSRF

#### ❌ Before (0.2.x)

```elixir
# src/pages/index.ex
defmodule MyApp.Pages.Index do
  use Nex.Page  # ❌ 编译错误

  def get(_req) do
    Nex.html(~H"""
    <h1>Hello</h1>
    """)
  end
end

# src/api/users.ex
defmodule MyApp.Api.Users do
  use Nex.Api  # ❌ 编译错误

  def get(req) do
    Nex.json(%{users: []})
  end
end

# src/partials/card.ex
defmodule MyApp.Partials.Card do
  use Nex.Partial  # ❌ 编译错误

  def card(assigns) do
    ~H"""
    <div class="card">...</div>
    """
  end
end
```

#### ✅ After (0.3.0)

```elixir
# src/pages/index.ex
defmodule MyApp.Pages.Index do
  use Nex  # ✅ 统一接口

  def get(_req) do
    Nex.html(~H"""
    <h1>Hello</h1>
    """)
  end
end

# src/api/users.ex
defmodule MyApp.Api.Users do
  use Nex  # ✅ 统一接口

  def get(req) do
    Nex.json(%{users: []})
  end
end

# src/components/card.ex
defmodule MyApp.Components.Card do
  use Nex  # ✅ 统一接口

  def card(assigns) do
    ~H"""
    <div class="card">...</div>
    """
  end
end
```

#### 💡 优势

- **认知负担降低**: 只需记住一个 `use Nex`
- **对齐 Next.js**: 类似 Next.js 的零配置理念
- **自动类型检测**: 框架智能识别模块类型

---

### 2. `partials/` → `components/`

#### 🎯 变化说明

为了对齐现代前端框架（React、Vue、Svelte）和 Phoenix 1.7+ 的命名约定，将 `partials` 重命名为 `components`。

#### ❌ Before (0.2.x)

```
src/
├── pages/
├── api/
└── partials/          # ❌ 旧命名
    ├── ui/
    │   ├── button.ex
    │   └── card.ex
    └── header.ex
```

```elixir
# src/partials/ui/button.ex
defmodule MyApp.Partials.Ui.Button do  # ❌ 旧命名空间
  use Nex.Partial

  def button(assigns) do
    ~H"""
    <button class="btn">Click</button>
    """
  end
end

# src/pages/index.ex
defmodule MyApp.Pages.Index do
  use Nex.Page

  def get(_req) do
    Nex.html(~H"""
    <MyApp.Partials.Ui.Button.button />  <!-- ❌ 旧引用 -->
    """)
  end
end
```

#### ✅ After (0.3.0)

```
src/
├── pages/
├── api/
└── components/        # ✅ 新命名
    ├── ui/
    │   ├── button.ex
    │   └── card.ex
    └── header.ex
```

```elixir
# src/components/ui/button.ex
defmodule MyApp.Components.Ui.Button do  # ✅ 新命名空间
  use Nex

  def button(assigns) do
    ~H"""
    <button class="btn">Click</button>
    """
  end
end

# src/pages/index.ex
defmodule MyApp.Pages.Index do
  use Nex

  def get(_req) do
    Nex.html(~H"""
    <MyApp.Components.Ui.Button.button />  <!-- ✅ 新引用 -->
    """)
  end
end
```

#### 💡 优势

- **行业标准**: 与 React/Vue/Phoenix 命名一致
- **降低学习曲线**: 前端开发者更熟悉
- **语义清晰**: `components` 比 `partials` 更直观

---

### 3. API 请求对象重设计

#### 🎯 变化说明

完全对齐 Next.js API Routes 的请求对象设计，移除 Nex 特有字段，只保留 Next.js 标准字段。

#### ❌ Before (0.2.x)

```elixir
defmodule MyApp.Api.Users do
  use Nex.Api

  # GET /api/users/123?page=2
  def get(req) do
    user_id = req.params["id"]        # ❌ 已移除
    page = req.params["page"]         # ❌ 已移除
    
    # 或者
    user_id = req.path_params["id"]   # ❌ 已移除
    page = req.query_params["page"]   # ❌ 已移除
    
    Nex.json(%{user_id: user_id, page: page})
  end

  # POST /api/users
  def post(req) do
    name = req.params["name"]         # ❌ 已移除
    email = req.params["email"]       # ❌ 已移除
    
    # 或者
    name = req.body_params["name"]    # ❌ 已移除
    
    Nex.json(%{message: "Created"})
  end
end
```

#### ✅ After (0.3.0)

```elixir
defmodule MyApp.Api.Users do
  use Nex

  # GET /api/users/123?page=2
  def get(req) do
    user_id = req.query["id"]    # ✅ 路径参数（来自 [id].ex）
    page = req.query["page"]     # ✅ 查询参数（来自 ?page=2）
    
    # req.query 包含路径参数 + 查询参数（路径参数优先）
    
    Nex.json(%{user_id: user_id, page: page})
  end

  # POST /api/users
  def post(req) do
    name = req.body["name"]      # ✅ 请求体参数
    email = req.body["email"]    # ✅ 请求体参数
    
    # req.body 完全独立，不与 req.query 合并
    
    Nex.json(%{message: "Created"})
  end
end
```

#### 📊 字段对照表

| 0.2.x | 0.3.0 | 说明 |
|-------|-------|------|
| `req.params` | ❌ 已移除 | 使用 `req.query` 或 `req.body` |
| `req.path_params` | ❌ 已移除 | 使用 `req.query` |
| `req.query_params` | ❌ 已移除 | 使用 `req.query` |
| `req.body_params` | ❌ 已移除 | 使用 `req.body` |
| - | ✅ `req.query` | 路径参数 + 查询参数 |
| - | ✅ `req.body` | 请求体参数 |
| `req.method` | ✅ `req.method` | 保持不变 |
| `req.headers` | ✅ `req.headers` | 保持不变 |
| `req.cookies` | ✅ `req.cookies` | 保持不变 |

#### 🔍 参数合并规则

**`req.query` 的行为**（与 Next.js 完全一致）:
```elixir
# GET /api/users/[id]?id=456&page=2
# 文件: src/api/users/[id].ex

def get(req) do
  req.query["id"]    # => "123" (路径参数优先！)
  req.query["page"]  # => "2"   (查询参数)
end
```

**`req.body` 的行为**:
```elixir
# POST /api/users
# Content-Type: application/json
# Body: {"name": "Alice", "email": "alice@example.com"}

def post(req) do
  req.body["name"]   # => "Alice"
  req.body["email"]  # => "alice@example.com"
  req.query          # => %{} (GET 请求才有查询参数)
end
```

#### 💡 优势

- **Next.js 对齐**: 与 Next.js API Routes 完全一致
- **语义清晰**: `query` vs `body` 更明确
- **降低学习成本**: 熟悉 Next.js 的开发者零学习成本

---

### 4. SSE 流式响应升级

#### 🎯 变化说明

移除 `use Nex.SSE` 和 `__sse_endpoint__` 标记，统一使用 `Nex.stream/1` 返回流式响应。

#### ❌ Before (0.2.x)

```elixir
defmodule MyApp.Api.Chat.Stream do
  use Nex.SSE  # ❌ 已移除

  def stream(params, send) do
    message = params["message"]
    
    send.("Thinking...")
    send.("Processing...")
    send.("Done!")
  end
end
```

#### ✅ After (0.3.0)

```elixir
defmodule MyApp.Api.Chat.Stream do
  use Nex  # ✅ 统一接口

  def get(req) do
    message = req.query["message"]
    
    Nex.stream(fn send ->
      send.("Thinking...")
      send.("Processing...")
      send.("Done!")
    end)
  end
end
```

#### 🚀 完整 AI 流式示例

```elixir
defmodule MyApp.Api.Chat.Stream do
  use Nex

  def get(req) do
    message = req.query["message"]
    
    Nex.stream(fn send ->
      # 使用 Finch.stream 实现真正的流式响应
      Finch.build(:post, "https://api.openai.com/v1/chat/completions",
        [{"authorization", "Bearer #{api_key}"}],
        Jason.encode!(%{
          model: "gpt-4",
          messages: [%{role: "user", content: message}],
          stream: true
        })
      )
      |> Finch.stream(MyApp.Finch, nil, fn
        {:status, _}, acc -> acc
        {:headers, _}, acc -> acc
        {:data, chunk}, acc ->
          # 解析 SSE chunk
          chunk
          |> String.split("\n\n", trim: true)
          |> Enum.each(fn line ->
            if String.starts_with?(line, "data: ") do
              data = String.slice(line, 6..-1)
              if data != "[DONE]" do
                case Jason.decode(data) do
                  {:ok, %{"choices" => [%{"delta" => %{"content" => content}}]}} ->
                    send.(content)  # 实时发送每个 token
                  _ -> :ok
                end
              end
            end
          end)
          acc
      end)
    end)
  end
end
```

#### 💡 优势

- **更简单**: 不需要 `use Nex.SSE` 标记
- **更灵活**: 可以在任何 API 端点返回流式响应
- **真正流式**: 使用 `Finch.stream` 实现真正的打字机效果

---

## 🆕 新功能

### 1. `Nex.html/2` 响应助手

专为 HTMX 场景设计的 HTML 响应助手。

```elixir
defmodule MyApp.Api.Users do
  use Nex

  def post(req) do
    name = req.body["name"]
    
    # 返回 HTML 片段（HTMX 会替换到页面中）
    Nex.html("""
    <div class="user-card">
      <h3>#{name}</h3>
      <p>User created successfully!</p>
    </div>
    """)
  end
end
```

### 2. `Nex.Store` 状态管理

页面范围的状态存储，支持 TTL 和自动清理。

```elixir
defmodule MyApp.Pages.Chat do
  use Nex

  def post(req) do
    message = req.body["message"]
    
    # 保存消息到 Store
    messages = Nex.Store.get(:messages, [])
    Nex.Store.put(:messages, [message | messages])
    
    # 生成 SSE URL
    msg_id = :crypto.strong_rand_bytes(16) |> Base.encode16()
    Nex.Store.put(:pending_message, %{msg_id: msg_id, content: message})
    
    sse_url = "/api/chat/stream?msg_id=#{msg_id}"
    Nex.html(~H"""
    <div hx-ext="sse" sse-connect={sse_url} sse-swap="message">
      Connecting...
    </div>
    """)
  end
end
```

### 3. 动态路由

基于文件系统的动态路由，支持参数和通配符。

```
src/api/
├── users/
│   ├── [id].ex           # /api/users/123
│   └── [id]/
│       └── posts.ex      # /api/users/123/posts
└── docs/
    └── [...path].ex      # /api/docs/a/b/c
```

```elixir
# src/api/users/[id].ex
defmodule MyApp.Api.Users.Id do
  use Nex

  def get(req) do
    user_id = req.query["id"]  # 从路径参数获取
    Nex.json(%{user_id: user_id})
  end
end

# src/api/docs/[...path].ex
defmodule MyApp.Api.Docs.Path do
  use Nex

  def get(req) do
    path = req.query["path"]  # => ["guide", "getting-started"]
    Nex.json(%{path: path})
  end
end
```

---

## 🔧 常见问题

### Q1: 编译错误 "undefined function Nex.Page.__using__/1"

**原因**: 使用了已移除的 `use Nex.Page`

**解决**: 替换为 `use Nex`

```elixir
# ❌ Before
defmodule MyApp.Pages.Index do
  use Nex.Page
end

# ✅ After
defmodule MyApp.Pages.Index do
  use Nex
end
```

### Q2: 找不到 `req.params`

**原因**: `req.params` 已被移除

**解决**: 使用 `req.query` 或 `req.body`

```elixir
# ❌ Before
def get(req) do
  id = req.params["id"]
end

# ✅ After
def get(req) do
  id = req.query["id"]  # 路径参数或查询参数
end

# ❌ Before
def post(req) do
  name = req.params["name"]
end

# ✅ After
def post(req) do
  name = req.body["name"]  # 请求体参数
end
```

### Q3: 组件引用报错 "module MyApp.Partials.* is not available"

**原因**: `Partials` 命名空间已改为 `Components`

**解决**: 更新模块名和引用

```elixir
# ❌ Before
defmodule MyApp.Partials.Card do
  use Nex.Partial
end

# 引用
<MyApp.Partials.Card.card />

# ✅ After
defmodule MyApp.Components.Card do
  use Nex
end

# 引用
<MyApp.Components.Card.card />
```

### Q4: SSE 端点不工作

**原因**: 使用了已移除的 `use Nex.SSE`

**解决**: 使用 `Nex.stream/1`

```elixir
# ❌ Before
defmodule MyApp.Api.Stream do
  use Nex.SSE

  def stream(params, send) do
    send.("Hello")
  end
end

# ✅ After
defmodule MyApp.Api.Stream do
  use Nex

  def get(req) do
    Nex.stream(fn send ->
      send.("Hello")
    end)
  end
end
```

---

## 📚 参考资源

### 官方文档
- [Getting Started](https://nex-framework.dev/getting_started)
- [HEEx Guide](https://nex-framework.dev/heex_guide)
- [API Reference](https://hexdocs.pm/nex_core)

### 示例项目
- `examples/chatbot_sse` - AI 流式聊天机器人
- `examples/todos` - HTMX CRUD 应用
- `examples/dynamic_routes` - 动态路由示例

### 对比 Next.js
- [Nex.Req vs Next.js Request](https://nex-framework.dev/api_reference#request-object)
- [SSE vs Next.js Streaming](https://nex-framework.dev/sse_guide)

---

## ✅ 迁移检查清单

完成迁移后，请确认以下事项：

- [ ] 所有 `use Nex.Page/Api/Partial/SSE` 已替换为 `use Nex`
- [ ] `src/partials/` 已重命名为 `src/components/`
- [ ] 所有 `MyApp.Partials.*` 模块已重命名为 `MyApp.Components.*`
- [ ] 所有组件引用已更新（`<MyApp.Partials.*` → `<MyApp.Components.*`）
- [ ] 所有 `req.params` 已替换为 `req.query` 或 `req.body`
- [ ] 所有 `req.path_params/query_params/body_params` 已移除
- [ ] SSE 端点已更新为使用 `Nex.stream/1`
- [ ] `mix.exs` 依赖版本已更新为 `~> 0.3.0`
- [ ] 运行 `mix compile` 无错误
- [ ] 运行 `mix nex.dev` 启动成功
- [ ] 所有功能测试通过

---

## 🎉 升级完成

恭喜！你已成功升级到 Nex 0.3.0。

享受更简洁、更现代的开发体验吧！🚀

如有问题，请查看：
- [GitHub Issues](https://github.com/gofenix/nex/issues)
- [Discussions](https://github.com/gofenix/nex/discussions)
