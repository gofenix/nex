defmodule RatelimitExample.Api.Status do
  use Nex

  @moduledoc """
  API endpoint demonstrating rate limiting.
  This endpoint is automatically rate-limited by Nex.RateLimit.Plug.
  """

  def get(_req) do
    Nex.json(%{
      status: "ok",
      message: "Request successful",
      timestamp: :os.system_time(:millisecond)
    })
  end
end
