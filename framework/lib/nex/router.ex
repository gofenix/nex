defmodule Nex.Router do
  @moduledoc """
  Router that discovers and dispatches routes from src/ directory.

  ## Route Discovery

  - `src/pages/*.ex` → Page routes (GET for render, POST for actions)
  - `src/api/*.ex` → API routes (function name = HTTP method)
  - `src/partials/*.ex` → No routes (pure components)
  """

  use Plug.Router

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug :match
  plug :dispatch

  # Catch-all route that delegates to Nex.Handler
  match _ do
    Nex.Handler.handle(conn)
  end
end
