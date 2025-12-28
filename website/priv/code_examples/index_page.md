```elixir
defmodule MyApp.Pages.Index do
  use Nex.Page

  def mount(_params) do
    %{count: Nex.Store.get(:count, 0)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-8">
      <h1>Count: {@count}</h1>
      <button hx-post="/increment" class="btn">+</button>
    </div>
    """
  end

  def increment(_params) do
    count = Nex.Store.update(:count, 0, &(&1 + 1))
    assigns = %{count: count}
    ~H"<h1>Count: {@count}</h1>"
  end
end
```
