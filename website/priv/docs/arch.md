# Nex Architecture Analysis Document

## 1. Overview

Nex is a minimalist Web framework built on Elixir, designed specifically for HTMX-driven applications. Its core philosophy is to leverage Elixir's high-concurrency capabilities and HTMX's frontend interactivity to provide a modern Web development experience without complex JavaScript build processes.

The Nex framework consists of two main components:

1. **Framework Core (`framework/`)**: Runtime core containing routing, request handling, state management, component models, and more.
2. **Installer (`installer/`)**: Project generator for quickly scaffolding Nex projects.

## 2. Core Architecture (Framework Core)

Nex's core architecture is built around Plug, HTMX, and Elixir's OTP model.

### 2.1 Request Lifecycle

Nex uses `Plug.Router` as its entry point, but delegates most routing logic to `Nex.Handler` for dynamic dispatch.

```mermaid
graph TD
    Client[Client (Browser/HTMX)] -->|HTTP Request| Router[Nex.Router]
    Router -->|Plug Pipeline| Parsers[Plug.Parsers]
    Parsers -->|Dispatch| Handler[Nex.Handler]

    Handler -->|Analysis| RouteType{Route Type}

    RouteType -->|/nex/live-reload-ws| WS[WebSockAdapter]
    RouteType -->|/api/*| API[API Handler - SSE via text/event-stream]
    RouteType -->|POST /action| Action[Action Handler]
    RouteType -->|GET /*| Page[Page Handler]

    Page -->|Route Discovery| Discovery[Nex.RouteDiscovery]
    Discovery -->|Find Module| PageModule[User Page Module]

    PageModule -->|mount/1| Assigns[Assigns]
    Assigns -->|render/1| HEEx[HEEx Template]
    HEEx -->|Layout Injection| Layout[Layout Module]
    Layout -->|HTML Response| Client
```

### 2.2 Route Discovery

Nex adopts file-system routing, scanning the `src/` directory at runtime via the `Nex.RouteDiscovery` module.

- **Pages (`src/pages/`)**: Mapped to Web page routes (GET requests).
- **API (`src/api/`)**: Mapped to JSON API routes (all HTTP methods).
- **Actions**: POST/PUT/PATCH/DELETE requests are resolved to page action functions based on the `Referer` header.

Supported routing patterns:

- **Static Routes**: `src/pages/users.ex` -> `/users`
- **Dynamic Routes**: `src/pages/users/[id].ex` -> `/users/123`
- **Catch-all Routes**: `src/pages/docs/[...path].ex` -> `/docs/getting-started/installation`

The route discovery mechanism parses path segments into module names. For example, `/users/123` will attempt to match the `MyApp.Pages.Users.Id` module and pass `123` as a parameter.

#### Route Caching

Routes are cached in an ETS table (`:nex_route_cache`) for performance. When files change during development, the cache is automatically cleared and rebuilt on the next request.

### 2.3 Component Model

Nex provides two primary types of UI components:

1. **Nex (`use Nex`)** - Unified module type, usable for Page, API, and SSE:
   - **Stateful**: Maintains page-level state via `Nex.Store`.
   - **Route Mapped**: Directly corresponds to URL routes.
   - **Lifecycle**: `mount/1` (initialize data), `render/1` (render UI), Action Functions (handle POST requests).
   - **HTMX Integration**: Automatically handles CSRF tokens and Page IDs.

2. **Nex (`use Nex`) - Partial Components**:
   - **Stateless**: Pure functional components.
   - **No Route**: Only called by Pages.
   - **Reusability**: Used to build reusable UI elements (buttons, list items, etc.).

### 2.4 State Management (Nex.Store)

Nex introduces the concept of **Page-scoped State**, aiming to provide a component-like state experience similar to React/Vue, but running on the server.

- **Page ID**: A unique `_page_id` generated for each page render.
- **Storage**: Uses ETS tables to store state, with keys as `{page_id, key}`.
- **Lifecycle**: State resets on page refresh (Ephemeral).
- **TTL**: Default 1-hour expiration, with `Nex.Store` GenServer periodically cleaning up.

### 2.5 Supervision Tree

Nex maintains its own supervision tree to ensure the stability of core services.

```mermaid
graph TD
    AppSup[User App Supervisor] --> NexSup[Nex.Supervisor]

    NexSup --> PubSub[Phoenix.PubSub]
    NexSup --> Store[Nex.Store (GenServer + ETS)]
    NexSup --> Reloader[Nex.Reloader (Dev Only)]

    subgraph "Framework Internal"
        PubSub -->|Broadcast| ReloadWS[Live Reload WebSocket]
        Store -->|State Mgmt| Pages[Page Processes]
        Reloader -->|File Watch| FileSystem[File System]
    end
```

- **Phoenix.PubSub**: Used for hot-reload notifications in development.
- **Nex.Store**: Manages page state storage and cleanup.
- **Nex.Reloader**: Watches for file changes and triggers recompilation and browser refresh.

### 2.6 Server-Sent Events (SSE)

Nex provides native support for SSE through the API layer.

- **Implementation**: SSE is not a separate route type. Instead, return a `%Nex.Response{}` with `content_type: "text/event-stream"` from any API handler.
- **Streaming**: Use `Nex.stream/1` to create a streaming response that maintains a long-lived connection.
- **Headers**: `Nex.Handler` automatically sets `content-type: text/event-stream`, `cache-control: no-cache`, and `connection: keep-alive`.

## 3. Installer Architecture

The `installer` directory contains the implementation of the `mix nex.new` task.

- **Template Generation**: Generates project scaffolding via embedded string templates (Heredocs).
- **Dependency Management**: Automatically runs `mix deps.get` to install dependencies.
- **Directory Structure**:
  - `src/pages`: Page code
  - `src/api`: API code
  - `src/components`: Component code
  - `src/layouts.ex`: Layout definition
  - `mix.exs`: Project configuration
  - `Dockerfile`: Container deployment support

## 4. Summary

Nex's architecture is extremely minimalist, reducing complexity through:

1. **Decentralized Routing**: No need to maintain `router.ex` files, utilizing file system structure instead.
2. **Unified Processing Flow**: `Nex.Handler` handles all types of requests uniformly, simplifying the middleware chain.
3. **Server-side State**: `Nex.Store` makes maintaining UI state on the server simple, enabling complex interactions with HTMX without client-side state management.
