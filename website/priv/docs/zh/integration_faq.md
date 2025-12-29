# 集成与常见问题 FAQ

Nex 框架专注于核心的路由和渲染，保持了极简的设计。对于数据库、认证等全栈需求，你可以通过集成 Elixir 生态中的标准库来实现。

## 目录

- [数据库集成 (Ecto)](#数据库集成-ecto)
- [认证与授权 (Authentication)](#认证与授权)
- [添加自定义中间件 (Plug)](#添加自定义中间件-plug)
- [编写测试](#编写测试)

---

## 数据库集成 (Ecto)

Nex 默认不包含 Ecto，但添加它非常简单。

### 1. 添加依赖

在 `mix.exs` 中添加 `ecto_sql` 和数据库驱动（例如 `postgrex`）：

```elixir
def deps do
  [
    {:nex_core, "~> 0.2.2"},
    {:ecto_sql, "~> 3.10"},
    {:postgrex, ">= 0.0.0"}
  ]
end
```

### 2. 生成配置

```bash
mix ecto.gen.repo -r MyApp.Repo
```

### 3. 启动 Repo

在 `src/application.ex` 的监督树中加入 Repo：

```elixir
def start(_type, _args) do
  children = [
    MyApp.Repo
  ]
  # ...
end
```

现在你可以在 Nex 的 Page 或 Action 函数中直接调用 `MyApp.Repo` 进行数据库操作。

---

## 认证与授权

Nex 设计为极简框架，目前**不内置**基于 Cookie 的 Session 管理（`Plug.Session`），也没有在 Page/API 层暴露 `conn` 对象。因此，传统的全栈框架登录方式（`put_session`）在这里不适用。

### 推荐的认证方案

1.  **无状态 Token (JWT)**
    *   客户端（如浏览器 localStorage 或移动端）保存 Token。
    *   通过 Header 传递：`Authorization: Bearer <token>`。
    *   目前框架尚未开放全局 Plug 拦截器，你需要在 Action/API 内部自行校验（或等待框架更新中间件支持）。

2.  **外部网关认证 (推荐)**
    *   使用 Nginx / API Gateway / Cloudflare Access 处理鉴权。
    *   认证通过后，网关将 User ID 通过 HTTP Header（如 `X-User-Id`）传给 Nex。
    *   Nex 在 Action 中通过 `Nex.Handler` 自动解析的 params 或 headers 读取用户信息（目前 header 读取需自行封装辅助函数，因为 Action 接收的是 params）。

### 为什么不能用 `conn.assigns`？

Nex 的 `handle/1` 管道是固定的，并且 Page/API 模块的函数签名仅接收 `params`。这意味着你无法在中间件中把 `current_user` 注入到 `conn.assigns` 并在业务代码中读取。一切数据必须通过参数传递。

---

## 添加自定义中间件 (Plug)

目前 `Nex.Router` 是固定的，用户无法直接修改框架内部的 Plug 管道。

如果你需要添加全局 Plug（例如日志、Request ID），目前**不支持**直接配置。

但是，对于 API 端点，你可以在具体的 API 模块中自行编写辅助函数（Pipe）来处理公共逻辑。

---

## 编写测试

Nex 项目是标准的 Elixir 项目，你可以使用 `ExUnit` 编写测试。

1.  **单元测试**: 测试纯函数逻辑。
2.  **集成测试**: 由于 Nex 页面是普通的 Elixir 模块，你可以直接调用 `render/1` 并断言返回的 HTML 字符串。

```elixir
defmodule MyApp.Pages.IndexTest do
  use ExUnit.Case
  alias MyApp.Pages.Index

  test "renders correctly" do
    html = Index.render(%{message: "Hello"}) |> Phoenix.HTML.Safe.to_iodata() |> to_string()
    assert html =~ "Hello"
  end
end
```

对于更复杂的浏览器集成测试，推荐使用 `Wallaby`。
