defmodule Myapp.Layouts do
  use Nex.Page

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>{@title}</title>
        <script src="https://cdn.tailwindcss.com?plugins=forms,typography,aspect-ratio"></script>
        <script src="https://unpkg.com/htmx.org@2.0.4"></script>
      </head>
      <body class="bg-gray-100 min-h-screen" hx-boost="true">
        <nav class="bg-white shadow-sm border-b">
          <div class="max-w-4xl mx-auto px-4 py-3">
            <a href="/" class="text-xl font-bold text-blue-600">Myapp</a>
          </div>
        </nav>
        <main class="max-w-4xl mx-auto px-4 py-8">
          {raw(@inner_content)}
        </main>
      </body>
    </html>
    """
  end
end
