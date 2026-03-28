defmodule AiSaga.Api.Hello do
  @moduledoc """
  Example API endpoint - Next.js style.

  ## Endpoints
  - GET /api/hello?name=World
  - POST /api/hello with body: {"name": "Alice"}

  ## Next.js API Routes Alignment
  - `req.query` - Path params + query string (path params take precedence)
  - `req.body` - Request body (always a Map, never nil)
  - `Nex.json/2` - JSON response helper
  """
  use Nex

  def get(req) do
    # Access query parameters - Next.js style
    name = req.query["name"] || "World"

    Nex.json(%{
      message: "Hello, #{name}!",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end

  def post(req) do
    # Access request body - Next.js style
    name = req.body["name"]

    cond do
      is_nil(name) or name == "" ->
        Nex.json(%{error: "Name is required"}, status: 400)

      true ->
        Nex.json(
          %{
            message: "Hello, #{name}! Welcome to Nex.",
            created_at: DateTime.utc_now() |> DateTime.to_iso8601()
          },
          status: 201
        )
    end
  end
end
