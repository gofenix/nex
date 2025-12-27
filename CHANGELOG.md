# Changelog

All notable changes to the Nex framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
