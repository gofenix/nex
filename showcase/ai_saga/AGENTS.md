# AI Saga — Nex Agent Guide

> Nex is a minimalist Elixir web framework. Folder structure = router. No config files. No asset pipeline. CDN-first.

---

## 0. Critical Anti-Patterns (Read First)

### DO NOT create a router file
```elixir
# WRONG — router.ex does not exist in Nex
# RIGHT — create src/pages/papers.ex and it becomes /papers automatically
```

### DO NOT use config/*.exs
```elixir
# WRONG
config :ai_saga, key: "value"
# RIGHT — use .env + Nex.Env
Nex.Env.get(:key)
```

### DO NOT use <%= for/if %> in HEEx templates
```elixir
# WRONG — syntax error
<%= for paper <- @papers do %>
  <div>{paper["title"]}</div>
<% end %>

# RIGHT — use :for directive
<div :for={paper <- @papers}>{paper["title"]}</div>
<div :if={condition}>...</div>
```

### DO NOT manually add CSRF tokens or hx-headers
```elixir
# WRONG — framework handles this automatically
<head>{meta_tag()}</head>
<body hx-headers={hx_headers()}>
<form hx-post="/save">{csrf_input_tag()}</form>

# RIGHT — just write the form, framework injects everything
<form hx-post="/save">
  <input name="title" />
  <button type="submit">Save</button>
</form>
```

### DO NOT use mix run --no-halt
```bash
# WRONG
mix run --no-halt
# RIGHT
mix nex.dev       # development
mix nex.start     # production
```

### DO NOT create a custom Repo
```elixir
# WRONG
defmodule AiSaga.Repo do
  use Ecto.Repo, otp_app: :ai_saga, adapter: Ecto.Adapters.Postgres
end

# RIGHT — NexBase provides the Repo internally
NexBase.from("aisaga_papers") |> NexBase.run()
```

### DO NOT manually zip SQL columns and rows
```elixir
# WRONG
{:ok, %{rows: rows, columns: cols}} = NexBase.query(sql, [])
Enum.map(rows, fn row -> Enum.zip(cols, row) |> Map.new() end)

# RIGHT — NexBase.sql/2 returns list of maps directly
{:ok, rows} = NexBase.sql("SELECT * FROM aisaga_papers WHERE id = $1", [id])
```

### DO NOT interpolate user input into SQL strings
```elixir
# WRONG — SQL injection risk!
NexBase.sql("SELECT * FROM aisaga_papers WHERE title LIKE '%#{query}%'", [])

# RIGHT — parameterized queries
NexBase.sql("SELECT * FROM aisaga_papers WHERE title ILIKE $1", ["%#{query}%"])

# RIGHT — for IN queries, use filter_in/3
NexBase.from("aisaga_papers") |> NexBase.filter_in(:id, ids) |> NexBase.run()
```

### CRITICAL: This project uses PostgreSQL (Supabase), NOT SQLite
- Always check `.env` for `DATABASE_URL` to confirm
- Never assume SQLite based on `data/` directory presence

---

## 1. Project Structure

```
ai_saga/
  src/
    application.ex      # App startup (Nex.Env + NexBase.init)
    layouts.ex          # HTML layout
    scheduler.ex        # Background GenServer (periodic tasks)
    pages/              # File = route
    api/                # API endpoints
    components/         # Shared components (3+ page reuse)
  priv/repo/migrations/ # SQL DDL scripts
  .env                  # DATABASE_URL, OPENAI_API_KEY, etc.
  mix.exs
```

---

## 2. Application Startup

```elixir
defmodule AiSaga.Application do
  use Application

  @impl true
  def start(_type, _args) do
    Nex.Env.init()
    conn = NexBase.init(url: Nex.Env.get(:database_url), ssl: true)

    children = [
      {NexBase.Repo, conn},
      AiSaga.Scheduler
    ]
    Supervisor.start_link(children, strategy: :one_for_one, name: AiSaga.Supervisor)
  end
end
```

---

## 3. Layout (Minimal)

The framework automatically injects `<meta name="csrf-token">` and HTMX CSRF headers.
You do **not** need `{meta_tag()}` or `hx-headers={hx_headers()}`.

