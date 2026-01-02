# Nex Framework HTMX Integration Guide

The Nex framework was built around HTMX from the ground up. This guide explains how to use HTMX in Nex to build dynamic, server-driven user interfaces.

## Table of Contents

- [Core Concepts](#core-concepts)
- [Basic Interaction](#basic-interaction)
- [Passing Parameters](#passing-parameters)
- [Form Handling](#form-handling)
- [State Persistence (Nex.Store)](#state-persistence-nexstore)
- [CSRF Protection](#csrf-protection)
- [Action Return Values](#action-return-values)
- [Real-time Streaming (SSE)](#real-time-streaming-sse)

---

## Core Concepts

The usage pattern of HTMX in Nex is very straightforward:

1.  **Trigger**: The frontend uses `hx-post="/action_name"` to trigger a request.
2.  **Handle**: The backend Page module defines a public function with the same name: `def action_name(params)`.
3.  **Update**: The function returns a HEEx template fragment, which the frontend inserts into the DOM via `hx-target` and `hx-swap`.

**No API routing required**, no JSON serialization logic required. Everything is an exchange of HTML fragments.

---

## Basic Interaction

### Example: Counter

**Frontend (src/pages/index.ex):**
```elixir
<div id="counter">{@count}</div>

<button hx-post="/increment"
        hx-target="#counter"
        hx-swap="outerHTML">
  +1
</button>
```

**Backend (src/pages/index.ex):**
```elixir
def increment(_params) do
  # 1. Update state
  new_count = Nex.Store.update(:count, 0, &(&1 + 1))
  
  # 2. Construct assigns (Action functions do not inherit old assigns automatically)
  assigns = %{count: new_count}
  
  # 3. Return updated HTML fragment
  ~H"<div id=\"counter\">{@count}</div>"
end
```

---

## Passing Parameters

In addition to form inputs, you can use `hx-vals` to pass extra parameters.

**Frontend:**
```elixir
<button hx-post="/delete_item"
        hx-vals={Jason.encode!(%{id: @item.id, type: "pro"})}
        hx-target={"#item-#{@item.id}"}
        hx-swap="outerHTML">
  Delete
</button>
```

**Backend:**
```elixir
def delete_item(%{"id" => id, "type" => type}) do
  # id and type can be retrieved from params
  delete_db_item(id, type)
  :empty
end
```

---

## Form Handling

For form submissions, use standard `hx-post`.

**Frontend:**
```elixir
<form hx-post="/add_todo"
      hx-target="#todo-list"
      hx-swap="beforeend"
      hx-on::after-request="this.reset()">
  <input type="text" name="text" required />
  <button>Add</button>
</form>

<ul id="todo-list">
  <!-- List content -->
</ul>
```

**Backend:**
```elixir
def add_todo(%{"text" => text}) do
  todo = create_todo(text)
  assigns = %{todo: todo}
  
  # Return only the new li element, which will be appended to ul
  ~H"<li>{@todo.text}</li>"
end
```

---

## State Persistence (Nex.Store)

Nex provides **Page-Scoped** state management.

*   **Page ID**: The framework automatically generates a unique Page ID for each page.
*   **Automatic Propagation**: The framework automatically intercepts all HTMX requests and injects `X-Nex-Page-Id` in the header.
*   **Backend Retrieval**: The backend restores the current page's state based on the Page ID.

This means you can maintain state across multiple HTMX interactions (e.g., counter value, shopping cart contents) without manually passing state in URLs or Hidden Inputs.

**Usage Example:**
```elixir
def mount(_params) do
  # Initialize state
  %{count: Nex.Store.get(:count, 0)}
end

def increment(_params) do
  # Get and update current page state
  new_count = Nex.Store.update(:count, 0, &(&1 + 1))
  # ...
end
```

---

## CSRF Protection

Nex framework has built-in CSRF protection mechanisms for HTMX.

*   **Automatic Injection**: When the page loads, the framework injects a JavaScript snippet.
*   **Event Listening**: Listens for `htmx:configRequest` events.
*   **Header Setting**: Automatically puts the CSRF Token into the `X-CSRF-Token` request header.

**Developers only need to do one thing**:
When writing `hx-post` requests, you **do not** need to manually add `_csrf_token` parameters or hidden inputs. The framework handles it automatically.

---

## Action Return Values

Action functions can return several types, and the framework automatically handles response headers:

| Return Value | HTTP Status | Behavior | Typical Scenario |
| :--- | :--- | :--- | :--- |
| `~H"..."` (HEEx) | 200 | Returns HTML fragment | Partial UI update |
| `:empty` | 200 (Empty Body) | No content update | Deleting elements (with `hx-swap="delete"`) |
| `{:redirect, path}` | 200 | Triggers frontend redirect | Login success, operation complete |
| `{:refresh, opts}` | 200 | Triggers frontend refresh | Resetting page state |

**Code Examples**:

```elixir
# 1. Return HTML
def update(params), do: ~H"..."

# 2. Delete (Used with hx-target="#id" hx-swap="outerHTML" on frontend)
# Note: To remove an element, typically return empty string or use hx-swap="delete"
def delete(_params), do: :empty

# 3. Redirect (Sets HX-Redirect header)
def login(_params), do: {:redirect, "/dashboard"}

# 4. Refresh Page (Sets HX-Refresh header)
def reset(_params), do: {:refresh, []}
```

---

## Real-time Streaming (SSE)

Nex combined with HTMX's SSE extension (`hx-ext="sse"`) can implement typewriter effects similar to ChatGPT.

**Frontend:**
```elixir
<!-- Connect to SSE endpoint -->
<div hx-ext="sse" sse-connect="/api/sse/stream?message=hello" sse-swap="message">
  <!-- Server pushed content will update here -->
</div>
```

**Backend (SSE Endpoint):**
In `src/api/sse/stream.ex`:
```elixir
defmodule MyApp.Api.Sse.Stream do
  use Nex

  def stream(params, send_fn) do
    # Simulate streaming push
    send_fn.(%{event: "message", data: "He"})
    Process.sleep(100)
    send_fn.(%{event: "message", data: "llo"})
    :ok
  end
end
```

**Note**:
*   SSE endpoints need to implement the `stream/2` callback.
*   HTMX's SSE extension automatically handles connection and message receipt.
