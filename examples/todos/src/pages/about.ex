defmodule Todos.Pages.About do
  use Nex.Page

  def mount(_conn, _params) do
    %{
      title: "About"
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto">
      <h1 class="text-3xl font-bold text-gray-800 mb-6">About</h1>
      
      <p class="text-gray-600 mb-4">
        This is a simple Todo app built with the Nex framework.
      </p>
      
      <p class="text-gray-600 mb-4">
        Nex is a minimalist Elixir web framework powered by HTMX.
      </p>
      
      <a href="/" class="text-blue-500 hover:underline">← Back to Todos</a>
    </div>
    """
  end
end
