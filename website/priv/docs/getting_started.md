# Getting Started with Nex

Nex comes with a convenient installer to bootstrap new projects quickly.

## 1. Install the Installer

```bash
mix archive.install hex nex_new
```

## 2. Create a New Project

Run the `nex.new` Mix task to create a new project directory.

```bash
mix nex.new my_app
cd my_app
```

## 3. Understand the Project Structure

Every Nex project follows a simple, convention-based structure.

```text
my_app/
├── src/
│   ├── pages/           # Page modules (auto-routed)
│   │   ├── index.ex     # GET /
│   │   └── [id].ex      # GET /id (dynamic route)
│   ├── api/             # JSON API endpoints
│   │   └── todos/
│   │       └── index.ex # GET/POST /api/todos
│   ├── partials/        # Reusable components
│   └── layouts.ex       # Layout template
├── mix.exs
└── Dockerfile           # Production deployment
```

**Key concept** - Just drop a file in `src/pages/` and it automatically becomes a route. No router configuration needed!

## 4. Run in Development Mode

Nex includes a built-in development server with hot reloading enabled by default. Changes to your code are reflected instantly.

```bash
mix nex.dev
```

Open `http://localhost:4000` in your browser. You should see your new Nex app running!

## 5. Build Your First Page

Create a new page with HTMX handlers. Pages are just Elixir modules that render HTML.

> See the examples directory for complete working examples of pages with HTMX handlers, real-time streaming, and more.

## 6. Deploy with Docker

Every Nex project includes a Dockerfile. Deploy to any platform that supports containers.

```bash
docker build -t my_app .
docker run -p 4000:4000 my_app
```

### Popular deployment platforms

*   **Railway** - Connect your GitHub repo and deploy automatically
*   **Fly.io** - Use `fly launch` (Dockerfile detected automatically)
*   **Render** - Create a new Web Service from your repository

## Next Steps

*   [Routing System](/docs/routing_guide)
*   [HTMX Integration](/docs/htmx_guide)
*   [State Management](/docs/state_management)
