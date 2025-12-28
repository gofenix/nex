defmodule NexWebsite.Layouts do
  use Nex.Page

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" data-theme="cupcake">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>{@title || "Nex - The Minimalist Elixir Web Framework"}</title>

        <!-- SEO Meta Tags -->
        <meta name="description" content="Nex is a minimalist Elixir web framework powered by HTMX. Perfect for rapid prototyping, indie hackers, and learning server-side rendering. Zero config, Docker-ready.">
        <meta name="keywords" content="Elixir, HTMX, web framework, minimalist, server-side rendering, rapid prototyping, indie hacker">
        <meta name="author" content="Nex Framework">

        <!-- Open Graph / Facebook -->
        <meta property="og:type" content="website">
        <meta property="og:url" content="https://nex-framework.dev/">
        <meta property="og:title" content="Nex - The Minimalist Elixir Web Framework">
        <meta property="og:description" content="The simplest way to build HTMX apps in Elixir. Perfect for rapid prototyping, indie hackers, and learning server-side rendering.">

        <!-- Twitter -->
        <meta property="twitter:card" content="summary_large_image">
        <meta property="twitter:url" content="https://nex-framework.dev/">
        <meta property="twitter:title" content="Nex - The Minimalist Elixir Web Framework">
        <meta property="twitter:description" content="The simplest way to build HTMX apps in Elixir. Perfect for rapid prototyping, indie hackers, and learning server-side rendering.">

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
            /* Claude's actual color palette */
            --claude-bg: #F5F5F0;
            --claude-text: #1A1A1A;
            --claude-purple: #9B7EBD;
            --claude-gold: #D4A574;
            --claude-muted: #6B6B6B;
            --claude-accent: #7B5FA8;
            --claude-light: #FAFAF8;
            --claude-border: #E5E5E0;
          }

          * {
            -webkit-font-smoothing: antialiased;
            -moz-osx-font-smoothing: grayscale;
          }

          body {
            background-color: var(--claude-bg);
            color: var(--claude-text);
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            font-weight: 400;
            line-height: 1.6;
          }

          /* Claude-style buttons */
          .btn-claude-purple {
            background-color: var(--claude-purple);
            color: white;
            border: none;
            font-weight: 500;
            letter-spacing: -0.02em;
            transition: all 0.15s cubic-bezier(0.4, 0, 0.2, 1);
            box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
          }
          .btn-claude-purple:hover {
            background-color: var(--claude-accent);
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(155, 126, 189, 0.25);
          }
          .btn-claude-purple:active {
            transform: translateY(0);
          }

          /* Text colors */
          .text-claude-purple { color: var(--claude-purple); }
          .text-claude-gold { color: var(--claude-gold); }
          .text-claude-muted { color: var(--claude-muted); }
          .bg-claude-bg { background-color: var(--claude-bg); }
          .bg-claude-light { background-color: var(--claude-light); }
          .border-claude-purple { border-color: var(--claude-purple); }

          /* Navbar */
          .navbar {
            background-color: rgba(250, 250, 248, 0.98);
            backdrop-filter: blur(8px) saturate(180%);
            border-bottom: 1px solid var(--claude-border);
            box-shadow: 0 1px 2px rgba(0, 0, 0, 0.04);
          }
          .menu li > a {
            transition: all 0.2s ease;
            border-radius: 8px;
          }
          .menu li > a:hover {
            background-color: rgba(164, 119, 100, 0.08);
            color: var(--claude-purple);
          }

          /* Cards */
          .card {
            transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
            border-radius: 12px;
          }
          .card:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 16px rgba(0, 0, 0, 0.06), 0 2px 4px rgba(0, 0, 0, 0.04);
          }

          /* Hero section */
          .hero {
            background: linear-gradient(180deg, #FAFAF8 0%, #F5F5F0 100%);
          }

          /* Typography */
          h1, h2, h3, h4, h5, h6 {
            font-weight: 600;
            letter-spacing: -0.02em;
            line-height: 1.2;
          }

          h1 { font-size: clamp(2.5rem, 5vw, 4rem); }
          h2 { font-size: clamp(2rem, 4vw, 3rem); }
          h3 { font-size: clamp(1.5rem, 3vw, 2rem); }

          /* Code blocks */
          pre {
            margin: 0;
            padding: 1.25rem;
            background-color: #1A1A1A;
            overflow-x: auto;
            border-radius: 8px;
            border: 1px solid rgba(255, 255, 255, 0.1);
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.12);
          }
          pre code {
            font-family: 'SF Mono', 'Monaco', 'Menlo', 'Consolas', monospace;
            font-size: 0.875rem;
            line-height: 1.5;
            font-weight: 400;
          }

          code {
            font-family: 'SF Mono', 'Monaco', 'Menlo', 'Consolas', monospace;
            font-size: 0.9em;
            font-weight: 500;
          }

          /* Smooth animations */
          @keyframes fadeInUp {
            from {
              opacity: 0;
              transform: translateY(20px);
            }
            to {
              opacity: 1;
              transform: translateY(0);
            }
          }

          .animate-fade-in-up {
            animation: fadeInUp 0.6s ease-out;
          }

          /* Badge */
          .badge {
            font-weight: 500;
            letter-spacing: -0.01em;
            font-size: 0.875rem;
          }

          /* Solid color text - no gradient */
          .gradient-text {
            color: var(--claude-purple);
          }

          /* Spacing utilities */
          .section-padding {
            padding: clamp(3rem, 8vw, 6rem) 0;
          }

          /* Border utilities */
          .border-subtle {
            border-color: var(--claude-border);
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
