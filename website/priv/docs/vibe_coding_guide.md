# AI-Assisted Development (Vibe Coding)

Nex is not just a framework; it is an architectural protocol tailored for **Vibe Coding** (Intent-Driven Development). In Nex, AI is no longer just a code completer, but a feature builder.

## 1. Why Nex is AI's Best Partner?

### Locality of Behavior (LoB)
Nex enforces the coupling of logic and UI. Within a single `.ex` file, you can see the entirety of a feature:
*   `mount/1`: Where data comes from.
*   `render/1`: What the UI looks like.
*   `Action` functions: What the interaction logic is.
**Value to AI**: AI only needs to read the context of one file to generate or modify a complete feature, completely solving the "context loss" problem caused by jumping back and forth between Controllers, Routers, and Templates.

### Zero-Config Routing (File System Routing)
**Value to AI**: Paths are routes. AI doesn't need to guess how `routes.ex` is configured. As long as it writes code in `src/pages/users/[id].ex`, it is certain that the corresponding URL is `/users/123`. This certainty significantly reduces the probability of AI generating "hallucinated" routing code.

### Function Signature Standards (CRITICAL)
**Value to AI**: AI often confuses parameter signatures between Page Actions and API Handlers.
*   **Page Action** (in `src/pages/`): Receives a flat **Map** (merged path, query, and body params).
    *   *Example*: `def add_item(%{"id" => id})`
*   **API Handler** (in `src/api/`): Receives a **`Nex.Req` struct** (mimicking Next.js, accessible via `req.query` or `req.body`).
    *   *Example*: `def get(%{query: %{"id" => id}})`
Defining this distinction prevents the AI from generating uncompilable code.

### State Management & One-Way Flow of Truth
AI should follow: **Receive Intent -> Mutate Store/DB -> Render latest state**.
*   **Nex.Store**: Server-side session state that clears on page refresh.
*   **Truth Flow**: Strictly avoid rendering UI directly based on request parameters; always use `Nex.Store.update` to update state before rendering the page.

### Real-time Streams & SSE Experience
When using `{:stream, fun}` for streaming responses (e.g., AI chat), the AI should always render an initial placeholder or "typing" state first to ensure immediate feedback.
 Nex comes with HTMX by default. If you include Alpine.js or Datastar in `layouts.ex`, the AI will also leverage their features automatically.

---

## 2. AI Tool Best Practices (Unified Rule System)

Nex advocates for "Architecture as Rules." When you create a new project with `mix nex.new`, the framework automatically generates a set of core rule files to ensure that AI assistants follow Nex's design philosophy from the very first line of code.

### A. Core Rule Files
A new project includes the following key files:
*   **`AGENTS.md`**: Defines the core principles of the framework (Locality of Behavior, File System Routing, Declarative Interaction, State Management). It serves as the "Supreme Constitution" for all AI tools (such as Cursor, Windsurf, Claude Code).
*   **`.cursorrules`**: Rules optimized specifically for **Cursor**, ensuring the AI maintains locality while generating code. It automatically references `AGENTS.md`.
*   **`CLAUDE.md`**: Provides a project overview and pattern guidance for the Claude series of tools.

### B. How to Use These Rules?
1.  **Unified Source of Truth**: Regardless of which AI tool you use, guide it to first read the `AGENTS.md` file in the root directory.
2.  **Cursor**: Cursor will automatically read `.cursorrules` when you open the project folder; no extra configuration is needed.
3.  **Other Tools**: You can directly paste the content of `AGENTS.md` to any AI assistant (such as Windsurf, GPT-4o, Claude 3.5 Sonnet) as its System Prompt.

---

## 3. Efficient Prompt Patterns

### Scenario 1: Creating a New Feature Page
> "Create a `counter.ex` under `src/pages`. Show a number in the center with plus/minus buttons below. Buttons should call `inc` and `dec` functions in the same module via `hx-post`. Use `Nex.Store` to store the value."

### Scenario 2: Adding Complex Interaction
> "Add a delete button to each row of the current `user_list`. Use `hx-delete` to call the `remove` Action. Upon success, the backend returns `:empty`, and HTMX should automatically remove that row from the DOM."

---

## 4. Common Pitfalls and AI Course Correction

When AI behaves as if it's writing traditional Phoenix or React, correct it promptly:

*   **Correction 1**: "Nex doesn't need a Router file; create files directly under `src/pages`."
*   **Correction 2**: "Do not introduce extra JavaScript libraries; prefer using the built-in HTMX. You may only use Alpine.js or Datastar if I have manually included them in the Layout."
*   **Correction 6**: "This is an API module; use the `def get(req)` signature and return `Nex.json/2`. For Page Actions, use the `def action_name(params)` signature."
*   **Correction 7**: "In forms, please use `{csrf_input_tag()}` instead of the old `input_tag()`."

## 5. Conclusion

In Nex, your role is that of an **Architect** and **Intent Describer**. By leveraging Nex's architectural certainty, you can allow AI to release unprecedented productivity.
