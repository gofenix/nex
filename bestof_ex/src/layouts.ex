defmodule BestofEx.Layouts do
  use Nex

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" data-theme="bestofex">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>{@title}</title>
        <script src="https://cdn.tailwindcss.com?plugins=forms,typography,aspect-ratio"></script>
        <link href="https://cdn.jsdelivr.net/npm/daisyui@4.12.23/dist/full.min.css" rel="stylesheet" type="text/css" />
        <script src="https://unpkg.com/htmx.org@2.0.4"></script>
        {meta_tag()}
        <style>
          /* Bestofex Premium Theme - Refined flat design with depth */
          :root {
            /* Primary - Softer Elixir Purple */
            --primary: #5D3A7A;
            --primary-light: #7C5295;
            --primary-dark: #4A2D61;
            /* Accent - Warm Amber (more refined than bright orange) */
            --accent: #D97706;
            --accent-light: #F59E0B;
            /* Neutrals - Softer grays */
            --gray-50: #FAFAFA;
            --gray-100: #F5F5F5;
            --gray-200: #E8E8E8;
            --gray-300: #D4D4D4;
            --gray-400: #A3A3A3;
            --gray-500: #737373;
            --gray-600: #525252;
            --gray-700: #404040;
            --gray-800: #262626;
            --gray-900: #171717;
          }
          [data-theme="bestofex"] {
            --p: 278 35% 36%;      /* Softer purple */
            --pf: 278 35% 45%;
            --a: 32 95% 43%;       /* Warm amber */
            --af: 32 95% 50%;
            --n: 0 0% 45%;         /* Neutral gray */
            --nf: 0 0% 35%;
            --b1: 0 0% 100%;       /* Pure white */
            --b2: 0 0% 98%;        /* Off-white */
            --b3: 0 0% 94%;        /* Light gray */
            --bc: 0 0% 15%;        /* Text color */
          }
          /* Text colors */
          .text-primary { color: var(--primary) !important; }
          .text-accent { color: var(--accent) !important; }
          .text-muted { color: var(--gray-500) !important; }
          /* Premium Card Styling */
          .card-premium {
            background: white;
            border: 1px solid var(--gray-200);
            border-radius: 12px;
            box-shadow:
              0 1px 2px rgba(0, 0, 0, 0.04),
              0 4px 8px rgba(0, 0, 0, 0.02);
            transition: all 0.2s ease;
          }
          .card-premium:hover {
            border-color: var(--gray-300);
            box-shadow:
              0 1px 2px rgba(0, 0, 0, 0.04),
              0 8px 16px rgba(0, 0, 0, 0.04);
            transform: translateY(-1px);
          }
          /* Glass effect for nav */
          .nav-glass {
            background: rgba(255, 255, 255, 0.92);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
            border-bottom: 1px solid var(--gray-200);
          }
          /* Refined badge */
          .badge-premium {
            background: transparent;
            border: 1px solid var(--gray-300);
            color: var(--gray-600);
            transition: all 0.15s ease;
          }
          .badge-premium:hover {
            background: var(--primary);
            border-color: var(--primary);
            color: white;
          }
          /* Star styling */
          .star-count {
            color: var(--accent);
            font-weight: 600;
            letter-spacing: -0.01em;
          }
          /* Input refinement */
          .input-premium {
            background: white;
            border: 1px solid var(--gray-200);
            transition: all 0.15s ease;
          }
          .input-premium:focus {
            border-color: var(--primary-light);
            box-shadow: 0 0 0 3px rgba(93, 58, 122, 0.08);
          }
          /* Typing animation */
          .typing-cursor::after {
            content: "|";
            animation: blink 1s step-end infinite;
            color: var(--primary);
          }
          @keyframes blink { 50% { opacity: 0; } }
          /* Smooth transitions */
          .transition-smooth {
            transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
          }
          /* Project row styling */
          .project-row {
            border-bottom: 1px solid var(--gray-100);
          }
          .project-row:last-child {
            border-bottom: none;
          }
          /* Rank badge */
          .rank-badge {
            font-size: 0.75rem;
            font-weight: 600;
            color: var(--gray-400);
            width: 1.5rem;
            text-align: center;
          }
          .rank-badge-top {
            color: var(--accent);
          }
          /* Button refinement */
          .btn-premium {
            border-radius: 8px;
            font-weight: 500;
            transition: all 0.15s ease;
          }
          .btn-premium:hover {
            transform: translateY(-1px);
          }
          /* Tab styling */
          .tab-premium {
            border-radius: 6px;
            font-weight: 500;
            transition: all 0.15s ease;
          }
          .tab-premium.tab-active {
            background: var(--primary);
            color: white;
          }
        </style>
      </head>
      <body class="min-h-screen flex flex-col" hx-boost="true" hx-headers={hx_headers()}>
        <!-- Navigation -->
        <nav class="nav-glass sticky top-0 z-50">
          <div class="container mx-auto max-w-6xl px-4 py-3">
            <div class="flex items-center justify-between">
              <!-- Logo -->
              <a href="/" class="text-xl font-bold flex items-center gap-1.5 tracking-tight">
                <span class="text-primary">bestof</span><span class="text-accent">ex</span>
              </a>
              <!-- Nav Links -->
              <div class="hidden md:flex items-center gap-6">
                <a href="/" class="text-sm font-medium text-gray-600 hover:text-primary transition-smooth">Home</a>
                <a href="/projects" class="text-sm font-medium text-gray-600 hover:text-primary transition-smooth">Projects</a>
                <a href="/tags" class="text-sm font-medium text-gray-600 hover:text-primary transition-smooth">Tags</a>
                <a href="/trending" class="text-sm font-medium text-gray-600 hover:text-primary transition-smooth">Trending</a>
              </div>
              <!-- Search & Actions -->
              <div class="flex items-center gap-3">
                <form action="/projects" method="get" class="relative hidden sm:block">
                  <input type="search" name="q" placeholder="Search..."
                         class="input input-sm input-premium w-44 pl-3 pr-8 text-sm rounded-lg" />
                  <kbd class="absolute right-2 top-1/2 -translate-y-1/2 text-[10px] text-gray-400 font-sans">⌘K</kbd>
                </form>
                <a href="https://github.com/gofenix/nex" target="_blank"
                   class="btn btn-ghost btn-sm btn-circle btn-premium text-gray-600 hover:text-primary">
                  <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                  </svg>
                </a>
              </div>
            </div>
          </div>
        </nav>

        <!-- Main Content -->
        <main class="flex-1 bg-gray-50">
          {raw(@inner_content)}
        </main>

        <!-- Footer -->
        <footer class="bg-white border-t border-gray-200 mt-auto">
          <div class="container mx-auto max-w-6xl px-4 py-8">
            <div class="flex flex-col sm:flex-row justify-between items-center gap-4 text-sm text-gray-500">
              <p>Best of Elixir — Curated open-source projects in the Elixir ecosystem</p>
              <p>Built with <a href="https://github.com/gofenix/nex" class="text-primary hover:text-accent transition-smooth" target="_blank">Nex Framework</a></p>
            </div>
          </div>
        </footer>
      </body>
    </html>
    """
  end
end
