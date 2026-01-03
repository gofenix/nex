# Alpine.js Integration

While Nex advocates for "Server-Driven" and "Minimalist Interaction," Alpine.js is Nex's perfect partner when handling pure client-side logic (like animations, transitions, and complex modal states).

## 1. Why Use Alpine.js?

Nex handles **server communication**, while Alpine.js handles **local UI logic**.

*   **Lightweight**: No Virtual DOM, operates directly on existing HTML.
*   **Declarative**: Write logic directly in HTML via `x-data`, `x-show`, and `x-on` attributes.
*   **Zero Build**: Included directly via CDN, aligning with Nex's development philosophy.

## 2. Integration Method

Include it in the `<head>` tag of your `src/layouts.ex` (using `defer` is recommended):

```html
<script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
```

## 3. Core Application Patterns

### A. Global State and Persistence
You can define global state on the `<body>` tag and use `localStorage` for persistence (e.g., theme switching).

```elixir
# src/layouts.ex
<body
  x-data="{ theme: localStorage.getItem('theme') || 'light' }"
  x-init="$watch('theme', val => localStorage.setItem('theme', val))"
  x-bind:data-theme="theme"
>
  <button @click="theme = theme === 'light' ? 'dark' : 'light'">Toggle Theme</button>
  {raw(@inner_content)}
</body>
```

### B. Local UI State (Tabs & Modals)
Use Alpine to handle UI toggles that don't require server involvement, ensuring instant responsiveness.

```elixir
~H"""
<div x-data="{ currentTab: 'users', modalOpen: false }">
  <!-- Tab Switching -->
  <div class="tabs">
    <a :class="{ 'active': currentTab === 'users' }" @click="currentTab = 'users'">User List</a>
    <a :class="{ 'active': currentTab === 'settings' }" @click="currentTab = 'settings'">Settings</a>
  </div>

  <div x-show="currentTab === 'users'">
    <button @click="modalOpen = true; $nextTick(() => $refs.nameInput.focus())">Add User</button>
  </div>

  <!-- Modal -->
  <div x-show="modalOpen" class="modal">
    <div @click.away="modalOpen = false">
      <input x-ref="nameInput" placeholder="Enter name...">
      <button @click="modalOpen = false">Close</button>
    </div>
  </div>
</div>
"""
```

### C. Global Notifications (Toasts)
Leverage Alpine's event system for cross-component notifications.

```elixir
# Toast container in Layout
<div x-data="{ show: false, message: '' }"
     x-on:show-toast.window="show = true; message = $event.detail; setTimeout(() => show = false, 3000)"
     x-show="show">
  <span x-text="message"></span>
</div>

# Triggering a notification
<button @click="$dispatch('show-toast', 'Action successful!')">Click Me</button>
```

## 4. Working with Nex Actions

### Resetting State After Request
You can listen to HTMX lifecycle events to reset Alpine state.

```elixir
~H"""
<div x-data="{ comment: '' }">
  <form hx-post="/add_comment" @htmx:after-request="comment = ''">
    <textarea x-model="comment" name="text"></textarea>
    <button type="submit">Send</button>
  </form>
</div>
"""
```

### Partial Refresh & State Persistence
When a Nex Action returns an HTML fragment and updates the DOM, if the parent element has `x-data`, Alpine automatically re-initializes newly inserted elements.

## 6. Complete Example Project

To dive deeper into integrating Alpine.js with Nex, please refer to our official showcase project:

**[GitHub: Alpine Showcase](https://github.com/gofenix/nex/tree/main/examples/alpine_showcase)**

### Features included in this example:
*   **Theme Switching**: Managed via Alpine in `layouts.ex` with `localStorage` persistence.
*   **Client-side Tabs**: Rapid view switching without server involvement.
*   **Responsive Modals**: Includes auto-focusing (`$refs`) and click-outside-to-close interactions.
*   **Global Toast System**: Cross-component notifications using Alpine's event system.
*   **Complex Form Interaction**: Combines Nex Action's asynchronous submission with instant frontend state resetting.
