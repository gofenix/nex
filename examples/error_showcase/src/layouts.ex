defmodule ErrorShowcase.Layouts do
  use Nex

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>{@title || "Error Handling"}</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <script src="https://unpkg.com/htmx.org@2.0.4"></script>
        <script src="https://unpkg.com/htmx-ext-response-targets@2.0.0/response-targets.js"></script>
      </head>
      <body class="bg-gray-100">
        <nav class="bg-white shadow-md">
          <div class="max-w-4xl mx-auto px-6 py-4">
            <a href="/" class="text-2xl font-bold text-gray-800 hover:text-blue-600">
              ⚠️ Error Handling Showcase
            </a>
            <p class="text-sm text-gray-600 mt-1">Learn how Nex intelligently handles errors based on request type</p>
          </div>
        </nav>

        <main class="py-8">
          {raw(@inner_content)}
        </main>

        <footer class="bg-gray-800 text-white text-center py-4 mt-12">
          <p class="text-sm">Error Handling Example - Nex Framework</p>
        </footer>
      </body>
    </html>
    """
  end
end
