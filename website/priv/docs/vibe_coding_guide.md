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

### Declarative Interaction (HTMX/Datastar)
**Value to AI**: Generating HTML attributes is much more robust for AI than generating complex JavaScript asynchronous flows (Promises/Async). AI's accuracy in writing declarative code is close to 100%.

---

## 2. Developer Tool Best Practices

To let AI tools like **Cursor**, **Windsurf**, and **Claude Code** guide Nex development more precisely, we recommend configuring rule files in your project root.

### A. Cursor Configuration (.cursorrules)
Create a `.cursorrules` file in your project root and paste the following:

```markdown
You are an expert Nex framework developer. Follow these rules:
1. Locality: Keep UI and logic in the same file (src/pages or src/api).
2. Routing: Files in src/pages/ are GET routes. [id].ex is dynamic. [...path].ex is catch-all.
3. Actions: Handle POST/PUT/DELETE by defining functions in the same module. Use hx-post="/func_name" for single-path.
4. State: Use Nex.Store.get/put/update(key, default, fun) for page-level state.
5. API 2.0: API modules must return Nex.Response (use Nex.json/2).
6. Layout: Layouts must have <body> tag. Use {raw(@inner_content)} to render page.
```

### B. Windsurf / Codex Prompts
At the start of a conversation, you can send this "Framework Persona":

> "This is a Nex project. It uses file system routing (src/pages for GET, src/api for JSON). Interactions use declarative Actions—functions defined within the page module and called via HTMX's hx-post. State management uses Nex.Store based on Page ID. Always maintain code locality."

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
*   **Correction 2**: "Don't introduce extra JavaScript libraries; prefer solving interactions with HTMX or Alpine.js attributes."
*   **Correction 3**: "Don't store state in memory variables; use `Nex.Store` to ensure persistence across interactions."

## 5. Conclusion

In Nex, your role is that of an **Architect** and **Intent Describer**. By leveraging Nex's architectural certainty, you can allow AI to release unprecedented productivity.
