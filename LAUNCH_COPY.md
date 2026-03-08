# Launch Copy

This file contains launch copy for the Nex framework.

## Positioning

- **Nex** — HTMX-first Elixir framework and related tooling

## Nex

### X Post

Built a new Elixir framework for people who want server-rendered apps without SPA complexity.

`Nex` is HTMX-first, file-routed, and intentionally small:

- one `use Nex`
- file-based pages and APIs
- SSR + HTMX by default
- SSE and WebSocket support
- examples and showcases in the repo

Repo: https://github.com/gofenix/nex

### X Thread Ideas

1. Why I wanted SSR without a large frontend stack
2. Why file-based routing and a small API surface matter
3. What Nex is great at: internal tools, indie products, HTMX apps
4. What Nex is not trying to be: complex SPA framework, enterprise platform
5. Best examples to start with: counter, todos, dynamic routes

### Reddit Post

I have been building a minimalist Elixir framework called `Nex` for HTMX-first, server-rendered apps.

The goal is simple: make it easier to ship real products without the ceremony of a large frontend stack or a huge framework surface area.

What it focuses on:

- file-based routing
- one `use Nex` entry point
- server-rendered HTML with HEEx
- HTMX integration out of the box
- JSON APIs, SSE, and WebSockets
- examples and larger showcases in the same repository

What it is not trying to do:

- replace Phoenix for every use case
- become an enterprise platform
- optimize for complex SPA-heavy apps

If you work in Elixir and like SSR or HTMX-style development, I would love feedback on the project structure, docs, and trade-offs.

Repo: https://github.com/gofenix/nex

### FAQ

- **Why not Phoenix?**
  Nex is optimized for a smaller surface area and a more constrained HTMX-first workflow.
- **Is this production-ready?**
  The repository includes examples and showcases, but users should evaluate fit based on their own requirements.
- **Who is this for?**
  Indie products, internal tools, dashboards, and teams that want SSR with less ceremony.
- **Who is this not for?**
  Teams building complex SPA-first products or looking for a full enterprise platform.
