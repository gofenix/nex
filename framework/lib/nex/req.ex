defmodule Nex.Req do
  @moduledoc """
  Standardized Request object for API handlers.

  Fully mimics Next.js API Routes behavior with minimal additions.

  ## Next.js Standard Fields

    * `query` - Path params + query string params (Next.js `req.query`)
    * `body` - Request body params (Next.js `req.body`)
    * `headers` - Request headers as a Map
    * `cookies` - Request cookies as a Map
    * `method` - HTTP method (uppercase string)

  ## Parameter Merging Behavior

  Like Next.js, `req.query` contains both dynamic path parameters and query string parameters.
  When the same key appears in both, **path parameters take precedence**.

  For example, `GET /api/users/123?id=456`:
    - `req.query["id"]` → `"123"` (path parameter wins)

  `req.body` is completely independent and never merged with `req.query`.

  ## Examples

      # GET /api/users/[id]?page=2
      def get(req) do
        user_id = req.query["id"]    # From path parameter [id]
        page = req.query["page"]     # From query string

        Nex.json(%{user_id: user_id, page: page})
      end

      # POST /api/users
      def post(req) do
        name = req.body["name"]
        email = req.body["email"]

        Nex.json(%{message: "User created"}, status: 201)
      end

  ## Comparison with Next.js

  | Next.js | Nex | Notes |
  |---------|-----|-------|
  | `req.query` | `req.query` | Identical behavior |
  | `req.body` | `req.body` | Identical behavior |
  | `req.headers` | `req.headers` | Identical behavior |
  | `req.cookies` | `req.cookies` | Identical behavior |
  | `req.method` | `req.method` | Identical behavior |
  """

  # Types
  @type method :: :get | :post | :put | :patch | :delete | :head | :options
  @type params :: %{optional(String.t()) => term()}
  @type headers :: %{optional(String.t()) => String.t()}
  @type cookies :: %{optional(String.t()) => String.t()}

  @type t :: %__MODULE__{
          query: params(),
          body: params() | %Plug.Upload{},
          headers: headers(),
          cookies: cookies(),
          method: String.t(),
          path: String.t(),
          private: map()
        }

  defstruct [
    :query,
    :body,
    :headers,
    :cookies,
    :method,
    :path,
    :private
  ]

  @doc """
  Constructs a Nex.Req from a Plug.Conn.

  This function normalizes the Plug.Conn into a Next.js-compatible request object.
  """
  @spec from_plug_conn(Plug.Conn.t(), params()) :: t()
  def from_plug_conn(%Plug.Conn{} = conn, path_params \\ %{}) do
    conn =
      conn
      |> Plug.Conn.fetch_query_params()
      |> Plug.Conn.fetch_cookies()

    # Normalize body_params: ensure it's always a Map (never Unfetched)
    body_params =
      case conn.body_params do
        %Plug.Conn.Unfetched{} -> %{}
        params when is_map(params) -> params
        _ -> %{}
      end

    # Convert headers list to Map
    headers = Map.new(conn.req_headers)

    # Next.js style: path params override query params
    query = Map.merge(conn.query_params, path_params)

    %__MODULE__{
      # Next.js standard - exactly the same behavior
      query: query,
      body: body_params,
      headers: headers,
      cookies: conn.cookies,
      method: conn.method,

      # Framework internals
      path: conn.request_path,
      private: conn.private
    }
  end
end
