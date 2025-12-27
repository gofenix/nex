# HTMX 集成

Nex 天然支持 HTMX，让你无需编写 JavaScript 就能实现丰富的交互。

## 什么是 HTMX

HTMX 是一个轻量级库，让你可以直接在 HTML 中声明 AJAX 请求、CSS 过渡、WebSocket 等功能。

```html
<button hx-post="/clicked" hx-swap="outerHTML">
  点击我
</button>
```

点击按钮时，HTMX 会：
1. 发送 POST 请求到 `/clicked`
2. 用响应内容替换按钮本身

## 基本属性

### hx-get / hx-post

发送 GET 或 POST 请求：

```html
<button hx-get="/data">加载数据</button>
<button hx-post="/submit">提交</button>
```

### hx-target

指定响应内容插入的目标元素：

```html
<button hx-post="/data" hx-target="#result">
  加载
</button>
<div id="result">结果会显示在这里</div>
```

### hx-swap

指定如何插入响应内容：

| 值 | 说明 |
|---|------|
| `innerHTML` | 替换目标内部内容（默认） |
| `outerHTML` | 替换整个目标元素 |
| `beforeend` | 插入到目标内部末尾 |
| `afterend` | 插入到目标后面 |
| `beforebegin` | 插入到目标前面 |
| `delete` | 删除目标元素 |
| `none` | 不做任何操作 |

### hx-vals

发送额外数据：

```html
<button hx-post="/delete" hx-vals='{"id": 123}'>
  删除
</button>
```

动态值（使用 Jason.encode!）：

```heex
<button hx-post="/delete" hx-vals={Jason.encode!(%{id: @todo.id})}>
  删除
</button>
```

### hx-trigger

指定触发事件：

```html
<!-- 默认是 click -->
<button hx-post="/submit">提交</button>

<!-- 其他事件 -->
<input hx-get="/search" hx-trigger="keyup changed delay:500ms" />
<div hx-get="/poll" hx-trigger="every 2s">实时数据</div>
<form hx-post="/submit" hx-trigger="submit">...</form>
```

## 常见模式

### 添加到列表

```elixir
def render(assigns) do
  ~H"""
  <form hx-post="/create"
        hx-target="#list"
        hx-swap="beforeend"
        hx-on::after-request="this.reset()">
    <input name="text" />
    <button>添加</button>
  </form>
  <ul id="list">
    <li :for={item <- @items}>{item.text}</li>
  </ul>
  """
end

def create(%{"text" => text}) do
  item = %{id: unique_id(), text: text}
  Nex.Store.update(:items, [], &[item | &1])
  ~H"<li>{item.text}</li>"
end
```

### 删除元素

```elixir
def render(assigns) do
  ~H"""
  <ul>
    <li :for={item <- @items} id={"item-#{item.id}"}>
      {item.text}
      <button hx-post="/delete"
              hx-vals={Jason.encode!(%{id: item.id})}
              hx-target={"#item-#{item.id}"}
              hx-swap="outerHTML">
        删除
      </button>
    </li>
  </ul>
  """
end

def delete(%{"id" => id}) do
  id = String.to_integer(id)
  Nex.Store.update(:items, [], &Enum.reject(&1, fn i -> i.id == id end))
  :empty  # 返回空，元素被删除
end
```

### 更新元素

```elixir
def render(assigns) do
  ~H"""
  <div :for={todo <- @todos} id={"todo-#{todo.id}"}>
    <input type="checkbox"
           checked={todo.completed}
           hx-post="/toggle"
           hx-vals={Jason.encode!(%{id: todo.id})}
           hx-target={"#todo-#{todo.id}"}
           hx-swap="outerHTML" />
    <span>{todo.text}</span>
  </div>
  """
end

def toggle(%{"id" => id}) do
  id = String.to_integer(id)
  Nex.Store.update(:todos, [], fn todos ->
    Enum.map(todos, fn t ->
      if t.id == id, do: %{t | completed: !t.completed}, else: t
    end)
  end)
  todo = Nex.Store.get(:todos, []) |> Enum.find(&(&1.id == id))
  assigns = %{todo: todo}
  ~H"""
  <div id={"todo-#{@todo.id}"}>
    <input type="checkbox"
           checked={@todo.completed}
           hx-post="/toggle"
           hx-vals={Jason.encode!(%{id: @todo.id})}
           hx-target={"#todo-#{@todo.id}"}
           hx-swap="outerHTML" />
    <span class={if @todo.completed, do: "line-through"}>{@todo.text}</span>
  </div>
  """
end
```

### 表单提交

```elixir
def render(assigns) do
  ~H"""
  <form hx-post="/submit" hx-target="#result">
    <input name="email" type="email" required />
    <input name="password" type="password" required />
    <button>登录</button>
  </form>
  <div id="result"></div>
  """
end

def submit(%{"email" => email, "password" => password}) do
  case authenticate(email, password) do
    {:ok, user} ->
      ~H"<div class='text-green-500'>登录成功！</div>"
    {:error, _} ->
      ~H"<div class='text-red-500'>邮箱或密码错误</div>"
  end
end
```

### 搜索

```elixir
def render(assigns) do
  ~H"""
  <input type="search"
         name="q"
         hx-get="/search"
         hx-target="#results"
         hx-trigger="keyup changed delay:300ms"
         placeholder="搜索..." />
  <div id="results"></div>
  """
end

def search(%{"q" => query}) do
  results = search_items(query)
  assigns = %{results: results}
  ~H"""
  <ul>
    <li :for={item <- @results}>{item.name}</li>
  </ul>
  """
end
```

### 无限滚动

```elixir
def render(assigns) do
  ~H"""
  <div id="items">
    <.item :for={item <- @items} item={item} />
  </div>
  <div hx-get="/load-more"
       hx-vals={Jason.encode!(%{page: @page + 1})}
       hx-target="#items"
       hx-swap="beforeend"
       hx-trigger="revealed">
    加载中...
  </div>
  """
end

def load_more(%{"page" => page}) do
  page = String.to_integer(page)
  items = fetch_page(page)
  assigns = %{items: items, page: page}
  ~H"""
  <.item :for={item <- @items} item={item} />
  <div :if={length(@items) > 0}
       hx-get="/load-more"
       hx-vals={Jason.encode!(%{page: @page + 1})}
       hx-target="this"
       hx-swap="outerHTML"
       hx-trigger="revealed">
    加载中...
  </div>
  """
end
```

## 高级属性

### hx-confirm

确认对话框：

```html
<button hx-post="/delete" hx-confirm="确定删除吗？">
  删除
</button>
```

### hx-indicator

加载指示器：

```html
<button hx-post="/submit" hx-indicator="#spinner">
  提交
</button>
<span id="spinner" class="htmx-indicator">加载中...</span>
```

### hx-disabled-elt

禁用元素：

```html
<button hx-post="/submit" hx-disabled-elt="this">
  提交
</button>
```

### hx-on

事件处理：

```html
<form hx-post="/submit" hx-on::after-request="this.reset()">
  ...
</form>
```

## HTMX 响应头

Nex 支持通过返回值设置 HTMX 响应头：

```elixir
# 重定向
def submit(_params) do
  {:redirect, "/dashboard"}
end

# 刷新页面
def submit(_params) do
  {:refresh, nil}
end
```

## 调试

在浏览器控制台启用 HTMX 日志：

```javascript
htmx.logAll()
```

## 更多资源

- [HTMX 官方文档](https://htmx.org/docs/)
- [HTMX 示例](https://htmx.org/examples/)

## 下一步

- [Pages](./pages.md) - 页面模块
- [Store](./store.md) - 状态管理
