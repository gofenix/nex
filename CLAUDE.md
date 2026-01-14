# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Nex is a minimalist Elixir web framework for building HTMX applications. It consists of three packages that share synchronized version numbers:
- `framework/` - Core framework (`nex_core`)
- `installer/` - Project generator (`nex_new`)
- `nex_ai/` - AI SDK (`nex_ai`) - Standalone AI interface inspired by Vercel AI SDK

## Development Commands

```bash
# Framework development
cd framework
mix deps.get              # Install dependencies
mix test                  # Run all tests
mix test test/nex/req_test.exs  # Run single test file
mix format                # Format code

# Run dev server from framework
mix nex.dev

# Install locally built installer
mix archive.build
mix archive.install _build/dev/lib/nex_new/archives/nex_new-*.ez

# NexAI development
cd ../nex_ai
mix deps.get
mix test
mix format
```

## Architecture

### Unified `use Nex` Interface

All modules use `use Nex` which auto-detects module type by path:
- `*.Pages.*` → Page module (HEEx + CSRF imports)
- `*.Api.*` → API module (pure functions, no imports)
- `*.Components.*` → Component (HEEx + CSRF)
- `*.Layouts` → Layout (HEEx + CSRF)

### Core Modules

- `nex.ex` - Main macro, response builders (`Nex.json/2`, `Nex.stream/1`, `Nex.html/2`)
- `handler.ex` - HTTP request routing and handler invocation
- `router.ex` - Plug-compatible router
- `route_discovery.ex` - File-based routing scanner (`src/pages/`, `src/api/`)
- `store.ex` - Page-scoped state management (`Nex.Store.get/2`, `Nex.Store.put/3`)
- `csrf.ex` - Automatic CSRF token generation and validation
- `reloader.ex` - File watcher for hot reload

### Request Flow

```
Bandit HTTP Server
    ↓
Nex.Handler (plug)
    ↓
RouteDiscovery.find_route/2  (maps path to module + function)
    ↓
Handler.call/2  (invokes get/post/etc based on HTTP method)
```

### File-Based Routing

Routes are auto-discovered from `src/` directory:
- `src/pages/index.ex` → `GET /`
- `src/pages/[id].ex` → `GET /:id`
- `src/pages/[...path].ex` → `GET /{*path}`
- `src/api/todos/index.ex` → `GET/POST /api/todos`

### NexAI Architecture

NexAI is a standalone AI SDK with a provider-agnostic design:

**Core Components**:
- `core.ex` - Main API (`generate_text/1`, `stream_text/1`, `embed/1`, etc.)
- `language_model.ex` - Protocol-based model abstraction
- `message.ex` - Message types (User, Assistant, Tool calls/results)
- `protocol.ex` - Vercel AI SDK compatibility protocol

**Providers** (in `nex_ai/provider/`):
- `openai.ex` - OpenAI models (GPT-4, o1, etc.)
- `anthropic.ex` - Anthropic Claude models
- `google.ex` - Google Gemini
- `mistral.ex` - Mistral models
- `cohere.ex` - Cohere models

**Middleware** (in `nex_ai/middleware/`):
- `cache.ex` - Response caching
- `logging.ex` - Request/response logging
- `retry.ex` - Automatic retry on failure
- `rate_limit.ex` - Rate limiting
- `smooth_stream.ex` - Token smoothing for streaming
- `extract_reasoning.ex` - Extract OpenAI reasoning content

**UI Protocols** (in `nex_ai/ui/`):
- `vercel.ex` - Vercel AI SDK Data Stream format
- `datastar.ex` - DataStar protocol format

**Usage Pattern**:
```elixir
model = NexAI.openai("gpt-4o")
{:ok, stream} = NexAI.stream_text(model: model, messages: [...])
NexAI.to_data_stream(stream)  # For Vercel AI SDK frontend
```

## Conventions

- **Zero boilerplate**: CSRF tokens and headers handled automatically; do NOT add CSRF input tags manually
- **Convention over configuration**: File paths determine routes; no router config needed
- **Module naming**: Pages in `MyApp.Pages.*`, APIs in `MyApp.Api.*`, Components in `MyApp.Components.*`
- **Commit messages**: Conventional Commits format, NO triple backticks in subject

## Version Management

Version numbers are synchronized across `nex_core` and `nex_new`. When modifying either:
1. Update `/VERSION` file
2. Update `CHANGELOG.md`
3. Run `./scripts/publish_hex.sh` to sync versions and publish

## Framework Modification Policy

When creating example projects that require framework changes, do NOT modify framework code directly. Report the need for evaluation.

## See Also

- `AGENTS.md` - AI agent handbook and principles
- `VERSIONING.md` - Detailed version management documentation
- `nex_ai/README.md` - NexAI SDK documentation
- `nex_ai/IMPLEMENTATION_SUMMARY.md` - NexAI implementation details
