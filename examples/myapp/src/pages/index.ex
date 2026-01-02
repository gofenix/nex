defmodule Myapp.Pages.Index do
  use Nex

  def mount(_params) do
    %{
      title: "Welcome to Myapp",
      message: "Your Nex app is running!"
    }
  end

  def render(assigns) do
    ~H"""
    <div class="text-center py-12">
      <h1 class="text-4xl font-bold text-gray-800 mb-4">{@message}</h1>
      <p class="text-gray-600 mb-8">
        Edit <code class="bg-gray-200 px-2 py-1 rounded">src/pages/index.ex</code> to get started.
      </p>
      <div class="bg-white rounded-lg p-6 shadow max-w-md mx-auto">
        <h2 class="text-xl font-semibold mb-4">Project Structure</h2>
        <ul class="space-y-2 text-left">
          <li>📁 <code>src/pages/</code> - Page components</li>
          <li>🔌 <code>src/api/</code> - API endpoints</li>
          <li>🧩 <code>src/components/</code> - Reusable components</li>
          <li>🎨 <code>src/layouts.ex</code> - Layout template</li>
        </ul>
      </div>
    </div>
    """
  end
end
