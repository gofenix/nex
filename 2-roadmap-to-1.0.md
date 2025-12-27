# Nex 框架 1.0 路线图：技术方案与任务拆解

**基于 José Valim 技术评审的系统性改进计划**

---

## 一、战略概述

### 1.1 核心目标

将 Nex 从 **0.1.0 (原型)** 推进到 **1.0.0 (生产就绪)**，需要解决：

| 维度 | 现状 | 1.0 目标 |
|------|------|----------|
| 架构 | Handler 665行单体 | 模块化、职责单一 |
| 性能 | 运行时路由解析 | 编译时路由表 |
| 安全 | 基础防护 | CSRF + 认证钩子 |
| 可靠性 | 开发体验优先 | 生产环境加固 |
| 可测试性 | 无测试工具 | 完整测试套件 |

### 1.2 版本里程碑

```
v0.1.0 (当前)
    │
    ▼
v0.2.0 ──── 架构重构 (Handler拆分 + Store优化)
    │
    ▼
v0.3.0 ──── 路由系统升级 (编译时 + 动态参数)
    │
    ▼
v0.4.0 ──── 安全加固 (CSRF + 认证钩子)
    │
    ▼
v0.5.0 ──── 生产就绪 (环境隔离 + 错误处理)
    │
    ▼
v0.6.0 ──── 开发者体验 (类型规范 + 测试工具)
    │
    ▼
v1.0.0 ──── 正式发布 (文档 + 稳定API)
```

### 1.3 向后兼容性承诺

- **0.x 系列**：允许 Breaking Changes，但需在 CHANGELOG 中明确说明
- **1.0.0 后**：遵循 SemVer，主版本内保持向后兼容

---

## 二、任务依赖关系图

```
                    ┌─────────────────────────────────┐
                    │  T1: Handler 拆分               │
                    │  (所有后续工作的基础)            │
                    └────────────┬────────────────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
          ▼                      ▼                      ▼
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│ T2: Store 优化   │   │ T3: 路由重构    │   │ T4: SSE 增强    │
│ (独立，无依赖)   │   │ (依赖T1)        │   │ (依赖T1)        │
└────────┬────────┘   └────────┬────────┘   └────────┬────────┘
         │                     │                     │
         │            ┌────────┴────────┐            │
         │            ▼                 ▼            │
         │   ┌─────────────┐   ┌─────────────┐      │
         │   │ T5: 动态路由 │   │ T6: 路由缓存│      │
         │   │ [param]支持 │   │ 编译时生成  │      │
         │   └──────┬──────┘   └──────┬──────┘      │
         │          │                 │              │
         │          └────────┬────────┘              │
         │                   ▼                       │
         │          ┌─────────────────┐              │
         │          │ T7: CSRF 防护   │              │
         │          │ (依赖路由系统)  │              │
         │          └────────┬────────┘              │
         │                   │                       │
         └───────────────────┼───────────────────────┘
                             ▼
                    ┌─────────────────┐
                    │ T8: 认证钩子    │
                    │ (依赖T7)        │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ T9: 生产加固    │
                    │ (环境隔离)      │
                    └────────┬────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
          ▼                  ▼                  ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ T10: 类型规范   │ │ T11: 测试工具   │ │ T12: 文档完善   │
│ (可并行)        │ │ (可并行)        │ │ (可并行)        │
└─────────────────┘ └─────────────────┘ └─────────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │    v1.0.0       │
                    └─────────────────┘
```

---

## 三、详细任务拆解

---

### T1: Handler 模块拆分 [v0.2.0]

**目标**：将 665 行的 `Nex.Handler` 拆分为职责单一的子模块

**影响范围**：核心架构，所有请求处理

**预估工时**：3-4 天

#### 子任务

