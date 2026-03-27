defmodule RatelimitExample.Plugs.ApiRateLimit do
  @moduledoc """
  Applies the built-in Nex rate-limit plug only to API routes.
  """

  def init(opts) do
    Nex.RateLimit.Plug.init(opts)
  end

  def call(conn, opts) do
    if String.starts_with?(conn.request_path, "/api/") do
      Nex.RateLimit.Plug.call(conn, opts)
    else
      conn
    end
  end
end
