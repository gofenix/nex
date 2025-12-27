# API 参考

本文档列出 Nex 框架所有公开的模块和函数。

## Nex.Page

页面模块宏。

### 使用

```elixir
defmodule MyApp.Pages.Index do
  use Nex.Page
end
```

### 提供的功能

- `~H` sigil — HEEx 模板
- `raw/1` — 插入原始 HTML

### 回调函数

#### mount/1

```elixir
@callback mount(params :: map()) :: map()
```

页面加载时调用，返回初始 assigns。

**参数**：
- `params` — URL 参数和查询参数

**返回**：assigns Map

**可选**：如果不定义，框架使用空 Map。

#### render/1

```elixir
@callback render(assigns :: map()) :: Phoenix.LiveView.Rendered.t()
```

渲染页面内容。

**参数**：
- `assigns` — mount/1 返回的数据

**返回**：HEEx 模板

---

## Nex.Api

API 模块宏。

### 使用

```elixir
defmodule MyApp.Api.Todos.Index do
  use Nex.Api
end
```

### 回调函数

#### get/0, get/1

```elixir
@callback get() :: response()
@callback get(params :: map()) :: response()
```

处理 GET 请求。

#### post/1

```elixir
@callback post(params :: map()) :: response()
```

处理 POST 请求。

#### put/1

```elixir
@callback put(params :: map()) :: response()
```

处理 PUT 请求。

#### delete/0, delete/1

```elixir
@callback delete() :: response()
@callback delete(params :: map()) :: response()
```

处理 DELETE 请求。

### 返回值类型

```elixir
@type response ::
  map()                           # 200 + JSON
  | {status :: integer(), map()}  # 自定义状态码 + JSON
  | {:error, status :: integer(), message :: String.t()}  # 错误响应
  | :empty                        # 204 No Content
```

---

## Nex.Partial

组件模块宏。

### 使用

```elixir
defmodule MyApp.Partials.Button do
  use Nex.Partial
end
```

### 提供的功能

- `~H` sigil — HEEx 模板

---

## Nex.Store

页面级状态管理。

### Nex.Store.get/2

```elixir
@spec get(key :: atom(), default :: any()) :: any()
```

获取状态值。

**参数**：
- `key` — 状态键
- `default` — 默认值（可选，默认 nil）

**返回**：状态值或默认值

**示例**：

```elixir
todos = Nex.Store.get(:todos, [])
count = Nex.Store.get(:count, 0)
```

### Nex.Store.put/2

```elixir
@spec put(key :: atom(), value :: any()) :: any()
```

设置状态值。

**参数**：
- `key` — 状态键
- `value` — 状态值

**返回**：设置的值

**示例**：

```elixir
Nex.Store.put(:todos, [todo | todos])
Nex.Store.put(:count, 10)
```

### Nex.Store.update/3

```elixir
@spec update(key :: atom(), default :: any(), fun :: (any() -> any())) :: any()
```

使用函数更新状态值。

**参数**：
- `key` — 状态键
- `default` — 如果键不存在时的默认值
- `fun` — 更新函数

**返回**：更新后的值

**示例**：

```elixir
Nex.Store.update(:count, 0, &(&1 + 1))
Nex.Store.update(:todos, [], &[todo | &1])
```

### Nex.Store.delete/1

```elixir
@spec delete(key :: atom()) :: :ok
```

删除状态值。

**参数**：
- `key` — 状态键

**返回**：`:ok`

**示例**：

```elixir
Nex.Store.delete(:todos)
```

---

## Nex.Env

环境变量管理。

### Nex.Env.get/2

```elixir
@spec get(key :: atom() | String.t(), default :: String.t() | nil) :: String.t() | nil
```

获取环境变量字符串值。

**参数**：
- `key` — 环境变量名
- `default` — 默认值（可选）

**返回**：字符串值或默认值

**示例**：

```elixir
port = Nex.Env.get(:PORT, "4000")
host = Nex.Env.get(:HOST, "localhost")
```

### Nex.Env.get!/1

```elixir
@spec get!(key :: atom() | String.t()) :: String.t()
```

获取必需的环境变量，不存在则抛出异常。

**参数**：
- `key` — 环境变量名

**返回**：字符串值

**异常**：如果变量不存在

**示例**：

```elixir
secret = Nex.Env.get!(:SECRET_KEY)
```

### Nex.Env.get_integer/2

```elixir
@spec get_integer(key :: atom() | String.t(), default :: integer()) :: integer()
```

获取整数环境变量。

**参数**：
- `key` — 环境变量名
- `default` — 默认值

**返回**：整数值

**示例**：

```elixir
port = Nex.Env.get_integer(:PORT, 4000)
```

### Nex.Env.get_boolean/2

```elixir
@spec get_boolean(key :: atom() | String.t(), default :: boolean()) :: boolean()
```

获取布尔环境变量。

**参数**：
- `key` — 环境变量名
- `default` — 默认值

**返回**：布尔值

**真值**：`"true"`, `"1"`, `"yes"`, `"on"`

**示例**：

```elixir
debug = Nex.Env.get_boolean(:DEBUG, false)
```

---

## Mix Tasks

### mix nex.dev

启动开发服务器。

```bash
mix nex.dev [options]
```

**选项**：
- `--port PORT` — 监听端口（默认 4000）
- `--host HOST` — 绑定主机（默认 localhost）

**示例**：

```bash
mix nex.dev
mix nex.dev --port 3000
mix nex.dev --host 0.0.0.0 --port 8080
```

---

## Action 返回值

Page action 函数的返回值：

| 返回值 | HTTP 响应 |
|-------|----------|
| `~H"<div>...</div>"` | 200 + HTML |
| `:empty` | 200 + 空响应 |
| `{:redirect, path}` | HX-Redirect 头 |
| `{:refresh, _}` | HX-Refresh 头 |

---

## API 返回值

API 函数的返回值：

| 返回值 | HTTP 响应 |
|-------|----------|
| `%{data: ...}` | 200 + JSON |
| `{201, %{data: ...}}` | 201 + JSON |
| `{:error, 400, "msg"}` | 400 + `{"error": "msg"}` |
| `:empty` | 204 No Content |
