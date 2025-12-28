defmodule Counter.Layouts do
  use Nex.Page

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" data-theme="light">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>{@title}</title>
        <script src="https://cdn.tailwindcss.com?plugins=forms,typography,aspect-ratio"></script>
        <link href="https://cdn.jsdelivr.net/npm/daisyui@4.12.23/dist/full.min.css" rel="stylesheet" type="text/css" />
        <script src="https://unpkg.com/htmx.org@2.0.4"></script>
      </head>
      <body class="min-h-screen bg-base-200">
        <nav class="navbar bg-base-100 shadow-sm">
          <div class="max-w-4xl mx-auto w-full px-4">
            <a href="/" class="btn btn-ghost text-xl">Counter</a>
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
