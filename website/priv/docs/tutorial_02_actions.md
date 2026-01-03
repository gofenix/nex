# Adding Interaction (Action)

Action is one of Nex's core innovations. It allows you to define functions that handle asynchronous requests (POST, PUT, DELETE) directly in the page module, without leaving the context of the current file.

## 1. What is an Action?

In traditional Web development, handling button clicks or form submissions usually requires defining routes, controllers, and response logic. In Nex, all of this is simplified into **Action functions**.

*   **Locality**: Interaction logic and UI are defined in the same file.
*   **Declarative Interaction**: Actions default to sending asynchronous requests via declarative tools like HTMX, without writing JavaScript.
*   **No mount**: Actions are called directly and don't require re-executing the page's `mount` or a full-page render.

## 2. Single-Path Action (Referer-based)

This is the most common Action pattern. You simply specify `hx-post="/function_name"` in the HTML, and Nex automatically finds the corresponding page module based on the request source (Referer) and executes that function.

### Example: Counter

Create `src/pages/counter.ex`:

```elixir
defmodule MyApp.Pages.Counter do
  use Nex

  def mount(_params) do
    # Get current value from state, default to 0
    %{count: Nex.Store.get(:count, 0)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-8 border rounded shadow">
      <h2 class="text-xl">Current Count: <span id="count">{@count}</span></h2>
      
      <!-- Click to send POST request to /increment -->
      <button hx-post="/increment"
              hx-target="#count"
              class="mt-4 px-4 py-2 bg-blue-500 text-white rounded">
        Increment +1
      </button>
    </div>
    """
  end

  # Define function with same name as hx-post path
  def increment(_params) do
    # Update server-side state
    new_count = Nex.Store.update(:count, 0, &(&1 + 1))
    
    # Return a string or HEEx fragment to replace hx-target content
    "#{new_count}"
  end
end
```

## 3. Multi-Path Action (Path-based)

If you need RESTful paths or need to pass IDs in the URL, use multi-path Actions.

### Example: Delete Message

Path: `POST /messages/123/delete`

Nex resolves this as follows:
1.  Find `src/pages/messages/[id].ex` (or `src/pages/messages/index.ex`).
2.  Extract parameter `id: "123"`.
3.  Call the `delete/1` function in that module.

```elixir
def delete(%{"id" => id}) do
  # Execute deletion logic
  # ...
  :empty  # Return :empty to indicate success without updating any DOM
end
```

## 4. Action Return Types

Actions can return various types of values, and Nex handles the HTTP response accordingly:

| Return Type | Effect | Status Code |
| :--- | :--- | :--- |
| **String / HEEx** | Returns HTML fragment for partial update | 200 OK |
| **`:empty`** | Returns empty content, no DOM update | 200 OK |
| **`{:redirect, url}`** | Triggers client-side redirect via HTMX | 200 OK + HX-Redirect |
| **`{:refresh}`** | Triggers full-page refresh | 200 OK + HX-Refresh |
| **`{:stream, fn}`** | Starts SSE stream response | 200 OK + SSE |

## Exercise: Advanced Counter

Add a "Reset" button to the counter page:
1.  Use `hx-post="/reset"`.
2.  Define `reset/1` in the module.
3.  Logic: Set `Nex.Store.put(:count, 0)`.
4.  Return: Use `{:refresh}` to observe the full page refresh.
