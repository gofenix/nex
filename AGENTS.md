# Nex Framework — AI Agent Guide

This guide helps AI coding agents understand the Nex framework to build applications.

## 1. Quick Reference

### Build & Test Commands

```bash
# Format code
mix format

# Run all tests
mix test

# Run single test file
mix test test/nex_base_test.exs

# Run single test (by line number)
mix test test/nex_base_test.exs:14

# Run tests matching pattern
mix test --trace                    # verbose
mix test --only filter_name         # run tagged tests
MIX_ENV=test mix test               # explicit env

# Start dev server
mix nex.dev
```

### Project Structure
```
my_app/
├── src/
│   ├── pages/           # Page routes (auto-routed)
│   │   ├── index.ex     # GET /
│   │   ├── users.ex     # GET /users
│   │   └── users/
│   │       └── [id].ex  # GET /users/:id
│   ├── api/             # JSON API routes
│   │   └── todos.ex     # GET/POST /api/todos
│   ├── components/      # Reusable components
│   └── layouts.ex       # HTML layout
├── priv/static/         # Static files (served at /static/*)
├── mix.exs
└── .env               # Environment variables
```

---

## 2. Code Style Guidelines

### Formatting
- Use `mix format` — follows Elixir standard
- `.formatter.exs` at project root with default settings

### Naming Conventions
- **Modules**: `PascalCase` (e.g., `Nex.Router`, `UserService`)
- **Functions/variables**: `snake_case` (e.g., `user_id`, `fetch_user`)
- **Files**: `snake_case.ex` (e.g., `user_service.ex`)

### Types
- Use `@type` for public API types
- Use typespecs for function contracts: `@spec function_name(type) :: return_type`
- Return tuples for errors: `{:ok, result}` or `{:error, reason}`

### Error Handling
```elixir
# Pattern match on results
case some_operation() do
  {:ok, result} -> handle_success(result)
  {:error, reason} -> handle_error(reason)
end

# Never swallow errors with empty catch
# WRONG: rescue ... -> nil
```

### Imports
- Use `alias` for clarity: `alias Nex.Router, as: Router`
- Group: `import` → `alias` → `use`
- Avoid wildcard imports in public APIs

---

## 3. Critical Anti-Patterns (Must Avoid)

### DO NOT create a custom Repo
```elixir
# WRONG
defmodule MyApp.Repo do
  use Ecto.Repo, otp_app: :my_app, adapter: Ecto.Adapters.Postgres
end

# RIGHT — use NexBase directly
NexBase.from("users") |> NexBase.run()
```

### DO NOT use `config/config.exs`
```elixir
# WRONG
config :my_app, MyApp.Repo, url: "..."

# RIGHT — use .env + Nex.Env
# .env: DATABASE_URL=postgresql://...
Nex.Env.get(:database_url)
```

### DO NOT use `for` comprehension in HEEx
```elixir
# WRONG
<%= for item <- @items do %> <div>{item.name}</div> <% end %>

# RIGHT — :for directive
<div :for={item <- @items}>{item.name}</div>
```

### DO NOT interpolate user input into SQL
```elixir
# WRONG — SQL injection
NexBase.sql("SELECT * FROM users WHERE name = '#{name}'", [])

# RIGHT — parameterized
NexBase.sql("SELECT * FROM users WHERE name = $1", [name])
```

### DO NOT manually add CSRF tags
The framework auto-injects `<meta name="csrf-token">` and HTMX headers. Do NOT add `{meta_tag()}` or `hx-headers={hx_headers()}` manually.

---

## 4. Framework Essentials

### File-based Routing
- `src/pages/index.ex` → `GET /`
- `src/pages/users/[id].ex` → `GET /users/:id` (params: `%{"id" => "42"}`)
- `src/api/todos.ex` → `/api/todos`

### Page Pattern
```elixir
defmodule MyApp.Pages.Index do
  use Nex

  def mount(_params) do
    %{title: "Home", items: fetch_items()}
  end

  def render(assigns) do
    ~H"""
    <h1>{@title}</h1>
    <div :for={item <- @items}>{item["name"]}</div>
    """
  end
end
```

### Application Startup
```elixir
def start(_type, _args) do
  Nex.Env.init()
  conn = NexBase.init(url: Nex.Env.get(:database_url), ssl: true)
  children = [{NexBase.Repo, conn}]
  Supervisor.start_link(children, strategy: :one_for_one)
end
```

### Built-in Helpers (via `use Nex`)
```elixir
format_number(12_345)     # => "12.3k"
format_date(~D[2026-01-15]) # => "Jan 15, 2026"
time_ago(datetime)        # => "3 hours ago"
pluralize(3, "item")      # => "3 items"
```

### Validation (Nex.Validator)
```elixir
# Validate params
case validate(params, %{
  "name" => [:required, :string],
  "email" => [:required, :string, :email],
  "age" => [:number, min: 18]
}) do
  {:ok, valid_params} -> # proceed
  {:error, errors} -> Nex.json(%{errors: errors}, status: 422)
end
```

