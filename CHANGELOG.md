# Changelog

All notable changes to the Nex framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.3] - Unreleased

### Added
- **Automated CSRF Protection**: Framework now automatically injects hidden CSRF tokens into all state-changing `<form>` tags (POST, PUT, PATCH, DELETE) and handles HTMX headers. Manual `{csrf_input_tag()}` and `hx-headers` are no longer required.
- **Refined Project Installer**: Enhanced `mix nex.new` with reserved name validation, automatic git initialization, and `.formatter.exs` generation.
- **Enhanced AI Agent Instructions**: Deeply optimized `AGENTS.md` with anti-hallucination guidelines, startup command instructions, and surgical UX patterns.
- **NexBase `sql/2` helper**: `NexBase.sql("SELECT ...", [params])` returns `{:ok, [%{col => val}]}` directly, hiding raw Postgrex result parsing.

### Changed
- **NexBase Supabase-style API**: Redesigned to `NexBase.init(url: ..., ssl: true)` + `NexBase.from("table")` — no client, no Repo knowledge needed.
- **NexBase decoupled from nex_core**: NexBase is now a standalone library with only `ecto_sql`, `postgrex`, and `jason`. Config passed via `NexBase.init/1`.
- **Removed `client/0`, `client/1`, `connect/1`**: Replaced by `NexBase.init/1` (for apps) and `NexBase.init(start: true)` (for scripts).

### NexBase 0.1.0 — Hex Publish Prep
- **Fixed**: `elixir: "~> 1.19"` → `"~> 1.17"` (1.19 does not exist)
- **Fixed**: `postgrex` version constraint `">= 0.0.0"` → `"~> 0.19"`
- **Added**: `source_url`, `homepage_url` to mix.exs package metadata
- **Added**: Type specs (`@type t`) to `NexBase.Query`
- **Removed**: Dead `NexBase.Client` module (replaced by direct `NexBase.from/1` API)
- **Removed**: Unused `opts` parameter from `NexBase.run/1`
- **Fixed**: `rpc/3` doc referencing non-existent `:repo` option
- **Rewritten**: README.md — English, matches actual API (no more `@client` pattern), documents `init/1`, `sql/2`, script usage

## [0.3.2] - 2026-01-04

### Added
- **AI Agent Handbook (AGENTS.md)**: Automatically generated for new projects to guide AI assistants (Cursor, Claude, etc.) in writing idiomatic Nex code.
- **Improved Vibe Coding Support**: Optimized framework architecture and documentation for intent-driven development.

### Changed
- **Renamed `Nex.CSRF.input_tag/0` to `Nex.CSRF.csrf_input_tag/0`**: Better clarity and consistency with AI guidance.
  - **Migration**: Replace `{csrf_input_tag()}` with `{csrf_input_tag()}` (wait, actually just update the name in your templates).
- **Refined API Terminology**: Removed misleading "API 2.0" references in favor of "JSON API Standards".

### Improved
- **REST API Guidance**: Clearer mapping between file-system routes and HTTP method handlers.
- **SSE Streaming UX**: Standardized placeholder rendering and chunk encoding for AI responses.

### Added
- **Unified `use Nex` Interface**: One statement for all module types
  - All modules (Pages, APIs, Components, Layouts) now use the same `use Nex` statement
  - Framework automatically detects module type based on path (`.Api.`, `.Pages.`, `.Components.`, `.Layouts`)
  - API modules: no imports (pure functions)
  - Page/Partial/Layout modules: automatic HEEx + CSRF imports
  - Provides the simplest possible developer experience
  - Fully aligned with Next.js convention-over-configuration philosophy

