# JSON API Guide

Nex provides a JSON API system that is **100% aligned with Next.js API Routes**, making it familiar for developers coming from the JavaScript ecosystem while leveraging Elixir's power.

## Table of Contents

- [Quick Start](#quick-start)
- [Next.js API Routes Alignment](#nextjs-api-routes-alignment)
- [Routing](#routing)
- [Request Object](#request-object)
- [Response Helpers](#response-helpers)
- [HTTP Methods](#http-methods)
- [Dynamic Routes](#dynamic-routes)
- [Error Handling](#error-handling)
- [Complete Example](#complete-example)

---

## Quick Start

Create an API endpoint in `src/api/hello.ex`:

```elixir
defmodule MyApp.Api.Hello do
  use Nex

  def get(req) do
    name = req.query["name"] || "World"
    Nex.json(%{message: "Hello, #{name}!"})
  end

  def post(req) do
    name = req.body["name"]
    
    if is_nil(name) or name == "" do
      Nex.json(%{error: "Name is required"}, status: 400)
    else
      Nex.json(%{message: "Hello, #{name}!"}, status: 201)
    end
  end
end
```

Test it:

```bash
# GET request
curl http://localhost:4000/api/hello?name=Alice
# {"message":"Hello, Alice!"}

# POST request
curl -X POST http://localhost:4000/api/hello \
  -H "Content-Type: application/json" \
  -d '{"name":"Bob"}'
# {"message":"Hello, Bob!"}
```

---

## Next.js API Routes Alignment

Nex's JSON API is designed to match Next.js API Routes behavior exactly:

### Comparison Table

| Feature | Next.js | Nex |
|---------|---------|-----|
| Request query | `req.query.id` | `req.query["id"]` |
| Request body | `req.body.name` | `req.body["name"]` |
| Path params | Merged into `req.query` | Merged into `req.query` |
| JSON response | `res.json({data})` | `Nex.json(%{data: ...})` |
| Status code | `res.status(201).json(...)` | `Nex.json(..., status: 201)` |
| Text response | `res.send("text")` | `Nex.text("text")` |
| Empty response | `res.status(204).end()` | `Nex.status(204)` |

### Key Principles

1. **`req.query`** - Merges path parameters and query string (path params take precedence)
2. **`req.body`** - Always a Map, never `nil` or `Unfetched`
3. **No Nex-specific fields** - Only standard fields: `query`, `body`, `method`, `headers`, `cookies`, `path`

---

## Routing

API files in `src/api/` automatically map to `/api/*` routes:

| File Path | Route | Example |
|-----------|-------|---------|
| `src/api/hello.ex` | `/api/hello` | `/api/hello?name=World` |
| `src/api/users/index.ex` | `/api/users` | `/api/users?limit=10` |
| `src/api/users/[id].ex` | `/api/users/:id` | `/api/users/123` |
| `src/api/posts/[id]/comments.ex` | `/api/posts/:id/comments` | `/api/posts/456/comments` |

---

## Request Object

The `req` parameter provides access to request data:

### Available Fields

```elixir
def get(req) do
  # Query parameters (path params + query string)
  req.query         # %{"id" => "123", "filter" => "active"}
  
  # Request body (always a Map)
  req.body          # %{"name" => "Alice", "email" => "alice@example.com"}
  
  # HTTP method
  req.method        # "GET", "POST", "PUT", "DELETE", etc.
  
  # Request headers
  req.headers       # %{"content-type" => "application/json", ...}
  
  # Cookies
  req.cookies       # %{"session_id" => "abc123"}
  
  # Request path
  req.path          # "/api/users/123"
  
  # Private data (internal use)
  req.private       # %{...}
end
```

### Query Parameters

Query parameters merge path params and query string, with **path params taking precedence**:

```elixir
# Route: /api/users/[id]
# Request: GET /api/users/123?id=456&filter=active

def get(req) do
  req.query["id"]      # "123" (from path, not "456" from query)
  req.query["filter"]  # "active"
end
```

### Request Body

The request body is always a Map, automatically parsed from JSON:

```elixir
# Request: POST /api/users
# Body: {"name": "Alice", "email": "alice@example.com"}

def post(req) do
  name = req.body["name"]    # "Alice"
  email = req.body["email"]  # "alice@example.com"
  
  # req.body is never nil, always a Map
  # Empty body: req.body == %{}
end
```

---

## Response Helpers

Nex provides response helpers similar to Next.js:

### `Nex.json/2` - JSON Response

```elixir
# Basic JSON response (200 OK)
Nex.json(%{data: users})

# With custom status code
Nex.json(%{data: user}, status: 201)

# With custom headers
Nex.json(%{data: user}, status: 200, headers: %{"X-Custom" => "value"})

# Error response
Nex.json(%{error: "Not found"}, status: 404)
```

### `Nex.text/2` - Text Response

```elixir
# Plain text response
Nex.text("Hello, World!")

# With custom status
Nex.text("Created", status: 201)
```

### `Nex.html/2` - HTML Response

```elixir
# HTML response (useful for HTMX)
Nex.html("<div>Hello</div>")

# With custom status
Nex.html("<div>Error</div>", status: 400)
```

### `Nex.status/1` - Status Only

```elixir
# 204 No Content (successful deletion)
Nex.status(204)

# 304 Not Modified
Nex.status(304)
```

### `Nex.redirect/2` - Redirect

```elixir
# Temporary redirect (302)
Nex.redirect("/login")

# Permanent redirect (301)
Nex.redirect("/new-url", status: 301)
```

---

## HTTP Methods

Define handler functions for different HTTP methods:

```elixir
defmodule MyApp.Api.Users do
  use Nex

  # GET /api/users
  def get(req) do
    users = get_all_users()
    Nex.json(%{data: users})
  end

  # POST /api/users
  def post(req) do
    user = create_user(req.body)
    Nex.json(%{data: user}, status: 201)
  end

  # PUT /api/users (bulk update)
  def put(req) do
    updated = update_users(req.body)
    Nex.json(%{data: updated})
  end

  # DELETE /api/users (bulk delete)
  def delete(req) do
    delete_users(req.body["ids"])
    Nex.status(204)
  end

  # PATCH /api/users (partial update)
  def patch(req) do
    updated = patch_users(req.body)
    Nex.json(%{data: updated})
  end
end
```

---

## Dynamic Routes

Use `[param]` syntax for dynamic route segments:

### Single Parameter

```elixir
# src/api/users/[id].ex
defmodule MyApp.Api.Users.Id do
  use Nex

  # GET /api/users/123
  def get(req) do
    id = req.query["id"]  # "123"
    
    case find_user(id) do
      nil -> Nex.json(%{error: "User not found"}, status: 404)
      user -> Nex.json(%{data: user})
    end
  end

  # PUT /api/users/123
  def put(req) do
    id = req.query["id"]
    attrs = req.body
    
    case update_user(id, attrs) do
      {:ok, user} -> Nex.json(%{data: user})
      {:error, reason} -> Nex.json(%{error: reason}, status: 400)
    end
  end

  # DELETE /api/users/123
  def delete(req) do
    id = req.query["id"]
    delete_user(id)
    Nex.status(204)
  end
end
```

### Nested Parameters

```elixir
# src/api/posts/[post_id]/comments/[id].ex
defmodule MyApp.Api.Posts.PostId.Comments.Id do
  use Nex

  # GET /api/posts/456/comments/789
  def get(req) do
    post_id = req.query["post_id"]    # "456"
    comment_id = req.query["id"]      # "789"
    
    comment = find_comment(post_id, comment_id)
    Nex.json(%{data: comment})
  end
end
```

---

## Error Handling

### Validation Errors

```elixir
def post(req) do
  name = req.body["name"]
  email = req.body["email"]
  
  cond do
    is_nil(name) or name == "" ->
      Nex.json(%{error: "Name is required"}, status: 400)
    
    is_nil(email) or not valid_email?(email) ->
      Nex.json(%{error: "Valid email is required"}, status: 400)
    
    true ->
      user = create_user(%{name: name, email: email})
      Nex.json(%{data: user}, status: 201)
  end
end
```

### Not Found

```elixir
def get(req) do
  id = req.query["id"]
  
  case find_user(id) do
    nil -> Nex.json(%{error: "User not found"}, status: 404)
    user -> Nex.json(%{data: user})
  end
end
```

### Unauthorized

```elixir
def delete(req) do
  token = req.headers["authorization"]
  
  if not valid_token?(token) do
    Nex.json(%{error: "Unauthorized"}, status: 401)
  else
    delete_resource()
    Nex.status(204)
  end
end
```

### Internal Server Error

```elixir
def post(req) do
  try do
    result = perform_operation(req.body)
    Nex.json(%{data: result}, status: 201)
  rescue
    e ->
      # Log the error
      Logger.error("Operation failed: #{inspect(e)}")
      Nex.json(%{error: "Internal server error"}, status: 500)
  end
end
```

---

## Complete Example

Here's a complete RESTful API for managing todos:

### Collection Endpoint

```elixir
# src/api/todos/index.ex
defmodule MyApp.Api.Todos.Index do
  @moduledoc """
  Todos collection API - Next.js style.
  
  Endpoints:
  - GET /api/todos - List todos with filtering
  - POST /api/todos - Create a new todo
  """
  use Nex

  # GET /api/todos?completed=false&limit=10
  def get(req) do
    completed_filter = req.query["completed"]
    limit = req.query["limit"]
    
    todos = Nex.Store.get(:todos, [])
    |> filter_by_completed(completed_filter)
    |> limit_results(limit)
    
    Nex.json(%{
      data: todos,
      count: length(todos)
    })
  end

  # POST /api/todos
  # Body: {"text": "Buy groceries", "completed": false}
  def post(req) do
    text = req.body["text"]
    completed = req.body["completed"] || false
    
    cond do
      is_nil(text) or text == "" ->
        Nex.json(%{error: "Text is required"}, status: 400)
      
      true ->
        todo = %{
          id: System.unique_integer([:positive, :monotonic]),
          text: text,
          completed: completed,
          created_at: DateTime.utc_now() |> DateTime.to_iso8601()
        }
        
        Nex.Store.update(:todos, [], &[todo | &1])
        
        Nex.json(%{data: todo}, status: 201)
    end
  end
  
  # Private helpers
  
  defp filter_by_completed(todos, nil), do: todos
  defp filter_by_completed(todos, "true"), do: Enum.filter(todos, & &1.completed)
  defp filter_by_completed(todos, "false"), do: Enum.filter(todos, &(not &1.completed))
  defp filter_by_completed(todos, _), do: todos
  
  defp limit_results(todos, nil), do: todos
  defp limit_results(todos, limit_str) do
    case Integer.parse(limit_str) do
      {limit, _} -> Enum.take(todos, limit)
      :error -> todos
    end
  end
end
```

### Resource Endpoint

```elixir
# src/api/todos/[id].ex
defmodule MyApp.Api.Todos.Id do
  @moduledoc """
  Individual todo API - Next.js style.
  
  Endpoints:
  - GET /api/todos/:id - Get a specific todo
  - PUT /api/todos/:id - Update a todo
  - DELETE /api/todos/:id - Delete a todo
  """
  use Nex

  # GET /api/todos/123
  def get(req) do
    id = req.query["id"]
    
    case find_todo(id) do
      nil ->
        Nex.json(%{error: "Todo not found"}, status: 404)
      
      todo ->
        Nex.json(%{data: todo})
    end
  end

  # PUT /api/todos/123
  # Body: {"text": "Updated text", "completed": true}
  def put(req) do
    id = req.query["id"]
    text = req.body["text"]
    completed = req.body["completed"]
    
    case find_todo(id) do
      nil ->
        Nex.json(%{error: "Todo not found"}, status: 404)
      
      todo ->
        updated_todo = todo
        |> update_if_present(:text, text)
        |> update_if_present(:completed, completed)
        
        Nex.Store.update(:todos, [], fn todos ->
          Enum.map(todos, fn t ->
            if t.id == todo.id, do: updated_todo, else: t
          end)
        end)
        
        Nex.json(%{data: updated_todo})
    end
  end

  # DELETE /api/todos/123
  def delete(req) do
    id = req.query["id"]
    
    case find_todo(id) do
      nil ->
        Nex.json(%{error: "Todo not found"}, status: 404)
      
      _todo ->
        Nex.Store.update(:todos, [], fn todos ->
          Enum.reject(todos, &(&1.id == parse_id(id)))
        end)
        
        Nex.status(204)
    end
  end
  
  # Private helpers
  
  defp find_todo(id_str) do
    case parse_id(id_str) do
      nil -> nil
      id ->
        Nex.Store.get(:todos, [])
        |> Enum.find(&(&1.id == id))
    end
  end
  
  defp parse_id(id_str) when is_binary(id_str) do
    case Integer.parse(id_str) do
      {id, _} -> id
      :error -> nil
    end
  end
  defp parse_id(_), do: nil
  
  defp update_if_present(map, _key, nil), do: map
  defp update_if_present(map, key, value), do: Map.put(map, key, value)
end
```

---

## Best Practices

### 1. Use Proper HTTP Status Codes

```elixir
# 200 OK - Successful GET, PUT, PATCH
Nex.json(%{data: resource})

# 201 Created - Successful POST
Nex.json(%{data: new_resource}, status: 201)

# 204 No Content - Successful DELETE
Nex.status(204)

# 400 Bad Request - Validation error
Nex.json(%{error: "Invalid input"}, status: 400)

# 404 Not Found - Resource not found
Nex.json(%{error: "Not found"}, status: 404)

# 401 Unauthorized - Authentication required
Nex.json(%{error: "Unauthorized"}, status: 401)

# 403 Forbidden - Insufficient permissions
Nex.json(%{error: "Forbidden"}, status: 403)

# 500 Internal Server Error - Server error
Nex.json(%{error: "Internal error"}, status: 500)
```

### 2. Consistent Response Format

```elixir
# Success responses
%{data: resource}
%{data: resources, count: 10, page: 1}

# Error responses
%{error: "Error message"}
%{error: "Error message", details: %{field: "is invalid"}}
```

### 3. Input Validation

```elixir
def post(req) do
  with {:ok, name} <- validate_required(req.body["name"], "Name"),
       {:ok, email} <- validate_email(req.body["email"]) do
    user = create_user(%{name: name, email: email})
    Nex.json(%{data: user}, status: 201)
  else
    {:error, message} ->
      Nex.json(%{error: message}, status: 400)
  end
end

defp validate_required(nil, field), do: {:error, "#{field} is required"}
defp validate_required("", field), do: {:error, "#{field} is required"}
defp validate_required(value, _field), do: {:ok, value}

defp validate_email(email) when is_binary(email) do
  if String.contains?(email, "@") do
    {:ok, email}
  else
    {:error, "Invalid email format"}
  end
end
defp validate_email(_), do: {:error, "Email is required"}
```

### 4. Error Logging

```elixir
require Logger

def post(req) do
  try do
    result = perform_operation(req.body)
    Nex.json(%{data: result}, status: 201)
  rescue
    e ->
      Logger.error("Operation failed: #{inspect(e)}\nStacktrace: #{Exception.format_stacktrace()}")
      Nex.json(%{error: "Internal server error"}, status: 500)
  end
end
```

---

## Migration from Old API

If you're upgrading from an older version of Nex, here's what changed:

### Removed Fields

These fields are **no longer available**:

- ❌ `req.params` - Use `req.query` instead
- ❌ `req.path_params` - Merged into `req.query`
- ❌ `req.query_params` - Use `req.query` instead
- ❌ `req.body_params` - Use `req.body` instead

### Migration Example

**Old code:**

```elixir
def get(req) do
  id = req.path_params["id"]
  filter = req.query_params["filter"]
  # ...
end

def post(req) do
  name = req.body_params["name"]
  # ...
end
```

**New code:**

```elixir
def get(req) do
  id = req.query["id"]       # Path params merged into query
  filter = req.query["filter"]
  # ...
end

def post(req) do
  name = req.body["name"]    # Direct access to body
  # ...
end
```

---

## Summary

Nex's JSON API system provides:

- ✅ **100% Next.js API Routes alignment** - Familiar for JavaScript developers
- ✅ **Simple routing** - File-based routing in `src/api/`
- ✅ **Clean request object** - `req.query` and `req.body`
- ✅ **Flexible responses** - `Nex.json/2`, `Nex.text/2`, `Nex.html/2`, etc.
- ✅ **Dynamic routes** - `[param]` syntax for path parameters
- ✅ **Type safety** - Leverages Elixir's pattern matching and guards

For more examples, check out the `examples/todos_api` project in the Nex repository.
