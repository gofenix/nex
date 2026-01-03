# 路由系统

Nex 的路由系统秉承“文件即路由”的原则，让你能够通过目录结构直观地组织应用 URL。

## 1. 静态路由

最简单的路由形式是直接映射。

*   `src/pages/index.ex` → `/`
*   `src/pages/about.ex` → `/about`
*   `src/pages/contact/index.ex` → `/contact`
*   `src/pages/blog/list.ex` → `/blog/list`

## 2. 动态路由 `[id]`

当你需要在 URL 中捕获参数时，使用方括号语法命名文件。

*   `src/pages/users/[id].ex` → `/users/123` (params: `id="123"`)
*   `src/pages/posts/[slug].ex` → `/posts/hello-nex` (params: `slug="hello-nex"`)

在代码中获取参数：
```elixir
defmodule MyApp.Pages.Users.Id do
  use Nex
  
  def mount(%{"id" => id}) do
    # id 将会是 "123"
    %{user: find_user(id)}
  end
end
```

## 3. 全匹配路由 `[...path]`

如果你需要捕获剩余的所有路径片段，使用 `[...name]` 语法。

*   `src/pages/docs/[...path].ex` → `/docs/intro/getting-started` (params: `path=["intro", "getting-started"]`)

## 4. 参数优先级

当存在多个来源的同名参数时，Nex 遵循以下优先级（前者覆盖后者）：

1.  **路径参数 (Path Params)**：如 `/users/[id]` 中的 `id`。
2.  **查询参数 (Query Params)**：如 `/search?q=nex` 中的 `q`。

## 5. 路由匹配规则

当一个 URL 匹配多个可能的路由文件时，Nex 按以下优先级排序：

1.  **完全静态匹配** 优先于 **动态参数匹配**。
2.  **动态参数较少** 的优先。
3.  **非全匹配 (catch-all)** 优先于 **全匹配**。
4.  **路径更长** 的优先。

示例：访问 `/users/new`
*   如果有 `src/pages/users/new.ex`，它将优先于 `src/pages/users/[id].ex`。
