```elixir
defmodule MyApp.Pages.Tasks do
  use Nex

  def toggle_status(%{"id" => id}) do
    status = DB.toggle(id)
    ~H"<span>{status}</span>"
  end
end
```
