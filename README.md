# Nex
 
 **The simplest way to build HTMX apps in Elixir**
 
 Nex is the main product line in this repository: a minimalist, HTMX-first toolkit for building server-rendered Elixir apps fast.
 
 This monorepo contains two product lines:
 
 - **Nex** — the main product, including the web framework, installer, environment helper, database layer, docs site, examples, and showcases
 - **nex_agent** — a separate agent product line with its own README, positioning, and launch narrative
 
 ## Why Nex
 
 Nex is built for developers who want to ship real products without dragging in SPA complexity or framework ceremony.
 
 - **HTMX-first** — server-rendered UX without a large frontend stack
 - **Minimal API surface** — one `use Nex` entry point for pages, APIs, and components
 - **File-based routing** — routes come from the filesystem, not route config
 - **Fast iteration** — hot reloading, simple project structure, and low boilerplate
 - **AI-friendly locality** — UI and behavior live close together, which makes the codebase easier for both humans and agents to modify
 
 ## What Nex Is and Is Not
 
 Nex is a pragmatic framework for:
 
 - indie products
 - internal tools and dashboards
 - HTMX-first web apps
 - JSON APIs and streaming endpoints
 - teams that want SSR with less complexity
 
 Nex is not trying to be:
 
 - a Phoenix replacement for every use case
 - a batteries-included enterprise platform
 - the best fit for complex SPAs
 
 ## Quick Start
 
 ```bash
 mix archive.install hex nex_new
 mix nex.new my_app
 cd my_app
 mix nex.dev
 ```
 
 Then open `http://localhost:4000`.
 
 ## Example Project Structure
 
 ```
 my_app/
 ├── src/
 │   ├── pages/
 │   │   ├── index.ex
 │   │   └── [id].ex
 │   ├── api/
 │   │   └── todos/
 │   │       └── index.ex
 │   ├── components/
 │   └── layouts.ex
 ├── mix.exs
 └── Dockerfile
 ```
 
 ## Core Capabilities
 
 ### Pages and Routing
 
 - File-based routing from `src/pages/`
 - Dynamic segments like `[id]`, `[slug]`, and `[...path]`
 - Convention-over-configuration module structure
 
 ### HTMX and SSR
 
 - HTML-first rendering with HEEx templates
 - HTMX integration out of the box
 - Automatic CSRF handling for state-changing requests
 - Partial updates without SPA plumbing
 
 ### APIs and Realtime
 
 - JSON APIs with a simple request object
 - Native SSE streaming with `Nex.stream/1`
 - WebSocket support for user-defined handlers
 - Shared request-time helpers for cookies, session, and flash
 
 ### Developer Experience
 
 - Unified `use Nex` entry point
 - Low-boilerplate layouts and page modules
 - Built-in static file serving
 - Examples and showcases in the same repository
 
 ## Monorepo Map
 
 ### Main Product Line: Nex
 
 - `framework/` — the core Nex framework published as `nex_core`
 - `installer/` — `mix nex.new` project generator
 - `nex_env/` — environment variable helper package
 - `nex_base/` — schema-less database layer and query builder
 - `examples/` — focused examples for learning specific capabilities
 - `showcase/` — larger apps that demonstrate real-world usage
 - `website/` — the official site built with Nex itself
 
 ### Separate Product Line: nex_agent
 
 - `nex_agent/` — agent runtime and tooling product line with separate positioning
 
 If you are here for the agent product, start with [`nex_agent/README.md`](nex_agent/README.md).
 
 ## Start Here
 
 If you want the fastest path into Nex, use this sequence:
 
 1. Read this README
 2. Create a fresh app with `mix nex.new`
 3. Open one focused example
 4. Open one showcase app once the basics click
 
 ## Recommended Examples
 
 These are the best starting points for understanding the main Nex product line:
 
 - [`examples/counter`](examples/counter) — minimal state + HTMX loop
 - [`examples/todos`](examples/todos) — CRUD-style page actions
 - [`examples/dynamic_routes`](examples/dynamic_routes) — routing conventions and path patterns
 - [`examples/upload`](examples/upload) — file upload handling
 - [`examples/todos_api`](examples/todos_api) — JSON API structure
 
 ## Recommended Showcases
 
 For more realistic product-shaped examples:
 
 - [`showcase/bestof_ex`](showcase/bestof_ex) — a larger Nex application structure
 - [`showcase/agent_console`](showcase/agent_console) — a UI-heavy showcase built on Nex
 
 ## A Tiny Example
 
 ```elixir
 defmodule MyApp.Pages.Index do
   use Nex
 
   def mount(_params) do
     %{count: Nex.Store.get(:count, 0)}
   end
 
   def render(assigns) do
     ~H"""
     <div>
       <h1>Counter</h1>
       <div id="counter-display">{@count}</div>
       <button hx-post="/increment" hx-target="#counter-display" hx-swap="outerHTML">+</button>
     </div>
     """
   end
 
   def increment(_params) do
     count = Nex.Store.update(:count, 0, &(&1 + 1))
     ~H"<div id="counter-display">{count}</div>"
   end
 end
 ```
 
 ## Documentation and Packages
 
 - [Official Documentation](https://nex-framework.up.railway.app/docs)
 - [Hex Package: nex_core](https://hex.pm/packages/nex_core)
 - [Hex Package: nex_new](https://hex.pm/packages/nex_new)
 - [HexDocs: nex_core](https://hexdocs.pm/nex_core)
 - [HexDocs: nex_new](https://hexdocs.pm/nex_new)
 
 ## Open Source
 
 If you want to contribute or evaluate the repository for adoption, start here:
 
 - [Contributing Guide](CONTRIBUTING.md)
 - [Security Policy](SECURITY.md)
 - [Code of Conduct](CODE_OF_CONDUCT.md)
 - [Versioning](VERSIONING.md)
 - [Changelog](CHANGELOG.md)
 
 ## License
 
 MIT