| ID | 任务 | 描述 | 预估 | 验收标准 |
|----|------|------|------|----------|
| T1.1 | 创建 `Nex.Handler.Page` | 提取页面渲染逻辑 (L268-L379) | 4h | 页面路由正常工作 |
| T1.2 | 创建 `Nex.Handler.Api` | 提取 API 处理逻辑 (L99-L267) | 3h | API 路由正常工作 |
| T1.3 | 创建 `Nex.Handler.SSE` | 提取 SSE 流处理 (L78-L237) | 3h | SSE 端点正常工作 |
| T1.4 | 创建 `Nex.Handler.Error` | 提取错误处理 (L572-L637) | 2h | 错误页面正常显示 |
| T1.5 | 创建 `Nex.Handler.Resolver` | 提取路由解析 (L433-L556) | 3h | 模块解析正常 |
| T1.6 | 重构 `Nex.Handler` 为调度器 | 仅保留入口分发逻辑 | 2h | 所有示例正常运行 |
| T1.7 | 添加模块间集成测试 | 确保拆分后行为一致 | 3h | 测试覆盖率 > 80% |

#### 目标文件结构

```
framework/lib/nex/handler/
├── handler.ex          # 入口调度器 (~50行)
├── page.ex             # 页面处理 (~120行)
├── api.ex              # API处理 (~100行)
├── sse.ex              # SSE处理 (~150行)
├── error.ex            # 错误处理 (~80行)
└── resolver.ex         # 路由解析 (~130行)
```

#### 实施方案

```elixir
# 新的 Nex.Handler (精简后)
defmodule Nex.Handler do
  alias Nex.Handler.{Page, Api, SSE, Error, Resolver}
  
  def handle(conn) do
    conn = register_before_send(conn, &cleanup/1)
    
    try do
      route(conn)
    rescue
      e -> Error.handle_exception(conn, e, __STACKTRACE__)
    end
  end
  
  defp route(conn) do
    case Resolver.classify(conn) do
      :live_reload_ws -> handle_live_reload_ws(conn)
      :live_reload -> handle_live_reload(conn)
      {:api, path} -> Api.handle(conn, path)
      {:sse, path} -> SSE.handle(conn, path)
      {:page, path} -> Page.handle(conn, path)
    end
  end
end
```

#### 迁移策略

1. 创建新模块，复制代码
2. 修改 `Nex.Handler` 调用新模块
3. 运行所有示例验证
4. 删除旧代码

---

### T2: Store 性能优化 [v0.2.0]

**目标**：将 `touch_page` 从 O(n) 优化为 O(1)

**影响范围**：状态管理性能

**预估工时**：1-2 天

#### 子任务

| ID | 任务 | 描述 | 预估 | 验收标准 |
|----|------|------|------|----------|
| T2.1 | 设计新的元数据存储结构 | `{:meta, page_id}` 存储最后访问时间 | 2h | 设计文档 |
| T2.2 | 重构 `touch_page` | O(1) 元数据更新 | 2h | 基准测试通过 |
| T2.3 | 重构 `cleanup_expired` | 基于元数据清理 | 2h | 清理逻辑正确 |
| T2.4 | 增加 page_id 长度 | 12字节 → 16字节 | 1h | 安全审计通过 |
| T2.5 | 添加性能基准测试 | 对比优化前后 | 2h | 性能提升 > 10x |

#### 实施方案

```elixir
# 优化后的 touch_page
defp touch_page(page_id) do
  # O(1) 操作：只更新元数据
  :ets.insert(@table, {{:meta, page_id}, System.system_time(:millisecond)})
end

# 优化后的清理逻辑
defp cleanup_expired do
  now = System.system_time(:millisecond)
  cutoff = now - @default_ttl
  
  # 1. 找出过期的页面
  expired_pages = 
    :ets.select(@table, [
      {{{:meta, :"$1"}, :"$2"}, [{:<, :"$2", cutoff}], [:"$1"]}
    ])
  
  # 2. 删除这些页面的所有数据
  Enum.each(expired_pages, fn page_id ->
    :ets.match_delete(@table, {{page_id, :_}, :_, :_})
    :ets.delete(@table, {:meta, page_id})
  end)
end

# 增强的 page_id 生成
def generate_page_id do
  :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
end
```

---

### T3: 路由系统重构 [v0.3.0]

**目标**：支持 `[param]` 文件名约定，提升路由灵活性

**影响范围**：路由解析，用户代码组织方式

**预估工时**：3-4 天

#### 子任务

