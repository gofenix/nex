# Best of Elixir — AI Agent Guide

> For Nex framework conventions, NexBase database patterns, and common pitfalls.

---

## 0. Critical Mistakes to Avoid

These are real errors made during development. **Read this section first.**

### DO NOT create a custom Repo
```elixir
# WRONG — do not create src/repo.ex
defmodule BestofEx.Repo do
  use Ecto.Repo, otp_app: :bestof_ex, adapter: Ecto.Adapters.Postgres
end

# RIGHT — NexBase provides the Repo internally
NexBase.from("projects") |> NexBase.run()
```

### DO NOT create a client object
```elixir
# WRONG — unnecessary indirection
@client NexBase.client()
@client |> NexBase.from("projects") |> NexBase.run()

# RIGHT — call NexBase directly
NexBase.from("projects") |> NexBase.run()
```

### DO NOT expose Repo/config complexity to application code
```elixir
# WRONG — leaks internal details
repo_config = [url: ..., pool_size: 10, ssl: true, ssl_opts: [verify: :verify_none]]
Application.put_env(:nex_base, :repo_config, repo_config)
children = [{NexBase.Repo, []}]

# RIGHT — one-line init, NexBase handles the rest
NexBase.init(url: Nex.Env.get(:database_url), ssl: true)
children = [{NexBase.Repo, []}]
```

### DO NOT use `ssl: true` for cloud databases (Postgrex 0.22+)
```elixir
# WRONG — Postgrex 0.22 will verify certs, Railway/Render self-signed certs fail
ssl: true

# WRONG — deprecated key
ssl_opts: [verify: :verify_none]

# RIGHT — NexBase.init(ssl: true) handles this internally
# It generates: ssl: [verify: :verify_none]
NexBase.init(url: "...", ssl: true)
```

### DO NOT use `config/config.exs`
```elixir
# WRONG — Nex does not use config files
config :bestof_ex, BestofEx.Repo, url: "..."

# RIGHT — use .env files + Nex.Env
# .env
DATABASE_URL=postgresql://...
```

### DO NOT use `for` comprehension inline in HEEx
```elixir
# WRONG — syntax error
<%= for project <- @projects do %>
  <div>{project["name"]}</div>
<% end %>

# RIGHT — use :for directive
<div :for={project <- @projects}>{project["name"]}</div>
```

### DO NOT manually zip SQL columns and rows
```elixir
# WRONG — verbose, error-prone
{:ok, %{rows: rows, columns: columns}} = NexBase.query(sql, params)
Enum.map(rows, fn row -> Enum.zip(columns, row) |> Map.new() end)

# RIGHT — NexBase.sql/2 returns list of maps directly
{:ok, rows} = NexBase.sql("SELECT * FROM projects WHERE id = $1", [id])
```

### DO NOT use `Ecto.Adapters.SQL.query!` in migrations
```elixir
# WRONG — exposes Ecto internals
Ecto.Adapters.SQL.query!(NexBase.Repo, "CREATE TABLE ...", [])

# RIGHT — NexBase wraps it
NexBase.query!("CREATE TABLE ...", [])
```

### DO NOT pass ISO 8601 strings to TIMESTAMP columns
```elixir
# WRONG — Postgrex expects %NaiveDateTime{}, not a string
NexBase.from("projects")
|> NexBase.insert(%{pushed_at: "2025-01-01T00:00:00Z"})
|> NexBase.run()

# RIGHT — parse to NaiveDateTime first
{:ok, dt, _} = DateTime.from_iso8601("2025-01-01T00:00:00Z")
ndt = DateTime.to_naive(dt)
NexBase.from("projects")
|> NexBase.insert(%{pushed_at: ndt})
|> NexBase.run()
```

### DO NOT pass ISO 8601 strings to DATE columns
```elixir
# WRONG — Postgrex expects %Date{}, not a string
NexBase.sql("SELECT ... WHERE recorded_at = $1", [Date.to_iso8601(Date.utc_today())])

# RIGHT — pass %Date{} struct directly
NexBase.sql("SELECT ... WHERE recorded_at = $1", [Date.utc_today()])
```

