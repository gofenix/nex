# Datastar Integration

Datastar is an ultra-lightweight declarative frontend enhancement library. It provides a minimalist way to manage frontend state through `data-signals` attributes and works seamlessly with Nex's Action mechanism.

## Quick Start

Generate a new Nex project with Datastar as the frontend:

```bash
mix nex.new my_app --frontend datastar
```

Or explore the `datastar_demo` example in the gallery for a full showcase of signals, morphing, and SSE streaming.

## 1. Core Philosophy

The heart of Datastar lies in **Signals**. It doesn't use a Virtual DOM; instead, it establishes reactive bindings by scanning HTML attributes.

*   **Zero Build**: No Node.js required, included directly via CDN.
*   **Extreme Transparency**: State is declared directly on HTML tags.
*   **Nex Synergy**: Use `@get` and `@post` expressions to call Nex Actions directly for partial DOM updates (Morphing).

## 2. Integration Method

Include the Datastar script in your `src/layouts.ex`:

```html
<script type="module" src="https://cdn.jsdelivr.net/gh/starfederation/datastar/dist/datastar.js"></script>
```

## 3. Core Application Patterns

### A. Reactive Signals and Binding
Use `data-signals` to define state, `data-bind` for two-way binding, and `data-text` to display values.

```elixir
~H"""
<div data-signals="{ name: 'Nex' }">
  <input type="text" data-bind:name class="border p-2">
  <p class="mt-2">Hello, <span data-text="$name"></span>!</p>
</div>
"""
```

### B. Backend Requests and Morphing (Crucial)
Datastar allows using `@get` or `@post` in `data-on` attributes to initiate asynchronous requests. You can pass signal values as parameters. Nex returns HTML fragments with matching `id`s, and Datastar automatically performs the Morph update.

```elixir
# Page Module
~H"""
<div data-signals="{ inputValue: '' }">
  <input type="text" data-bind:inputValue class="border">
  <!-- Send POST request with parameters -->
  <button data-on:click="@post('/process', { text: $inputValue })" class="btn">
    Process
  </button>
  <div id="result" class="mt-4 p-4 bg-gray-50">Waiting for result...</div>
</div>
"""
```

### C. Merge Strategies
Control how backend responses are merged into the existing DOM using the `data-merge` attribute.

*   **morph** (default): Smart diff-based update.
*   **append**: Append to the end.
*   **prepend**: Prepend to the beginning.

```elixir
~H"""
<div id="logs" data-merge="append" class="space-y-2">
  <button data-on:click="@post('/add_log')">Add Log</button>
  <div class="text-sm text-gray-500 italic">Logs will be appended here...</div>
</div>
"""
```

### D. JavaScript Expressions
Datastar supports standard JavaScript expressions directly within attributes. You can use this for string manipulation, mathematical operations, or array handling.

```elixir
~H"""
<div data-signals="{ x: 5, y: 3, text: 'hello' }">
  <!-- Math -->
  <div data-text="$x + $y"></div>
  
  <!-- String Methods -->
  <div data-text="$text.toUpperCase()"></div>
  
  <!-- Ternary Logic -->
  <div data-text="$x > $y ? 'X is larger' : 'Y is larger'"></div>
</div>
"""
```

## 4. The Tao of Datastar

When integrating Datastar with Nex, follow these core principles:

1.  **Hypermedia First**: Prefer returning HTML fragments from the server instead of JSON whenever possible.
2.  **Frontend Reactivity**: Use Datastar signals for UI state that doesn't need persistence (e.g., tabs, modal visibility).
3.  **Minimal JavaScript**: Use `data-*` attributes to declare behavior rather than writing imperative JS.
4.  **Smart Morphing**: Leverage Datastar's Morphing mechanism (via `id` matching) to update only changed DOM elements, preserving form focus and animations.

## 5. Datastar Directive Cheat Sheet

| Directive | Description |
| :--- | :--- |
| `data-signals` | Defines reactive state (JSON format). |
| `data-text` | Binds element text content to expression results. |
| `data-bind` | Establishes two-way binding between input and signal. |
| `data-on` | Listens for events and executes expressions (supports `@get`, `@post`, etc.). |
| `data-show` | Decides visibility based on expression result. |
| `data-class` | Dynamically adds or removes CSS classes based on signals. |
| `data-attr` | Binds HTML attributes (e.g., `disabled`). |
| `data-computed` | Defines derived signals (computed properties). |
| `data-merge` | Defines the merge strategy for backend responses (morph, append, prepend). |

## 6. Server-Side SSE Helpers

Nex provides `Nex.Datastar` helpers for sending SSE events in the Datastar wire protocol format. These work with `Nex.stream/1` out of the box.

### `Nex.Datastar.patch_elements/2`

Builds a `datastar-patch-elements` SSE event for morphing HTML fragments into the DOM.

```elixir
# In an API endpoint
def get(_req) do
  Nex.stream(fn send ->
    send.(Nex.Datastar.patch_elements(
      ~s(<div id="feed">Updated content</div>),
      selector: "#feed"
    ))
  end)
end
```

**Options:**
- `:selector` — CSS selector for the target element. If omitted, Datastar uses the fragment's `id` attribute.
- `:mode` — Merge mode: `"morph"`, `"inner"`, `"outer"`, `"prepend"`, `"append"`, `"before"`, `"after"`, `"upsertAttributes"`.
- `:use_view_transition` — Whether to use view transitions (boolean, default `false`).

### `Nex.Datastar.patch_signals/2`

Builds a `datastar-patch-signals` SSE event for updating reactive signals on the client.

```elixir
send.(Nex.Datastar.patch_signals(%{count: 42, status: "active"}))
```

**Options:**
- `:only_if_missing` — Only set signals that don't already exist on the client (boolean, default `false`).

### Complete Streaming Example

```elixir
defmodule MyApp.Api.Stream do
  use Nex

  def get(_req) do
    Nex.stream(fn send ->
      Enum.each(1..10, fn i ->
        # Update DOM
        send.(Nex.Datastar.patch_elements(
          ~s(<div id="counter">#{i}</div>),
          selector: "#counter"
        ))

        # Update client signals
        send.(Nex.Datastar.patch_signals(%{count: i}))

        Process.sleep(1_000)
      end)
    end)
  end
end
```

## 7. Complete Example Project

See the `datastar_demo` example in the gallery for a working demonstration of:

- **Reactive Signals** — Client-side reactivity with `data-signals`, `data-bind`, and `data-text`
- **Backend Morphing** — Sending data to the server and morphing HTML fragments back
- **SSE Streaming** — Real-time updates using `Nex.Datastar.patch_elements/2` and `patch_signals/2`

## 8. Best Practices (Nex + Datastar)

1.  **Fine-Grained Updates**: Leverage Datastar's Morphing to return only the smallest necessary HTML fragments.
2.  **Avoid Redundant State**: For pure UI interactions (toggles, input previews), prioritize Datastar signals; for business data (saving to DB), use `@post` to call Nex Actions.
3.  **Computed Properties**: Use simple JavaScript expressions directly in `data-text` for logic composition.

## 9. Datastar vs Alpine.js

*   **Alpine.js**: Better suited for traditional UI interactions (modals, collapse menus, simple logic).
*   **Datastar**: Advantageous in handling large-scale state sharing across components and complex frontend business logic.

In a Nex project, you can choose either based on your team's preference. Nex's file system routing and Action mechanism coordinate perfectly with both.
