# AiSaga

A web application built with [Nex](https://github.com/gofenix/nex).

## Getting Started

```bash
mix deps.get
mix nex.dev
```

Open http://localhost:4000

## Project Structure

```
ai_saga/
├── src/
│   ├── application.ex      # Application supervision tree
│   ├── layouts.ex          # HTML layout template
│   ├── pages/              # Page components (routes)
│   │   └── index.ex        # Homepage (/)
│   ├── api/                # API endpoints (Next.js style)
│   │   └── hello.ex        # Example: GET/POST /api/hello
│   └── components/           # Reusable components
│       └── card.ex         # Example card component
├── mix.exs                 # Project configuration
└── .env.example            # Environment variables template
```

## Creating Pages

```elixir
# src/pages/about.ex -> /about
defmodule AiSaga.Pages.About do
  use Nex

  def render(assigns) do
    ~H"""
    <h1>About Us</h1>
    """
  end
end
```

## Creating API Endpoints (Next.js Style)

```elixir
# src/api/users.ex -> /api/users
defmodule AiSaga.Api.Users do
  use Nex

  def get(req) do
    # req.query - path params + query string
    id = req.query["id"]
    Nex.json(%{users: []})
  end

  def post(req) do
    # req.body - request body (always a Map)
    name = req.body["name"]
    Nex.json(%{created: true}, status: 201)
  end
end
```

## Creating Components

```elixir
# src/components/button.ex
defmodule AiSaga.Components.Button do
  use Nex

  def button(assigns) do
    ~H"""
    <button class="btn">{@text}</button>
    """
  end
end
```

Use in pages:

```elixir
~H"""
<AiSaga.Components.Button.button text="Click me" />
"""
```

## Deployment

```bash
# Docker
docker build -t ai_saga .
docker run -p 4000:4000 ai_saga

# Production
MIX_ENV=prod mix nex.start
```

## Resources

- [Nex Documentation](https://hexdocs.pm/nex_core)
- [Nex GitHub](https://github.com/gofenix/nex)
- [HTMX](https://htmx.org)
