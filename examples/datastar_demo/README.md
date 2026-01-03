# Datastar Demo - Nex Framework

这是一个 Datastar 集成的完整演示项目，展示 Datastar 的核心特性以及如何在 Nex 框架中使用。

## 项目概述

Datastar 是一个超媒体优先的前端框架，结合了：
- **HTMX 的后端驱动** - 服务器端渲染和更新
- **Alpine.js 的前端响应性** - 客户端状态管理和响应式 UI

**版本**: Datastar 1.0.0-RC.7（最新稳定版）

本 demo 展示了 Datastar 的 11 大核心特性。

## 功能演示

### 1. 计数器 (`/`)
- **后端驱动更新**：使用 `data-on:click="@post()"` 发送请求
- **前端信号**：使用 `data-signals` 定义响应式状态
- **对比展示**：后端计数器 vs 纯前端计数器

### 2. 表单验证 (`/form`)
- **实时验证**：使用 `data-computed` 计算属性
- **条件显示**：使用 `data-show` 显示错误提示
- **动态禁用**：使用 `data-attr:disabled` 控制按钮状态
- **双向绑定**：使用 `data-bind` 绑定输入框

### 3. SSE 聊天 (`/chat`)
- **流式响应**：使用 Server-Sent Events 实现 AI 流式输出
- **加载状态**：使用信号控制 UI 状态
- **实时更新**：逐字显示响应内容
- **data-init**：页面加载时自动建立 SSE 连接

### 4. Todo 列表 (`/todos`)
- **前端过滤**：使用信号实现客户端过滤（全部/进行中/已完成）
- **动态样式**：使用 `data-class` 条件应用 CSS 类
- **CRUD 操作**：添加、切换、删除任务
- **综合应用**：前端验证 + 后端交互

### 5. 高级特性 (`/advanced`)
- **data-init**：页面加载时执行（CQRS 模式）
- **data-on-intersect**：懒加载和无限滚动
- **data-effect**：响应式副作用
- **data-ref**：DOM 元素引用
- **data-indicator**：自动加载指示器
- **data-style**：动态内联样式

## 快速开始

```bash
# 安装依赖
cd examples/datastar_demo
mix deps.get

# 启动服务器
mix run --no-halt

# 或使用开发模式（如果支持）
# mix nex.dev
```

访问 http://localhost:4000

## 项目结构

```
datastar_demo/
├── src/
│   ├── application.ex          # 应用启动配置
│   ├── layouts.ex              # 布局（引入 Datastar CDN）
│   ├── pages/
│   │   ├── index.ex           # 计数器演示
│   │   ├── form.ex            # 表单验证演示
│   │   ├── chat.ex            # SSE 聊天演示
│   │   └── todos.ex           # Todo 列表演示
│   └── api/
│       └── chat.ex            # SSE 流式 API
├── mix.exs
└── README.md
```

## Datastar 核心概念

### 1. 信号 (Signals)

```html
<div data-signals="{count: 0}">
  <span data-text="$count"></span>
  <button data-on:click="$count++">+</button>
</div>
```

### 2. 计算属性 (Computed)

```html
<div data-signals="{email: ''}" 
     data-computed:isValid="$email.includes('@')">
  <span data-show="!$isValid">Invalid email</span>
</div>
```

### 3. 后端请求 (Actions)

```html
<button data-on:click="@post('/increment')">+</button>
```

### 4. 条件渲染

```html
<span data-show="$count > 0">Count is positive</span>
```

### 5. 动态属性

```html
<button data-attr:disabled="!$isValid">Submit</button>
```

### 6. 动态样式

```html
<div data-class:bg-blue-500="$isActive">...</div>
```

## 后端代码示例

Datastar 的优势在于后端代码非常简洁：

```elixir
defmodule DatastarDemo.Pages.Index do
  use Nex

  def mount(_params) do
    %{count: 0}
  end

  def render(assigns) do
    ~H"""
    <div data-signals="{count: {@count}}">
      <div id="counter" data-text="$count"></div>
      <button data-on:click="@post('/increment')">+</button>
    </div>
    """
  end

  # 后端只需返回 HTML 片段
  def increment(_params) do
    count = Nex.Store.update(:count, 0, &(&1 + 1))
    ~H"""<div id="counter">{@count}</div>"""
  end
end
```

## SSE 流式响应

对于 AI 聊天等场景，使用 `Nex.stream/1`：

```elixir
def stream(req) do
  Nex.stream(fn send ->
    for token <- ai_response() do
      send.(~s"""
      event: datastar-patch-elements
      data: selector #response
      data: elements <div id="response">#{token}</div>

      """)
    end
  end)
end
```

## 技术栈

- **Nex** - Elixir 极简 Web 框架
- **Datastar** - 超媒体优先前端框架
- **Tailwind CSS** - 样式框架
- **Bandit** - HTTP 服务器

## Datastar Tao 哲学

本 demo 遵循 [Datastar Tao](https://data-star.dev/guide/the_tao_of_datastar) 的最佳实践：

### ✅ 核心原则

1. **后端为真理源** - 状态应该在后端管理，前端只是展示
2. **少用 signals** - 仅用于用户交互和发送数据到后端
3. **使用 morphing** - 发送大块 DOM，让 Datastar 智能更新
4. **优先 SSE** - 使用 `text/event-stream` 进行后端推送
5. **压缩流** - 使用 Brotli 压缩 SSE 响应（生产环境）
6. **保持 DRY** - 使用模板语言复用代码
7. **使用锚点导航** - 用 `<a>` 标签，不要自己管理路由
8. **CQRS 模式** - 长连接读取 + 短请求写入

## 技术栈

- **Nex** - Elixir 极简 Web 框架
- **Datastar 1.0.0-RC.7** - 超媒体优先前端框架
- **Tailwind CSS** - 样式框架

## 关键发现

### ✅ 优势

1. **统一的 API**：`data-*` 属性统一前后端交互
2. **无需 Alpine.js**：Datastar 内置前端响应性
3. **原生 SSE**：完美支持流式响应
4. **简洁的后端**：仍然返回 HTML，无需学习新 API
5. **智能 morphing**：只更新变化的部分，保持状态

### ⚠️ 需要注意

1. **请求格式**：Datastar 请求带有 `datastar-request: true` header
2. **响应格式**：需要返回 SSE 格式（`event: datastar-patch-elements`）
3. **信号传递**：Datastar 会在请求中发送所有信号（GET 的 query 参数，POST 的 body）

## 许可证

MIT
