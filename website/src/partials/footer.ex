defmodule NexWebsite.Partials.Footer do
  use Nex.Page

  def render(assigns) do
    ~H"""
    <footer class="footer p-10 bg-base-200 text-base-content mt-20 border-t border-gray-100">
      <aside>
        <div class="text-2xl font-black tracking-tighter mb-2">
          <span class="text-claude-purple">Nex</span>
        </div>
        <p>Nex Framework<br/>The minimalist way to build Elixir apps.</p>
        <p class="text-xs mt-4 text-claude-muted">© 2025 Nex Project. All rights reserved.</p>
      </aside>
      <nav>
        <h6 class="footer-title">Framework</h6>
        <a href="/features" class="link link-hover">Features</a>
        <a href="/getting_started" class="link link-hover">Getting Started</a>
        <a href="https://github.com/gofenix/nex" class="link link-hover">Source Code</a>
      </nav>
      <nav>
        <h6 class="footer-title">Community</h6>
        <a href="https://github.com/gofenix/nex/issues" class="link link-hover">Issues</a>
        <a href="https://github.com/gofenix/nex/discussions" class="link link-hover">Discussions</a>
      </nav>
      <nav>
        <h6 class="footer-title">Legal</h6>
        <a class="link link-hover">MIT License</a>
      </nav>
    </footer>
    """
  end
end
