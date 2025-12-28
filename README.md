# Nex

**The simplest way to build HTMX apps in Elixir**

Nex is a minimalist web framework that embraces simplicity and convention over configuration.

## Philosophy

Nex is designed for:
- 🚀 **Rapid prototyping** - Get ideas to production fast
- 🎯 **Indie hackers** - Build MVPs without complexity
- 📚 **Learning HTMX** - Best way to learn server-side rendering with HTMX
- 🛠️ **Internal tools** - Perfect for dashboards and admin panels

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

- **📁 File-based Routing** - Drop a file in `src/pages/`, get a route
- **🔀 Dynamic Routes** - Support for `[id]`, `[slug]`, and `[...path]` patterns
- **⚡ HTMX-first** - Built-in HTMX integration, no JavaScript needed
- **🔄 Server-Sent Events** - Real-time streaming with SSE support
- **🛡️ CSRF Protection** - Automatic token generation and validation
- **🔥 Hot Reload** - Instant file change detection via WebSocket
- **🐳 Docker Ready** - Dockerfile generated with every project
- **🎨 CDN-first** - Use Tailwind/DaisyUI via CDN, no build step

## Deployment

Every Nex project includes a Dockerfile:

```bash
docker build -t my_app .
docker run -p 4000:4000 my_app
```

Or deploy to any platform that supports Elixir:
- Railway
- Fly.io
- Render
- Traditional VPS

## Examples

Check out the `examples/` directory for:
- `chatbot` - AI chat with streaming responses
- `todos` - Classic todo app with HTMX
- `guestbook` - Simple guestbook with persistence
- `dynamic_routes` - Showcase of all routing patterns

## Documentation

- [GitHub Repository](https://github.com/gofenix/nex)
- [Hex Package: nex_core](https://hex.pm/packages/nex_core)
- [Hex Package: nex_new](https://hex.pm/packages/nex_new)

## License

MIT
