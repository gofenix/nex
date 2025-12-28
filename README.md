# Nex

A minimalist Elixir web framework powered by HTMX.

## Installation

Add `nex_core` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:nex_core, "~> 0.1.0"}
  ]
end
```

## Getting Started

Create a new Nex project using the installer:

```bash
mix archive.install hex nex_new
mix nex.new my_app
cd my_app
mix nex.dev
```

Visit `http://localhost:4000` to see your app running.

## Features

- **File-based Routing**: Automatic route discovery based on file structure
- **Dynamic Routes**: Support for parameterized routes `[id]`, `[slug]`, and catch-all `[...path]`
- **HTMX Integration**: Built-in support for HTMX with server-side rendering
- **Server-Sent Events**: First-class SSE support for real-time streaming
- **CSRF Protection**: Automatic CSRF token generation and validation
- **Hot Reload**: Instant file change detection in development
- **Zero Config**: Sensible defaults, minimal boilerplate

## Documentation

For more information, visit the [GitHub repository](https://github.com/fenix/nex).

## License

MIT
