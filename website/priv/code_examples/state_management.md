# Nex State Management Guide

Nex uses a unique **Page-Scoped State** mechanism, combining the stateless nature of server-side rendering with the stateful experience of SPAs.

## Table of Contents

- [Core Concepts](#core-concepts)
- [State Lifecycle](#state-lifecycle)
- [Nex.Store API](#nexstore-api)
- [State Cleanup Mechanism](#state-cleanup-mechanism)
- [Best Practices](#best-practices)

---

## Core Concepts

Traditional server-side rendered Web frameworks are typically stateless, where each request is independent. Technologies like LiveView, on the other hand, maintain persistent process state on the server.

Nex chooses a middle ground: **ETS-based Temporary Page State**.

1.  **Page ID**: The framework generates a unique `_page_id` when each page loads.
2.  **Automatic Propagation**: This ID is automatically passed in every request via HTMX (`X-Nex-Page-Id` header).
3.  **Independent Storage**: State is stored in memory (ETS), isolated by `page_id`.

This means:
*   **Reset on Refresh**: Refreshing the browser generates a new `page_id`, and old state is lost.
*   **Multi-Tab Isolation**: The same URL opened in two tabs has independent states.
*   **No Persistent Connection**: No WebSocket is needed to maintain state, making it more suitable for Serverless environments.

---

## State Lifecycle

1.  **Creation**: `page_id` is generated on the first GET request to the page.
2.  **Usage**: HTMX interactions (clicks, forms) on the page carry the `page_id`, and the backend reads/writes state via `Nex.Store`.
3.  **Expiration**: State has a TTL (default 1 hour). Each access refreshes the TTL.
4.  **Destruction**: State is cleared if not accessed beyond the TTL, or if the server restarts.

---

## Nex.Store API

Nex provides a simple Key-Value API to manage state.

### Get State `get/2`

```elixir
# Get value, return default if not exists
count = Nex.Store.get(:count, 0)
```

### Set State `put/2`

```elixir
Nex.Store.put(:user, %{name: "Alice"})
```

### Update State `update/3`

Atomic update operation to avoid concurrency race conditions.

```elixir
# update(key, default_value, update_function)
Nex.Store.update(:count, 0, fn count -> count + 1 end)
# Shorthand
Nex.Store.update(:count, 0, &(&1 + 1))
```

### Delete State `delete/1`

```elixir
Nex.Store.delete(:temp_data)
```

---

## State Cleanup Mechanism

Nex internally starts a GenServer to periodically clean up expired state to prevent memory leaks.

*   **Default TTL**: 1 hour (`:timer.hours(1)`)
*   **Cleanup Interval**: 5 minutes (`:timer.minutes(5)`)
*   **Touch Mechanism**: Every `Nex.Store` operation (read or write) "touches" the current page, resetting its TTL.

**Note**: Since state is stored in memory (ETS), if the application is deployed across multiple nodes without sticky sessions, or if the application restarts, state will be lost. Nex is suitable for storing **temporary UI state** (like form steps, UI toggles, instant counters); persistent data should always be stored in a database.

---

## Best Practices

1.  **Distinguish State Types**:
    *   **Temporary UI State** -> `Nex.Store` (e.g., dropdown open/close, unsaved form drafts)
    *   **Business Data** -> Database (Postgres/SQLite)

2.  **Do Not Abuse Store**:
    Do not store large amounts of data (like an entire user list) in the Store, as this consumes server memory. Store IDs and query the database when needed.

3.  **Initialization**:
    Always initialize required Store state in the `mount/1` function, or handle the case where `get/2` returns `nil`.

```elixir
def mount(_params) do
  # Recommended: Initialize on page load
  %{
    count: Nex.Store.get(:count, 0),
    items: fetch_items_from_db() # Query business data directly from DB
  }
end
```