### DO NOT mix `NexBase.select` (atom keys) with string key access
```elixir
# WRONG — NexBase.select returns atom keys, but accessing with string keys
{:ok, rows} = NexBase.from("projects") |> NexBase.select([:id, :stars]) |> NexBase.run()
hd(rows)["id"]   # => nil (keys are atoms, not strings)

# RIGHT — use NexBase.sql for consistent string keys
{:ok, rows} = NexBase.sql("SELECT id, stars FROM projects")
hd(rows)["id"]   # => 1 ✓

# OR — access with atom keys if using NexBase.select
{:ok, rows} = NexBase.from("projects") |> NexBase.select([:id, :stars]) |> NexBase.run()
hd(rows).id      # => 1 ✓
```

### DO NOT manually add CSRF tags or hx-headers
```elixir
# WRONG — framework handles all of this automatically
<head>{meta_tag()}</head>
<body hx-headers={hx_headers()}>
<form hx-post="/action">
  {csrf_input_tag()}
</form>

# RIGHT — just write the form, framework injects everything
<form hx-post="/action">
  <input name="title" />
  <button type="submit">Save</button>
</form>
```

### DO NOT interpolate user input into SQL strings
```elixir
# WRONG — SQL injection risk!
NexBase.sql("SELECT * FROM projects WHERE name = '#{name}'", [])

# RIGHT — parameterized queries
NexBase.sql("SELECT * FROM projects WHERE name = $1", [name])

# RIGHT — for IN queries, use filter_in/3
NexBase.from("project_tags") |> NexBase.filter_in(:project_id, ids) |> NexBase.run()
```

---

## 1. Project Structure

```
bestof_ex/
  .env                  # DATABASE_URL, POOL_SIZE
  .specs/               # Design specifications
  mix.exs               # deps: nex_core, nex_base
  seeds/import.exs      # Seed data script
  priv/repo/migrations/ # SQL migration scripts
  src/
    application.ex      # App startup (Nex.Env + NexBase.init)
    layouts.ex          # Global HTML layout
    pages/
      index.ex          # Homepage
      trending.ex       # Trending page
      projects/
        index.ex        # All projects
        [id].ex         # Project detail (dynamic route)
      tags/
        index.ex        # All tags
        [slug].ex       # Tag detail (dynamic route)
    components/         # Shared components (3+ page reuse)
```

---

## 2. Application Startup

```elixir
defmodule BestofEx.Application do
  use Application

  @impl true
  def start(_type, _args) do
    Nex.Env.init()
    conn = NexBase.init(url: Nex.Env.get(:database_url), ssl: true)

    children = [{NexBase.Repo, conn}]
    Supervisor.start_link(children, strategy: :one_for_one, name: BestofEx.Supervisor)
  end
end
```

- `Nex.Env.init()` — loads `.env` file
- `NexBase.init/1` — returns a `%NexBase.Conn{}`, pass it to `NexBase.Repo`
- `{NexBase.Repo, conn}` — starts the connection pool

---

## 3. NexBase Database Patterns

### Query Builder (Supabase-style)

```elixir
# Select
{:ok, projects} = NexBase.from("projects")
|> NexBase.order(:stars, :desc)
|> NexBase.limit(10)
|> NexBase.run()

# Insert
NexBase.from("tags")
|> NexBase.insert(%{name: "Web", slug: "web"})
|> NexBase.run()

# Update
NexBase.from("projects")
|> NexBase.eq(:id, 1)
|> NexBase.update(%{stars: 5000})
|> NexBase.run()

# Delete
NexBase.from("projects")
|> NexBase.eq(:id, 1)
|> NexBase.delete()
|> NexBase.run()
```

### Raw SQL (for JOINs and complex queries)

```elixir
# NexBase.sql/2 returns {:ok, [%{"col" => val}]}
{:ok, rows} = NexBase.sql("""
  SELECT t.name, t.slug FROM tags t
  JOIN project_tags pt ON pt.tag_id = t.id
  WHERE pt.project_id = $1
  ORDER BY t.name
""", [project_id])

# NexBase.query!/2 for DDL (returns raw Postgrex result)
NexBase.query!("CREATE TABLE IF NOT EXISTS ...", [])
```

### Scripts (seeds, migrations)

