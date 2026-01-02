defmodule EnergyDashboard.Pages.Index do
  use Nex

  def mount(_params) do
    # Calculate offset from the start of the current hour
    # This ensures all clients see the same synchronized time
    now = DateTime.utc_now()
    hour_start = %{now | minute: 0, second: 0, microsecond: {0, 0}}
    offset_seconds = DateTime.diff(now, hour_start)

    %{
      title: "Energy Dashboard - Time-Synchronized SSE",
      offset: offset_seconds,
      current_time: DateTime.to_iso8601(now)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto">
      <!-- Header -->
      <div class="text-center mb-12">
        <h1 class="text-5xl font-bold text-white mb-4">⚡ Energy Dashboard</h1>
        <p class="text-xl text-purple-100">Real-time energy price monitoring with synchronized time</p>
        <p class="text-sm text-purple-200 mt-2">All devices show the same data at the same time</p>
      </div>

      <!-- Main Dashboard -->
      <div class="glass rounded-3xl p-8 mb-8 pulse-glow" hx-ext="sse" sse-connect={"/api/energy_stream?offset=#{@offset}"}>
        <div class="text-center mb-6">
          <div class="text-sm text-purple-200 mb-2">Current Energy Price</div>
          <div
            id="price-display"
            class="text-7xl font-bold text-white"
            sse-swap="price"
          >
            Loading...
          </div>
          <div class="text-2xl text-purple-100 mt-2">$/MWh</div>
        </div>

        <!-- Time Display -->
        <div class="text-center mb-8">
          <div
            id="time-display"
            class="text-xl text-purple-200"
            sse-swap="time"
          >
            {format_time(@current_time)}
          </div>
        </div>

        <!-- Stats Grid -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mt-8">
          <div class="glass rounded-xl p-6 text-center">
            <div class="text-3xl mb-2">📊</div>
            <div class="text-2xl font-bold text-white" id="data-points" sse-swap="data_points">3,600</div>
            <div class="text-sm text-purple-200 mt-2">Data Points/Hour</div>
          </div>

          <div class="glass rounded-xl p-6 text-center">
            <div class="text-3xl mb-2">⏱️</div>
            <div class="text-2xl font-bold text-white">1s</div>
            <div class="text-sm text-purple-200 mt-2">Update Rate</div>
          </div>

          <div class="glass rounded-xl p-6 text-center">
            <div class="text-3xl mb-2">🔄</div>
            <div class="text-2xl font-bold text-white">60m</div>
            <div class="text-sm text-purple-200 mt-2">Cycle Duration</div>
          </div>
        </div>
      </div>

      <!-- Info Cards -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div class="glass rounded-2xl p-6">
          <h3 class="text-xl font-bold text-white mb-4">🎯 Time Synchronization</h3>
          <p class="text-purple-100 mb-4">
            This dashboard demonstrates time-synchronized Server-Sent Events (SSE). All connected devices
            see the same data at the same time, regardless of when they connected.
          </p>
          <ul class="space-y-2 text-sm text-purple-200">
            <li>✓ Server-side time reference</li>
            <li>✓ Offset-based synchronization</li>
            <li>✓ No client-side drift</li>
            <li>✓ Consistent across all devices</li>
          </ul>
        </div>

        <div class="glass rounded-2xl p-6">
          <h3 class="text-xl font-bold text-white mb-4">🔧 How It Works</h3>
          <p class="text-purple-100 mb-4">
            The server calculates an offset from the start of the current hour and sends it to each client.
            The SSE stream uses this offset to ensure all clients receive synchronized data.
          </p>
          <div class="text-sm text-purple-200 space-y-2">
            <div><strong>1.</strong> Client connects and receives offset</div>
            <div><strong>2.</strong> Server streams data based on absolute time</div>
            <div><strong>3.</strong> All clients stay in sync</div>
          </div>
        </div>
      </div>

      <!-- Technical Details -->
      <div class="glass rounded-2xl p-6 mt-6">
        <h3 class="text-xl font-bold text-white mb-4">📝 Implementation Details</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6 text-sm">
          <div>
            <h4 class="font-semibold text-purple-100 mb-2">Server-Side (Elixir)</h4>
            <ul class="space-y-1 text-purple-200">
              <li>• Calculate offset in <code class="bg-black/30 px-2 py-1 rounded">mount/1</code></li>
              <li>• Use absolute time in SSE stream</li>
              <li>• Send synchronized events every second</li>
              <li>• Simulate energy price fluctuations</li>
            </ul>
          </div>
          <div>
            <h4 class="font-semibold text-purple-100 mb-2">Client-Side (HTMX)</h4>
            <ul class="space-y-1 text-purple-200">
              <li>• Connect with offset parameter</li>
              <li>• Use <code class="bg-black/30 px-2 py-1 rounded">sse-swap</code> for updates</li>
              <li>• No JavaScript required</li>
              <li>• Automatic reconnection</li>
            </ul>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div class="text-center mt-8 text-purple-200 text-sm">
        <p>Built with <a href="https://github.com/gofenix/nex" class="text-white hover:underline">Nex Framework</a> + HTMX SSE</p>
        <p class="mt-2">Open this page on multiple devices to see synchronized updates</p>
      </div>
    </div>
    """
  end

  defp format_time(iso_time) do
    case DateTime.from_iso8601(iso_time) do
      {:ok, dt, _} ->
        Calendar.strftime(dt, "%H:%M:%S UTC")
      _ ->
        "Loading..."
    end
  end
end
