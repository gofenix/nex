# Action Routing Mechanism ⭐ Nex's Core Innovation

Nex provides a set of extremely smart and minimalist Action routing solutions, aiming to completely eliminate the tedious routing configuration in traditional Web development.

## 1. Core Concept: Locality of Behavior (LoB)

In Nex, functions that handle interactions (Actions) are tightly coupled with their corresponding UI (HEEx) within the same Elixir module. This design not only improves code maintainability but also makes AI-assisted programming much more efficient.

## 2. Single-Path Action (Referer-based)

This is Nex's default behavior and its most powerful feature.

### How It Works
When you send a POST/PUT/DELETE request to a specific Action path (e.g., `hx-post="/increment"`):
1.  **Identify Source**: Nex looks at the `Referer` in the HTTP request header (e.g., `http://localhost:4000/todos`).
2.  **Locate Module**: Based on the `Referer` path `/todos`, it finds the corresponding page module `MyApp.Pages.Todos.Index`.
3.  **Execute Function**: Executes the function with the same name as the path, `increment/1`, within the found module.

### Advantages
*   **Extreme Simplification**: You don't need to write out the full page path in `hx-post`.
*   **Logic Reuse**: If you call the same `/add` on different pages, they automatically route to the `add` function defined on their respective pages.

## 3. Multi-Path Action (Path-based)

When you need to operate on specific resources (e.g., delete, edit) or build a REST-style API, you can use multi-path Actions.

### Example
Path: `POST /users/123/delete`

### Resolution Rules
1.  **Path Prefix Resolution**: Nex resolves `/users/123` to the `MyApp.Pages.Users.Id` module (assuming the corresponding file is `src/pages/users/[id].ex`).
2.  **Extract Parameters**: Automatically extracts `id: "123"`.
3.  **Execute Action**: Resolves the last segment of the path, `delete`, and calls the `delete(%{"id" => "123"})` function in that module.

## 4. Atomic Safety (Atom Safety)

Traditional routing systems are often vulnerable to "atom overflow" attacks (maliciously crafted requests leading to exhaustion of the Erlang atom table). Nex's routing mechanism naturally defends against such attacks:

*   **Compile-time Binding**: Routing resolution only attempts to find modules and functions that **already exist in compiled form**.
*   **Deny Dynamic Generation**: Nex does not dynamically create atoms based on unknown strings at runtime.

## 5. Automatic CSRF and State Tracking

All Action requests routed through Nex automatically enjoy the following protections:
*   **CSRF Validation**: Scripts automatically inject `X-CSRF-Token`, and the server enforces validation.
*   **Automatic Page ID Carrying**: Scripts automatically inject `X-Nex-Page-Id`, ensuring `Nex.Store` state isolation takes effect.

## 6. Common Return Patterns

| Return Value | Description |
| :--- | :--- |
| `~H"""..."""` | Returns an HTML fragment for partial update. |
| `:empty` | Logic execution success, but returns no content (usually used with `hx-swap="none"`). |
| `{:redirect, "/path"}` | Triggers client-side redirect (HX-Redirect). |
| `{:refresh}` | Forces the browser to refresh the current page (HX-Refresh). |
| `Nex.stream(fn -> ... end}` | Starts an SSE real-time stream. |