| ID | 任务 | 描述 | 预估 | 验收标准 |
|----|------|------|------|----------|
| T3.1 | 设计动态路由语法 | `[id].ex`, `[...slug].ex` | 3h | RFC 文档 |
| T3.2 | 实现文件名解析器 | 解析 `[param]` 模式 | 4h | 单元测试通过 |
| T3.3 | 重构 `path_to_module_parts` | 支持新语法 | 4h | 集成测试通过 |
| T3.4 | 更新示例项目 | 使用新的动态路由 | 2h | 示例正常运行 |
| T3.5 | 支持多参数路由 | `/users/[id]/posts/[post_id]` | 4h | 复杂路由工作 |

#### 实施方案

```elixir
# 文件结构约定
# src/pages/users/[id].ex          → GET /users/:id
# src/pages/users/[id]/posts.ex    → GET /users/:id/posts
# src/pages/posts/[...slug].ex     → GET /posts/* (catch-all)

# 路由解析器
defmodule Nex.Handler.Resolver do
  @doc """
  解析文件名中的动态参数
  
  Examples:
    "[id].ex" → {:param, "id"}
    "[...slug].ex" → {:catch_all, "slug"}
    "index.ex" → {:static, "index"}
  """
  def parse_filename(filename) do
    cond do
      String.match?(filename, ~r/^\[\.\.\.(\w+)\]\.ex$/) ->
        [_, param] = Regex.run(~r/^\[\.\.\.(\w+)\]\.ex$/, filename)
        {:catch_all, param}
      
      String.match?(filename, ~r/^\[(\w+)\]\.ex$/) ->
        [_, param] = Regex.run(~r/^\[(\w+)\]\.ex$/, filename)
        {:param, param}
      
      true ->
        {:static, Path.rootname(filename)}
    end
  end
end
```

---

### T4: SSE 增强 [v0.3.0]

**目标**：增加心跳机制，完善错误处理

**影响范围**：SSE 连接稳定性

**预估工时**：1-2 天

#### 子任务

| ID | 任务 | 描述 | 预估 | 验收标准 |
|----|------|------|------|----------|
| T4.1 | 实现心跳机制 | 每30秒发送 `:ping` | 3h | 长连接不超时 |
| T4.2 | 增强错误处理 | 捕获所有异常，通知客户端 | 2h | 优雅降级 |
| T4.3 | 添加连接状态回调 | `on_connect`, `on_disconnect` | 3h | 生命周期可观测 |
| T4.4 | 支持重连机制 | 客户端断线重连 | 2h | 自动恢复 |

#### 实施方案

```elixir
defmodule Nex.Handler.SSE do
  @heartbeat_interval :timer.seconds(30)
  
  def send_sse_stream(conn, module, params) do
    # 启动心跳进程
    heartbeat_ref = schedule_heartbeat()
    
    try do
      if function_exported?(module, :stream, 2) do
        apply(module, :stream, [params, &send_event(conn, &1)])
      end
      :ok
    rescue
      e ->
        send_event(conn, %{event: "error", data: Exception.message(e)})
        :error
    catch
      :closed -> :ok
    after
      cancel_heartbeat(heartbeat_ref)
    end
  end
  
  defp schedule_heartbeat do
    Process.send_after(self(), :heartbeat, @heartbeat_interval)
  end
  
  defp handle_heartbeat(conn) do
    case chunk(conn, ": heartbeat\n\n") do
      {:ok, conn} -> 
        schedule_heartbeat()
        conn
      {:error, _} -> 
        throw(:closed)
    end
  end
end
```

---

### T5: 编译时路由表 [v0.3.0]

**目标**：消除运行时模块解析开销

**影响范围**：请求处理性能

**预估工时**：4-5 天

#### 子任务

| ID | 任务 | 描述 | 预估 | 验收标准 |
|----|------|------|------|----------|
| T5.1 | 设计路由表数据结构 | 支持静态+动态路由 | 4h | 设计文档 |
| T5.2 | 实现编译时路由收集 | Mix 编译器扩展 | 6h | 自动生成路由 |
| T5.3 | 实现路由匹配算法 | 支持优先级排序 | 4h | O(log n) 匹配 |
| T5.4 | 集成到 Handler | 替换运行时解析 | 3h | 性能测试通过 |
| T5.5 | 开发模式热更新 | 路由表动态刷新 | 4h | 热重载工作 |

#### 实施方案

