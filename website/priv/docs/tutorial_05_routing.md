# Routing System

Nex's routing system follows the principle of "file-as-router," allowing you to organize your application URLs intuitively through directory structure.

## 1. Static Routes

The simplest form of routing is direct mapping.

*   `src/pages/index.ex` -> `/`
*   `src/pages/about.ex` -> `/about`
*   `src/pages/contact/index.ex` -> `/contact`
*   `src/pages/blog/list.ex` -> `/blog/list`

## 2. Dynamic Routes `[id]`

When you need to capture parameters in a URL, use the square bracket syntax for filenames.

*   `src/pages/users/[id].ex` -> `/users/123` (params: `id="123"`)
*   `src/pages/posts/[slug].ex` -> `/posts/hello-nex` (params: `slug="hello-nex"`)

Accessing parameters in code:
```elixir
defmodule MyApp.Pages.Users.Id do
  use Nex
  
  def mount(%{"id" => id}) do
    # id will be "123"
    %{user: find_user(id)}
  end
end
```

## 3. Catch-All Routes `[...path]`

If you need to capture all remaining path segments, use the `[...name]` syntax.

*   `src/pages/docs/[...path].ex` -> `/docs/intro/getting-started` (params: `path=["intro", "getting-started"]`)

## 4. Parameter Priority

When multiple sources have parameters with the same name, Nex follows this priority (former overrides latter):

1.  **Path Parameters**: e.g., `id` in `/users/[id]`.
2.  **Query Parameters**: e.g., `q` in `/search?q=nex`.

## 5. Route Matching Rules

When a URL matches multiple possible route files, Nex sorts them by priority:

1.  **Exact Static Match** over **Dynamic Parameter Match**.
2.  **Fewer Dynamic Parameters** first.
3.  **Non-Catch-All** over **Catch-All**.
4.  **Longer Path** first.

Example: Visiting `/users/new`
*   If `src/pages/users/new.ex` exists, it will take priority over `src/pages/users/[id].ex`.
