# Integration and FAQ

Nex framework focuses on core routing and rendering, maintaining a minimalist design. For full-stack requirements like databases and authentication, you can implement them by integrating standard libraries from the Elixir ecosystem.

## Table of Contents

- [Database Integration (Ecto)](#database-integration-ecto)
- [Authentication and Authorization](#authentication-and-authorization)
- [Adding Custom Middleware (Plug)](#adding-custom-middleware-plug)
- [Writing Tests](#writing-tests)

---

## Database Integration (Ecto)

Nex does not include Ecto by default, but adding it is very simple.

### 1. Add Dependencies

Add `ecto_sql` and a database driver (e.g., `postgrex`) to your `mix.exs`:

```elixir
def deps do
  [
    {:nex_core, "~> 0.2.2"},
    {:ecto_sql, "~> 3.10"},
    {:postgrex, ">= 0.0.0"}
  ]
end
```

### 2. Generate Configuration

```bash
mix ecto.gen.repo -r MyApp.Repo
```

### 3. Start Repo

Add Repo to the supervision tree in `src/application.ex`:

```elixir
def start(_type, _args) do
  children = [
    MyApp.Repo
  ]
  # ...
end
```

Now you can directly call `MyApp.Repo` in Nex Page or Action functions to perform database operations.

---

## Authentication and Authorization

Nex is designed as a minimalist framework. It currently **does not support** built-in cookie-based Session management (`Plug.Session`) and does not expose the `conn` object at the Page/API layer. Therefore, traditional full-stack framework login methods (like `put_session`) are not applicable here.

### Recommended Authentication Schemes

1.  **Stateless Token (JWT)**
    *   Client (e.g., browser localStorage or mobile app) stores the Token.
    *   Pass via Header: `Authorization: Bearer <token>`.
    *   Currently, the framework has not exposed global Plug interceptors, so you need to validate manually within Action/API (or wait for middleware support updates).

2.  **External Gateway Authentication (Recommended)**
    *   Use Nginx / API Gateway / Cloudflare Access for authentication.
    *   After authentication, the gateway passes the User ID to Nex via HTTP Header (e.g., `X-User-Id`).
    *   In Action, read user info via `Nex.Handler` automatically parsed params or headers (note: reading headers currently requires writing your own helper functions, as Action only receives params).

### Why can't I use `conn.assigns`?

Nex's `handle/1` pipeline is fixed, and the function signature for Page/API modules only accepts `params`. This means you cannot inject `current_user` into `conn.assigns` in middleware and read it in business code. All data must be passed via parameters.

---

## Adding Custom Middleware (Plug)

Currently, `Nex.Router` is fixed, and users cannot directly modify the internal Plug pipeline of the framework.

If you need to add global Plugs (e.g., logging, Request ID), direct configuration is currently **not supported**.

However, for API endpoints, you can write your own helper functions (Pipes) within specific API modules to handle common logic.

---

## Writing Tests

Nex projects are standard Elixir projects, and you can use `ExUnit` to write tests.

1.  **Unit Tests**: Test pure function logic.
2.  **Integration Tests**: Since Nex pages are ordinary Elixir modules, you can directly call `render/1` and assert the returned HTML string.

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

For more complex browser integration testing, `Wallaby` is recommended.