```elixir
# 编译时生成的路由表
defmodule Nex.Routes do
  @moduledoc """
  编译时生成的路由表，避免运行时模块解析开销
  """
  
  # 编译时收集所有路由
  @routes [
    # 静态路由 (优先级高)
    %{pattern: [], module: MyApp.Pages.Index, params: []},
    %{pattern: ["about"], module: MyApp.Pages.About, params: []},
    
    # 动态路由
    %{pattern: ["users", :id], module: MyApp.Pages.Users.Id, params: [:id]},
    %{pattern: ["posts", :id, "comments"], module: MyApp.Pages.Posts.Id.Comments, params: [:id]},
  ]
  
  def match(path) do
    Enum.find_value(@routes, :error, fn route ->
      case match_pattern(path, route.pattern, %{}) do
        {:ok, params} -> {:ok, route.module, params}
        :error -> nil
      end
    end)
  end
  
  defp match_pattern([], [], params), do: {:ok, params}
  defp match_pattern([seg | path], [seg | pattern], params), 
    do: match_pattern(path, pattern, params)
  defp match_pattern([value | path], [param | pattern], params) when is_atom(param),
    do: match_pattern(path, pattern, Map.put(params, Atom.to_string(param), value))
  defp match_pattern(_, _, _), do: :error
end

# Mix 编译器扩展
defmodule Mix.Tasks.Compile.NexRoutes do
  use Mix.Task.Compiler
  
  def run(_args) do
    routes = scan_src_directory()
    generate_routes_module(routes)
    {:ok, []}
  end
  
  defp scan_src_directory do
    Path.wildcard("src/**/*.ex")
    |> Enum.map(&parse_route_from_path/1)
    |> Enum.reject(&is_nil/1)
  end
end
```

---

### T6: CSRF 防护 [v0.4.0]

**目标**：提供可选的 CSRF 防护机制

**影响范围**：表单安全

**预估工时**：2-3 天

#### 子任务

| ID | 任务 | 描述 | 预估 | 验收标准 |
|----|------|------|------|----------|
| T6.1 | 实现 Token 生成/验证 | 基于 page_id 的 HMAC | 3h | 安全审计通过 |
| T6.2 | 创建 HEEx 组件 | `<.csrf_token />` | 2h | 模板可用 |
| T6.3 | 实现 Plug 中间件 | 自动验证 POST 请求 | 3h | 拦截无效请求 |
| T6.4 | 添加配置选项 | `config :nex, csrf: true` | 2h | 可开关 |
| T6.5 | HTMX 集成 | 自动注入 header | 2h | HTMX 请求通过 |

#### 实施方案

```elixir
# CSRF Token 管理
defmodule Nex.CSRF do
  @secret_key Application.compile_env(:nex, :secret_key_base, :crypto.strong_rand_bytes(32))
  
  def generate_token(page_id) do
    :crypto.mac(:hmac, :sha256, @secret_key, page_id)
    |> Base.url_encode64(padding: false)
  end
  
  def valid_token?(page_id, token) do
    expected = generate_token(page_id)
    Plug.Crypto.secure_compare(expected, token)
  end
end

# Plug 中间件
defmodule Nex.Plug.CSRF do
  import Plug.Conn
  
  def init(opts), do: opts
  
  def call(conn, _opts) do
    if conn.method in ["POST", "PUT", "PATCH", "DELETE"] do
      verify_csrf(conn)
    else
      conn
    end
  end
  
  defp verify_csrf(conn) do
    page_id = get_req_header(conn, "x-nex-page-id") |> List.first()
    token = get_req_header(conn, "x-csrf-token") |> List.first() ||
            conn.params["_csrf_token"]
    
    if Nex.CSRF.valid_token?(page_id, token) do
      conn
    else
      conn
      |> send_resp(403, "Invalid CSRF token")
      |> halt()
    end
  end
end

# HEEx 组件
defmodule Nex.Components do
  use Phoenix.Component
  
  def csrf_token(assigns) do
    token = Nex.CSRF.generate_token(assigns._page_id)
    ~H"""
    <input type="hidden" name="_csrf_token" value={@token} />
    """
  end
end

# 自动注入到 HTMX
# 在 page_id_script 中添加:
"""
document.body.addEventListener('htmx:configRequest', function(evt) {
  evt.detail.headers['X-Nex-Page-Id'] = document.body.dataset.pageId;
  evt.detail.headers['X-CSRF-Token'] = document.body.dataset.csrfToken;
});
"""
```