- **`Nex.stream/1` - Server-Sent Events (SSE) Support**: Native streaming response for AI applications
  - Simple callback function API: `Nex.stream(fn send -> send.("message") end)`
  - Similar to Python's `StreamingResponse` with generators and Next.js's `ReadableStream`
  - Real-time streaming using `Finch.stream` - data is sent as it arrives (true typewriter effect)
  - Automatic SSE formatting and header management
  - Zero boilerplate - simpler than Python FastAPI and Next.js (5 lines vs 7 lines vs 15 lines)
  - Perfect for AI streaming responses (OpenAI, Anthropic, etc.)
  - Automatic connection close detection and error handling
  - Smart history management using `Nex.Store` to avoid URL length limits
  - Supports custom events: `send.(%{event: "message", data: "content"})`
  - Example: Complete AI chatbot with history in under 50 lines of code

### Changed
- **BREAKING: Removed `Nex.Page`, `Nex.Api`, `Nex.Partial`, and `Nex.SSE` modules**: Use `use Nex` instead
  - All `use Nex.*` modules have been completely removed
  - Using `use Nex.Page`, `use Nex.Api`, `use Nex.Partial`, or `use Nex.SSE` will now cause compilation errors
  - **Migration required**: Replace all with `use Nex`
  - Framework automatically detects module type based on path and imports appropriate functions
  - This is a hard breaking change - old code will not compile until updated

- **BREAKING: Renamed `partials/` to `components/`**: Better alignment with modern frameworks
  - Directory: `src/partials/` → `src/components/`
  - Module namespace: `MyApp.Partials.*` → `MyApp.Components.*`
  - Path detection: `.Partials.` → `.Components.`
  - **Reason**: Aligns with React, Vue, Svelte, and Phoenix 1.7+ conventions
  - **Migration required**: Rename directories and update module names
  - Improves DX for developers familiar with modern frontend frameworks

### Migration Guide

**Before:**
```elixir
defmodule MyApp.Pages.Index do
  use Nex.Page  # ❌ Will cause compilation error
end

defmodule MyApp.Api.Users do
  use Nex.Api  # ❌ Will cause compilation error
end

defmodule MyApp.Partials.Header do
  use Nex.Partial  # ❌ Will cause compilation error
end

# Old directory structure
src/partials/  # ❌ Old naming
```

**After:**
```elixir
defmodule MyApp.Pages.Index do
  use Nex  # ✅ Unified interface
end

defmodule MyApp.Api.Users do
  use Nex  # ✅ Unified interface
end

defmodule MyApp.Components.Header do
  use Nex  # ✅ Unified interface + new naming
end

# New directory structure
src/components/  # ✅ Modern naming (aligned with React/Vue/Phoenix)

# SSE endpoints use unified interface with Nex.stream/1
defmodule MyApp.Api.Chat.Stream do
  use Nex  # ✅ Unified interface

  def get(req) do
    message = req.query["message"]
    
    Nex.stream(fn send ->
      send.("Thinking...")
      send.("Processing...")
      send.("Done!")
    end)
  end
end
```

### Improved
- **Simplified Module API**: Reduced cognitive load for developers
  - No need to remember different `use` statements for different module types
  - One unified interface: `use Nex`
  - Better alignment with Next.js simplicity
  - Automatic type detection based on module path

### Removed
- **Legacy SSE Code Cleanup**: Removed ~160 lines of deprecated SSE handling code
  - Deleted old `handle_sse/3`, `handle_sse_endpoint/3`, `try_sse_index_module/2`, `send_sse_stream/3`
  - Deleted old `format_sse_event/1` (4 overloads) and `format_sse_data/1` (2 overloads)
  - Removed `/sse/*` route (use `/api/*` with `Nex.stream/1` instead)
  - Removed `__sse_endpoint__` marker check
  - All SSE functionality now uses the unified `Nex.stream/1` API

