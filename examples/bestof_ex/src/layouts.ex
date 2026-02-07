defmodule BestofEx.Layouts do
  use Nex

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" data-theme="emerald">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>{@title}</title>
        <script src="https://cdn.tailwindcss.com?plugins=forms,typography,aspect-ratio"></script>
        <link href="https://cdn.jsdelivr.net/npm/daisyui@4.12.23/dist/full.min.css" rel="stylesheet" type="text/css" />
        <script src="https://unpkg.com/htmx.org@2.0.4"></script>
        {meta_tag()}
        <style>
          .star-icon { color: #f59e0b; }
          .project-row:hover { background-color: oklch(var(--b2)); }
        </style>
      </head>
      <body class="min-h-screen bg-base-200 flex flex-col" hx-boost="true" hx-headers={hx_headers()}>
        <nav class="navbar bg-base-100 border-b border-base-300 sticky top-0 z-50">
          <div class="max-w-6xl mx-auto w-full px-4">
            <div class="flex-1 gap-2">
              <a href="/" class="text-xl font-bold text-primary flex items-center gap-2">
                <svg class="w-6 h-6" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z"/></svg>
                Best of Elixir
              </a>
            </div>
            <div class="flex-none">
              <ul class="menu menu-horizontal px-1 gap-1">
                <li><a href="/" class="text-sm font-medium">Home</a></li>
                <li><a href="/projects" class="text-sm font-medium">Projects</a></li>
                <li><a href="/tags" class="text-sm font-medium">Tags</a></li>
                <li><a href="/trending" class="text-sm font-medium">Trending</a></li>
              </ul>
            </div>
          </div>
        </nav>
        <main class="max-w-6xl mx-auto w-full px-4 py-8 flex-1">
          {raw(@inner_content)}
        </main>
        <footer class="border-t border-base-300 bg-base-100">
          <div class="max-w-6xl mx-auto px-4 py-6 text-center text-sm text-base-content/60">
            <p>Best of Elixir — A curated list of the best open-source projects in the Elixir ecosystem.</p>
            <p class="mt-1">Built with <a href="https://github.com/gofenix/nex" class="link link-primary" target="_blank">Nex Framework</a></p>
          </div>
        </footer>
      </body>
    </html>
    """
  end
end
