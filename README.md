# Nex

**The simplest way to build HTMX apps in Elixir**

Nex is a minimalist web framework for **indie hackers, startups, and teams** who want to ship real products fast without enterprise complexity. Build modern web applications with server-side rendering, zero JavaScript complexity, and instant hot reloading.

## Philosophy

Nex is designed for building **real applications** that work in production:
- 🚀 **Rapid development** - Ship features fast, not prototypes
- 🎯 **Indie hackers & startups** - Build profitable products without enterprise complexity
- 📊 **Internal tools & dashboards** - Admin panels, data dashboards, operational tools
- 🔄 **Real-time applications** - Live dashboards, chat apps, streaming data with SSE
- 🌐 **Server-side rendering done right** - Modern web apps without JavaScript overhead

Nex is **not**:
- ❌ A Phoenix competitor (use Phoenix for enterprise apps)
- ❌ A full-stack framework (no built-in ORM, auth, or asset pipeline)
- ❌ For complex SPAs (use LiveView or React for that)

## Quick Start

```bash
# Install the project generator
mix archive.install hex nex_new

# Create a new project
mix nex.new my_app
cd my_app

# Start development server
mix nex.dev
```

Visit `http://localhost:4000` to see your app running.

## Core Features

### Routing & Pages
- **📁 File-based Routing** - Drop a file in `src/pages/`, get a route automatically
- **🔀 Dynamic Routes** - Support for `[id]`, `[slug]`, `[...path]` patterns, and mixed routes
- **🎯 Convention over Configuration** - No route configuration needed, just create files

### Development Experience
- **🔥 Hot Reload** - Instant file change detection via WebSocket, no manual refresh needed
- **⚡ Zero Config** - Works out of the box, sensible defaults for everything
- **🎨 CDN-first** - Use Tailwind/DaisyUI via CDN, no build step required

### Frontend Integration
- **⚡ HTMX-first** - Built-in HTMX integration, server-side rendering without JavaScript
- **🛡️ CSRF Protection** - Automatic token generation and validation on all POST/PUT/PATCH/DELETE requests
- **📝 HTML Templates** - Phoenix HEEx templates for type-safe markup

### Real-time & APIs
- **🔄 Server-Sent Events** - Real-time streaming with SSE support for live updates
- **📡 JSON APIs** - Easy JSON endpoint creation with `Nex.Api`
- **🔗 Dynamic API Routes** - Support for dynamic API routes with parameters

### Deployment
- **🐳 Docker Ready** - Production-ready Dockerfile generated with every project
- **📦 Single Binary** - Compile to a single executable for easy deployment
- **🚀 Multi-platform** - Deploy to Railway, Fly.io, Render, or any VPS

## Project Structure

```
my_app/
├── src/
│   ├── pages/           # Page modules (auto-routed)
│   │   ├── index.ex     # GET /
│   │   └── [id].ex      # GET /:id
│   ├── api/             # API endpoints (JSON)
│   │   └── todos/
│   │       └── index.ex # GET/POST /api/todos
│   ├── partials/        # Reusable components
│   └── layouts.ex       # Layout template
├── mix.exs
└── Dockerfile           # Production deployment
```

## Usage Examples

### Simple Counter with State

```elixir
defmodule MyApp.Pages.Index do
  use Nex.Page

  def mount(_params) do
    %{count: Nex.Store.get(:count, 0)}
  end

  def render(assigns) do
    ~H"""
    <div class="text-center py-12">
      <h1 class="text-4xl font-bold mb-4">Counter</h1>
      <div id="counter-display" class="text-6xl font-bold mb-8">{@count}</div>
      <div class="space-x-2">
        <button hx-post="/decrement" hx-target="#counter-display" hx-swap="outerHTML">-</button>
        <button hx-post="/reset" hx-target="#counter-display" hx-swap="outerHTML">Reset</button>
        <button hx-post="/increment" hx-target="#counter-display" hx-swap="outerHTML">+</button>
      </div>
    </div>
    """
  end

  def increment(_params) do
    count = Nex.Store.update(:count, 0, &(&1 + 1))
    ~H"<div id="counter-display" class="text-6xl font-bold mb-8">{count}</div>"
  end

  def decrement(_params) do
    count = Nex.Store.update(:count, 0, &(&1 - 1))
    ~H"<div id="counter-display" class="text-6xl font-bold mb-8">{count}</div>"
  end

  def reset(_params) do
    Nex.Store.put(:count, 0)
    ~H"<div id="counter-display" class="text-6xl font-bold mb-8">0</div>"
  end
end
```

### Page with HTMX Handler

```elixir
defmodule MyApp.Pages.Todos do
  use Nex.Page

  def mount(_params) do
    %{todos: fetch_todos()}
  end

  def render(assigns) do
    ~H"""
    <h1>My Todos</h1>
    <form hx-post="/add_todo" hx-target="#todos" hx-swap="beforeend">
      <input type="text" name="title" required />
      <button>Add</button>
    </form>
    <ul id="todos">
      <li :for={todo <- @todos}>{todo.title}</li>
    </ul>
    """
  end

  # HTMX POST handler
  def add_todo(%{"title" => title}) do
    todo = create_todo(title)
    ~H"<li>{@todo.title}</li>"
  end
end
```

### Server-Sent Events (Real-time Streaming)

```elixir
defmodule MyApp.Api.Chat.Stream do
  use Nex.SSE

  @impl true
  def stream(%{"message" => msg}, send_fn) do
    # Stream response character by character
    msg
    |> String.graphemes()
    |> Enum.each(fn char ->
      send_fn.(%{event: "message", data: char})
      Process.sleep(50)
    end)
    :ok
  end
end
```

### JSON API Endpoint

```elixir
defmodule MyApp.Api.Todos.Index do
  use Nex.Api

  def get do
    %{data: fetch_todos()}
  end

  def post(%{"title" => title}) do
    todo = create_todo(title)
    {201, %{data: todo}}
  end
end
```

## Deployment

Every Nex project includes a production-ready Dockerfile:

```bash
docker build -t my_app .
docker run -p 4000:4000 my_app
```

Deploy to any platform that supports Elixir:
- **Railway** - Easiest option, auto-deploy from Git
- **Fly.io** - Global deployment with edge computing
- **Render** - Simple and straightforward
- **Traditional VPS** - Full control with Elixir installed

## Examples

Check out the `examples/` directory for complete working applications:
- **chatbot** - AI chat with streaming responses using SSE
- **chatbot_sse** - Real-time streaming with HTMX SSE extension
- **todos** - Classic todo app with HTMX interactions
- **guestbook** - Simple guestbook with persistence
- **dynamic_routes** - Comprehensive showcase of all routing patterns

## Documentation

- [GitHub Repository](https://github.com/gofenix/nex)
- [Hex Package: nex_core](https://hex.pm/packages/nex_core)
- [Hex Package: nex_new](https://hex.pm/packages/nex_new)
- [HexDocs: nex_core](https://hexdocs.pm/nex_core)
- [HexDocs: nex_new](https://hexdocs.pm/nex_new)

## License

MIT
