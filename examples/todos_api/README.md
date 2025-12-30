# Todos API Demo

This example demonstrates **HTMX calling API endpoints** with HTML fragments generated from Partial components.

## Architecture

```
HTMX Request
     │
     ▼
API Module (uses Partial)
     │
     ▼
Partial Component (generates HTML)
     │
     ▼
HTML Fragment (returned to HTMX)
```

## Flow

1. HTMX sends `POST /api/todos`
2. API creates todo and calls Partial
3. Partial renders `<.todo_item />`
4. API returns HTML fragment to HTMX
5. HTMX swaps into DOM

## Code Structure

```
src/
├── pages/index.ex              # Main page, renders initial HTML
├── partials/todos/item.ex      # Reusable <.todo_item /> component
└── api/todos/index.ex          # API, uses Partial to return HTML
```

## Key Code

**API** (`src/api/todos/index.ex`):
```elixir
def post(_conn, %{"text" => text}) do
  todo = %{id: ..., text: text, completed: false}
  Nex.Store.update(:todos, [], &[todo | &1])
  ~H"<.todo_item todo={todo} />"  # Uses Partial
end
```

**Partial** (`src/partials/todos/item.ex`):
```elixir
def todo_item(assigns) do
  ~H"""
  <li id={"todo-#{@todo.id}"}>
    {@todo.text}
  </li>
  """
end
```

**Page** (`src/pages/index.ex`):
```elixir
<form hx-post="/api/todos"
      hx-target="#todo-list"
      hx-swap="beforeend">
  ...
</form>

<ul id="todo-list">
  <.todo_item :for={todo <- @todos} todo={todo} />
</ul>
```

## Running

```bash
cd examples/todos_api
mix deps.get
mix nex.start
```

Visit http://localhost:4000
