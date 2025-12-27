# Nex Framework 开发工作流

本文档定义 Nex 框架的项目组织结构和开发工作流。

## 1. 项目组织（Monorepo）

```
nex/
├── framework/                  # 框架核心
│   ├── lib/
│   │   ├── nex/
│   │   │   ├── router.ex
│   │   │   ├── handler.ex
│   │   │   ├── state.ex
│   │   │   ├── env.ex
│   │   │   ├── view.ex
│   │   │   ├── api.ex
│   │   │   └── partial.ex
│   │   ├── mix/
│   │   │   └── tasks/
│   │   │       ├── nex.dev.ex      # mix nex.dev
│   │   │       ├── nex.build.ex    # mix nex.build
│   │   │       └── nex.new.ex      # mix nex.new
│   │   └── nex.ex
│   ├── mix.exs
│   ├── mix.lock
│   └── README.md
├── examples/                   # 示例项目
│   ├── todos/
│   │   ├── src/
│   │   │   ├── pages/
│   │   │   ├── api/
│   │   │   └── partials/
│   │   ├── priv/static/
│   │   ├── layouts.ex
│   │   ├── mix.exs
│   │   └── .env
│   └── blog/
│       ├── src/
│       ├── mix.exs
│       └── .env
├── specs/                      # 设计文档
│   ├── 000-intro.md
│   ├── 001-tech.md
│   └── 002-dev-workflow.md
└── README.md
```

### 1.1 为什么选择 Monorepo？

| 优势 | 说明 |
|-----|------|
| **开发便捷** | 框架和示例在同一仓库，修改即时生效 |
| **版本一致** | 示例始终使用最新框架代码 |
| **独立发布** | `framework/` 可单独发布到 hex.pm |
| **CI/CD 简化** | 一次 CI 运行覆盖框架和所有示例 |

### 1.2 目录职责

| 目录 | 职责 |
|-----|------|
| `framework/` | Nex 框架核心代码，发布到 hex.pm |
| `examples/` | 示例项目，用于验证框架功能 |
| `specs/` | 设计文档和技术规范 |

---

## 2. 依赖配置

### 2.1 示例项目依赖框架（开发时）

`examples/todos/mix.exs`:

```elixir
defmodule Todos.MixProject do
  use Mix.Project

  def project do
    [
      app: :todos,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Todos.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # 开发时使用本地路径依赖
      {:nex, path: "../../framework"}
    ]
  end
end
```

### 2.2 用户项目依赖框架（发布后）

用户创建的项目 `mix.exs`:

```elixir
defp deps do
  [
    # 从 hex.pm 安装
    {:nex, "~> 0.1.0"}
  ]
end
```

### 2.3 依赖原理

| 依赖类型 | 来源 | 适用场景 |
|---------|------|---------|
| `path: "../../framework"` | 本地文件系统 | 框架开发时 |
| `"~> 0.1.0"` | hex.pm | 用户项目 |
| `github: "user/nex"` | GitHub | 未发布时的用户项目 |

**关键点**：
- `path:` 依赖在每次 `mix compile` 时自动检测变化
- 无需手动重新编译依赖
- 修改框架代码后，示例项目立即生效

---

## 3. Mix Tasks

### 3.1 `mix nex.dev` — 开发服务器

```elixir
# framework/lib/mix/tasks/nex.dev.ex
defmodule Mix.Tasks.Nex.Dev do
  @moduledoc """
  启动 Nex 开发服务器。

  ## 用法

      mix nex.dev

  ## 选项

      --port PORT    指定端口，默认 4000
      --host HOST    指定主机，默认 localhost
  """

  use Mix.Task

  @shortdoc "Start Nex development server with hot reload"

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, 
      switches: [port: :integer, host: :string]
    )

    # 确保依赖已编译
    Mix.Task.run("compile")

    # 加载环境变量
    Nex.Env.init()

    # 启动应用
    Mix.Task.run("app.start")

    port = opts[:port] || Nex.Env.get_integer(:PORT, 4000)
    host = opts[:host] || Nex.Env.get(:HOST, "localhost")

    IO.puts("""
    
    🚀 Nex dev server running at http://#{host}:#{port}
    
    Press Ctrl+C to stop.
    """)

    # 启动文件监听（热重载）
    start_watcher()

    # 保持进程运行
    Process.sleep(:infinity)
  end

  defp start_watcher do
    {:ok, watcher_pid} = FileSystem.start_link(dirs: ["src/", "lib/"])
    FileSystem.subscribe(watcher_pid)
    spawn(fn -> watch_loop() end)
  end

  defp watch_loop do
    receive do
      {:file_event, _watcher, {path, _events}} ->
        if String.ends_with?(path, ".ex") do
          IO.puts("📦 Recompiling: #{Path.basename(path)}")
          IEx.Helpers.recompile()
        end
        watch_loop()
    end
  end
end
```

### 3.2 `mix nex.new` — 创建新项目