### Refactored
- **Unified Route Resolution**: Consolidated all route resolution logic into `RouteDiscovery`
  - Moved `resolve_action`, `resolve_page_module`, `resolve_api_module` from Handler to RouteDiscovery
  - **Removed all legacy fallback code** - now only uses file-system based routing
  - Deleted `resolve_legacy`, `resolve_action_legacy`, `path_to_module_parts`, `is_dynamic_segment?`
  - New unified API: `RouteDiscovery.resolve(:pages | :api | :action, path)`
  - Handler now only orchestrates request handling, RouteDiscovery handles all routing
  - Handler reduced from 714 lines to 537 lines (-25%)
  - RouteDiscovery reduced from 394 lines to 342 lines (-13%)
  - Clearer separation of concerns: Handler = request processing, RouteDiscovery = routing
  - **Breaking**: Dynamic routes now require explicit file-system routing (e.g., `[id].ex`)
  - Fixed: `index.ex` files now correctly match their parent path (e.g., `pages/index.ex` → `/`, `users/index.ex` → `/users`)

## [0.3.0] - 2025-12-31

### Added
- **`Nex.html/2` Response Helper**: New helper function for returning HTML responses
  - Designed for HTMX scenarios where API endpoints return HTML fragments
  - Consistent API with other response helpers (`json`, `text`, `redirect`, `status`)
  - Example: `Nex.html("<div>User Profile</div>", status: 200)`

### Changed
- **BREAKING: API Request Object Redesign**: Fully aligned with Next.js API Routes
  - Removed `req.params` field (not in Next.js)
  - Removed `req.path_params`, `req.query_params`, `req.body_params` (not in Next.js)
  - Kept only Next.js standard fields: `req.query`, `req.body`, `req.method`, `req.headers`, `req.cookies`
  - `req.query` now contains path params + query string (path params take precedence)
  - `req.body` is completely independent and never merged with `req.query`
  - Migration: Replace `req.params["id"]` with `req.query["id"]` or `req.body["name"]`

### Fixed
- **API Request Body Handling**: Fixed crash when request has no body or invalid Content-Type
  - `req.body` is now guaranteed to be a Map (never `%Plug.Conn.Unfetched{}`)
  - Prevents `FunctionClauseError` when using `Map.has_key?/2` on `req.body`
  - GET requests and requests without body now have `req.body == %{}`

### Improved
- **Developer Experience**: Enhanced error messages for API handlers
  - Development environment now returns detailed error information in JSON response
  - Production environment returns generic error message for security
  - Error messages now include `Nex.html/2` in the list of available helpers
  - Added comprehensive documentation to `Nex.Req` module with Next.js comparison

## [0.2.4] - 2025-12-30

### Added
- **RESTful API Support**: Extended HTTP method support for DELETE, PUT, and PATCH requests
  - CSRF validation now applies to all modifying methods (POST, DELETE, PUT, PATCH)
  - Action handlers can now respond to DELETE/PUT/PATCH requests
  - Enables full RESTful API implementations
- **SSE Performance Documentation**: Added comprehensive guide for Server-Sent Events
  - Performance characteristics and concurrency limits
  - System tuning recommendations for high-concurrency deployments
  - Time synchronization patterns for real-time applications
  - Production-ready SSE endpoint examples
- **LLM Usage Guide**: Created `.cursorrules` file for AI-assisted development
  - Complete framework architecture overview
  - Module usage patterns and conventions
  - Common patterns and best practices
  - Security and performance guidelines
- **New Example Projects**:
  - `todos_api`: RESTful API example with HTMX integration demonstrating DELETE/PUT operations
  - `energy_dashboard`: Time-synchronized SSE dashboard showing real-time energy prices
- **Architecture Documentation**: Added comprehensive framework architecture guide (`arch.md`)

### Fixed
- **SSE Handler**: Fixed connection closure to return `Plug.Conn` instead of `:ok`
  - Prevents "expected dispatch/2 to return a Plug.Conn" error
  - Properly handles client disconnections
- **SSE Event Format**: Corrected event format for HTMX SSE extension compatibility
  - Changed from JSON-wrapped format to plain text format
  - Events now properly trigger `sse-swap` updates in HTMX

### Changed
- Removed unused `test_app` and old `todos` examples for clarity

## [0.2.3] - 2025-12-30