---

### T7: 认证钩子 [v0.4.0]

**目标**：提供可扩展的认证/授权机制

**影响范围**：API 和页面安全

**预估工时**：2-3 天

#### 子任务

| ID | 任务 | 描述 | 预估 | 验收标准 |
|----|------|------|------|----------|
| T7.1 | 设计钩子接口 | `before_action`, `authorize` | 3h | API 设计文档 |
| T7.2 | 实现 Page 钩子 | 页面级权限控制 | 3h | 拦截未授权访问 |
| T7.3 | 实现 API 钩子 | API 级权限控制 | 3h | 拦截未授权请求 |
| T7.4 | 添加示例认证模块 | JWT/Session 示例 | 2h | 文档完整 |

#### 实施方案

```elixir
# 钩子行为定义
defmodule Nex.Auth do
  @callback authenticate(Plug.Conn.t()) :: {:ok, map()} | {:error, String.t()}
  @callback authorize(Plug.Conn.t(), atom(), map()) :: :ok | {:error, String.t()}
  
  defmacro __using__(_opts) do
    quote do
      @behaviour Nex.Auth
      
      # 默认实现
      def authorize(_conn, _action, _user), do: :ok
      
      defoverridable authorize: 3
    end
  end
end

# 在 Page 模块中使用
defmodule MyApp.Pages.Admin do
  use Nex.Page
  use Nex.Auth
  
  # 认证钩子
  def authenticate(conn) do
    case get_session(conn, :user_id) do
      nil -> {:error, "Please login"}
      user_id -> {:ok, %{id: user_id}}
    end
  end
  
  # 授权钩子
  def authorize(_conn, _action, user) do
    if user.role == :admin, do: :ok, else: {:error, "Admin only"}
  end
  
  def render(assigns) do
    ~H"<h1>Admin Panel</h1>"
  end
end
```

---

### T8: 生产环境加固 [v0.5.0]

**目标**：确保生产环境安全可靠

**影响范围**：部署和运行时行为

**预估工时**：2 天

#### 子任务

| ID | 任务 | 描述 | 预估 | 验收标准 |
|----|------|------|------|----------|
| T8.1 | 环境感知热重载 | 生产环境禁用 | 2h | 生产无热重载 |
| T8.2 | 环境感知错误页面 | 生产隐藏堆栈 | 2h | 无敏感信息泄露 |
| T8.3 | 添加 Telemetry 事件 | 请求/错误指标 | 4h | 可观测性 |
| T8.4 | 优化日志级别 | 生产减少日志 | 2h | 日志精简 |

#### 实施方案

```elixir
# 环境感知的 Reloader
defmodule Nex.Reloader do
  def init(_opts) do
    if Application.get_env(:nex, :env, :dev) == :dev do
      {:ok, watcher_pid} = FileSystem.start_link(dirs: @watch_dirs)
      FileSystem.subscribe(watcher_pid)
      {:ok, %{watcher: watcher_pid, last_reload: 0}}
    else
      # 生产环境：不启动文件监听
      :ignore
    end
  end
end

# 环境感知的错误页面
defp send_error_page(conn, status, message, error) do
  error_detail = 
    if error && Application.get_env(:nex, :env, :dev) == :dev do
      "<pre>#{html_escape(inspect(error, pretty: true))}</pre>"
    else
      ""
    end
  # ...
end

# Telemetry 事件
defmodule Nex.Telemetry do
  def emit_request_start(conn) do
    :telemetry.execute(
      [:nex, :request, :start],
      %{system_time: System.system_time()},
      %{conn: conn}
    )
  end
  
  def emit_request_stop(conn, duration) do
    :telemetry.execute(
      [:nex, :request, :stop],
      %{duration: duration},
      %{conn: conn, status: conn.status}
    )
  end
end
```

---

### T9: 类型规范 [v0.6.0]

**目标**：添加完整的 `@spec` 定义

**影响范围**：代码可维护性，Dialyzer 支持

**预估工时**：2 天

#### 子任务

