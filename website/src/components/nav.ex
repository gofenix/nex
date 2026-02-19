defmodule NexWebsite.Components.Nav do
  use Nex

  def render(assigns) do
    ~H"""
    <nav class="site-nav sticky top-0 z-50 flex items-center justify-between px-6 md:px-10 h-14" style="background: rgba(250,250,248,0.92); backdrop-filter: blur(12px); border-bottom: 1px solid rgba(0,0,0,0.06);">
      <!-- Logo -->
      <a href="/" class="flex items-center gap-2.5 group">
        <div class="w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0" style="background: linear-gradient(135deg, #9B7EBD, #7B5FA8);">
          <span class="text-white font-bold text-xs">N</span>
        </div>
        <span class="font-semibold text-gray-900 text-base tracking-tight group-hover:text-claude-purple transition-colors">Nex</span>
      </a>

      <!-- Center links (desktop) -->
      <div class="hidden md:flex items-center gap-1">
        <a href="/features" class="nav-link px-3.5 py-1.5 text-sm font-medium text-gray-600 hover:text-gray-900 rounded-lg hover:bg-gray-100 transition-all">Features</a>
        <a href="/docs" class="nav-link px-3.5 py-1.5 text-sm font-medium text-gray-600 hover:text-gray-900 rounded-lg hover:bg-gray-100 transition-all">Docs</a>
        <a href="https://github.com/gofenix/nex/tree/main/examples" class="nav-link px-3.5 py-1.5 text-sm font-medium text-gray-600 hover:text-gray-900 rounded-lg hover:bg-gray-100 transition-all">Examples</a>
        <a href="https://github.com/gofenix/nex" class="nav-link px-3.5 py-1.5 text-sm font-medium text-gray-600 hover:text-gray-900 rounded-lg hover:bg-gray-100 transition-all">GitHub</a>
      </div>

      <!-- CTA -->
      <div class="flex items-center gap-3">
        <a href="https://hex.pm/packages/nex_core" target="_blank" class="hidden md:flex items-center gap-1.5 text-xs font-medium text-gray-500 hover:text-gray-700 transition-colors">
          <span class="w-1.5 h-1.5 rounded-full bg-green-400 inline-block"></span>
          v0.3
        </a>
        <a href="/getting_started" class="flex items-center gap-1.5 text-sm font-semibold text-white px-4 py-1.5 rounded-full transition-all hover:opacity-90" style="background: linear-gradient(135deg, #9B7EBD, #7B5FA8); box-shadow: 0 2px 8px rgba(123,95,168,0.3);">
          Get Started
        </a>
      </div>
    </nav>
    """
  end
end
