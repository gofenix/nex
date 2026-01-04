```elixir
# src/api/stream.ex
defmodule MyApp.Api.Stream do
  use Nex

  def get(_req) do
    Nex.stream(fn send ->
      send.(%{event: "update", data: "Hello from AI!"})
    end)
  end
end
```
