defmodule NexWebsite.Components.Footer do
  use Nex

  def render(assigns) do
    ~H"""
    <footer class="footer p-10 bg-base-200 text-base-content mt-20 border-t border-gray-100">
      <aside>
        <div class="text-2xl font-black tracking-tighter mb-2">
          <span class="text-claude-purple">Nex</span>
        </div>
        <p>Nex Framework<br/>The minimalist way to build Elixir apps.</p>
        <p class="text-xs mt-4 text-claude-muted">© 2025 Nex Project. MIT License.</p>
      </aside>
      <nav>
        <h6 class="footer-title">Framework</h6>
        <a href="/features" class="link link-hover">Features</a>
        <a href="/getting_started" class="link link-hover">Getting Started</a>
        <a href="https://github.com/gofenix/nex/tree/main/examples" class="link link-hover">Examples</a>
        <a href="https://hex.pm/packages/nex_core" class="link link-hover">Hex Package</a>
      </nav>
      <nav>
        <h6 class="footer-title">Resources</h6>
        <a href="https://github.com/gofenix/nex" class="link link-hover">GitHub</a>
        <a href="https://github.com/gofenix/nex/issues" class="link link-hover">Issues</a>
        <a href="https://github.com/gofenix/nex/discussions" class="link link-hover">Discussions</a>
        <a href="https://hexdocs.pm/nex_core" class="link link-hover">Documentation</a>
      </nav>
      <nav>
        <h6 class="footer-title">Deploy</h6>
        <a href="https://railway.app" class="link link-hover">Railway</a>
        <a href="https://fly.io" class="link link-hover">Fly.io</a>
        <a href="https://render.com" class="link link-hover">Render</a>
      </nav>
    </footer>
    """
  end
end
