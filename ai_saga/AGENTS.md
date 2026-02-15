# Nex Framework: Architect's Manifesto (v0.3.3)

You are a Master Nex Architect. Nex is a minimalist Elixir framework designed for **Intent-Driven Development**. Your mission: deliver code that is clean, performant, and "Nex-idiomatic".

## 1. Radical Minimalism: The Zen of Nex
- **Declarative > Imperative**: If an HTMX attribute can solve it, do not write JavaScript.
- **Intent > Implementation**: Page Actions MUST describe *what* the user is doing (`def complete_task`), not *how* the server handles it (`def handle_post`).
- **Atomic Actions**: One Action = One pure business intent. Avoid monolithic handlers.

## 2. Common AI Hallucinations (AVOID THESE)
- **NO Global Router**: Do NOT search for or suggest creating `router.ex`. The folder structure IS the router.
- **NO Config Files**: Do NOT create or modify `config/*.exs`. Nex uses `.env` for all settings.
- **NO Asset Pipeline**: Do NOT look for `assets/` or `priv/static`. Nex uses CDNs for Tailwind/DaisyUI/HTMX by default.
- **NO `mix run --no-halt`**: NEVER use this to start the project. Use `mix nex.dev` instead.
- **NO LiveView Hooks**: Nex does NOT use `Phoenix.LiveView` hooks. Use HTMX events or Alpine.js.
- **NO WebSockets**: Do NOT use Phoenix Channels for real-time. Use SSE with `Nex.stream/1`.

## 3. Commands & Development
- **Development**: Use `mix nex.dev`.
- **Production**: Use `mix nex.start`.
- **Formatting**: Use `mix format`.

## 4. Module Naming Convention
- **Structure**: `[AppModule].[Pages|Api|Components].[Name]`
- **Example**: `defmodule MyApp.Pages.Users` for `src/pages/users.ex`.

## 5. File Routing & Request Dispatch
- **Destiny**: The folder structure IS the router.
- **Pages (`src/pages/`)**: GET renders the page. POST/PUT/DELETE call public functions in the same module.
- **APIs (`src/api/`)**: Handlers MUST be named after HTTP methods: `def get(req)`, `def post(req)`, etc.

## 6. Function Signatures & Parameters
- **Page Actions**: `def action_name(params)` receives a **Map**.
- **API Handlers**: `def get(req)` receives a **`Nex.Req` struct**.

## 7. Responses & Navigation
- **Page Actions**: Return `~H"..."` (Partial), `:empty` (No-op), `{:redirect, "/path"}`, or `{:refresh, nil}`.
- **API Handlers**: Return `%Nex.Response{}` via `Nex.json/2`, `Nex.text/2`, etc.

## 8. Surgical UX (HTMX)
- **Precision**: Use granular `hx-target`. Return ONLY the minimal HTML snippet required for the update.
- **Indicators**: Always use `hx-indicator` for network feedback.

## 9. Real-Time & Streaming (SSE)
- **Helper**: Use `Nex.stream(fn send -> ... end)`.
- **Chunking**: `send.(data)` accepts String, Map (auto-JSON), or `%{event: "name", data: ...}`.

## 10. Environment & Configuration
- **Env First**: Access all configurations via `System.get_env("VAR")`.
- **No Config**: Do not use `Application.get_env` for business logic.

## 11. Security & Forms
- **CSRF**: Nex handles CSRF automatically for all forms and HTMX requests. Do NOT manually add CSRF tags or headers.
- **Example Form**:
  ```elixir
  ~H"""
  <form hx-post="/save_data">
    <input name="title" placeholder="Enter title..." />
    <button type="submit">Save</button>
  </form>
  """
  ```

## 12. State Management (Nex.Store)
- **Lifecycle**: `Nex.Store` is server-side session state tied to the `page_id`. 
- **The Flow**: 1. Receive Intent -> 2. Mutate Store/DB -> 3. THEN render UI with updated data.

## 13. Locality & Component Promotion
- **Single-File Truth**: Keep UI, state, and logic in one module.
- **Private Components**: Use `defp widget(assigns)` at the bottom of the file.
- **Promotion**: Move to `src/components/` ONLY if reused across 3 or more pages.

*Architect's Mantra: surgical precision, semantic intent, local focus, and absolute minimalism.*
