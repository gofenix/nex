# 开发工具

Nex 提供了一套开发工具，让开发体验更加流畅。

## 开发服务器

### 启动服务器

```bash
mix nex.dev
```

输出：

```
🚀 Nex dev server starting...

   App module: MyApp
   URL: http://localhost:4000
   Hot reload: enabled

Press Ctrl+C to stop.
```

### 命令行选项

```bash
# 指定端口
mix nex.dev --port 3000

# 指定主机（允许外部访问）
mix nex.dev --host 0.0.0.0

# 组合使用
mix nex.dev --port 3000 --host 0.0.0.0
```

### 环境变量

也可以通过环境变量配置：

```bash
# .env
PORT=3000
HOST=localhost
```

命令行选项优先于环境变量。

## 热重载

Nex 开发服务器支持热重载，修改 `.ex` 文件后自动重新编译。

### 工作原理

1. 监听 `src/` 和 `lib/` 目录
2. 检测 `.ex` 文件的修改、创建、重命名
3. 自动重新编译变更的文件
4. 通知浏览器刷新页面

### 日志输出

```
[Nex.Reloader] Recompiling: index.ex
[Nex.Reloader] ✓ Reloaded successfully
```

### 编译错误

如果代码有错误，会在终端显示：

```
[Nex.Reloader] Recompiling: index.ex
[Nex.Reloader] ✗ Compile error: ** (CompileError) ...
```

浏览器不会刷新，你可以修复错误后保存，会自动重试。

## Live Reload

修改代码后，浏览器会自动刷新页面。

### 工作原理

1. 页面加载时，注入 Live Reload 脚本
2. 脚本每秒轮询 `/nex/live-reload` 端点
3. 当检测到新的编译时，自动刷新页面

### 禁用 Live Reload

如果不需要自动刷新，可以在浏览器控制台执行：

```javascript
// 禁用 Live Reload
window.__nex_live_reload_disabled = true;
```

## 项目结构

开发时推荐的项目结构：

```
my_app/
├── src/                    # Nex 应用代码
│   ├── pages/
│   ├── api/
│   ├── partials/
│   └── layouts.ex
├── lib/                    # 业务逻辑
│   └── my_app/
├── test/                   # 测试
├── priv/                   # 静态资源
├── mix.exs
├── .env                    # 环境变量
├── .env.dev                # 开发环境变量
└── .gitignore
```

## 调试

### IEx 调试

在代码中添加断点：

```elixir
def create_todo(params) do
  require IEx; IEx.pry()  # 断点
  # ...
end
```

然后使用 `iex -S mix nex.dev` 启动服务器。

### IO.inspect 调试

```elixir
def create_todo(params) do
  params |> IO.inspect(label: "params")
  # ...
end
```

### Logger

```elixir
require Logger

def create_todo(params) do
  Logger.debug("Creating todo: #{inspect(params)}")
  Logger.info("Todo created")
  Logger.warning("Something might be wrong")
  Logger.error("Something went wrong")
  # ...
end
```

## 测试

### 运行测试

```bash
mix test
```

### 测试 Page 模块

```elixir
# test/pages/index_test.exs
defmodule MyApp.Pages.IndexTest do
  use ExUnit.Case

  test "mount returns initial data" do
    assigns = MyApp.Pages.Index.mount(%{})
    assert assigns.title == "Home"
  end
end
```

### 测试 API 模块

```elixir
# test/api/todos_test.exs
defmodule MyApp.Api.Todos.IndexTest do
  use ExUnit.Case

  test "get returns todos" do
    # 设置测试数据
    Nex.Store.set_page_id("test")
    Nex.Store.put(:todos, [%{id: 1, text: "Test"}])

    result = MyApp.Api.Todos.Index.get()
    assert result == %{data: [%{id: 1, text: "Test"}]}
  end
end
```

## 生产部署

### 编译发布

```bash
MIX_ENV=prod mix release
```

### 启动生产服务器

```bash
PORT=80 _build/prod/rel/my_app/bin/my_app start
```

### Docker 部署

```dockerfile
# Dockerfile
FROM elixir:1.18-alpine

WORKDIR /app

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

COPY . .
RUN MIX_ENV=prod mix release

CMD ["_build/prod/rel/my_app/bin/my_app", "start"]
```

## 常见问题

### 端口被占用

```
** (Bandit.TransportError) address already in use
```

解决：使用其他端口或关闭占用端口的进程。

```bash
# 查找占用端口的进程
lsof -i :4000

# 使用其他端口
mix nex.dev --port 3000
```

### 模块未找到

```
** (UndefinedFunctionError) function MyApp.Pages.Index.render/1 is undefined
```

解决：确保模块名与文件路径匹配。

### 热重载不工作

确保：
1. 服务器是用 `mix nex.dev` 启动的
2. 修改的是 `src/` 或 `lib/` 目录下的 `.ex` 文件
3. 文件保存成功

## 下一步

- [快速开始](./getting-started.md) - 创建第一个应用
- [项目结构](./project-structure.md) - 目录组织