### Changed
- **HTMX Boost**: Added `hx-boost="true"` to body tag in all layouts (installer template and examples)
  - Automatically converts regular links to AJAX requests for smoother page transitions
  - Maintains browser history and back/forward functionality
  - Progressive enhancement: works without JavaScript
  - Users can selectively disable with `hx-boost="false"` on specific elements

## [0.2.2] - 2025-12-28

### Changed
- **Internationalization**: Translated all project documentation and code comments to English
  - Core documentation: AGENTS.md, CLAUDE.md, VERSIONING.md, CHANGELOG.md
  - Framework code: Module documentation and inline comments
  - Example projects: All README files and UI text
  - Installer documentation: CHANGELOG.md entries
  - Specifications: website.md and related docs
  - Result: Project is now fully English-ready for open source release

## [0.2.1] - 2025-12-28

### Changed
- **Version Sync**: Synchronized version number to 0.2.1, consistent with nex_new

## [0.2.0] - 2025-12-28

### Removed
- **Mix.Tasks.Nex.Release**: Removed `mix nex.release` command, switched to Docker as standard deployment method
  - Projects automatically generate Dockerfile and .dockerignore on creation
  - Simplified deployment process, unified containerization approach

### Changed
- **Documentation**: Rewrote README to clarify framework positioning and philosophy
  - Emphasized Nex is suitable for rapid prototyping, indie hackers, learning HTMX, internal tools
  - Clarified Nex is not a Phoenix competitor, not an enterprise framework
  - Highlighted CDN-first, Docker-ready design philosophy

## [0.1.6] - 2025-12-28

### Fixed
- **Framework & Installer**: Fixed version number management approach, now hardcoding version in mix.exs to completely resolve VERSION file reading issues when installed as Hex dependency

## [0.1.5] - 2025-12-28

### Fixed
- **Framework**: Fixed VERSION file reading path issue, using `__DIR__` to ensure correct version number reading when installed as dependency
- **Mix.Tasks.Nex.Start**: Added compilation step to fix 404 errors in production mode caused by unloaded modules
- **Mix.Tasks.Nex.Dev**: Optimized dependency checking logic to avoid triggering Hex compatibility issues when using path dependencies

### Changed
- **Package Metadata**: Updated GitHub repository link to `gofenix/nex`
- **Installer**: Added README.md file, improved package documentation

## [0.1.4] - 2025-12-28

### Changed
- **Installer Package**: Updated default project template to improve out-of-the-box experience
  - `layouts.ex`: Added DaisyUI CDN for semantic components (card, btn, navbar, etc.)
  - `index.ex`: Rewrote example page using DaisyUI components
  - Used semantic colors like `bg-base-100`, `bg-base-300` instead of hardcoded colors

## [0.1.3] - 2025-12-28

### Added
- **Mix.Tasks.Nex.Start**: Added production environment start command `mix nex.start`
  - Supports deployment to platforms like Railway, Fly.io, Docker
  - Reads `PORT` and `HOST` from environment variables
  - Automatically disables hot reload in production
  - Listens on `0.0.0.0` by default for container environments
- **Website**: Added `railway.json` configuration file to simplify Railway deployment
- **Website**: Restructured project, added `src/support/` directory for auxiliary modules

## [0.1.2] - 2025-12-28

### Changed
- **Mix.Tasks.Nex.Dev**: Automatically checks and installs missing dependencies to prevent startup failures due to not running `mix deps.get`
- **Mix.Tasks.Nex.New**: Automatically runs `mix deps.get` after project creation, users can directly run `mix nex.dev` to start the project

### Fixed
- **Mix.Tasks.Nex.Dev**: Fixed `app_name` type error to ensure `Application.ensure_all_started/2` receives atom type parameter

## [0.1.1] - 2025-12-28

### Fixed
- **Installer Package**: Fixed VERSION file path issue that prevented `mix archive.install hex nex_new` from working
- **Package Structure**: Both `nex_core` and `nex_new` now include their own VERSION, README.md, and CHANGELOG.md files instead of referencing parent directory

