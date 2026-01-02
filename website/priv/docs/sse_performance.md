# Server-Sent Events (SSE) Performance Guide

This guide covers performance considerations, concurrency limits, and best practices for using Server-Sent Events in Nex applications.

## Table of Contents

- [What is SSE?](#what-is-sse)
- [Performance Characteristics](#performance-characteristics)
- [Concurrency Limits](#concurrency-limits)
- [Best Practices](#best-practices)
- [Time Synchronization](#time-synchronization)
- [Monitoring and Debugging](#monitoring-and-debugging)

---

## What is SSE?

Server-Sent Events (SSE) is a server push technology that allows servers to send real-time updates to clients over a single HTTP connection. In Nex, SSE is a first-class feature through the `Nex.SSE` behavior.

**Common Use Cases:**
- Live dashboards and metrics
- Real-time notifications
- AI streaming responses
- Progress bars and status updates
- Chat applications
- Live data feeds

---

## Performance Characteristics

### Connection Model

Each SSE connection in Nex:
- Uses one Erlang/Elixir process per connection
- Maintains a persistent HTTP connection
- Consumes minimal memory when idle (~2-10 KB per connection)
- Scales efficiently due to Erlang's lightweight process model

### Throughput

Nex uses **Bandit** as its HTTP server, which is built on top of Erlang/OTP:

- **Small deployments (<1,000 concurrent connections)**: Excellent performance with minimal resource usage
- **Medium deployments (1,000-10,000 connections)**: Good performance, may require tuning
- **Large deployments (>10,000 connections)**: Possible but requires careful optimization

---

## Concurrency Limits

### Theoretical Limits

Erlang/OTP can theoretically handle **millions of processes**, but practical SSE limits depend on:

1. **Available Memory**: Each connection uses ~2-10 KB when idle, more when actively streaming
2. **CPU Resources**: Data serialization and transmission overhead
3. **Network Bandwidth**: Outbound data rate
4. **Operating System Limits**: File descriptors, socket buffers

### Practical Guidelines

| Deployment Size | Concurrent SSE Connections | Server Requirements |
|----------------|---------------------------|---------------------|
| Small | < 1,000 | 1 CPU, 512 MB RAM |
| Medium | 1,000 - 10,000 | 2-4 CPUs, 2-4 GB RAM |
| Large | > 10,000 | 4+ CPUs, 8+ GB RAM, tuning required |

### System Tuning for High Concurrency

For deployments expecting >5,000 concurrent SSE connections:

**1. Increase File Descriptor Limits**

```bash
# Linux: /etc/security/limits.conf
* soft nofile 65536
* hard nofile 65536
```

**2. Tune Erlang VM**

```elixir
# In your mix.exs or vm.args
# Increase maximum processes
+P 1000000

# Increase maximum ports (for network connections)
+Q 65536
```

**3. Configure Bandit**

```elixir
# In your application.ex
Bandit.start_link(
  plug: YourApp.Router,
  port: 4000,
  thousand_island_options: [
    num_acceptors: 100,
    max_connections: 16_384
  ]
)
```

---

## Best Practices

### 1. Efficient Data Streaming

**❌ Bad: Sending large payloads frequently**
```elixir
def stream(conn, _params) do
  SSE.stream(conn, fn send_event ->
    # Sending 1MB every second = high bandwidth
    send_event.("data", %{huge_payload: generate_1mb_data()})
    :timer.sleep(1000)
  end)
end
```

**✅ Good: Send only changed data**
```elixir
def stream(conn, _params) do
  SSE.stream(conn, fn send_event ->
    # Send only the delta or small updates
    send_event.("update", %{value: get_current_value()})
    :timer.sleep(1000)
  end)
end
```

### 2. Use Appropriate Update Intervals

- **Real-time dashboards**: 1-5 seconds
- **Stock tickers**: 1-2 seconds
- **Chat messages**: Event-driven (no polling)
- **Progress bars**: 100-500ms

### 3. Implement Connection Cleanup

Always ensure connections are properly closed:

```elixir
def stream(conn, _params) do
  SSE.stream(conn, fn send_event ->
    try do
      loop(send_event)
    rescue
      e -> 
        Logger.error("SSE error: #{inspect(e)}")
        :stop
    end
  end)
end
```

### 4. Use Phoenix.PubSub for Broadcasting

For broadcasting to multiple clients efficiently:

```elixir
# In your Application.ex
children = [
  {Phoenix.PubSub, name: MyApp.PubSub}
]

# In your SSE endpoint
def stream(conn, _params) do
  Phoenix.PubSub.subscribe(MyApp.PubSub, "updates")
  
  SSE.stream(conn, fn send_event ->
    receive do
      {:update, data} ->
        send_event.("update", data)
        :continue
      _ ->
        :continue
    end
  end)
end
```

---

## Time Synchronization

A common requirement is to synchronize data across all connected clients based on server time rather than client connection time.

### Problem

When clients connect at different times, they may see different states:
- Client A connects at 12:00:00 → sees counter at 0
- Client B connects at 12:00:30 → sees counter at 0 (but should be at 30)

### Solution: Server-Side Time Reference

**Method 1: Include Timestamp in Events**

```elixir
def stream(conn, _params) do
  start_time = DateTime.utc_now()
  
  SSE.stream(conn, fn send_event ->
    current_time = DateTime.utc_now()
    elapsed = DateTime.diff(current_time, start_time)
    
    send_event.("tick", %{
      elapsed: elapsed,
      timestamp: DateTime.to_iso8601(current_time)
    })
    
    :timer.sleep(1000)
    :continue
  end)
end
```

**Method 2: Calculate Offset in Mount**

```elixir
def mount(_params) do
  # Use a fixed reference point (e.g., start of hour)
  now = DateTime.utc_now()
  hour_start = %{now | minute: 0, second: 0, microsecond: {0, 0}}
  offset_seconds = DateTime.diff(now, hour_start)
  
  %{
    title: "Synchronized Dashboard",
    offset: offset_seconds
  }
end

def render(assigns) do
  ~H"""
  <div hx-ext="sse" sse-connect="/api/stream?offset={@offset}">
    <div sse-swap="update"></div>
  </div>
  """
end
```

**Method 3: Use Absolute Time Values**

```elixir
def stream(conn, _params) do
  SSE.stream(conn, fn send_event ->
    # Send absolute values based on current time
    current_hour = DateTime.utc_now().hour
    current_minute = DateTime.utc_now().minute
    
    send_event.("time", %{
      hour: current_hour,
      minute: current_minute,
      value: calculate_value_for_time(current_hour, current_minute)
    })
    
    :timer.sleep(1000)
    :continue
  end)
end
```

---

## Monitoring and Debugging

### Check Active Connections

```elixir
# Get count of all processes
:erlang.system_info(:process_count)

# Get memory usage
:erlang.memory()
```

### Monitor SSE Endpoints

Add logging to track connection lifecycle:

```elixir
def stream(conn, _params) do
  Logger.info("SSE connection opened: #{inspect(conn.remote_ip)}")
  
  SSE.stream(conn, fn send_event ->
    # Your streaming logic
  end)
  
  Logger.info("SSE connection closed")
end
```

### Performance Testing

Use tools like `wrk` or `k6` to test SSE endpoints:

```bash
# Using k6 for SSE load testing
k6 run --vus 1000 --duration 30s sse-test.js
```

---

## When to Consider Alternatives

SSE is excellent for most real-time use cases, but consider alternatives when:

- **Bidirectional communication needed**: Use WebSockets
- **>50,000 concurrent connections**: Consider Redis Pub/Sub + multiple servers
- **Binary data streaming**: Use WebSockets or HTTP/2 streams
- **Mobile apps with unreliable networks**: Consider polling with exponential backoff

---

## Example: Production-Ready SSE Endpoint

```elixir
defmodule MyApp.Api.Stream do
  use Nex
  require Logger

  @max_duration_ms 3_600_000  # 1 hour max connection time

  def stream(conn, params) do
    start_time = System.monotonic_time(:millisecond)
    client_id = get_client_id(conn)
    
    Logger.info("SSE connected: #{client_id}")
    
    # Subscribe to updates
    Phoenix.PubSub.subscribe(MyApp.PubSub, "live_updates")
    
    SSE.stream(conn, fn send_event ->
      # Check connection duration
      if System.monotonic_time(:millisecond) - start_time > @max_duration_ms do
        Logger.info("SSE max duration reached: #{client_id}")
        :stop
      else
        receive do
          {:update, data} ->
            send_event.("update", data)
            :continue
            
          :stop ->
            :stop
        after
          30_000 ->
            # Send keepalive every 30 seconds
            send_event.("ping", %{})
            :continue
        end
      end
    end)
    
    Logger.info("SSE disconnected: #{client_id}")
  end
  
  defp get_client_id(conn) do
    conn.remote_ip
    |> :inet.ntoa()
    |> to_string()
  end
end
```

---

## Further Reading

- [Nex SSE Examples](https://github.com/gofenix/nex/tree/main/examples/chatbot_sse)
- [HTMX SSE Extension](https://htmx.org/extensions/server-sent-events/)
- [MDN: Server-Sent Events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events)
