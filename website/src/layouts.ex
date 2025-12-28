defmodule NexWebsite.Layouts do
  use Nex.Page

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="zh-CN" data-theme="cupcake">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>{@title || "Nex - The Minimalist Elixir Web Framework"}</title>
        <script src="https://cdn.tailwindcss.com?plugins=typography,forms,aspect-ratio"></script>
        <link href="https://cdn.jsdelivr.net/npm/daisyui@4.12.23/dist/full.min.css" rel="stylesheet" type="text/css" />
        <link rel="preconnect" href="https://fonts.googleapis.com">
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.min.css">
        <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/languages/elixir.min.js"></script>
        <script src="https://unpkg.com/htmx.org@2.0.4"></script>
        <style>
          :root {
            --claude-bg: #F4F1EA;
            --claude-text: #2B1810;
            --claude-purple: #A47764;
            --claude-gold: #D4A574;
            --claude-muted: #6B5D54;
            --claude-accent: #8B6F47;
          }
          body {
            background-color: var(--claude-bg);
            color: var(--claude-text);
            font-family: 'Inter', sans-serif;
          }
          .btn-claude-purple {
            background-color: var(--claude-purple);
            color: white;
            border: none;
          }
          .btn-claude-purple:hover {
            background-color: var(--claude-accent);
          }
          .text-claude-purple { color: var(--claude-purple); }
          .text-claude-gold { color: var(--claude-gold); }
          .text-claude-muted { color: var(--claude-muted); }
          .bg-claude-bg { background-color: var(--claude-bg); }
          .border-claude-purple { border-color: var(--claude-purple); }

          /* Custom styles for DaisyUI overrides */
          .navbar {
            background-color: rgba(244, 241, 234, 0.95);
            backdrop-filter: blur(8px);
            border-bottom: 1px solid rgba(164, 119, 100, 0.1);
          }
          .menu li > a:hover {
            background-color: rgba(164, 119, 100, 0.1);
            color: var(--claude-purple);
          }
          .hero { background-color: var(--claude-bg); }

          /* Code block styling */
          pre {
            margin: 0;
            padding: 1.5rem;
            background-color: #1e1e1e;
            overflow-x: auto;
          }
          pre code {
            font-family: 'Courier New', Courier, monospace;
            font-size: 0.875rem;
            line-height: 1.6;
          }
        </style>
      </head>
      <body>
        {NexWebsite.Partials.Nav.render(assigns)}
        <main>
          {raw(@inner_content)}
        </main>
        {NexWebsite.Partials.Footer.render(assigns)}
        <script>
          document.addEventListener('DOMContentLoaded', function() {
            document.querySelectorAll('pre code').forEach((block) => {
              hljs.highlightElement(block);
            });
          });
        </script>
      </body>
    </html>
    """
  end
end
