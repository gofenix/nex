# Changelog

All notable changes to the Nex framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2025-12-31

### Changed
- **Project Template**: Updated generated project dependency from `nex_core ~> 0.2.4` to `nex_core ~> 0.3.0`
  - New projects will use the latest framework version with standardized request/response system

## [0.2.4] - 2025-12-30

### Changed
- **Project Template**: Updated generated project dependency from `nex_core ~> 0.2.3` to `nex_core ~> 0.2.4`
  - New projects will use the latest framework version with RESTful API support and SSE fixes

## [0.2.3] - 2025-12-30

### Changed
- **Project Template**: Added `hx-boost="true"` to body tag in generated layout template
  - New projects automatically get HTMX boost for smoother page transitions
  - Converts regular links to AJAX requests while maintaining browser history
  - Progressive enhancement: gracefully degrades when JavaScript is disabled

## [0.2.2] - 2025-12-28

### Fixed
- **Mix.Tasks.Nex.New**: Updated generated project dependency from `nex_core ~> 0.1` to `nex_core ~> 0.2.2` to use latest framework version

## [0.2.1] - 2025-12-28

### Fixed
- **Mix.Tasks.Nex.New**: Fixed Documentation link in generated projects, corrected from incorrect `aspect-build/nex` to `gofenix/nex`

## [0.2.0] - 2025-12-28

### Added
- **Mix.Tasks.Nex.New**: Automatically creates Dockerfile and .dockerignore when generating projects
  - Uses Alpine Linux base image, small image size (~150-200MB)
  - Simplified single-stage build, easy to understand and maintain
  - README includes Docker deployment instructions

### Changed
- **Deployment**: Switch to Docker as standard deployment method, removed `mix nex.release` command
- **Documentation**: Updated generated project README template with Docker deployment instructions

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
- **Naming**: Renamed framework core package to `nex_core`, renamed project generator to `nex_new` to resolve Hex.pm naming conflicts.
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