```elixir
# framework/lib/mix/tasks/nex.new.ex
defmodule Mix.Tasks.Nex.New do
  @moduledoc """
  创建新的 Nex 项目。

  ## 用法

      mix nex.new my_app

  ## 选项

      --path PATH    指定创建路径
  """

  use Mix.Task

  @shortdoc "Create a new Nex project"

  def run([name | _] = args) when is_binary(name) do
    {opts, _, _} = OptionParser.parse(args, switches: [path: :string])
    
    path = opts[:path] || name
    app_module = Macro.camelize(name)

    IO.puts("Creating Nex project #{name}...")

    # 创建目录结构
    create_directory(path)
    create_directory("#{path}/src/pages")
    create_directory("#{path}/src/api")
    create_directory("#{path}/src/partials")
    create_directory("#{path}/priv/static")

    # 生成文件
    create_file("#{path}/mix.exs", mix_template(name, app_module))
    create_file("#{path}/.env", env_template())
    create_file("#{path}/layouts.ex", layouts_template(app_module))
    create_file("#{path}/src/pages/index.ex", index_page_template(app_module))
    create_file("#{path}/.gitignore", gitignore_template())
    create_file("#{path}/README.md", readme_template(name))

    IO.puts("""

    ✅ Project created successfully!

    Next steps:

        cd #{path}
        mix deps.get
        mix nex.dev

    Then open http://localhost:4000 in your browser.
    """)
  end

  def run(_) do
    IO.puts("Usage: mix nex.new <project_name>")
  end

  defp create_directory(path) do
    File.mkdir_p!(path)
  end

  defp create_file(path, content) do
    File.write!(path, content)
    IO.puts("  Created #{path}")
  end

  defp mix_template(name, app_module) do
    """
    defmodule #{app_module}.MixProject do
      use Mix.Project

      def project do
        [
          app: :#{name},
          version: "0.1.0",
          elixir: "~> 1.15",
          start_permanent: Mix.env() == :prod,
          deps: deps()
        ]
      end

      def application do
        [
          mod: {#{app_module}.Application, []},
          extra_applications: [:logger]
        ]
      end

      defp deps do
        [
          {:nex, "~> 0.1.0"}
        ]
      end
    end
    """
  end

  defp env_template do
    """
    # Application
    PORT=4000
    HOST=localhost

    # Database (optional)
    # DATABASE_URL=postgresql://user:pass@localhost/my_app
    """
  end

  defp layouts_template(app_module) do
    """
    defmodule #{app_module}.Layouts do
      use Nex.View

      def render(assigns) do
        ~H\"\"\"
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <title>{@title}</title>
            <script src="https://cdn.tailwindcss.com"></script>
            <script src="https://unpkg.com/htmx.org@1.9.10"></script>
          </head>
          <body class="bg-gray-100 min-h-screen">
            {@inner_content}
          </body>
        </html>
        \"\"\"
      end
    end
    """
  end

  defp index_page_template(app_module) do
    """
    defmodule #{app_module}.Pages.Index do
      use Nex.View

      def mount(_conn, _params) do
        %{
          title: "Welcome to Nex"
        }
      end

      def render(assigns) do
        ~H\"\"\"
        <div class="container mx-auto px-4 py-16 text-center">
          <h1 class="text-4xl font-bold text-gray-800 mb-4">
            Welcome to Nex
          </h1>
          <p class="text-gray-600 mb-8">
            A minimalist Elixir web framework powered by HTMX.
          </p>
          <a href="https://github.com/user/nex" 
             class="bg-blue-500 text-white px-6 py-3 rounded-lg hover:bg-blue-600">
            Get Started
          </a>
        </div>
        \"\"\"
      end
    end
    """
  end

  defp gitignore_template do
    """
    # Dependencies
    /deps/
    /_build/

    # Environment
    .env.local
    .env.*.local

    # IDE
    .elixir_ls/
    .vscode/
    *.beam

    # OS
    .DS_Store
    """
  end

  defp readme_template(name) do
    """
    # #{Macro.camelize(name)}

    A Nex application.

    ## Development

    ```bash
    mix deps.get
    mix nex.dev
    ```

    Open http://localhost:4000

    ## Production

    ```bash
    MIX_ENV=prod mix nex.build
    ```
    """
  end
end
```

### 3.3 `mix nex.build` — 生产构建

```elixir
# framework/lib/mix/tasks/nex.build.ex
defmodule Mix.Tasks.Nex.Build do
  @moduledoc """
  构建生产版本。

  ## 用法

      MIX_ENV=prod mix nex.build
  """

  use Mix.Task

  @shortdoc "Build for production"

  def run(_args) do
    IO.puts("Building for production...")

    # 编译
    Mix.Task.run("compile")

    # 生成 release
    Mix.Task.run("release")

    IO.puts("""

    ✅ Build complete!

    Run with:

        _build/prod/rel/#{Mix.Project.config()[:app]}/bin/#{Mix.Project.config()[:app]} start
    """)
  end
end
```

