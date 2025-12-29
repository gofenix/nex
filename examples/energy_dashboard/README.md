# Energy Dashboard - Time-Synchronized SSE Example

A real-time energy price monitoring dashboard that demonstrates **time-synchronized Server-Sent Events (SSE)** in Nex.

## Features

- ⚡ **Real-time Updates**: Energy prices update every second
- 🎯 **Time Synchronization**: All connected devices see the same data at the same time
- 📊 **Realistic Simulation**: Uses sine wave patterns to simulate price fluctuations
- 🎨 **Beautiful UI**: Glassmorphism design with smooth animations
- 🔄 **Automatic Reconnection**: HTMX handles connection drops gracefully

## The Problem This Solves

When building real-time dashboards with SSE, a common issue is that clients connecting at different times see different states:

- Client A connects at 12:00:00 → sees counter at 0
- Client B connects at 12:00:30 → also sees counter at 0 (but should be at 30)

This example demonstrates how to synchronize all clients to show the same data based on absolute server time.

## How It Works

### 1. Server-Side Time Reference

In `src/pages/index.ex`, we calculate an offset from the start of the current hour:

```elixir
def mount(_params) do
  now = DateTime.utc_now()
  hour_start = %{now | minute: 0, second: 0, microsecond: {0, 0}}
  offset_seconds = DateTime.diff(now, hour_start)
  
  %{offset: offset_seconds}
end
```

### 2. SSE Stream with Absolute Time

In `src/api/energy_stream.ex`, the stream uses the current absolute time to calculate prices:

```elixir
def stream(conn, params) do
  SSE.stream(conn, fn send_event ->
    now = DateTime.utc_now()
    hour_start = %{now | minute: 0, second: 0, microsecond: {0, 0}}
    current_offset = DateTime.diff(now, hour_start)
    
    # Price is calculated based on absolute time, not connection time
    price = calculate_price(current_offset)
    send_event.("price", format_price(price))
    
    :timer.sleep(1000)
    :continue
  end)
end
```

### 3. Client-Side Connection

The client passes the offset when connecting:

```html
<div 
  hx-ext="sse" 
  sse-connect="/api/energy_stream?offset=#{@offset}"
  sse-swap="price"
>
  Loading...
</div>
```

## Running the Example

```bash
# Install dependencies
mix deps.get

# Start the server
mix nex.dev
```

Then open http://localhost:4000 in multiple browsers or devices to see synchronized updates.

## Testing Synchronization

1. Open the dashboard on your laptop
2. Open the same URL on your phone
3. Observe that both devices show the same price at the same time
4. Refresh one device - it will sync to the current time immediately

## Key Concepts

### Time-Based Calculation

Instead of incrementing a counter from when the client connects, we calculate values based on the current time:

```elixir
# ❌ Bad: Counter starts from connection time
counter = counter + 1

# ✅ Good: Value based on absolute time
seconds_in_hour = DateTime.diff(now, hour_start)
value = calculate_value(seconds_in_hour)
```

### Sine Wave Pattern

The price simulation uses multiple sine waves to create realistic-looking fluctuations:

```elixir
angle = 2 * :math.pi() * seconds_in_hour / 3600
primary_wave = :math.sin(angle)
secondary_wave = :math.sin(angle * 3) * 0.3
tertiary_wave = :math.sin(angle * 7) * 0.15
```

This creates a smooth, repeating pattern over each hour.

## Performance

This example can handle:
- **1,000+ concurrent connections** on a small server (1 CPU, 512 MB RAM)
- **10,000+ concurrent connections** with proper tuning

See the [SSE Performance Guide](../../website/priv/docs/sse_performance.md) for more details.

## Customization

### Change Update Frequency

In `energy_stream.ex`:
```elixir
:timer.sleep(1000)  # Change to 500 for 2x speed, 2000 for 0.5x speed
```

### Adjust Price Range

```elixir
@base_price 45.0      # Average price
@price_variance 15.0  # ±15 variation
```

### Modify Wave Pattern

```elixir
# Faster cycles: multiply angle by larger number
angle = 2 * :math.pi() * seconds_in_hour / 1800  # 30-minute cycle

# More variation: add more waves
quaternary_wave = :math.sin(angle * 11) * 0.1
```

## Related Examples

- **chatbot_sse**: AI streaming with SSE
- **counter**: Basic HTMX interactions
- **todos**: State management patterns

## Learn More

- [Nex SSE Documentation](https://github.com/gofenix/nex)
- [HTMX SSE Extension](https://htmx.org/extensions/server-sent-events/)
- [Server-Sent Events Spec](https://html.spec.whatwg.org/multipage/server-sent-events.html)