| ID | 任务 | 描述 | 预估 | 验收标准 |
|----|------|------|------|----------|
| T9.1 | 定义核心类型 | `@type` 定义 | 2h | 类型文件 |
| T9.2 | Handler 模块规范 | 所有公开函数 | 3h | Dialyzer 通过 |
| T9.3 | Store 模块规范 | 所有公开函数 | 2h | Dialyzer 通过 |
| T9.4 | 其他模块规范 | 剩余公开函数 | 3h | Dialyzer 通过 |
| T9.5 | CI 集成 Dialyzer | GitHub Actions | 2h | 自动检查 |

#### 实施方案

```elixir
defmodule Nex.Types do
  @type page_id :: String.t()
  @type params :: %{optional(String.t()) => any()}
  @type route_result :: {:ok, module(), params()} | :error
  @type action_result :: :empty | {:redirect, String.t()} | Phoenix.LiveView.Rendered.t()
  @type api_result :: map() | {integer(), map()} | {:error, integer(), String.t()} | :empty
end

defmodule Nex.Store do
  @spec generate_page_id() :: Nex.Types.page_id()
  def generate_page_id do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end
  
  @spec get(atom(), any()) :: any()
  def get(key, default \\ nil) do
    # ...
  end
  
  @spec put(atom(), any()) :: any()
  def put(key, value) do
    # ...
  end
end
```

---

### T10: 测试工具 [v0.6.0]

**目标**：提供类似 `Phoenix.ConnTest` 的测试辅助

**影响范围**：用户测试体验

**预估工时**：3-4 天

#### 子任务

| ID | 任务 | 描述 | 预估 | 验收标准 |
|----|------|------|------|----------|
| T10.1 | 创建 `Nex.Test` 模块 | 测试辅助函数 | 4h | API 可用 |
| T10.2 | 实现 `get/post/put/delete` | HTTP 请求模拟 | 4h | 请求模拟工作 |
| T10.3 | 实现断言辅助 | `assert_html`, `assert_json` | 3h | 断言可用 |
| T10.4 | 实现 Store 隔离 | 测试间状态隔离 | 3h | 无状态污染 |
| T10.5 | 添加示例测试 | 所有示例项目 | 4h | 测试通过 |

#### 实施方案

```elixir
defmodule Nex.Test do
  @moduledoc """
  测试辅助模块，提供类似 Phoenix.ConnTest 的体验
  """
  
  import ExUnit.Assertions
  import Plug.Conn
  import Plug.Test
  
  @doc "创建测试连接"
  def conn(method, path, params \\ %{}) do
    conn(method, path)
    |> Map.put(:params, params)
    |> put_req_header("x-nex-page-id", Nex.Store.generate_page_id())
  end
  
  @doc "发送 GET 请求"
  def get(conn, path) do
    conn(:get, path)
    |> Nex.Router.call([])
  end
  
  @doc "发送 POST 请求"
  def post(conn, path, params \\ %{}) do
    conn(:post, path, params)
    |> Nex.Router.call([])
  end
  
  @doc "断言 HTML 包含文本"
  def assert_html(conn, text) do
    assert conn.resp_body =~ text
    conn
  end
  
  @doc "断言 JSON 响应"
  def assert_json(conn, expected) do
    actual = Jason.decode!(conn.resp_body)
    assert actual == expected
    conn
  end
  
  @doc "断言重定向"
  def assert_redirect(conn, to) do
    assert get_resp_header(conn, "hx-redirect") == [to]
    conn
  end
end

# 使用示例
defmodule Todos.Pages.IndexTest do
  use ExUnit.Case
  import Nex.Test
  
  test "renders todo list" do
    conn = get(conn(), "/")
    
    assert conn.status == 200
    assert_html(conn, "Todo List")
  end
  
  test "creates todo" do
    conn = post(conn(), "/create_todo", %{"text" => "Buy milk"})
    
    assert conn.status == 200
    assert_html(conn, "Buy milk")
  end
end
```

---

### T11: 文档完善 [v1.0.0]

**目标**：提供完整的用户文档

**影响范围**：用户上手体验

**预估工时**：3-4 天

#### 子任务

