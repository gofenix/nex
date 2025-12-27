# Changelog

All notable changes to the Nex framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Nex.Supervisor**: 新增框架层监督树模块，统一管理 Nex 核心进程（Store、PubSub、Reloader）
  - 任何进程崩溃会自动重启，提高框架可靠性
  - 对用户完全透明，无需额外配置
  - 符合 OTP 最佳实践

### Changed
- **Mix.Tasks.Nex.Dev**: 重构进程启动逻辑，使用 `Nex.Supervisor` 替代手动启动单个进程
  - 原来：手动启动 Store、PubSub、Reloader（无监督）
  - 现在：通过 `Nex.Supervisor.start_link()` 统一管理（有监督）

### Security
- **Nex.Handler**: Fixed atom exhaustion vulnerability (CVE-level security issue) by replacing `String.to_atom/1` with `String.to_existing_atom/1` for user-supplied input. This prevents attackers from crashing the server by requesting random paths like `/api/random_1`, `/api/random_2`, etc.
- **Nex.Handler**: Improved privacy by moving `page_id` from request payload to HTTP header (`X-Nex-Page-Id`), preventing exposure in browser dev tools and network logs
- **Nex.Store**: Added automatic process dictionary cleanup after each request using `Plug.Conn.register_before_send/2`, preventing potential session leakage when HTTP server processes are reused

### Performance
- **Nex.Store**: Optimized `touch_page/1` to use `:ets.match/2` instead of `:ets.foldl/3`, reducing complexity from O(n) to O(m) where m is the number of keys for a specific page. This significantly improves performance when the ETS table contains many pages.

### Removed
- **Nex.Router.Compiler**: Removed unused 100+ line module that was never called. All routing is handled at runtime by `Nex.Handler` for better flexibility and hot reload support.

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
