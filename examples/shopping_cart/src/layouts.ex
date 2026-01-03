defmodule ShoppingCart.Layouts do
  use Nex

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>{@title || "Shopping Cart"}</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <script src="https://unpkg.com/htmx.org@1.9.10"></script>
      </head>
      <body class="bg-gray-100">
        <nav class="bg-white shadow-md">
          <div class="max-w-2xl mx-auto px-6 py-4">
            <h1 class="text-2xl font-bold text-gray-800">🛒 Shopping Cart Demo</h1>
            <p class="text-sm text-gray-600 mt-1">Learn Nex.Store with a real shopping cart</p>
          </div>
        </nav>

        <main class="py-8">
          {raw(@inner_content)}
        </main>

        <footer class="bg-gray-800 text-white text-center py-4 mt-12">
          <p class="text-sm">Shopping Cart Example - Nex Framework</p>
        </footer>
      </body>
    </html>
    """
  end
end
