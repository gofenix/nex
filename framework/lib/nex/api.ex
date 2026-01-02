defmodule Nex.Api do
  @moduledoc """
  Conventions for API endpoints.

  ## Recommended Usage

  Use `use Nex` instead of importing this module:

      defmodule MyApp.Api.Users.Index do
        use Nex  # ← Unified interface

        def get(req) do
          Nex.json(%{data: users})
        end
      end

  The framework automatically detects API modules based on the `.Api.` path segment.

  API modules are regular Elixir modules that export HTTP method functions.
  They follow Next.js API Routes conventions for simplicity and familiarity.

  ## Convention

  Place API modules under `src/api/` directory. The file structure maps to URL routes:

  - `src/api/users/index.ex` → `/api/users`
  - `src/api/users/[id].ex` → `/api/users/:id`
  - `src/api/posts/[id]/comments.ex` → `/api/posts/:id/comments`

  ## HTTP Methods

  Define functions matching HTTP methods. Each function receives a `Nex.Req` struct
  and must return a `Nex.Response` struct.

      defmodule MyApp.Api.Users.Index do
        def get(req) do
          # Access query parameters
          page = req.query["page"] || "1"
          users = fetch_users(page)

          Nex.json(%{data: users})
        end

        def post(req) do
          # Access request body
          name = req.body["name"]
          email = req.body["email"]

          case create_user(name, email) do
            {:ok, user} ->
              Nex.json(%{data: user}, status: 201)

            {:error, reason} ->
              Nex.json(%{error: reason}, status: 400)
          end
        end

        def delete(req) do
          id = req.query["id"]
          delete_user(id)

          Nex.status(204)
        end
      end

  ## Dynamic Routes

  Use `[param]` in filename for dynamic segments:

      # src/api/users/[id].ex
      defmodule MyApp.Api.Users.Id do
        def get(req) do
          # Path parameter available in req.query
          user_id = req.query["id"]
          user = fetch_user(user_id)

          Nex.json(%{data: user})
        end
      end

  ## Request Object

  See `Nex.Req` for details. Key fields:

  - `req.query` - Path params + query string (Next.js style)
  - `req.body` - Request body (always a Map)
  - `req.method` - HTTP method (String)
  - `req.headers` - Request headers (Map)
  - `req.cookies` - Request cookies (Map)

  ## Response Helpers

  - `Nex.json(data, opts)` - JSON response
  - `Nex.html(content, opts)` - HTML response (for HTMX)
  - `Nex.text(string, opts)` - Plain text response
  - `Nex.redirect(to, opts)` - Redirect response
  - `Nex.status(code)` - Status-only response

  ## Next.js Alignment

  This design fully aligns with Next.js API Routes:

  | Next.js | Nex |
  |---------|-----|
  | `req.query` | `req.query` |
  | `req.body` | `req.body` |
  | `req.method` | `req.method` |
  | `req.headers` | `req.headers` |
  | `req.cookies` | `req.cookies` |
  | `res.json(data)` | `Nex.json(data)` |
  | `res.send(text)` | `Nex.text(text)` |
  | `res.redirect(url)` | `Nex.redirect(url)` |
  | `res.status(code)` | `Nex.status(code)` |

  """
end
