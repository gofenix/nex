# Datastar Integration

Datastar is another excellent ultra-lightweight frontend enhancement library that provides declarative state synchronization capabilities. For complex interactions that require state synchronization across elements, Datastar is a powerful choice.

## 1. Core Philosophy

Datastar binds HTML elements to a unified state store via `data-star` attributes. Its integration with Nex is similarly based on CDN inclusion, maintaining the zero-build advantage.

## 2. Integration Method

Include it in `src/layouts.ex`:

```html
<script type="module" src="https://cdn.jsdelivr.net/gh/starfederation/datastar/dist/datastar.js"></script>
```

## 3. Example: Real-Time Search Filtering

```elixir
~H"""
<div data-star="{ search: '' }">
  <input type="text" data-model="search" placeholder="Enter search term..." class="...">
  
  <ul>
    <li data-show="search == '' || 'apple'.includes(search)">Apple</li>
    <li data-show="search == '' || 'banana'.includes(search)">Banana</li>
    <li data-show="search == '' || 'cherry'.includes(search)">Cherry</li>
  </ul>
</div>
"""
```

## 4. Datastar vs Alpine.js

*   **Alpine.js**: More suitable for traditional UI interactions (modals, collapse menus, simple logic).
*   **Datastar**: Advantageous in handling large-scale state sharing across components and complex frontend business logic.

In a Nex project, you can choose either based on your team's preference. Nex's file system routing and Action mechanism can perfectly coordinate with both.
