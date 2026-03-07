# Launch Copy

This file contains first-pass launch copy for the two product lines in this repository.

## Positioning

- **Nex** — the main product line: HTMX-first Elixir framework and related tooling
- **Nex Agent** — the separate agent runtime and tooling line

Keep these narratives separate in public posts.

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

## Nex Agent

### X Post

I have also been building `Nex Agent`, a separate Elixir product line for coding agents.

It supports:

- sessions
- tools
- memory
- skills
- MCP integration
- reflection
- self-evolution workflows

It is being positioned separately from the web framework because it serves a different audience and use case.

Repo: https://github.com/gofenix/nex/tree/main/nex_agent

### X Thread Ideas

1. Why I split the agent product line from the framework narrative
2. Why Elixir is interesting for long-lived agent sessions
3. How tools, memory, and MCP fit together
4. Why self-evolution and rollback are first-class ideas here
5. Where feedback is most needed

### Reddit Post

I am separately packaging `Nex Agent`, an Elixir runtime for building tool-using coding agents.

The focus is not a generic chat UI. The focus is an agent runtime with:

- persistent sessions
- tool execution
- memory
- skills
- MCP server integration
- reflection
- self-evolution and rollback workflows

I am intentionally keeping this separate from the main `Nex` framework narrative so each product line can be evaluated on its own terms.

If you work on agent runtimes, coding assistants, or MCP-heavy systems, I would love feedback on the positioning and API shape.

Repo: https://github.com/gofenix/nex/tree/main/nex_agent

### FAQ

- **Is Nex Agent part of the web framework?**
  It lives in the same monorepo, but it is a separate product line.
- **What makes it different?**
  The combination of Elixir runtime patterns, tools, memory, skills, MCP support, and self-evolution workflows.
- **Who is it for?**
  Developers building coding agents or autonomous dev workflows.
- **What kind of feedback is most useful?**
  API ergonomics, runtime model, tool architecture, and product positioning.
