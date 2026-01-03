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
            <div class="flex gap-4">
              <a href="/" class="text-blue-600 hover:text-blue-800">Counter</a>
              <a href="/form" class="text-blue-600 hover:text-blue-800">Form Validation</a>
              <a href="/chat" class="text-blue-600 hover:text-blue-800">SSE Chat</a>
              <a href="/todos" class="text-blue-600 hover:text-blue-800">Todos</a>
              <a href="/advanced" class="text-blue-600 hover:text-blue-800">Advanced</a>
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
