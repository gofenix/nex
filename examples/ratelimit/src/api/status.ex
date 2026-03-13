defmodule RateLimitExample.Api.Status do
  use Nex

  @moduledoc """
  API endpoint demonstrating rate limiting.
  This endpoint is automatically rate-limited by Nex.RateLimit.Plug.
  """

  def get(req) do
    # The plug has already checked rate limiting
    # We can also check programmatically if needed
    ip = get_client_ip(req)

    case Nex.RateLimit.check(ip, max: 5, window: 60) do
      :ok ->
        remaining = get_remaining(ip)

        Nex.json(
          %{
            status: "ok",
            message: "Request successful",
            timestamp: :os.system_time(:millisecond)
          },
          headers: [
            {"X-RateLimit-Limit", "5"},
            {"X-RateLimit-Remaining", to_string(remaining)}
          ]
        )

      {:error, :rate_limited} ->
        Nex.json(
          %{
            status: "error",
            message: "Too many requests",
            retry_after: 60
          },
          status: 429,
          headers: [
            {"X-RateLimit-Limit", "5"},
            {"X-RateLimit-Remaining", "0"},
            {"Retry-After", "60"}
          ]
        )
    end
  end

  defp get_client_ip(req) do
    # Extract client IP from request
    # In real scenarios, you might get this from x-forwarded-for header
    req.remote_ip
    |> :inet.ntoa()
    |> to_string()
  end

  defp get_remaining(_ip) do
    # Calculate remaining requests (simplified)
    # In production, this would query the rate limiter state
    _max = 5
    5
  end
end
