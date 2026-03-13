# Rate Limiting Example

Demonstrates Nex.RateLimit from Nex 0.4.

## Features

- Programmatic rate limiting with `Nex.RateLimit.check/2`
- Plug middleware `Nex.RateLimit.Plug` for automatic rate limiting
- X-RateLimit-Limit and X-RateLimit-Remaining headers
- Visual feedback when rate limited (HTTP 429)

## Run

```bash
cd examples/ratelimit
mix deps.get
mix nex.dev
```

Visit http://localhost:4000

## API Endpoints

- `GET /api/status` - Returns current rate limit status (limited to 5 requests per minute)
- `POST /api/action` - Demonstrates programmatic rate limiting

## Configuration

Rate limiting is configured in `src/application.ex`:

```elixir
# Configure rate limiter
Application.put_env(:nex_core, :rate_limit, max: 5, window: 60)

# Add rate limiting plug
Application.put_env(:nex_core, :plugs, [Nex.RateLimit.Plug])
```
