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

---

## AI Saga Project: Critical Lessons Learned

### Database & Data Integrity

**CRITICAL: Always verify database configuration first**
- This project uses **PostgreSQL (Supabase)**, NOT SQLite
- Check `.env` file for `DATABASE_URL` to confirm database type
- `NexBase` supports both PostgreSQL and SQLite, but project configuration determines which is used
- Never assume database type based on dependency presence in `deps/`

**Duplicate Data Prevention**
- Always add uniqueness constraints at database level AND application level
- For `papers` table: check `arxiv_id` uniqueness before insert
- Example check in `save_paper`:
  ```elixir
  case NexBase.from("papers") |> NexBase.eq(:arxiv_id, arxiv_id) |> NexBase.single() |> NexBase.run() do
    {:ok, [existing]} -> {:error, "论文已存在"}
    _ -> # proceed with insert
  end
  ```

**Data Cleanup Scripts**
- When writing cleanup scripts, always:
  1. Query to find duplicates first
  2. Show what will be deleted
  3. Delete duplicates keeping oldest record (MIN(id))
  4. Verify deletion count matches expectation
- Use title-based deduplication when `arxiv_id` may be NULL

### SSE & Real-time Features

**Native EventSource vs HTMX SSE**
- Use native JavaScript `EventSource` API, NOT HTMX SSE extension
- HTMX SSE has auto-reconnect issues causing infinite loops
- Always close EventSource connection on `done` event
- Use `hasError` flag to prevent duplicate close/error handling

**SSE Event Flow**
```javascript
var eventSource = new EventSource('/api/stream');
var hasError = false;

eventSource.onmessage = function(e) { /* append message */ };

eventSource.addEventListener('done', function(e) {
  if (!hasError) {
    hasError = true;
    eventSource.close();
    // update UI based on e.data (success/error)
  }
});

eventSource.onerror = function() {
  if (!hasError) {
    hasError = true;
    eventSource.close();
    // show error UI
  }
};
```

### AI Prompt Design

**Unified Prompts > Conditional Prompts**
- Don't split prompts into separate functions based on conditions
- Instead, build one unified prompt that adapts based on available data
- Example: Show HuggingFace candidates if available, otherwise show classic paper guidance
- Let AI see all context and make decisions, don't pre-filter too aggressively

**Prompt Priority Logic**
- Clearly state priority in prompt: "优先从X推荐，如果X为空则从Y推荐"
- Provide fallback options within same prompt
- Trust AI to follow instructions rather than hardcoding fallback lists

### Common Debugging Mistakes

**❌ Wrong: Assuming SQLite based on file structure**
- Seeing `sqlite:data/` directory doesn't mean project uses SQLite
- Always check actual `.env` DATABASE_URL

**❌ Wrong: Writing separate cleanup scripts for SQLite**
- Wasted time writing SQLite-specific cleanup code
- Should have verified database type first

**❌ Wrong: Querying wrong database instance**
- Spent time debugging "no duplicates found" when duplicates existed
- Issue: Was querying with wrong assumptions about database type
- Fix: Use Playwright to verify actual page content, then trace back to data source

**✅ Right: Verify with browser automation**
- Use Playwright to see actual rendered page
- Count elements with JavaScript: `document.querySelectorAll('.card').length`
- Compare browser reality with database queries to find discrepancies

### Button State Management

**Disable buttons during async operations**
```html
<button disabled class="opacity-50 cursor-not-allowed">
  ⏳ 生成中...
</button>
```

**Update button on completion**
- Listen for SSE `done` event
- Update button text and style based on success/error
- Remove `disabled` attribute or replace button entirely

### Error Handling

**Always send `done` event in all code paths**
- Success path: `send.(%{event: "done", data: "success"})`
- Error path: `send.(%{event: "done", data: "error"})`
- This ensures UI always updates, never stuck in loading state
