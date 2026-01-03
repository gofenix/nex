# Building JSON APIs

Nex is not only great at generating HTML but also an ideal choice for building high-performance JSON APIs. The Nex API specification enforces a set of standards to ensure API response consistency, robustness, and a great developer experience.

## 1. API Routing and Structure

API files are stored in the `src/api/` directory. URL paths are automatically prefixed with `/api`.

*   `src/api/users.ex` -> `/api/users`
*   `src/api/products/[id].ex` -> `/api/products/123`

## 2. API Enforced Specifications

In Nex, to unify response formats, we have established the following enforced rules:

1.  **Must Return `Nex.Response` Struct**: Action functions can no longer return raw Maps or Lists.
2.  **Use Helper Functions**: You must use helper functions like `Nex.json/2`, `Nex.text/2`, `Nex.redirect/2` to build responses.
3.  **Function Signature**: API handler functions receive a `Nex.Req` struct, which contains fields like `body`, `query`, and `params`.

### Correct Example

```elixir
defmodule MyApp.Api.Todos do
  use Nex

  # GET /api/todos
  def get(req) do
    todos = MyApp.Repo.all_todos()
    Nex.json(todos) # Returns a Nex.Response struct
  end

  # POST /api/todos
  def post(req) do
    # Use req.body to get submitted data
    case MyApp.Repo.create_todo(req.body) do
      {:ok, todo} -> 
        Nex.json(todo, status: 201)
      {:error, reason} -> 
        Nex.json(%{error: reason}, status: 422)
    end
  end
end
```

## 3. Nex.Req Struct Analysis

The `req` parameter provides unified access to request data:

*   **`req.body`**: Body content of POST/PUT requests (usually a parsed Map).
*   **`req.query`**: Query parameters in the URL (e.g., `?search=nex`).
*   **`req.params`**: Dynamic parameters in the URL path (e.g., `[id]`).
*   **`req.headers`**: Request header information.

## 4. Smart Error Handling Mechanism

When your API code throws an exception or returns an incorrect format, Nex's `Handler` intervenes and provides valuable feedback:

*   **Development Mode (`:dev`)**: Returns a JSON containing detailed error descriptions, stack traces, and an "expected response format" tip.
*   **Production Mode (`:prod`)**: Returns generic error information to ensure security.

### Example Error Response
```json
{
  "error": "Internal Server Error: API signature mismatch",
  "expected": "Nex.Response struct (e.g., Nex.json(%{data: ...}))",
  "details": "..."
}
```

## 5. Response Helper Function Reference

| Function | Description |
| :--- | :--- |
| `Nex.json(data, opts)` | Returns a JSON response. `opts` can include `:status`. |
| `Nex.text(string, opts)` | Returns a plain text response. |
| `Nex.html(content, opts)` | Returns an HTML response (Content-Type: text/html). |
| `Nex.redirect(to, opts)` | Sends a standard 302 redirect. |
| `Nex.status(code)` | Returns only the specified HTTP status code. |