| ID | 任务 | 描述 | 预估 | 验收标准 |
|----|------|------|------|----------|
| T11.1 | 快速入门指南 | 5分钟上手 | 3h | 新用户可跟随 |
| T11.2 | 核心概念文档 | Pages/API/SSE/Store | 4h | 概念清晰 |
| T11.3 | API 参考文档 | ExDoc 生成 | 3h | 所有公开API |
| T11.4 | 迁移指南 | 0.x → 1.0 | 2h | 迁移路径清晰 |
| T11.5 | 部署指南 | Fly.io/Railway | 3h | 可部署 |
| T11.6 | 示例项目文档 | 每个示例说明 | 2h | 示例可运行 |

---

## 四、版本发布计划

### v0.2.0 - 架构重构

**目标日期**：+2 周

**包含任务**：T1, T2

**Breaking Changes**：
- 内部模块结构变化（用户代码不受影响）

**发布检查清单**：
- [ ] Handler 拆分完成
- [ ] Store 优化完成
- [ ] 所有示例正常运行
- [ ] 基准测试对比
- [ ] CHANGELOG 更新

---

### v0.3.0 - 路由升级

**目标日期**：+4 周

**包含任务**：T3, T4, T5

**Breaking Changes**：
- 动态路由语法变化（可选迁移）

**发布检查清单**：
- [ ] `[param]` 路由工作
- [ ] 编译时路由表生成
- [ ] SSE 心跳机制
- [ ] 热重载正常
- [ ] CHANGELOG 更新

---

### v0.4.0 - 安全加固

**目标日期**：+6 周

**包含任务**：T6, T7

**Breaking Changes**：
- 无（CSRF 可选启用）

**发布检查清单**：
- [ ] CSRF 防护可用
- [ ] 认证钩子可用
- [ ] 安全审计通过
- [ ] CHANGELOG 更新

---

### v0.5.0 - 生产就绪

**目标日期**：+7 周

**包含任务**：T8

**Breaking Changes**：
- 生产环境行为变化（更安全）

**发布检查清单**：
- [ ] 生产环境热重载禁用
- [ ] 错误页面隐藏敏感信息
- [ ] Telemetry 事件可用
- [ ] CHANGELOG 更新

---

### v0.6.0 - 开发者体验

**目标日期**：+9 周

**包含任务**：T9, T10

**Breaking Changes**：
- 无

**发布检查清单**：
- [ ] Dialyzer 通过
- [ ] 测试工具可用
- [ ] 示例项目测试通过
- [ ] CHANGELOG 更新

---

### v1.0.0 - 正式发布

**目标日期**：+11 周

**包含任务**：T11

**发布检查清单**：
- [ ] 文档完整
- [ ] API 稳定
- [ ] 所有已知问题修复
- [ ] 发布博客文章
- [ ] Hex.pm 发布

---

## 五、风险评估与缓解

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|------|----------|
| Handler 拆分引入 bug | 高 | 中 | 完整的集成测试 |
| 编译时路由影响热重载 | 中 | 高 | 开发模式保留运行时解析 |
| CSRF 破坏现有 HTMX 流程 | 高 | 低 | 默认禁用，渐进启用 |
| 性能优化不明显 | 低 | 中 | 先建立基准，持续测量 |
| 文档工作量超预期 | 中 | 高 | 优先核心文档，迭代完善 |

---

## 六、成功标准

### 技术指标

- [ ] 代码行数：Handler < 100 行
- [ ] 性能：路由解析 < 1μs
- [ ] 安全：通过 OWASP 基础检查
- [ ] 质量：Dialyzer 零警告
- [ ] 测试：覆盖率 > 80%

### 用户体验指标

- [ ] 新用户 5 分钟内完成 Hello World
- [ ] 示例项目可一键运行
- [ ] 文档无死链
- [ ] 生产部署指南可执行

### 社区指标

- [ ] Hex.pm 发布
- [ ] GitHub Stars > 100
- [ ] 至少 3 个外部贡献者

---

## 七、下一步行动

### 立即开始 (本周)

1. **T1.1**: 创建 `Nex.Handler.Page` 模块
2. **T2.1**: 设计 Store 元数据结构
3. 建立基准测试框架

### 下周

1. **T1.2-T1.4**: 完成 Handler 拆分
2. **T2.2-T2.3**: 完成 Store 优化
3. **T1.7**: 添加集成测试

### 两周内

1. **T1.5-T1.6**: Handler 调度器重构
2. 发布 **v0.2.0**

---

**文档版本**: 1.0  
**最后更新**: 2024年12月  
**维护者**: Nex Core Team
