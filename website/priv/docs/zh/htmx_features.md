# HTMX 完整特性指南

本指南涵盖所有 HTMX 特性以及它们如何与 Nex 框架集成。Nex 从设计之初就与 HTMX 无缝配合，完全支持所有 HTMX 功能。

## 目录

- [核心 AJAX 属性](#核心-ajax-属性)
- [触发请求](#触发请求)
- [目标与交换](#目标与交换)
- [请求指示器](#请求指示器)
- [同步机制](#同步机制)
- [Out of Band 交换](#out-of-band-交换)
- [参数控制](#参数控制)
- [确认请求](#确认请求)
- [属性继承](#属性继承)
- [Boosting](#boosting)
- [WebSockets 与 SSE](#websockets-与-sse)
- [历史支持](#历史支持)
- [表单验证](#表单验证)
- [动画效果](#动画效果)
- [扩展系统](#扩展系统)
- [事件与日志](#事件与日志)
- [安全特性](#安全特性)

---

## 核心 AJAX 属性

HTMX 提供五个核心属性用于发起 AJAX 请求。**Nex 完全支持所有 HTTP 方法。**

### ✅ hx-get

向指定 URL 发起 GET 请求。

```html
<button hx-get="/api/users">加载用户</button>
```

**Nex 集成：**
```elixir
defmodule MyApp.Api.Users do
  use Nex

  def get(_params) do
    users = ["Alice", "Bob", "Charlie"]
    {:ok, %{users: users}}
  end
end
```

### ✅ hx-post

向指定 URL 发起 POST 请求。

```html
<form hx-post="/submit">
  <input name="email" type="email" />
  <button type="submit">提交</button>
</form>
```

**Nex 集成：**
```elixir
defmodule MyApp.Pages.Index do
  use Nex

  def submit(params) do
    email = params["email"]
    ~H"""
    <p>谢谢，{email}！</p>
    """
  end
end
```

### ✅ hx-put

向指定 URL 发起 PUT 请求。

```html
<button hx-put="/api/todos/123">更新待办</button>
```

**Nex 集成（v0.2.4+）：**
```elixir
defmodule MyApp.Api.Todos.Id do
  use Nex

  def put(params) do
    id = params["id"]
    # 更新逻辑
    {:ok, %{message: "待办 #{id} 已更新"}}
  end
end
```

### ✅ hx-patch

向指定 URL 发起 PATCH 请求。

```html
<button hx-patch="/api/users/123">部分更新用户</button>
```

**Nex 集成（v0.2.4+）：**
```elixir
defmodule MyApp.Api.Users.Id do
  use Nex

  def patch(params) do
    id = params["id"]
    # 部分更新逻辑
    {:ok, %{message: "用户 #{id} 已更新"}}
  end
end
```

### ✅ hx-delete

向指定 URL 发起 DELETE 请求。

```html
<button hx-delete="/api/todos/123">删除待办</button>
```

**Nex 集成（v0.2.4+）：**
```elixir
defmodule MyApp.Api.Todos.Id do
  use Nex

  def delete(params) do
    id = params["id"]
    # 删除逻辑
    {:ok, %{message: "待办 #{id} 已删除"}}
  end
end
```

**✅ 状态：Nex v0.2.4+ 完全支持所有 HTTP 方法**

---

## 触发请求

HTMX 允许你使用 `hx-trigger` 属性控制何时触发请求。

### ✅ 默认触发器

不同元素有自然的触发事件：
- `input`、`textarea`、`select` → `change` 事件
- `form` → `submit` 事件
- 其他所有元素 → `click` 事件

**Nex 集成：**
```elixir
def render(assigns) do
  ~H"""
  <input hx-get="/search" name="q" placeholder="搜索..." />
  <form hx-post="/submit">
    <button type="submit">提交</button>
  </form>
  <button hx-get="/data">点击我</button>
  """
end
```

### ✅ 自定义触发器

```html
<div hx-post="/mouse_entered" hx-trigger="mouseenter">
  鼠标悬停在我上面！
</div>
```

**Nex 集成：**
```elixir
def mouse_entered(_params) do
  ~H"<p>鼠标进入了！</p>"
end
```

### ✅ 触发器修饰符

HTMX 支持多个触发器修饰符：

**once** - 只触发一次：
```html
<div hx-get="/data" hx-trigger="click once">只点击一次</div>
```

**changed** - 仅在值改变时触发：
```html
<input hx-get="/search" hx-trigger="keyup changed" />
```

**delay** - 延迟触发：
```html
<input hx-get="/search" hx-trigger="keyup changed delay:500ms" />
```

**throttle** - 节流触发：
```html
<input hx-get="/search" hx-trigger="keyup throttle:1s" />
```

**from** - 监听不同元素：
```html
<input hx-get="/search" hx-trigger="keyup from:body" />
```

**Nex 集成示例（实时搜索）：**
```elixir
def render(assigns) do
  ~H"""
  <input 
    type="text" 
    name="q"
    hx-get="/search"
    hx-trigger="keyup changed delay:500ms"
    hx-target="#results"
    placeholder="搜索..."
  />
  <div id="results"></div>
  """
end

def search(params) do
  query = params["q"]
  results = search_database(query)
  ~H"""
  <ul>
    <li :for={result <- results}>{result}</li>
  </ul>
  """
end
```

### ✅ 触发器过滤器

使用 JavaScript 表达式条件触发：

```html
<div hx-get="/clicked" hx-trigger="click[ctrlKey]">
  Ctrl+点击我
</div>
```

**Nex 集成：**
开箱即用 - 无需特殊处理。

### ✅ 特殊事件

HTMX 提供特殊触发事件：

**load** - 元素加载时触发：
```html
<div hx-get="/data" hx-trigger="load">加载中...</div>
```

**revealed** - 滚动到视口时触发：
```html
<div hx-get="/more" hx-trigger="revealed">加载更多...</div>
```

**intersect** - 视口交叉时触发：
```html
<div hx-get="/data" hx-trigger="intersect once">
  懒加载内容
</div>
```

**Nex 集成：**
```elixir
def render(assigns) do
  ~H"""
  <div hx-get="/load_more" hx-trigger="revealed">
    加载更多项目...
  </div>
  """
end

def load_more(_params) do
  items = get_next_page()
  ~H"""
  <div :for={item <- items}>{item}</div>
  """
end
```

**✅ 状态：完全支持所有触发特性**

---

## 目标与交换

### ✅ hx-target

使用 CSS 选择器指定加载响应的位置。

```html
<button hx-get="/data" hx-target="#result">加载</button>
<div id="result"></div>
```

**Nex 集成：**
```elixir
def render(assigns) do
  ~H"""
  <button hx-get="/load_data" hx-target="#result">加载</button>
  <div id="result">初始内容</div>
  """
end

def load_data(_params) do
  ~H"<p>新内容已加载！</p>"
end
```

### ✅ 扩展 CSS 选择器

HTMX 支持扩展选择器：

- `this` - 元素本身
- `closest <selector>` - 最近的祖先元素
- `next <selector>` - 下一个兄弟元素
- `previous <selector>` - 上一个兄弟元素
- `find <selector>` - 第一个子孙元素

```html
<tr>
  <td>项目 1</td>
  <td>
    <button hx-delete="/item/1" hx-target="closest tr">删除</button>
  </td>
</tr>
```

**Nex 集成：**
```elixir
def render(assigns) do
  ~H"""
  <table>
    <tr :for={item <- @items}>
      <td>{item.name}</td>
      <td>
        <button 
          hx-delete={"/delete/#{item.id}"} 
          hx-target="closest tr"
          hx-swap="outerHTML"
        >
          删除
        </button>
      </td>
    </tr>
  </table>
  """
end

def delete(params) do
  # 返回空以移除行
  ~H""
end
```

**✅ 状态：完全支持所有目标特性**

### ✅ hx-swap

控制内容如何交换到 DOM 中。

**交换策略：**
- `innerHTML`（默认）- 替换内部 HTML
- `outerHTML` - 替换整个元素
- `beforebegin` - 在元素前插入
- `afterbegin` - 在元素开始处插入
- `beforeend` - 在元素结束处插入
- `afterend` - 在元素后插入
- `delete` - 删除目标元素
- `none` - 不交换，仅处理响应

```html
<button hx-get="/data" hx-swap="outerHTML">替换我</button>
```

**Nex 集成：**
```elixir
def render(assigns) do
  ~H"""
  <div id="list">
    <button hx-get="/add_item" hx-target="#list" hx-swap="beforeend">
      添加项目
    </button>
  </div>
  """
end

def add_item(_params) do
  ~H"""
  <div class="item">新项目</div>
  """
end
```

### ✅ 交换修饰符

HTMX 支持交换修饰符：

- `transition:true` - 使用 View Transitions API
- `swap:<time>` - 延迟交换（默认 0ms）
- `settle:<time>` - 延迟稳定（默认 20ms）
- `ignoreTitle:true` - 不更新页面标题
- `scroll:<selector>:top|bottom` - 滚动目标
- `show:<selector>:top|bottom` - 显示目标

```html
<button hx-get="/data" hx-swap="innerHTML swap:100ms settle:200ms">
  延迟加载
</button>
```

**Nex 集成：**
自动工作 - 无需特殊处理。

**✅ 状态：完全支持所有交换特性**

---

## 请求指示器

### ✅ 加载状态

HTMX 在请求期间自动添加 `htmx-request` 类。

```html
<button hx-get="/data">
  <span class="htmx-indicator">加载中...</span>
  加载数据
</button>

<style>
  .htmx-indicator { display: none; }
  .htmx-request .htmx-indicator { display: inline; }
</style>
```

**Nex 集成：**
```elixir
def render(assigns) do
  ~H"""
  <style>
    .htmx-indicator { display: none; }
    .htmx-request .htmx-indicator { display: inline; }
  </style>
  
  <button hx-get="/slow_operation">
    <span class="htmx-indicator">⏳ 加载中...</span>
    <span class="htmx-request-hidden">点击我</span>
  </button>
  """
end

def slow_operation(_params) do
  :timer.sleep(2000)
  ~H"<p>操作完成！</p>"
end
```

**✅ 状态：完全支持**

---

## 同步机制

### ✅ hx-sync

同步请求以防止竞态条件。

```html
<form hx-post="/submit" hx-sync="this:replace">
  <input name="email" />
  <button type="submit">提交</button>
</form>
```

**策略：**
- `drop` - 有请求进行时丢弃新请求
- `abort` - 中止当前请求，发起新请求
- `replace` - 中止当前，替换为新请求
- `queue` - 队列请求

**Nex 集成：**
```elixir
def render(assigns) do
  ~H"""
  <input 
    hx-get="/search"
    hx-trigger="keyup changed delay:500ms"
    hx-sync="this:replace"
    placeholder="搜索..."
  />
  """
end
```

**✅ 状态：完全支持**

---

## Out of Band 交换

### ✅ hx-swap-oob

从单个响应更新多个元素。

```html
<div id="main">主要内容</div>
<div id="sidebar">侧边栏</div>
```

**Nex 集成：**
```elixir
def update_page(_params) do
  ~H"""
  <div id="main">
    更新的主要内容
  </div>
  <div id="sidebar" hx-swap-oob="true">
    更新的侧边栏
  </div>
  """
end
```

**✅ 状态：完全支持**

---

## 参数控制

### ✅ hx-params

控制请求中包含哪些参数。

```html
<form hx-post="/submit" hx-params="email,name">
  <input name="email" />
  <input name="name" />
  <input name="ignore" />
</form>
```

**Nex 集成：**
```elixir
def submit(params) do
  # 只有 email 和 name 会存在
  email = params["email"]
  name = params["name"]
  ~H"<p>你好 {name}！</p>"
end
```

### ✅ hx-vals

向请求添加静态值。

```html
<button hx-post="/submit" hx-vals='{"action": "delete"}'>
  删除
</button>
```

**Nex 集成：**
```elixir
def submit(params) do
  action = params["action"] # "delete"
  # 处理操作
end
```

**✅ 状态：完全支持**

---

## 确认请求

### ✅ hx-confirm

在请求前显示确认对话框。

```html
<button hx-delete="/account" hx-confirm="确定要删除吗？">
  删除账户
</button>
```

**Nex 集成：**
```elixir
def render(assigns) do
  ~H"""
  <button 
    hx-delete="/delete_account"
    hx-confirm="确定要删除您的账户吗？"
  >
    删除账户
  </button>
  """
end

def delete_account(_params) do
  # 删除逻辑
  ~H"<p>账户已删除</p>"
end
```

**✅ 状态：完全支持**

---

## 属性继承

### ✅ 继承属性

大多数 HTMX 属性会被子元素继承。

```html
<div hx-confirm="确定吗？">
  <button hx-delete="/item/1">删除 1</button>
  <button hx-delete="/item/2">删除 2</button>
</div>
```

**Nex 集成：**
```elixir
def render(assigns) do
  ~H"""
  <div hx-target="#result" hx-swap="innerHTML">
    <button hx-get="/data1">加载 1</button>
    <button hx-get="/data2">加载 2</button>
  </div>
  <div id="result"></div>
  """
end
```

### ✅ 取消继承

使用 `unset` 禁用继承。

```html
<div hx-confirm="确定吗？">
  <button hx-delete="/item">删除</button>
  <button hx-get="/" hx-confirm="unset">取消</button>
</div>
```

**✅ 状态：完全支持**

---

## Boosting

### ✅ hx-boost

将普通链接和表单转换为 AJAX 请求。

```html
<div hx-boost="true">
  <a href="/page1">页面 1</a>
  <a href="/page2">页面 2</a>
</div>
```

**Nex 集成：**

Nex v0.2.3+ 在所有布局的 body 标签上默认包含 `hx-boost="true"`：

```elixir
def render(assigns) do
  ~H"""
  <!DOCTYPE html>
  <html>
    <head>
      <title>{@title}</title>
      <script src="https://unpkg.com/htmx.org@2.0.4"></script>
    </head>
    <body hx-boost="true">
      {raw(@inner_content)}
    </body>
  </html>
  """
end
```

**优势：**
- 平滑的页面过渡，无需完整重载
- 维护浏览器历史
- 渐进增强
- 无需 JavaScript 也能工作

**✅ 状态：完全支持并默认启用**

---

## WebSockets 与 SSE

### ✅ 服务器发送事件（SSE）

HTMX 通过 `sse` 扩展支持 SSE。

```html
<div hx-ext="sse" sse-connect="/api/stream">
  <div sse-swap="message"></div>
</div>
```

**Nex 集成：**

Nex 对 SSE 有一等公民支持，使用 `Nex.SSE`：

```elixir
defmodule MyApp.Api.Stream do
  use Nex

  @impl true
  def stream(params, send_fn) do
    # 流循环
    stream_loop(send_fn)
  end

  defp stream_loop(send_fn) do
    data = get_current_data()
    send_fn.(%{event: "message", data: data})
    :timer.sleep(1000)
    stream_loop(send_fn)
  end
end
```

**客户端：**
```elixir
def render(assigns) do
  ~H"""
  <div hx-ext="sse" sse-connect="/api/stream">
    <div sse-swap="message">等待更新...</div>
  </div>
  """
end
```

**✅ 状态：通过专用的 `Nex.SSE` 行为完全支持**

### ✅ WebSockets

HTMX 通过 `ws` 扩展支持 WebSockets。

```html
<div hx-ext="ws" ws-connect="/chatroom">
  <div id="chat"></div>
  <form ws-send>
    <input name="message" />
  </form>
</div>
```

**Nex 集成：**

⚠️ **状态：不直接支持** - Nex 目前专注于 SSE 实现实时功能。WebSocket 支持需要额外实现。对于大多数实时用例，SSE 已经足够且更简单。

**替代方案：** 使用 Phoenix Channels 或使用 Bandit 实现自定义 WebSocket 处理。

---

## 历史支持

### ✅ hx-push-url

将 URL 推送到浏览器历史。

```html
<a hx-get="/page2" hx-push-url="true">前往页面 2</a>
```

**Nex 集成：**
```elixir
def render(assigns) do
  ~H"""
  <nav>
    <a hx-get="/about" hx-push-url="true">关于</a>
    <a hx-get="/contact" hx-push-url="true">联系</a>
  </nav>
  """
end
```

### ✅ 历史恢复

HTMX 在从历史恢复时发送 `HX-History-Restore-Request` 头。

**Nex 集成：**

Nex 自动处理历史恢复。当用户点击后退按钮时，HTMX 将：
1. 如果可用，使用缓存内容
2. 使用历史头发起新请求

```elixir
def mount(params) do
  # Nex 自动处理初始和历史请求
  %{
    title: "我的页面",
    content: "页面内容"
  }
end
```

**✅ 状态：完全支持**

---

## 表单验证

### ✅ HTML5 验证

HTMX 遵守 HTML5 验证属性。

```html
<form hx-post="/submit">
  <input name="email" type="email" required />
  <button type="submit">提交</button>
</form>
```

**Nex 集成：**
```elixir
def render(assigns) do
  ~H"""
  <form hx-post="/submit">
    <input name="email" type="email" required />
    <input name="age" type="number" min="18" max="100" />
    <button type="submit">提交</button>
  </form>
  """
end

def submit(params) do
  # 客户端验证已通过
  email = params["email"]
  age = params["age"]
  
  # 服务器端验证
  case validate(email, age) do
    :ok -> ~H"<p>成功！</p>"
    {:error, msg} -> ~H"<p class='error'>{msg}</p>"
  end
end
```

### ✅ hx-validate

在请求前强制验证。

```html
<input name="email" hx-get="/check" hx-validate="true" />
```

**✅ 状态：完全支持**

---

## 动画效果

### ✅ CSS 过渡

HTMX 与 CSS 过渡无缝配合。

```html
<style>
  .item {
    opacity: 1;
    transition: opacity 200ms ease-out;
  }
  .item.htmx-swapping {
    opacity: 0;
  }
</style>

<div class="item" hx-get="/new-content">内容</div>
```

**Nex 集成：**
```elixir
def render(assigns) do
  ~H"""
  <style>
    .fade-in {
      animation: fadeIn 300ms ease-in;
    }
    @keyframes fadeIn {
      from { opacity: 0; }
      to { opacity: 1; }
    }
  </style>
  
  <div class="fade-in" hx-get="/load_content">
    点击加载
  </div>
  """
end
```

### ✅ View Transitions API

HTMX 支持新的 View Transitions API。

```html
<button hx-get="/data" hx-swap="innerHTML transition:true">
  带过渡加载
</button>
```

**Nex 集成：**
自动工作 - 无需特殊处理。

**✅ 状态：完全支持**

---

## 扩展系统

### ✅ 核心扩展

HTMX 提供多个官方扩展：

**SSE 扩展** - 服务器发送事件支持
```html
<div hx-ext="sse" sse-connect="/stream">
  <div sse-swap="message"></div>
</div>
```
**✅ 通过 `Nex.SSE` 完全支持**

**WebSocket 扩展** - WebSocket 支持
```html
<div hx-ext="ws" ws-connect="/chat"></div>
```
**⚠️ 不直接支持 - 使用 Phoenix Channels**

**JSON 编码** - 发送 JSON 而非表单数据
```html
<form hx-ext="json-enc" hx-post="/api/data"></form>
```
**✅ 完全支持**

**Morphdom** - DOM 变形以获得更好的动画
```html
<div hx-ext="morphdom-swap"></div>
```
**✅ 完全支持**

**Class Tools** - 在事件上切换类
```html
<div hx-ext="class-tools"></div>
```
**✅ 完全支持**

**Preload** - 悬停时预加载内容
```html
<a hx-ext="preload" href="/page">链接</a>
```
**✅ 完全支持**

### ✅ 自定义扩展

你可以创建自定义 HTMX 扩展。

**Nex 集成：**
自定义扩展与 Nex 配合使用无需任何特殊处理。

**✅ 状态：除 WebSocket 外所有扩展都支持**

---

## 事件与日志

### ✅ HTMX 事件

HTMX 在其生命周期中触发众多事件：

**请求事件：**
- `htmx:configRequest` - 请求发起前
- `htmx:beforeRequest` - 请求发送前
- `htmx:afterRequest` - 请求完成后
- `htmx:responseError` - 响应错误时

**交换事件：**
- `htmx:beforeSwap` - 交换发生前
- `htmx:afterSwap` - 交换发生后
- `htmx:beforeSettle` - 稳定前
- `htmx:afterSettle` - 稳定后

**Nex 集成：**
```elixir
def render(assigns) do
  ~H"""
  <script>
    document.body.addEventListener('htmx:configRequest', (e) => {
      // 添加自定义头
      e.detail.headers['X-Custom-Header'] = 'value';
    });
    
    document.body.addEventListener('htmx:afterSwap', (e) => {
      console.log('内容已交换！');
    });
  </script>
  
  <button hx-get="/data">加载数据</button>
  """
end
```

### ✅ hx-on 属性

使用 `hx-on*` 属性内联处理事件。

```html
<button 
  hx-get="/data"
  hx-on::after-request="alert('完成！')"
>
  加载
</button>
```

**Nex 集成：**
```elixir
def render(assigns) do
  ~H"""
  <button 
    hx-get="/load_data"
    hx-on::after-request="console.log('已加载！')"
  >
    加载数据
  </button>
  """
end
```

**✅ 状态：完全支持**

---

## 安全特性

### ✅ CSRF 保护

HTMX 自动在请求中包含 CSRF 令牌。

**Nex 集成：**

Nex 内置 CSRF 保护：

```elixir
def render(assigns) do
  ~H"""
  <head>
    <meta name="csrf-token" content={Nex.CSRF.generate_token()} />
  </head>
  
  <form hx-post="/submit">
    {csrf_input_tag()}
    <input name="email" />
    <button type="submit">提交</button>
  </form>
  """
end
```

对于 HTMX AJAX 请求，在布局中添加：

```elixir
~H"""
<script>
  document.body.addEventListener('htmx:configRequest', (e) => {
    const token = document.querySelector('meta[name="csrf-token"]')?.content;
    if (token) {
      e.detail.headers['X-CSRF-Token'] = token;
    }
  });
</script>
"""
```

**✅ 状态：通过 `Nex.CSRF` 完全支持**

### ✅ 内容安全策略（CSP）

HTMX 支持使用 `hx-on*` 属性而非内联脚本的 CSP。

**Nex 集成：**
使用 `hx-on*` 属性而非内联事件处理器。

**✅ 状态：完全支持**

### ✅ XSS 防护

始终转义响应中的用户内容。

**Nex 集成：**

HEEx 模板自动转义内容：

```elixir
def render(assigns) do
  ~H"""
  <p>{@user_input}</p>  <!-- 自动转义 -->
  <p>{raw(@trusted_html)}</p>  <!-- 仅对可信内容使用 raw() -->
  """
end
```

**✅ 状态：通过 HEEx 自动 XSS 保护**

---

## 特性兼容性矩阵

| 特性 | HTMX | Nex 支持 | 备注 |
|------|------|----------|------|
| **HTTP 方法** | | | |
| GET | ✅ | ✅ | 完全支持 |
| POST | ✅ | ✅ | 完全支持 |
| PUT | ✅ | ✅ | v0.2.4+ |
| PATCH | ✅ | ✅ | v0.2.4+ |
| DELETE | ✅ | ✅ | v0.2.4+ |
| **触发器** | | | |
| 默认触发器 | ✅ | ✅ | 完全支持 |
| 自定义事件 | ✅ | ✅ | 完全支持 |
| 触发器修饰符 | ✅ | ✅ | once, changed, delay, throttle, from |
| 触发器过滤器 | ✅ | ✅ | JavaScript 表达式 |
| 特殊事件 | ✅ | ✅ | load, revealed, intersect |
| **目标** | | | |
| CSS 选择器 | ✅ | ✅ | 完全支持 |
| 扩展选择器 | ✅ | ✅ | this, closest, next, previous, find |
| **交换** | | | |
| 所有交换策略 | ✅ | ✅ | innerHTML, outerHTML 等 |
| 交换修饰符 | ✅ | ✅ | transition, swap, settle 等 |
| Out of band 交换 | ✅ | ✅ | 完全支持 |
| **特性** | | | |
| 请求指示器 | ✅ | ✅ | 完全支持 |
| 同步机制 | ✅ | ✅ | 完全支持 |
| 参数控制 | ✅ | ✅ | hx-params, hx-vals |
| 确认对话框 | ✅ | ✅ | hx-confirm |
| 属性继承 | ✅ | ✅ | 完全支持 |
| Boosting | ✅ | ✅ | v0.2.3+ 默认启用 |
| 历史支持 | ✅ | ✅ | hx-push-url |
| 表单验证 | ✅ | ✅ | HTML5 + 自定义 |
| 动画效果 | ✅ | ✅ | CSS 过渡 |
| **实时通信** | | | |
| 服务器发送事件 | ✅ | ✅ | 通过 Nex.SSE 一等公民支持 |
| WebSockets | ✅ | ⚠️ | 使用 Phoenix Channels 替代 |
| **安全** | | | |
| CSRF 保护 | ✅ | ✅ | 内置 Nex.CSRF |
| XSS 防护 | ✅ | ✅ | 通过 HEEx 自动 |
| CSP 支持 | ✅ | ✅ | 使用 hx-on* 属性 |
| **扩展** | | | |
| SSE 扩展 | ✅ | ✅ | 完全支持 |
| JSON 编码 | ✅ | ✅ | 完全支持 |
| Morphdom | ✅ | ✅ | 完全支持 |
| Class Tools | ✅ | ✅ | 完全支持 |
| Preload | ✅ | ✅ | 完全支持 |
| WebSocket 扩展 | ✅ | ⚠️ | 不直接支持 |
| 自定义扩展 | ✅ | ✅ | 完全支持 |

**图例：**
- ✅ 完全支持
- ⚠️ 部分支持或有替代方案
- ❌ 不支持

---

## 总结

**Nex 为 HTMX 提供全面支持**，框架从设计之初就与所有 HTMX 特性无缝配合。唯一值得注意的例外是 WebSocket 支持，我们建议使用 Phoenix Channels 或 SSE 作为替代方案。

### 核心优势

1. **完整的 HTTP 方法支持** - GET、POST、PUT、PATCH、DELETE（v0.2.4+）
2. **一等公民 SSE 支持** - 专用的 `Nex.SSE` 行为
3. **内置安全** - CSRF 保护和 XSS 防护
4. **零配置** - HTMX boost 默认启用
5. **HEEx 集成** - 清晰、类型安全的模板
6. **RESTful API** - 通过 `Nex.Api` 完全支持

### 快速开始

```bash
# 安装 Nex
mix archive.install hex nex_new

# 创建新项目
mix nex.new my_app
cd my_app

# 启动开发服务器
mix nex.dev
```

你的新 Nex 项目已预配置 HTMX，可以直接使用！

---

## 延伸阅读

- [HTMX 官方文档](https://htmx.org/docs/)
- [Nex 框架指南](https://github.com/gofenix/nex)
- [SSE 性能指南](sse_performance.md)
- [HTMX 集成指南](htmx_guide.md)
