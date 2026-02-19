defmodule NexWebsite.Layouts do
  use Nex

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

          /* ============================================
             DOCS PAGE STYLES
          ============================================ */

          /* Sidebar nav items */
          .docs-nav-default {
            color: #555;
            font-weight: 400;
          }
          .docs-nav-default:hover {
            background: #F5F5F0;
            color: #1A1A1A;
          }
          .docs-nav-active {
            background: #F0EBF8;
            color: #7B5FA8;
            font-weight: 500;
          }

          /* Docs prose — clean, readable typography */
          .docs-prose {
            color: #2D2D2D;
            font-size: 1rem;
            line-height: 1.75;
          }

          .docs-prose h1 {
            font-size: 2rem;
            font-weight: 700;
            letter-spacing: -0.03em;
            color: #111;
            margin-bottom: 0.5rem;
            margin-top: 0;
            line-height: 1.2;
          }

          .docs-prose h2 {
            font-size: 1.35rem;
            font-weight: 650;
            letter-spacing: -0.02em;
            color: #111;
            margin-top: 2.5rem;
            margin-bottom: 0.75rem;
            padding-bottom: 0.5rem;
            border-bottom: 1px solid #EBEBEB;
            line-height: 1.3;
          }

          .docs-prose h3 {
            font-size: 1.1rem;
            font-weight: 600;
            color: #222;
            margin-top: 2rem;
            margin-bottom: 0.5rem;
            line-height: 1.4;
          }

          .docs-prose h4 {
            font-size: 0.95rem;
            font-weight: 600;
            color: #333;
            margin-top: 1.5rem;
            margin-bottom: 0.4rem;
            text-transform: uppercase;
            letter-spacing: 0.04em;
          }

          .docs-prose p {
            margin-bottom: 1.1rem;
            color: #444;
          }

          .docs-prose a {
            color: #7B5FA8;
            text-decoration: underline;
            text-decoration-color: rgba(123, 95, 168, 0.3);
            text-underline-offset: 2px;
            transition: text-decoration-color 0.15s;
          }
          .docs-prose a:hover {
            text-decoration-color: #7B5FA8;
          }

          .docs-prose ul, .docs-prose ol {
            padding-left: 1.5rem;
            margin-bottom: 1.1rem;
          }
          .docs-prose ul { list-style-type: disc; }
          .docs-prose ol { list-style-type: decimal; }
          .docs-prose li {
            margin-bottom: 0.35rem;
            color: #444;
          }
          .docs-prose li > ul, .docs-prose li > ol {
            margin-top: 0.35rem;
            margin-bottom: 0.35rem;
          }

          /* Inline code */
          .docs-prose code {
            font-family: 'SF Mono', 'Monaco', 'Menlo', 'Consolas', monospace;
            font-size: 0.85em;
            font-weight: 500;
            background: #F0EBF8;
            color: #6B4FA0;
            padding: 0.15em 0.45em;
            border-radius: 4px;
            border: 1px solid #E0D5F0;
          }

          /* Code blocks */
          .docs-prose pre {
            margin: 1.5rem 0;
            padding: 0;
            background: transparent;
            border-radius: 10px;
            overflow: hidden;
            border: 1px solid #2A2A2A;
            box-shadow: 0 4px 16px rgba(0,0,0,0.12), 0 1px 4px rgba(0,0,0,0.08);
          }
          .docs-prose pre code {
            display: block;
            padding: 1.25rem 1.5rem;
            background: #1C1C1E;
            color: #E8E8E8;
            font-size: 0.875rem;
            line-height: 1.65;
            overflow-x: auto;
            border: none;
            border-radius: 0;
            font-weight: 400;
          }

          /* Blockquote / callout */
          .docs-prose blockquote {
            margin: 1.5rem 0;
            padding: 0.875rem 1.25rem;
            background: #FFFBF0;
            border-left: 3px solid #D4A574;
            border-radius: 0 8px 8px 0;
            color: #5A4A30;
            font-style: normal;
          }
          .docs-prose blockquote p {
            margin: 0;
            color: #5A4A30;
          }
          .docs-prose blockquote strong {
            color: #3D2E10;
          }

          /* Tables */
          .docs-prose table {
            width: 100%;
            border-collapse: collapse;
            margin: 1.5rem 0;
            font-size: 0.9rem;
          }
          .docs-prose th {
            text-align: left;
            padding: 0.6rem 1rem;
            background: #F5F5F0;
            font-weight: 600;
            color: #333;
            border-bottom: 2px solid #DDDDD8;
            font-size: 0.8rem;
            text-transform: uppercase;
            letter-spacing: 0.04em;
          }
          .docs-prose td {
            padding: 0.6rem 1rem;
            border-bottom: 1px solid #EBEBEB;
            color: #444;
            vertical-align: top;
          }
          .docs-prose tr:last-child td { border-bottom: none; }
          .docs-prose tr:hover td { background: #FAFAF8; }

          /* Strong / em */
          .docs-prose strong { color: #111; font-weight: 600; }
          .docs-prose em { color: #555; }

          /* HR */
          .docs-prose hr {
            border: none;
            border-top: 1px solid #EBEBEB;
            margin: 2rem 0;
          }

          /* Docs layout: hide global navbar and footer on docs pages */
          body:has(.docs-layout) #global-nav,
          body:has(.docs-layout) #global-footer { display: none; }
          body:has(.docs-layout) > main { padding: 0; margin: 0; }
        </style>
      </head>
      <body hx-boost="true">
        <div id="global-nav" class="docs-hide-on-docs">{NexWebsite.Components.Nav.render(assigns)}</div>
        <main>
          {raw(@inner_content)}
        </main>
        <div id="global-footer" class="docs-hide-on-docs">{NexWebsite.Components.Footer.render(assigns)}</div>
        <script>
          // Function to highlight all code blocks
          function highlightCode() {
            document.querySelectorAll('pre code').forEach((block) => {
              // Remove existing highlighting classes
              block.className = block.className.replace(/hljs-[^\s]*/g, '').trim();
              // Re-highlight
              hljs.highlightElement(block);
            });
          }

          // Initial highlight on page load
          document.addEventListener('DOMContentLoaded', highlightCode);

          // Re-highlight after HTMX swaps content (for language switching)
          document.body.addEventListener('htmx:afterSwap', highlightCode);
        </script>
      </body>
    </html>
    """
  end
end
