# Nex JSON API Development Guide

Nex has built-in support for JSON APIs, making it easy to provide data interfaces for mobile apps or third-party services.

## Table of Contents

- [Routing Rules](#routing-rules)
- [Request Handling](#request-handling)
- [Return Value Format](#return-value-format)

---

## Routing Rules

API route files are located in the `src/api/` directory, and all URLs automatically get the `/api/` prefix.

| File Path | HTTP URL |
| :--- | :--- |
| `src/api/users.ex` | `/api/users` |
| `src/api/posts/[id].ex` | `/api/posts/123` |

---

## Request Handling

API modules need to `use Nex.Api`. You need to define functions named after HTTP methods (`get`, `post`, `put`, `delete`, etc.).

*   **No Params**: Define `def get do ... end`
*   **With Params**: Define `def post(params) do ... end`

```elixir
defmodule MyApp.Api.Todos.Index do
  use Nex.Api

  # GET /api/todos
  def get do
    todos = Nex.Store.get(:todos, [])
    %{data: todos}
  end

  # POST /api/todos
  def post(%{"text" => text}) do
    todo = %{id: System.unique_integer(), text: text}
    Nex.Store.update(:todos, [], &[todo | &1])
    
    # Return custom status code
    {201, %{data: todo}}
  end
  
  # Parameter validation example
  def post(_params) do
    {:error, 400, "Missing text parameter"}
  end
end
```

---

## Return Value Format

`Nex.Api` automatically serializes return values to JSON and sets `Content-Type: application/json`.

| Return Value (Elixir) | HTTP Status | JSON Body | Description |
| :--- | :--- | :--- | :--- |
| `%{key: "val"}` | 200 | `{"key": "val"}` | Default success response |
| `{201, %{...}}` | 201 | `{"..."}` | Custom status code |
| `{:error, 404, "msg"}` | 404 | `{"error": "msg"}` | Error response shorthand |
| `:empty` | 204 | (No Content) | No content success response |
| `:method_not_allowed` | 405 | `{"error": "Method Not Allowed"}` | Method not supported |
