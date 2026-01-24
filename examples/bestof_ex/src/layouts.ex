defmodule BestofEx.Layouts do
  use Nex

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
        {meta_tag()}
      </head>
      <body class="min-h-screen bg-base-200" hx-boost="true" hx-headers={hx_headers()}>
        <nav class="navbar bg-base-100 shadow-sm">
          <div class="max-w-6xl mx-auto w-full px-4">
            <div class="flex-1">
              <a href="/" class="btn btn-ghost text-xl font-bold">Best of Elixir</a>
            </div>
            <div class="flex-none gap-2">
              <a href="/projects" class="btn btn-ghost btn-sm">Projects</a>
              <a href="/tags" class="btn btn-ghost btn-sm">Tags</a>
              <a href="/trending" class="btn btn-ghost btn-sm">Trending</a>
            </div>
          </div>
        </nav>
        <main class="max-w-6xl mx-auto px-4 py-8">
          {raw(@inner_content)}
        </main>
        <footer class="footer footer-center p-4 bg-base-100 text-base-content border-t">
          <aside>
            <p>Best of Elixir - A curated list of the best Elixir libraries and tools.</p>
          </aside>
        </footer>
      </body>
    </html>
    """
  end
end