```elixir
defmodule AiSaga.Layouts do
  use Nex

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="zh-CN">
      <head>
        <meta charset="UTF-8" />
        <title>{@title} - AiSaga</title>
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

---

## 4. Page Module Pattern

```elixir
defmodule AiSaga.Pages.Index do
  use Nex

  def mount(_params) do
    %{
      title: "AI Saga",
      papers: fetch_recent_papers()
    }
  end

  def render(assigns) do
    ~H"""
    <div :for={paper <- @papers}>{paper["title"]}</div>
    <div :if={@papers == []}>No papers yet.</div>
    """
  end

  defp fetch_recent_papers do
    case NexBase.from("aisaga_papers") |> NexBase.order(:created_at, :desc) |> NexBase.limit(20) |> NexBase.run() do
      {:ok, rows} -> rows
      _ -> []
    end
  end
end
```

### File → Route mapping
| File | Route |
|------|-------|
| `src/pages/index.ex` | `GET /` |
| `src/pages/paper/index.ex` | `GET /paper` |
| `src/pages/paper/[slug].ex` | `GET /paper/attention-is-all-you-need` |
| `src/pages/author/[slug].ex` | `GET /author/hinton` |

---

## 5. API Module Pattern

```elixir
defmodule AiSaga.Api.GeneratePaper do
  use Nex

  def post(req) do
    arxiv_id = req.body["arxiv_id"]
    Nex.html(generate_and_render(arxiv_id))
  end
end
```

### API responses
- `Nex.json(map)` — JSON response
- `Nex.html("<div>...</div>")` — HTML fragment (for HTMX)
- `Nex.stream(fn send -> ... end)` — SSE streaming

---

## 6. NexBase Database Patterns

### Query Builder
```elixir
# SELECT with filters
{:ok, papers} = NexBase.from("aisaga_papers")
  |> NexBase.eq(:paradigm, "transformer")
  |> NexBase.order(:year, :desc)
  |> NexBase.limit(10)
  |> NexBase.run()

# Duplicate check before insert
case NexBase.from("aisaga_papers") |> NexBase.eq(:arxiv_id, arxiv_id) |> NexBase.single() |> NexBase.run() do
  {:ok, [_existing]} -> {:error, "Paper already exists"}
  _ -> proceed_with_insert()
end
```

### Raw SQL (for JOINs and complex queries)
```elixir
# Returns {:ok, [%{"col" => val}]} — always string keys
{:ok, rows} = NexBase.sql("""
  SELECT p.title, p.year, a.name as author_name
  FROM aisaga_papers p
  JOIN aisaga_paper_authors pa ON pa.paper_id = p.id
  JOIN aisaga_authors a ON a.id = pa.author_id
  WHERE p.id = $1
""", [paper_id])
```

### Scripts (seeds, migrations)
```elixir
# At top of script file
Nex.Env.init()
NexBase.init(url: Nex.Env.get(:database_url), ssl: true, start: true)

NexBase.query!("CREATE TABLE IF NOT EXISTS aisaga_papers (...)", [])
```

---

## 7. Built-in Helpers (Nex.Helpers)

Available automatically in all page/component/layout modules:

```elixir
format_number(12_345)    # => "12.3k"
format_date(~D[2026-01-15])          # => "Jan 15, 2026"
format_date("2017-06-12T00:00:00Z")  # => "Jun 12, 2017"
time_ago(datetime)       # => "3 hours ago", "2 days ago", etc.
```

---

## 8. SSE Streaming

```elixir
# API handler
def get(_req) do
  Nex.stream(fn send ->
    send.("Fetching paper...")
    send.(%{event: "chunk", data: "Processing..."})
    send.(%{event: "done", data: "success"})
  end)
end
```

```javascript
// Client — use native EventSource, NOT HTMX SSE extension
// HTMX SSE has auto-reconnect issues causing infinite loops
var es = new EventSource('/api/stream');
var done = false;

es.onmessage = function(e) { appendMessage(e.data); };

es.addEventListener('done', function(e) {
  if (!done) { done = true; es.close(); updateUI(e.data); }
});

