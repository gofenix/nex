```elixir
# src/api/stream.ex
defmodule MyApp.Api.Stream do
  use Nex.SSE

  def stream(_params, send_fn) do
    send_fn.(%{event: "update", data: "Hello!"})
  end
end
```