```elixir
# Use start: true to boot the Repo in-process
Nex.Env.init()
NexBase.init(url: Nex.Env.get(:database_url), ssl: true, start: true)

NexBase.from("tags") |> NexBase.insert(%{name: "Web"}) |> NexBase.run()
```

---

## 4. Nex Framework Essentials

### File Routing
- `src/pages/index.ex` → `GET /`
- `src/pages/projects/index.ex` → `GET /projects`
- `src/pages/projects/[id].ex` → `GET /projects/42` (params: `%{"id" => "42"}`)
- `src/pages/tags/[slug].ex` → `GET /tags/web-framework`

### Page Module Pattern

```elixir
defmodule BestofEx.Pages.Index do
  use Nex

  def mount(_params) do
    %{
      title: "Best of Elixir",
      projects: fetch_projects()
    }
  end

  def render(assigns) do
    ~H"""
    <div :for={p <- @projects}>
      <a href={"/projects/#{p["id"]}"}>{p["name"]}</a>
    </div>
    """
  end

  defp fetch_projects do
    case NexBase.from("projects") |> NexBase.order(:stars, :desc) |> NexBase.run() do
      {:ok, rows} -> rows
      _ -> []
    end
  end
end
```

### Page Actions (HTMX)

```elixir
# Public function = callable via hx-post
def search(%{"q" => query}) do
  results = search_projects(query)
  ~H"""
  <div :for={p <- results} id="results">
    {p["name"]}
  </div>
  """
end
```

### Responses
- `~H"..."` — return HTML partial
- `:empty` — no response (204)
- `{:redirect, "/path"}` — redirect
- `{:refresh, nil}` — full page refresh

---

## 5. Layout

The framework automatically injects `<meta name="csrf-token">` and HTMX CSRF headers.
You do **not** need `{meta_tag()}` or `hx-headers={hx_headers()}`.

```elixir
defmodule BestofEx.Layouts do
  use Nex

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html data-theme="bestofex">
    <head>
      <meta charset="utf-8" />
      <script src="https://cdn.tailwindcss.com"></script>
      <link href="https://cdn.jsdelivr.net/npm/daisyui@4/dist/full.min.css" rel="stylesheet" />
      <script src="https://unpkg.com/htmx.org@2"></script>
    </head>
    <body hx-boost="true">
      <nav>...</nav>
      {raw(@inner_content)}
    </body>
    </html>
    """
  end
end
```

- `{raw(@inner_content)}` — renders page content
- `hx-boost="true"` — SPA-like navigation (optional)

---

## 6. Environment

Use `.env` files only. No `config/*.exs`.

```bash
# .env
DATABASE_URL=postgresql://user:pass@host:port/db
POOL_SIZE=10
```

```elixir
Nex.Env.init()                          # Load .env
Nex.Env.get(:database_url)              # "postgresql://..."
Nex.Env.get!(:database_url)             # Raises if missing
Nex.Env.get_integer(:pool_size, 10)     # Parse as integer
```

---

## 7. Built-in Helpers (Nex.Helpers)

Available automatically in all page/component/layout modules:

```elixir
format_number(12_345)    # => "12.3k"
format_number(1_500_000) # => "1.5M"
format_date(~D[2026-01-15])          # => "Jan 15, 2026"
format_date("2026-01-15T10:00:00Z")  # => "Jan 15, 2026"
time_ago(datetime)       # => "3 hours ago", "2 days ago", etc.
```

---

## 8. UI Guidelines

- **DaisyUI first**: Use `.card`, `.badge`, `.btn`, `.table` etc.
- **Tailwind for gaps**: Use raw Tailwind only for spacing, flex, grid.
- **HTMX for interactions**: `hx-get`, `hx-post`, `hx-target`, `hx-trigger`.
- **No JavaScript**: Unless purely local UI state (e.g., dropdown toggle).
- **`:for` directive**: Always use `<div :for={item <- @list}>`, never `<%= for ... %>`.
- **`:if` directive**: Use `<div :if={condition}>` for conditional rendering.

---

## 8. Design Reference

See `.specs/` folder for detailed design specifications:
- `.specs/design.md` — Brand, colors, layout system
- `.specs/pages.md` — Page-by-page wireframes and data
- `.specs/components.md` — Reusable component specs
- `.specs/data.md` — Schema, queries, seed strategy