---

## 4. 开发工作流

### 4.1 框架开发流程

```
1. 修改 framework/lib/nex/*.ex
2. cd examples/todos
3. mix nex.dev（自动重编译框架）
4. 浏览器测试
5. 重复
```

### 4.2 示例项目开发流程

```
1. cd examples/todos
2. mix nex.dev
3. 修改 src/pages/*.ex 或 src/partials/*.ex
4. 热重载自动生效
5. 浏览器测试
```

### 4.3 发布流程

```
1. 更新 framework/mix.exs 版本号
2. cd framework
3. mix hex.publish
4. 用户项目更新依赖版本
```

---

## 5. Mix Task 发现机制

### 5.1 原理

当用户运行 `mix nex.dev`：

```
1. Mix 加载当前项目 mix.exs
2. 解析 deps，发现 {:nex, ...}
3. 编译 nex 依赖（包括 lib/mix/tasks/*.ex）
4. 扫描所有 Mix.Tasks.* 模块
5. 发现 Mix.Tasks.Nex.Dev
6. 调用 Mix.Tasks.Nex.Dev.run/1
```

### 5.2 关键点

| 问题 | 答案 |
|-----|------|
| Task 从哪来？ | 依赖编译时自动发现 |
| 需要全局安装吗？ | 不需要，通过项目依赖 |
| 如何更新？ | 更新依赖版本即可 |

### 5.3 命名约定

```elixir
# 文件路径
lib/mix/tasks/nex.dev.ex

# 模块名
Mix.Tasks.Nex.Dev

# 命令
mix nex.dev
```

模块名中的 `.` 对应命令中的 `.`：
- `Mix.Tasks.Nex.Dev` → `mix nex.dev`
- `Mix.Tasks.Nex.New` → `mix nex.new`
- `Mix.Tasks.Nex.Build` → `mix nex.build`

---

## 6. 热重载实现

### 6.1 文件监听

```elixir
defmodule Nex.Reloader do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    dirs = ["src/", "lib/"]
    {:ok, watcher} = FileSystem.start_link(dirs: dirs)
    FileSystem.subscribe(watcher)
    {:ok, %{watcher: watcher}}
  end

  def handle_info({:file_event, _watcher, {path, events}}, state) do
    if should_reload?(path, events) do
      reload_module(path)
    end
    {:noreply, state}
  end

  defp should_reload?(path, events) do
    String.ends_with?(path, ".ex") and
      Enum.any?(events, &(&1 in [:modified, :created]))
  end

  defp reload_module(path) do
    IO.puts("\n📦 Reloading: #{Path.basename(path)}")
    
    try do
      Code.compile_file(path)
      IO.puts("✅ Reloaded successfully")
    rescue
      e ->
        IO.puts("❌ Compile error: #{inspect(e)}")
    end
  end
end
```

### 6.2 浏览器自动刷新（可选）

通过 Server-Sent Events (SSE) 通知浏览器：

```elixir
# 在 Layout 中添加
<script>
  const evtSource = new EventSource("/nex/live-reload");
  evtSource.onmessage = () => window.location.reload();
</script>
```

```elixir
# Nex.Router 中添加
get "/nex/live-reload" do
  conn
  |> put_resp_header("content-type", "text/event-stream")
  |> put_resp_header("cache-control", "no-cache")
  |> send_chunked(200)
  |> live_reload_loop()
end
```

---

## 7. 测试策略

### 7.1 框架测试

```
framework/
└── test/
    ├── nex/
    │   ├── router_test.exs
    │   ├── handler_test.exs
    │   └── state_test.exs
    └── test_helper.exs
```

```bash
cd framework
mix test
```

### 7.2 示例项目测试

```
examples/todos/
└── test/
    ├── pages/
    │   └── index_test.exs
    ├── api/
    │   └── todos_test.exs
    └── test_helper.exs
```

```bash
cd examples/todos
mix test
```

### 7.3 集成测试

在 CI 中运行所有示例项目的测试：

```yaml
# .github/workflows/ci.yml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.15'
          otp-version: '26'
      
      - name: Test framework
        run: |
          cd framework
          mix deps.get
          mix test
      
      - name: Test examples
        run: |
          for dir in examples/*/; do
            cd "$dir"
            mix deps.get
            mix test
            cd ../..
          done
```

---

## 8. 常见问题

### Q: 修改框架后示例没有更新？

```bash
cd examples/todos
mix deps.compile nex --force
```

### Q: 如何调试框架代码？

```bash
cd examples/todos
iex -S mix nex.dev
```

然后在 IEx 中：
```elixir
iex> Nex.Router.routes()
iex> Nex.State.get_assigns("session_id")
```

### Q: 如何发布到 hex.pm？

```bash
cd framework
mix hex.publish
```

首次发布需要：
```bash
mix hex.user register
mix hex.user auth
```

---

## 下一步

- `003-router.md` — 路由编译器详细实现
- `004-state.md` — 状态管理深入设计
