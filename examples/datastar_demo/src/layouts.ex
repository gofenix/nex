defmodule DatastarDemo.Layouts do
  use Nex

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>{@title || "Datastar Demo"}</title>

        <!-- Datastar CDN -->
        <script type="module" src="https://cdn.jsdelivr.net/gh/starfederation/datastar@1.0.0-RC.7/bundles/datastar.js"></script>
        <!-- Tailwind CSS -->
        <script src="https://cdn.tailwindcss.com"></script>
      </head>
      <body class="bg-gray-100 min-h-screen">
        <div class="container mx-auto px-4 py-8">
          <nav class="mb-8 bg-white rounded-lg shadow p-4">
            <h1 class="text-2xl font-bold text-gray-800 mb-4">Datastar Demo</h1>
            <div class="flex gap-3 flex-wrap">
              <a href="/" class="px-3 py-1 bg-blue-100 text-blue-800 rounded hover:bg-blue-200">第 1 课：Getting Started</a>
              <a href="/signals" class="px-3 py-1 bg-green-100 text-green-800 rounded hover:bg-green-200">第 2 课：Reactive Signals</a>
              <a href="/expressions" class="px-3 py-1 bg-purple-100 text-purple-800 rounded hover:bg-purple-200">第 3 课：Expressions</a>
              <a href="/requests" class="px-3 py-1 bg-orange-100 text-orange-800 rounded hover:bg-orange-200">第 4 课：Backend Requests</a>
              <a href="/tao" class="px-3 py-1 bg-red-100 text-red-800 rounded hover:bg-red-200">第 5 课：The Tao</a>
            </div>
          </nav>

          <main>
            {raw(@inner_content)}
          </main>
        </div>
      </body>
    </html>
    """
  end
end
