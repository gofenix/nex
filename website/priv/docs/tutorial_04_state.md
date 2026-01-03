# State Management (Nex.Store)

In traditional Web development, managing the state of asynchronous interactions (like shopping carts or temporary form data) can be a headache. Nex provides a simple, page-based server-side state storage mechanism called `Nex.Store`.

## 1. Core Concepts

The philosophy of `Nex.Store` is: **State should be bound to the current page lifecycle.**

*   **Ephemeral**: State is automatically reset upon a full page refresh (full page load).
*   **Persistent (During Interactions)**: State persists during asynchronous HTMX requests (Action calls).
*   **Isolation**: State is isolated between different browser tabs, even for the same page.

## 2. Common Operations

`Nex.Store` provides an interface similar to a Map:

### Reading State
```elixir
# Get the value for key :items, returning default [] if it doesn't exist
items = Nex.Store.get(:items, [])
```

### Storing State
```elixir
# Directly set the value for key :user_name
Nex.Store.put(:user_name, "Alice")
```

### Updating State
```elixir
# Update state using a function (atomic operation)
Nex.Store.update(:count, 0, &(&1 + 1))
```

### Deleting State
```elixir
Nex.Store.delete(:items)
```

## 3. How page_id Works

This is the core of Nex's state management.
1.  **Generation**: Every time you refresh the page (initiate a standard GET request), Nex generates a new random `page_id`.
2.  **Binding**: All `Nex.Store` operations are actually stored as `{page_id, key} -> value`.
3.  **Tracking**: Nex automatically injects a script into the page. When HTMX initiates a request, the script automatically adds the `X-Nex-Page-Id` header.
4.  **Invalidation**: When you click browser refresh or visit the URL directly, you get a new `page_id`. Since the old ID cannot be found, the state appears to "reset" on the server.

> **Tip**: This is the design intent of Nex—to simulate the user's temporary memory on the current page. If you need persistent state across pages or sessions, use a traditional database like PostgreSQL.

## 4. Automatic Cleanup (TTL)

To prevent memory leaks, Nex automatically cleans up expired state:
*   **Default Expiry**: 1 hour.
*   The expiry time is automatically refreshed every time state under a specific `page_id` is accessed or updated.
*   A background process on the server performs a full cleanup every 5 minutes.

## Exercise: Shopping Cart Prototype

Create `src/pages/cart.ex`:
1.  Read `:cart_items` in `mount`.
2.  Add a form to add item names.
3.  In the `add_item` Action, use `Nex.Store.update` to add the new item to the list.
4.  Observe: After adding a few items, refresh the browser. Does the cart become empty as expected?
