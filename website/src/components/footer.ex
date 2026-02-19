defmodule NexWebsite.Components.Footer do
  use Nex

  def render(assigns) do
    ~H"""
    <footer style="background: #111111; color: #999;">
      <div class="max-w-6xl mx-auto px-6 md:px-10 py-16">
        <div class="grid grid-cols-2 md:grid-cols-5 gap-10">
          <!-- Brand -->
          <div class="col-span-2">
            <a href="/" class="flex items-center gap-2.5 mb-4 group">
              <div class="w-7 h-7 rounded-lg flex items-center justify-center" style="background: linear-gradient(135deg, #9B7EBD, #7B5FA8);">
                <span class="text-white font-bold text-xs">N</span>
              </div>
              <span class="font-semibold text-white text-base">Nex</span>
            </a>
            <p class="text-sm leading-relaxed mb-5" style="color: #777;">
              The minimalist Elixir web framework.<br/>
              Built for Vibe Coding and rapid shipping.
            </p>
            <div class="flex items-center gap-3">
              <a href="https://hex.pm/packages/nex_core" target="_blank" class="text-xs px-2.5 py-1 rounded-full font-medium transition-colors" style="background: #1E1E1E; color: #9B7EBD; border: 1px solid #333;">
                hex.pm
              </a>
              <a href="https://github.com/gofenix/nex" target="_blank" class="text-xs px-2.5 py-1 rounded-full font-medium transition-colors" style="background: #1E1E1E; color: #999; border: 1px solid #333;">
                MIT License
              </a>
            </div>
          </div>

          <!-- Product -->
          <div>
            <h6 class="text-xs font-semibold uppercase tracking-widest mb-4" style="color: #555; letter-spacing: 0.1em;">Product</h6>
            <div class="space-y-2.5">
              <div><a href="/features" class="text-sm hover:text-white transition-colors" style="color: #777;">Features</a></div>
              <div><a href="/docs" class="text-sm hover:text-white transition-colors" style="color: #777;">Documentation</a></div>
              <div><a href="/getting_started" class="text-sm hover:text-white transition-colors" style="color: #777;">Quick Start</a></div>
              <div><a href="https://github.com/gofenix/nex/tree/main/examples" class="text-sm hover:text-white transition-colors" style="color: #777;">Examples</a></div>
            </div>
          </div>

          <!-- Resources -->
          <div>
            <h6 class="text-xs font-semibold uppercase tracking-widest mb-4" style="color: #555; letter-spacing: 0.1em;">Resources</h6>
            <div class="space-y-2.5">
              <div><a href="https://github.com/gofenix/nex" target="_blank" class="text-sm hover:text-white transition-colors" style="color: #777;">GitHub</a></div>
              <div><a href="https://hexdocs.pm/nex_core" target="_blank" class="text-sm hover:text-white transition-colors" style="color: #777;">HexDocs</a></div>
              <div><a href="https://github.com/gofenix/nex/issues" target="_blank" class="text-sm hover:text-white transition-colors" style="color: #777;">Issues</a></div>
              <div><a href="https://github.com/gofenix/nex/discussions" target="_blank" class="text-sm hover:text-white transition-colors" style="color: #777;">Discussions</a></div>
            </div>
          </div>

          <!-- Deploy -->
          <div>
            <h6 class="text-xs font-semibold uppercase tracking-widest mb-4" style="color: #555; letter-spacing: 0.1em;">Deploy</h6>
            <div class="space-y-2.5">
              <div><a href="https://fly.io" target="_blank" class="text-sm hover:text-white transition-colors" style="color: #777;">Fly.io</a></div>
              <div><a href="https://railway.app" target="_blank" class="text-sm hover:text-white transition-colors" style="color: #777;">Railway</a></div>
              <div><a href="https://render.com" target="_blank" class="text-sm hover:text-white transition-colors" style="color: #777;">Render</a></div>
            </div>
          </div>
        </div>

        <div class="mt-14 pt-6 flex flex-col md:flex-row items-center justify-between gap-4" style="border-top: 1px solid #222;">
          <p class="text-xs" style="color: #555;">© 2026 Nex Project. Open source under the MIT License.</p>
          <p class="text-xs" style="color: #444;">Built with Nex · Deployed on Fly.io</p>
        </div>
      </div>
    </footer>
    """
  end
end