es.onerror = function() {
  if (!done) { done = true; es.close(); showError(); }
};
```

**Always send `done` event in all code paths:**
```elixir
# Success
send.(%{event: "done", data: "success"})
# Error
send.(%{event: "done", data: "error"})
```

---

## 9. Environment

```bash
# .env
DATABASE_URL=postgresql://user:pass@host:5432/db
OPENAI_API_KEY=sk-...
```

```elixir
Nex.Env.init()                    # load .env (call in Application.start/2)
Nex.Env.get(:database_url)        # => "postgresql://..."
Nex.Env.get!(:openai_api_key)     # raises if missing
```

---

## 10. Commands

```bash
mix nex.dev      # start development server (hot reload)
mix nex.start    # start production server
mix format       # format code
```

---

## 11. Browser Automation

Use `agent-browser` for validation. Run `agent-browser --help` for all commands.

```bash
agent-browser open http://localhost:4000   # navigate
agent-browser snapshot -i                  # get interactive elements with refs
agent-browser click @e1                    # click by ref
agent-browser fill @e2 "text"              # fill input by ref
```

---

## 12. Project-Specific Lessons Learned

### Database & Data Integrity

**CRITICAL: Always verify database configuration first**
- This project uses **PostgreSQL (Supabase)**, NOT SQLite
- Check `.env` file for `DATABASE_URL` to confirm database type
- `NexBase` supports both PostgreSQL and SQLite, but project configuration determines which is used
- Never assume database type based on dependency presence in `deps/`

**Duplicate Data Prevention**
- Always add uniqueness constraints at database level AND application level
- For `papers` table: check `arxiv_id` uniqueness before insert
- Example check in `save_paper`:
  ```elixir
  case NexBase.from("aisaga_papers") |> NexBase.eq(:arxiv_id, arxiv_id) |> NexBase.single() |> NexBase.run() do
    {:ok, [existing]} -> {:error, "Paper already exists"}
    _ -> # proceed with insert
  end
  ```

**Data Cleanup Scripts**
- When writing cleanup scripts, always:
  1. Query to find duplicates first
  2. Show what will be deleted
  3. Delete duplicates keeping oldest record (MIN(id))
  4. Verify deletion count matches expectation
- Use title-based deduplication when `arxiv_id` may be NULL

### SSE & Real-time Features

**Native EventSource vs HTMX SSE**
- Use native JavaScript `EventSource` API, NOT HTMX SSE extension
- HTMX SSE has auto-reconnect issues causing infinite loops
- Always close EventSource connection on `done` event
- Use `hasError` flag to prevent duplicate close/error handling

**SSE Event Flow**
```javascript
var eventSource = new EventSource('/api/stream');
var hasError = false;

eventSource.onmessage = function(e) { /* append message */ };

eventSource.addEventListener('done', function(e) {
  if (!hasError) {
    hasError = true;
    eventSource.close();
    // update UI based on e.data (success/error)
  }
});

eventSource.onerror = function() {
  if (!hasError) {
    hasError = true;
    eventSource.close();
    // show error UI
  }
};
```

### AI Prompt Design

**Unified Prompts > Conditional Prompts**
- Don't split prompts into separate functions based on conditions
- Instead, build one unified prompt that adapts based on available data
- Example: Show HuggingFace candidates if available, otherwise show classic paper guidance
- Let AI see all context and make decisions, don't pre-filter too aggressively

**Prompt Priority Logic**
- Clearly state priority in prompt: "优先从X推荐，如果X为空则从Y推荐"
- Provide fallback options within same prompt
- Trust AI to follow instructions rather than hardcoding fallback lists

### Common Debugging Mistakes

**❌ Wrong: Assuming SQLite based on file structure**
- Seeing `sqlite:data/` directory doesn't mean project uses SQLite
- Always check actual `.env` DATABASE_URL

**❌ Wrong: Writing separate cleanup scripts for SQLite**
- Wasted time writing SQLite-specific cleanup code
- Should have verified database type first

**❌ Wrong: Querying wrong database instance**
- Spent time debugging "no duplicates found" when duplicates existed
- Issue: Was querying with wrong assumptions about database type
- Fix: Use Playwright to verify actual page content, then trace back to data source

**✅ Right: Verify with browser automation**
- Use Playwright to see actual rendered page
- Count elements with JavaScript: `document.querySelectorAll('.card').length`
- Compare browser reality with database queries to find discrepancies

### Button State Management

**Disable buttons during async operations**
```html
<button disabled class="opacity-50 cursor-not-allowed">
  ⏳ 生成中...
</button>
```

**Update button on completion**
- Listen for SSE `done` event
- Update button text and style based on success/error
- Remove `disabled` attribute or replace button entirely

### Error Handling

**Always send `done` event in all code paths**
- Success path: `send.(%{event: "done", data: "success"})`
- Error path: `send.(%{event: "done", data: "error"})`
- This ensures UI always updates, never stuck in loading state

## Browser Automation

Use `agent-browser` for web automation. Run `agent-browser --help` for all commands.

Core workflow:
1. `agent-browser open <url>` - Navigate to page
2. `agent-browser snapshot -i` - Get interactive elements with refs (@e1, @e2)
3. `agent-browser click @e1` / `fill @e2 "text"` - Interact using refs
4. Re-snapshot after page changes