### File Upload (Nex.Upload)
```elixir
# Files are automatically parsed from multipart forms
def post(req) do
  case req.body["avatar"] do
    nil ->
      Nex.json(%{error: "No file uploaded"}, status: 400)

    upload ->
      # Validate before saving
      case validate(upload, max_size: 5_000_000, types: ["image/jpeg", "image/png"]) do
        :ok ->
          save(upload, "priv/uploads")
        {:error, reason} ->
          Nex.json(%{error: reason}, status: 400)
      end
  end
end
```

### Custom Error Pages
```elixir
# Configure in application.ex
Application.put_env(:nex_core, :error_page_module, MyApp.ErrorPages)

# Custom error module
defmodule MyApp.ErrorPages do
  def render_error(conn, status, message, error) do
    # Return custom HTML string
  end
end
```

---

## 5. Common Patterns for AI Agents

### API Endpoint Pattern
```elixir
defmodule MyApp.Api.Users do
  use Nex

  # GET /api/users
  def get(req) do
    users = fetch_users()
    Nex.json(%{data: users})
  end

  # POST /api/users
  def post(req) do
    case validate(req.body, %{
      "name" => [:required, :string],
      "email" => [:required, :string, :email]
    }) do
      {:ok, params} ->
        user = create_user(params)
        Nex.json(%{data: user}, status: 201)
      {:error, errors} ->
        Nex.json(%{errors: errors}, status: 422)
    end
  end
end
```

### HTMX Action Pattern
```elixir
defmodule MyApp.Pages.Todos do
  use Nex

  def mount(_params) do
    %{todos: fetch_todos()}
  end

  def render(assigns) do
    ~H"""
    <form hx-post="/add_todo" hx-target="#todos" hx-swap="beforeend">
      <input type="text" name="title" required />
      <button>Add</button>
    </form>
    <ul id="todos">
      <li :for={todo <- @todos}>{todo["title"]}</li>
    </ul>
    """
  end

  # HTMX POST handler - returns HTML fragment
  def add_todo(req) do
    todo = create_todo(req.body["title"])
    ~H"<li>{todo["title"]}</li>"
  end
end
```

### Session & Authentication
```elixir
# Read session
def mount(_params) do
  user_id = Session.get(:user_id)
  %{logged_in: user_id != nil}
end

# Write session
def login(req) do
  Session.put(:user_id, user_id)
  Nex.redirect("/dashboard")
end
```

### Database Query (with NexBase)
```elixir
# Query builder
{:ok, users} = NexBase.from("users")
|> NexBase.eq(:active, true)
|> NexBase.order(:created_at, :desc)
|> NexBase.limit(10)
|> NexBase.run()

# Raw SQL
{:ok, rows} = NexBase.sql("SELECT * FROM users WHERE id = $1", [user_id])
```

### Streaming Response (AI/LLM)
```elixir
def post(req) do
  message = req.body["message"]

  Nex.stream(fn send ->
    send.(%{event: "message", data: "Thinking..."})
    # Stream from AI...
  end)
end
```

---

## 6. Release Process

### nex_core + nex_new (synchronized)
1. Update `/VERSION` file
2. Update `CHANGELOG.md`, `framework/CHANGELOG.md`, `installer/CHANGELOG.md`
3. Run `./scripts/publish_hex.sh`

### nex_base (independent)
1. Update version in `nex_base/mix.exs`
2. Update `CHANGELOG.md`
3. Run `./scripts/publish_nex_base.sh`

---

## 7. Commit Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):
- Format: `<type>(<scope>): <subject>`
- Subject: ≤50 chars, imperative mood
- **NO triple backticks** in commit messages

---

## 8. Additional Rules

- **English Only**: All code, comments, docs, commits in English
- **Changelog First**: Update changelog before any framework change
- **No Config Files**: Use `.env` only, never `config/*.exs`
- **Cursor Rules**: If project has `.cursorrules`, follow it (see `bestof_ex/.cursorrules`)

<!-- opensrc:start -->

## Source Code Reference

Source code for dependencies is available in `opensrc/` for deeper understanding of implementation details.

See `opensrc/sources.json` for the list of available packages and their versions.

Use this source code when you need to understand how a package works internally, not just its types/interface.

### Fetching Additional Source Code

To fetch source code for a package or repository you need to understand, run:

```bash
npx opensrc <package>           # npm package (e.g., npx opensrc zod)
npx opensrc pypi:<package>      # Python package (e.g., npx opensrc pypi:requests)
npx opensrc crates:<package>    # Rust crate (e.g., npx opensrc crates:serde)
npx opensrc <owner>/<repo>      # GitHub repo (e.g., npx opensrc vercel/ai)
```

<!-- opensrc:end -->