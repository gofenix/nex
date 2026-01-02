defmodule EnergyDashboard.Api.EnergyStream do
  use Nex
  require Logger

  @moduledoc """
  Real-time energy price streaming endpoint using Server-Sent Events (SSE).

  Simulates real-time energy pricing with smooth wave patterns.

  ## Usage

  Connect to this endpoint to receive real-time energy price updates:

      GET /api/energy_stream

  The stream will send three types of events:
  - `price`: Current energy price ($/MWh)
  - `time`: Current UTC time
  - `data_points`: Seconds since start of hour
  """

  @base_price 45.0
  @price_variance 15.0

  def get(_req) do
    Logger.info("SSE connection started")

    Nex.stream(fn send ->
      stream_loop(send)
    end)
  end

  defp stream_loop(send) do
    # Calculate current time
    now = DateTime.utc_now()
    hour_start = %{now | minute: 0, second: 0, microsecond: {0, 0}}
    current_offset = DateTime.diff(now, hour_start)

    # Calculate price based on time within the hour (0-3599 seconds)
    # This ensures all clients see the same price at the same absolute time
    price = calculate_price(current_offset)

    # Send price update
    send.(%{event: "price", data: format_price(price)})

    # Send time update
    send.(%{event: "time", data: format_time(now)})

    # Send data points (simulated)
    send.(%{event: "data_points", data: "#{current_offset}"})

    # Wait 1 second before next update
    Process.sleep(1000)

    # Continue streaming
    stream_loop(send)
  end

  # Calculate price based on seconds within the hour
  # Uses a sine wave pattern to simulate realistic price fluctuations
  defp calculate_price(seconds_in_hour) do
    # Create a smooth wave pattern over the hour
    # Period: 3600 seconds (1 hour)
    angle = 2 * :math.pi() * seconds_in_hour / 3600

    # Combine multiple sine waves for more realistic variation
    primary_wave = :math.sin(angle)
    secondary_wave = :math.sin(angle * 3) * 0.3
    tertiary_wave = :math.sin(angle * 7) * 0.15

    # Add some randomness (±5%)
    random_factor = (:rand.uniform() - 0.5) * 0.1

    # Calculate final price
    variation = (primary_wave + secondary_wave + tertiary_wave + random_factor) * @price_variance
    price = @base_price + variation

    # Ensure price is positive
    max(price, 10.0)
  end

  defp format_price(price) do
    # Format to 2 decimal places
    :erlang.float_to_binary(price, decimals: 2)
  end

  defp format_time(datetime) do
    Calendar.strftime(datetime, "%H:%M:%S UTC")
  end
end
