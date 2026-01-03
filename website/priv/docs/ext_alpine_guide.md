# Alpine.js Integration

While Nex advocates for "Server-Driven" and "Minimalist Interaction," Alpine.js is Nex's perfect partner when handling pure client-side logic (like animations, transitions, complex modal states).

## 1. Why Use Alpine.js?

Nex handles **server communication**, while Alpine.js handles **local UI logic**.

*   **Lightweight**: No Virtual DOM, operates directly on existing HTML.
*   **Declarative**: Write logic directly in HTML via `x-data`, `x-show`, `x-on` attributes.
*   **Zero Build**: Included directly via CDN, aligning with Nex's development philosophy.

## 2. Integration Method

Include it in the `<head>` tag of your `src/layouts.ex`:

```html
<script defer src="https://unpkg.com/alpinejs@3.x.x/dist/cdn.min.js"></script>
```

## 3. Common Usage Examples

### Modal Control
Manage display state using Alpine.js without sending requests to the server.

```elixir
~H"""
<div x-data="{ open: false }">
  <button @click="open = true" class="...">Open Modal</button>

  <div x-show="open" @click.away="open = false" class="fixed inset-0 bg-black/50">
    <div class="bg-white p-8 rounded">
      <h3>This is a Modal</h3>
      <button @click="open = false">Close</button>
    </div>
  </div>
</div>
"""
```

### Cooperation with Nex Action
You can have Alpine.js listen to HTMX lifecycle events. For example, clear an input box after a Nex Action returns successfully:

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

## 4. Best Practices

*   **Responsibility Division**:
    *   **Nex**: Handles form submission, database updates, page redirects, and global state storage.
    *   **Alpine**: Handles dropdown menus, tab switching, real-time search filtering (frontend only), and complex CSS animations.
*   **Locality of Behavior (LoB)**: Nex's `hx-*` attributes and Alpine's `x-*` attributes coexist in the same tag—this is exactly the mode Vibe Coding loves: seeing all interaction logic in one place.
