```elixir
defmodule MyApp.Pages.Tasks do
  use Nex

  def toggle_status(req) do
    status = DB.toggle(req.query["id"])
    ~H"<span>{status}</span>"
  end
end
```
