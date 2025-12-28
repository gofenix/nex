```elixir
defmodule MyApp.Pages.Index do
  use Nex.Page

  def mount(_params) do
    %{count: 0}
  end

  def render(assigns) do
    ~H"""
    <div class="p-8">
      <h1>Count: {@count}</h1>
      <button hx-post="/inc" class="btn">+</button>
    </div>
    """
  end

  def inc(_params) do
    count = Nex.Store.update(:count, 0, &(&1 + 1))
    ~H"<h1 hx-swap-oob='true'>Count: {count}</h1>"
  end
end
```
