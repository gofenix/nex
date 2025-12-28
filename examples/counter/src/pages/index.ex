defmodule Counter.Pages.Index do
  use Nex.Page

  def mount(_params) do
    %{
      title: "Counter App",
      count: Nex.Store.get(:count, 0)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="text-center py-12">
      <h1 class="text-4xl font-bold mb-4">Counter</h1>

      <div id="counter-display" class="text-6xl font-bold mb-8">
        {@count}
      </div>

      <div class="space-x-2">
        <button hx-post="/decrement"
                hx-target="#counter-display"
                hx-swap="outerHTML"
                class="btn">
          -
        </button>

        <button hx-post="/reset"
                hx-target="#counter-display"
                hx-swap="outerHTML"
                class="btn">
          Reset
        </button>

        <button hx-post="/increment"
                hx-target="#counter-display"
                hx-swap="outerHTML"
                class="btn">
          +
        </button>
      </div>
    </div>
    """
  end

  def increment(_params) do
    count = Nex.Store.update(:count, 0, &(&1 + 1))
    assigns = %{count: count}
    ~H"""
    <div id="counter-display" class="text-6xl font-bold mb-8">
      {@count}
    </div>
    """
  end

  def decrement(_params) do
    count = Nex.Store.update(:count, 0, &(&1 - 1))
    assigns = %{count: count}
    ~H"""
    <div id="counter-display" class="text-6xl font-bold mb-8">
      {@count}
    </div>
    """
  end

  def reset(_params) do
    Nex.Store.put(:count, 0)
    assigns = %{count: 0}
    ~H"""
    <div id="counter-display" class="text-6xl font-bold mb-8">
      {@count}
    </div>
    """
  end
end
