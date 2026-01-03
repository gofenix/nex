# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code) when working with Nex example projects.

## Project Type

This is a **Nex** web framework example project. Nex is a minimalist server-side rendered web framework for Elixir that uses HTMX for interactivity.

## Standard Structure

```
example_project/
├── src/
│   ├── application.ex      # Application supervisor setup
│   ├── layouts.ex          # HTML layout (Tailwind, HTMX, scripts)
│   ├── pages/              # Page modules with mount/1 + render/1 + action handlers
│   │   └── index.ex
│   ├── components/         # Reusable components (optional)
│   │   └── card.ex
│   └── api/                # API modules (optional)
│       └── users.ex
├── mix.exs                 # Mix project config
├── mix.lock
├── .env.example
├── .gitignore
├── Dockerfile
└── README.md
```

## Development Commands

```bash
# Install dependencies
mix deps.get

# Run in development mode
mix nex.dev

# Run in production mode
mix nex.prod

# Build Docker image
docker build -t example_name .
docker run -p 4000:4000 example_name
```

## Key Patterns (IMPORTANT)

### 1. Unified Interface - Just Use `use Nex`

Nex uses a unified macro that **automatically detects module type based on path**. You only need `use Nex`:

```elixir
defmodule MyApp.Pages.Index do
  use Nex  # Automatically recognized as a Page module

  def mount(_params) do
    %{title: "Home", count: Nex.Store.get(:count, 0)}
  end

  def render(assigns) do
    ~H"""<h1>Hello {@count}</h1>"""
  end

  def increment(_params) do
    count = Nex.Store.update(:count, 0, &(&1 + 1))
    ~H"""<h1>Hello {@count}</h1>"""
  end
end
```

### 2. Module Type Detection (based on path)

| Path Pattern | Module Type | Imports |
|--------------|-------------|---------|
| `*.Pages.*` | Page module | HEEx + CSRF |
| `*.Api.*` | API module | None (pure functions) |
| `*.Components.*` | Component | HEEx + CSRF |
| `*.Layouts` | Layout | HEEx + CSRF |

### 3. Page Module Pattern

Pages have **three types of functions**:

```elixir
defmodule MyApp.Pages.Index do
  use Nex

  # 1. mount/1 - Initial state (called on page load)
  def mount(_params) do
    %{title: "My Page", count: Nex.Store.get(:count, 0)}
  end

  # 2. render/1 - Main HTML (called on page load)
  def render(assigns) do
    ~H"""
    <div>
      <h1>{@title}</h1>
      <button hx-post="/increment" hx-target="this">Increment</button>
      <div id="display">{@count}</div>
    </div>
    """
  end

  # 3. Action functions - HTMX endpoints (function name = POST path)
  # POST /increment → increment/1
  # POST /decrement → decrement/1
  def increment(_params) do
    count = Nex.Store.update(:count, 0, &(&1 + 1))
    ~H"""<div id="display">{@count}</div>"""
  end

  def decrement(_params) do
    count = Nex.Store.update(:count, 0, &max(0, &1 - 1))
    ~H"""<div id="display">{@count}</div>"""
  end
end
```

**Naming Convention**: A function `increment/1` automatically handles `POST /increment`.

### 4. API Module Pattern

API modules use HTTP method as function name:

```elixir
defmodule MyApp.Api.Users.Index do
  use Nex

  def get(_req) do
    Nex.json(%{users: ["Alice", "Bob"]})
  end
end

defmodule MyApp.Api.Users.Create do
  def post(req) do
    %{"name" => name} = req.body
    Nex.json(%{id: 1, name: name}, status: 201)
  end
end
```

### 5. Store (State Management)

State is **page-scoped** - tied to a `_page_id` generated on first render:

```elixir
# Get with default
count = Nex.Store.get(:count, 0)

# Put value
Nex.Store.put(:count, 42)

# Update with function
count = Nex.Store.update(:count, 0, &(&1 + 1))

# Delete
Nex.Store.delete(:count)
```

State survives HTMX requests but **is cleared on page refresh**.

### 6. Layout Module

```elixir
defmodule MyApp.Layouts do
  use Nex

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html>
      <head>
        <script src="https://unpkg.com/htmx.org@2.0.4"></script>
        <script src="https://cdn.tailwindcss.com"></script>
      </head>
      <body>
        <nav>...</nav>
        <main>{raw(@inner_content)}</main>
      </body>
    </html>
    """
  end
end
```

### 7. Response Helpers

```elixir
Nex.html("<div>...</div>")                    # HTML fragment
Nex.html("<div>...</div>", status: 200)      # With status
Nex.json(%{data: "..."})                      # JSON response
Nex.redirect("/other-page")                   # Redirect
Nex.stream(fn send -> send.("data") end)      # Server-Sent Events
```

## Style Guidelines

- Use **Tailwind CSS** for styling (via CDN for examples)
- Use **HEEx** templates (`~H"..."`) for HTML
- Use **HTMX** attributes (`hx-post`, `hx-target`, etc.)
- Keep pages focused - one feature per page module
- Components go in `src/components/`
- Layout should include Tailwind + HTMX scripts

## Common HTMX Patterns

```elixir
# Click to update
<button hx-post="/action" hx-target="#result">Click</button>
<div id="result"></div>

# Form submission
<form hx-post="/submit" hx-target="#result">
  <input name="text" />
</form>

# Swap inner HTML
<div hx-get="/data" hx-trigger="load" hx-target="this">
  Loading...
</div>
```

## Project Configuration

The framework handles all HTTP server setup automatically. Example projects only need minimal configuration.

### mix.exs

```elixir
defmodule MyApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :my_app,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: ["src"],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {MyApp.Application, []}
    ]
  end

  defp deps do
    [
      {:nex_core, path: "../../framework"}
    ]
  end
end
```

### application.ex

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = []
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

**Note**: The framework automatically starts Bandit (HTTP server) and all required services.

## Documentation

Every example project should have a `README.md` with:

1. Project name and description
2. Features demonstrated
3. Getting started instructions (`mix deps.get && mix nex.dev`)
4. Code structure overview
5. How it works explanation
6. Deployment instructions (if applicable)

## Running Examples

```bash
cd examples/counter
mix deps.get
mix nex.dev
```

Then open http://localhost:4000

## DO and DO NOT

### DO:
- Follow the unified `use Nex` pattern
- Use descriptive module names following the `*.Pages.*`, `*.Api.*` conventions
- Use `Nex.Store` for page-scoped state
- Include HTMX attributes for interactivity
- Keep examples focused on demonstrating one feature
- Use simple Application supervisor (framework handles Bandit automatically)

### DO NOT:
- Create custom router modules - use `Nex.Router` as-is
- Import Phoenix components manually - `use Nex` handles it
- Create separate store modules - use `Nex.Store` directly
- Start Bandit manually in Application - framework handles it
- Add bandit, jason, or other dependencies - framework transitively provides them
- Modify framework code (report issues instead)
