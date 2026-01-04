# Datastar Integration

Datastar is an ultra-lightweight declarative frontend enhancement library. It provides a minimalist way to manage frontend state through `data-signals` attributes and works seamlessly with Nex's Action mechanism.

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

## 6. Complete Example Project: Datastar Tutorial

We provide a complete, step-by-step tutorial project covering all core scenarios from basic binding to AI streaming chat:

**[GitHub: Datastar Demo](https://github.com/gofenix/nex/tree/main/examples/datastar_demo)**

### Tutorial Content and Feature Distribution:

#### 📍 Basic (Lessons 1-3)
*   **Quick Start (`index.ex`)**: Learn `data-on` event listening and simple `@post` backend Morphing updates.
*   **Reactive Signals (`signals.ex`)**: Master `data-signals` (state definition), `data-bind` (two-way binding), `data-show` (visibility), and `data-computed` (computed properties).
*   **JS Expressions (`expressions.ex`)**: Demonstrates how to use JS directly in attributes to handle strings, arrays, and logical operations.

#### 📍 Intermediate (Lessons 4-5)
*   **Requests and Merging (`requests.ex`)**: Deep dive into passing parameters via `@get`/`@post`, and list merging strategies like `data-merge="append"`.
*   **The Tao of Datastar (`tao.ex`)**: Summarizes the 6 design principles, including Hypermedia First and Backend as Source of Truth.

#### 📍 Real-world (Advanced & Apps)
*   **Advanced Features (`advanced.ex`)**:
    *   `data-init`: Automatically execute on page load (e.g., initializing long-lived connections).
    *   `data-on-intersect`: Triggered when scrolling into viewport (implements **infinite scroll/lazy loading**).
    *   `data-indicator`: Fully automatic request loading state display.
    *   `data-ref`: Direct DOM element reference for complex interactions (e.g., auto-focusing).
*   **AI Chatbot (`chat.ex`)**: Combined with Nex's `Nex.stream(fn}` return value to implement **AI word-by-word streaming responses**.
*   **Real-time Form Validation (`form.ex`)**: Complex validation logic driven by pure frontend signals, no backend round-trips required.
*   **Todo MVC (`todos.ex`)**: A comprehensive showcase of CRUD operations, client-side list filtering, and dynamic style switching.

## 7. Best Practices (Nex + Datastar)

1.  **Fine-Grained Updates**: Leverage Datastar's Morphing to return only the smallest necessary HTML fragments.
2.  **Avoid Redundant State**: For pure UI interactions (toggles, input previews), prioritize Datastar signals; for business data (saving to DB), use `@post` to call Nex Actions.
3.  **Computed Properties**: Use simple JavaScript expressions directly in `data-text` for logic composition.

## 6. Datastar vs Alpine.js

*   **Alpine.js**: Better suited for traditional UI interactions (modals, collapse menus, simple logic).
*   **Datastar**: Advantageous in handling large-scale state sharing across components and complex frontend business logic.

In a Nex project, you can choose either based on your team's preference. Nex's file system routing and Action mechanism coordinate perfectly with both.
