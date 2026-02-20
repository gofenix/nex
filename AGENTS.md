# AI Agent Handbook & Principles

## 1. Core Principles

### Principle 1: Changelog First
Every modification to the framework code must be recorded in the changelog to facilitate future framework version releases.
Check the changelog before and after any modification.

### Principle 2: Framework Modification Policy
When creating example projects (in `website/` or `examples/`), if you determine that we need to modify the framework code to support them, please let me know. I will evaluate whether to make those changes.

### Principle 3: Upgrade Verification
When upgrading the framework:
1. Ensure the changelog is actually updated.
2. Ensure the version number is correctly bumped.
3. Ensure the installer code (`installer/`) is updated to reflect the change.

### Principle 4: English Only
All code, comments, documentation, README files, and commit messages **must be in English**.
The only exception is `website/priv/docs/zh/` which holds Chinese translations for the documentation site.

---

## 2. Project Context

### Project Structure
```
nex/
  framework/      # Core package (nex_core) — published to hex.pm
  installer/      # Project generator (nex_new) — published to hex.pm
  nex_base/       # Database query builder (nex_base) — PostgreSQL + SQLite, published to hex.pm (independent version)
  website/        # Official documentation site
  examples/       # Example projects (counter, todos, bestof_ex, etc.)
  scripts/        # Release scripts
```

### Package Versions
- `nex_core` + `nex_new`: Synchronized version via `/VERSION` file. Published together with `./scripts/publish_hex.sh`.
- `nex_base`: Independent version in `nex_base/mix.exs`. Published separately with `./scripts/publish_nex_base.sh`.

