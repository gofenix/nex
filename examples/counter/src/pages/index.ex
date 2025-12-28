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
    <div class="flex items-center justify-center min-h-screen bg-gradient-to-br from-purple-100 to-blue-100">
      <div class="bg-white rounded-2xl shadow-2xl p-12 max-w-md w-full">
        <h1 class="text-4xl font-bold text-center mb-8 text-gray-800">Counter</h1>

        <div class="bg-gradient-to-r from-purple-500 to-blue-500 rounded-xl p-8 mb-8">
          <div class="text-6xl font-bold text-center text-white">
            {@count}
          </div>
        </div>

        <div class="flex gap-4 justify-center">
          <button hx-post="/decrement"
                  hx-target="closest div"
                  hx-swap="outerHTML"
                  class="px-6 py-3 bg-red-500 text-white font-bold rounded-lg hover:bg-red-600 transition-colors">
            -
          </button>

          <button hx-post="/reset"
                  hx-target="closest div"
                  hx-swap="outerHTML"
                  class="px-6 py-3 bg-gray-500 text-white font-bold rounded-lg hover:bg-gray-600 transition-colors">
            Reset
          </button>

          <button hx-post="/increment"
                  hx-target="closest div"
                  hx-swap="outerHTML"
                  class="px-6 py-3 bg-green-500 text-white font-bold rounded-lg hover:bg-green-600 transition-colors">
            +
          </button>
        </div>

        <div class="mt-8 p-4 bg-gray-50 rounded-lg text-sm text-gray-600">
          <p class="font-semibold mb-2">How it works:</p>
          <ul class="space-y-1">
            <li>Click + to increment</li>
            <li>Click - to decrement</li>
            <li>Click Reset to go back to 0</li>
            <li>State is managed server-side with Nex.Store</li>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  def increment(_params) do
    count = Nex.Store.update(:count, 0, &(&1 + 1))
    assigns = %{count: count}
    ~H"""
    <div class="bg-gradient-to-r from-purple-500 to-blue-500 rounded-xl p-8 mb-8">
      <div class="text-6xl font-bold text-center text-white">
        {@count}
      </div>
    </div>
    """
  end

  def decrement(_params) do
    count = Nex.Store.update(:count, 0, &(max(&1 - 1, 0)))
    assigns = %{count: count}
    ~H"""
    <div class="bg-gradient-to-r from-purple-500 to-blue-500 rounded-xl p-8 mb-8">
      <div class="text-6xl font-bold text-center text-white">
        {@count}
      </div>
    </div>
    """
  end

  def reset(_params) do
    Nex.Store.put(:count, 0)
    assigns = %{count: 0}
    ~H"""
    <div class="bg-gradient-to-r from-purple-500 to-blue-500 rounded-xl p-8 mb-8">
      <div class="text-6xl font-bold text-center text-white">
        {@count}
      </div>
    </div>
    """
  end
end