## [0.1.0] - 2025-12-28

### Published
- **Hex.pm Release**: Published `nex_core` v0.1.0 to Hex.pm at https://hex.pm/packages/nex_core/0.1.0
- **Hex.pm Release**: Published `nex_new` v0.1.0 to Hex.pm at https://hex.pm/packages/nex_new/0.1.0
- **Documentation**: Published documentation to HexDocs at https://hexdocs.pm/nex_core/0.1.0 and https://hexdocs.pm/nex_new/0.1.0

### Changed
- **Naming**: Renamed framework core package to `nex_core`, renamed project generator to `nex_new` to resolve Hex.pm naming conflicts
- **Version Management**: Installer and framework now share a single VERSION file for synchronized releases
- **Dependencies**: Added `ex_doc` as dev dependency for documentation generation

## [0.1.0] - 2025-12-28

### Added
- **Nex.CSRF**: Added CSRF protection module to prevent cross-site request forgery attacks
  - `Nex.CSRF.generate_token/0` - Generate CSRF token
  - `Nex.CSRF.input_tag/0` - Generate form hidden field
  - `Nex.CSRF.hx_headers/0` - Generate HTMX hx-headers attribute
  - `Nex.CSRF.validate/1` - Validate CSRF token in requests
  - Auto-injected into pages, HTMX requests automatically carry `X-CSRF-Token` header
  - POST requests automatically validate CSRF token
- **Nex.RouteDiscovery**: Added dynamic route discovery module supporting file-system-based automatic route discovery
  - Supports single-parameter dynamic routes `[param]` (e.g., `users/[id].ex` matches `/users/123`)
  - Supports named parameter routes `[slug]` (e.g., `posts/[slug].ex` matches `/posts/hello-world`)
  - Supports multi-parameter dynamic routes (e.g., `posts/[year]/[month].ex` matches `/posts/2024/12`)
  - Supports wildcard routes `[...path]` (e.g., `docs/[...path].ex` matches any level of path)
  - Supports mixed routes (e.g., `files/[category]/[...path].ex`)
  - Route caching mechanism (ETS), auto-refresh on file changes in development
  - Route priority sorting: static routes > dynamic routes > wildcard routes
- **Examples**: Added `dynamic_routes` example project showcasing all dynamic route types
- **Mix.Tasks.Nex.New**: Global project generator to create complete Nex projects from scratch
  - `mix nex.new my_app` - Create complete project structure (no need to run mix new first)
  - Supports specifying path `mix nex.new my_app --path ~/projects`
  - Automatically generates clean mix.exs, no need to clean up lib/ and test/
  - Packaged as Mix archive via `installer/` directory
- **Mix.Tasks.Nex.Release**: Added production build task
  - `mix nex.release` - Compile and package for deployment
  - Automatically generates optimized Dockerfile for containerized deployment

### Changed
- **Nex.Handler**: Refactored route parsing logic to prioritize `Nex.RouteDiscovery` for dynamic route matching
  - `resolve_page_module/1` now supports filename-based dynamic parameter extraction
  - `resolve_api_module/1` also supports dynamic routes
  - `resolve_action/1` supports POST actions under dynamic routes
  - Retained legacy route logic for backward compatibility
- **Nex.Reloader**: Automatically clears route cache on file changes to ensure new routes take effect immediately
- **Nex.Reloader**: Automatically disables hot reload in production
  - `Nex.Reloader.enabled?/0` checks if enabled (only in `:dev` environment)
  - Production environment does not inject live reload WebSocket script
  - Environment configured via `Application.get_env(:nex, :env)`
- **Mix.Tasks.Nex.Dev**: Refactored process startup logic, using `Nex.Supervisor` instead of manually starting individual processes
  - Before: Manually starting Store, PubSub, Reloader (no supervision)
  - Now: Unified management through `Nex.Supervisor.start_link()` (with supervision)