### Commit Message Convention
Follow [Conventional Commits](https://www.conventionalcommits.org/):
- **Format**: `<type>(<scope>): <subject>`
- **Strict Rule**: **NO triple backticks (```)** in the commit message.
- Subject: ≤ 50 chars, imperative mood.

### Developer Experience (DX)
- **Zero Boilerplate**: Nex handles CSRF automatically. Do NOT manually add CSRF input tags or headers unless specifically requested.
- **Convention over Configuration**: File paths are routes. Modules use a unified `use Nex` interface.
- **No config files**: Use `.env` + `Nex.Env` instead of `config/*.exs`.

---

## 3. Critical Anti-Patterns

### DO NOT create a custom Repo
```elixir
# WRONG
defmodule MyApp.Repo do
  use Ecto.Repo, otp_app: :my_app, adapter: Ecto.Adapters.Postgres
end

# RIGHT — NexBase provides the Repo internally
NexBase.from("users") |> NexBase.run()
```

### DO NOT create a NexBase client object
```elixir
# WRONG — client pattern was removed in 0.1.1
@client NexBase.client()
@client |> NexBase.from("users") |> NexBase.run()

# RIGHT — call NexBase directly
NexBase.from("users") |> NexBase.run()
```

### DO NOT use `config/config.exs`
```elixir
# WRONG — Nex does not use config files
config :my_app, MyApp.Repo, url: "..."

# RIGHT — use .env files + Nex.Env
# .env
DATABASE_URL=postgresql://...
```

### DO NOT use `for` comprehension inline in HEEx
```elixir
# WRONG — syntax error
<%= for item <- @items do %>
  <div>{item["name"]}</div>
<% end %>

# RIGHT — use :for directive
<div :for={item <- @items}>{item["name"]}</div>
```

### DO NOT manually add CSRF tags, meta_tag, or hx-headers
```elixir
# WRONG — framework handles all of this automatically
<head>{meta_tag()}</head>
<body hx-headers={hx_headers()}>
<form hx-post="/action">
  {csrf_input_tag()}
</form>

# RIGHT — framework auto-injects <meta name="csrf-token"> into </head>
# and HTMX CSRF headers via htmx:configRequest JS listener
<form hx-post="/action">
  ...
</form>
```

### DO NOT manually zip SQL columns and rows
```elixir
# WRONG
{:ok, %{rows: rows, columns: columns}} = NexBase.query(sql, params)
Enum.map(rows, fn row -> Enum.zip(columns, row) |> Map.new() end)

# RIGHT — NexBase.sql/2 returns list of maps directly
{:ok, rows} = NexBase.sql("SELECT * FROM users WHERE id = $1", [id])
```

### DO NOT interpolate user input into SQL strings
```elixir
# WRONG — SQL injection risk!
NexBase.sql("SELECT * FROM users WHERE name = '#{name}'", [])

# RIGHT — always use parameterized queries
NexBase.sql("SELECT * FROM users WHERE name = $1", [name])

# RIGHT — for IN queries, use filter_in/3
NexBase.from("tags") |> NexBase.filter_in(:project_id, ids) |> NexBase.run()
```

### DO NOT pass `{NexBase.Repo, []}` — pass the conn struct
```elixir
# WRONG — [] is not a valid child spec since NexBase 0.3
children = [{NexBase.Repo, []}]

# RIGHT — NexBase.init/1 returns a %NexBase.Conn{}, pass it to NexBase.Repo
conn = NexBase.init(url: Nex.Env.get(:database_url), ssl: true)
children = [{NexBase.Repo, conn}]
```

---

## 4. Release Process

### nex_core + nex_new (synchronized)
1. Update `/VERSION` file.
2. Update `CHANGELOG.md`, `framework/CHANGELOG.md`, `installer/CHANGELOG.md`.
3. Run `./scripts/publish_hex.sh`.

### nex_base (independent)
1. Update version in `nex_base/mix.exs`.
2. Update `CHANGELOG.md` (NexBase section).
3. Run `./scripts/publish_nex_base.sh`.

---

## 5. Example Projects

Dependencies for example projects:
```elixir
# Use path dep for nex_core (monorepo), hex dep for nex_base
defp deps do
  [
    {:nex_core, path: "../../framework"},
    {:nex_base, "~> 0.3"}  # only if project needs database
  ]
end
```

- Do NOT add bandit, jason, plug, etc. — they are transitive deps of nex_core.
- Do NOT add extra_applications for those deps.

### Correct application startup with NexBase
```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    Nex.Env.init()
    conn = NexBase.init(url: Nex.Env.get(:database_url), ssl: true)

    children = [{NexBase.Repo, conn}]
    Supervisor.start_link(children, strategy: :one_for_one, name: MyApp.Supervisor)
  end
end
```

### Correct minimal layout (no meta_tag or hx-headers needed)
```elixir
defmodule MyApp.Layouts do
  use Nex

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8" />
        <title>{@title}</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <script src="https://unpkg.com/htmx.org@2"></script>
      </head>
      <body hx-boost="true">
        {raw(@inner_content)}
      </body>
    </html>
    """
  end
end
```

The framework automatically injects:
- `<meta name="csrf-token">` before `</head>` on every page render
- CSRF header into every HTMX request via injected JS (`htmx:configRequest` listener)

### Built-in helpers (Nex.Helpers)
Available automatically in all page/component/layout modules via `use Nex`:
```elixir
format_number(12_345)        # => "12.3k"
format_date(~D[2026-01-15])  # => "Jan 15, 2026"
time_ago(datetime)           # => "3 hours ago"
truncate("Long text", 10)    # => "Long te..."
pluralize(3, "item", "items") # => "3 items"
clsx(["btn", {"btn-active", true}, {"hidden", false}])  # => "btn btn-active"
```

### Cookie API (Nex.Cookie)
Available as `Cookie` alias in all page/component modules via `use Nex`:
```elixir
# Write (applied to response automatically)
Cookie.put(:theme, "dark", max_age: 86_400, http_only: false)
Cookie.delete(:theme)

# Read (from current request)
Cookie.get(:theme, "light")
Cookie.all()  # => %{"theme" => "dark"}
```

### Session (Nex.Session)
Server-side ETS session, persisted via signed `_nex_session` cookie. Available as `Session` alias:
```elixir
# In mount/1 — read session
def mount(_params) do
  user_id = Session.get(:user_id)
  %{logged_in: user_id != nil}
end

# In action — write session
def login(%{"email" => email}) do
  Session.put(:user_id, 42)
  Nex.redirect("/dashboard")
end

def logout(_params) do
  Session.clear()
  Nex.redirect("/")
end
```

Requires `SECRET_KEY_BASE` env var in production. TTL: 7 days (configurable via `:nex_core, :session_ttl`).

### Flash Messages (Nex.Flash)
One-time messages stored in session, cleared after being read. Available as `Flash` alias:
```elixir
# In action
Flash.put(:info, "Saved successfully!")
Flash.put(:error, "Invalid credentials.")

# In mount/1
def mount(_params) do
  %{flash: Flash.pop_all()}
end

# In template
~H"""
<%= if @flash[:error] do %>
  <div class="alert alert-error">{@flash[:error]}</div>
<% end %>
"""
```

### Middleware (Nex.Middleware)
Plug pipeline that runs before routing. Configure in `application.ex`:
```elixir
Application.put_env(:nex_core, :plugs, [
  MyApp.Plugs.Auth,
  {Nex.RateLimit.Plug, max: 100, window: 60}
])
```

Writing a plug:
```elixir
defmodule MyApp.Plugs.Auth do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if Nex.Session.get(:user_id) do
      conn
    else
      conn |> put_resp_header("location", "/login") |> send_resp(302, "") |> halt()
    end
  end
end
```

### WebSocket (Nex.WebSocket)
Place handler in `src/api/`, use `use Nex.WebSocket`. Routes to `/ws/<path>`:
```elixir
defmodule MyApp.Api.Chat do
  use Nex.WebSocket

  def handle_connect(state) do
    Nex.WebSocket.subscribe("chat")
    {:ok, state}
  end

  def handle_message("ping", state), do: {:reply, "pong", state}
  def handle_message(msg, state) do
    Nex.WebSocket.broadcast("chat", msg)
    {:ok, state}
  end

  def handle_disconnect(state), do: {:ok, state}

  def initial_state(req), do: %{user_id: req.cookies["_nex_session"]}
end
```

Connect from browser: `new WebSocket("ws://localhost:4000/ws/chat")`

### Rate Limiting (Nex.RateLimit)
```elixir
# Standalone check
case Nex.RateLimit.check(ip, max: 10, window: 60) do
  :ok -> Nex.json(%{ok: true})
  {:error, :rate_limited} -> Nex.status(429, "Too Many Requests")
end

# As middleware plug (per-IP, all routes)
Application.put_env(:nex_core, :plugs, [
  {Nex.RateLimit.Plug, max: 100, window: 60}
])
```

### Static Files
Place files in `priv/static/`. They are served at `/static/*` automatically:
- `priv/static/app.css` → `/static/app.css`
- `priv/static/logo.png` → `/static/logo.png`

No configuration needed.

---

## 6. Browser Automation

Use `agent-browser` for web automation. Run `agent-browser --help` for all commands.

Core workflow:
1. `agent-browser open <url>` - Navigate to page
2. `agent-browser snapshot -i` - Get interactive elements with refs (@e1, @e2)
3. `agent-browser click @e1` / `fill @e2 "text"` - Interact using refs
4. Re-snapshot after page changes