### Added (Earlier)
- **Nex.Supervisor**: Added framework-level supervision tree module to uniformly manage Nex core processes (Store, PubSub, Reloader)
  - Any process crash automatically restarts, improving framework reliability
  - Completely transparent to users, no additional configuration required
  - Follows OTP best practices

### Security
- **Nex.Handler**: Fixed atom exhaustion vulnerability (CVE-level security issue) by replacing `String.to_atom/1` with `String.to_existing_atom/1` for user-supplied input. This prevents attackers from crashing the server by requesting random paths like `/api/random_1`, `/api/random_2`, etc.
- **Nex.Handler**: Improved privacy by moving `page_id` from request payload to HTTP header (`X-Nex-Page-Id`), preventing exposure in browser dev tools and network logs
- **Nex.Store**: Added automatic process dictionary cleanup after each request using `Plug.Conn.register_before_send/2`, preventing potential session leakage when HTTP server processes are reused

### Performance
- **Nex.Store**: Optimized `touch_page/1` to use `:ets.match/2` instead of `:ets.foldl/3`, reducing complexity from O(n) to O(m) where m is the number of keys for a specific page. This significantly improves performance when the ETS table contains many pages.

### Removed
- **Mix.Tasks.Nex.Init**: Removed `mix nex.init` task. Now recommend using `mix nex.new` from `installer` to create projects, to maintain framework simplicity and single responsibility principle.

### Fixed
- **Nex.Env**: Fixed `.env` file loading to correctly resolve project root directory using `Mix.Project.app_path()` instead of relying on current working directory
- **Nex.Env**: Fixed environment variables not being accessible via `System.get_env/1` by explicitly setting loaded variables to system environment after Dotenvy parsing
- **Nex.Env**: Added debug logging to show which `.env` files are being loaded, their paths, and how many variables were loaded
- **Mix.Tasks.Nex.Dev**: Fixed user application not being started, which prevented application supervision trees (like Finch for HTTP clients) from running

### Added
- **Nex.SSE**: Added new `Nex.SSE` behaviour module for defining Server-Sent Events (SSE) endpoints
- **SSE Routing**: SSE endpoints can now be placed anywhere in the application structure (e.g., `src/api/chat/stream.ex`) and are identified by `use Nex.SSE` instead of requiring a specific `/sse/` path
- **SSE Handler**: Added `handle_sse_endpoint/3` function to automatically detect and handle modules that use `Nex.SSE` behaviour
- **Documentation**: Added comprehensive `application.md` guide explaining Application modules and supervision trees
- **Examples**: All example projects now include a default `Application` module template with documentation
- **Examples**: Added `chatbot_sse` example demonstrating SSE streaming with HTMX SSE extension for zero-JavaScript real-time streaming
- **Getting Started**: Updated quick start guide to include Application module setup

### Changed
- **SSE Routing**: SSE endpoints are now identified by `use Nex.SSE` behaviour instead of path-based detection, allowing SSE endpoints to coexist with JSON API endpoints at the same path structure
- **Handler**: Refactored API routing to check for SSE endpoints (via `__sse_endpoint__/0` function) before treating as regular API endpoints
- **Handler**: SSE format now supports plain text for `message` event type (for HTMX SSE extension compatibility) while maintaining JSON format for other event types
- **Nex.Env**: Improved `.env` file path resolution to work correctly regardless of where `mix nex.dev` is executed from
- **Nex.Env**: Enhanced error handling to show specific error messages when `.env` file loading fails
- **Examples**: All example projects (`chatbot`, `guestbook`, `todos`) now have `Application` modules configured in `mix.exs`
- **Live Reload**: Migrated from HTTP polling to WebSocket push for instant file change notifications without network request spam

### Deprecated
- **SSE Path Convention**: The `/sse/*` path convention is still supported for backward compatibility but is now considered legacy. New SSE endpoints should use `use Nex.SSE` and can be placed under `/api/*` or any other path structure
