defmodule NexWebsite.Pages.Features do
  use Nex
  alias NexWebsite.CodeExamples

  def mount(_params) do
    %{
      title: "Features - Nex Framework",
      htmx_action_code: CodeExamples.get("htmx_action.md") |> CodeExamples.format_for_display(),
      sse_stream_code: CodeExamples.get("sse_stream.md") |> CodeExamples.format_for_display(),
      routing_example: """
    <div style="background: #1C1C1E; padding: 1.25rem 1.5rem; overflow-x: auto;"><pre><code style="color: #E8E8E8; font-family: monospace; font-size: 0.8rem; line-height: 1.65;">src/pages/index.ex       GET /
    src/pages/about.ex       GET /about
    src/pages/blog/[id].ex   GET /blog/:id
    src/pages/[...path].ex   GET /*</code></pre></div>
    """
    }
  end

  def render(assigns) do
    ~H"""
    <div class="py-20 px-6 md:px-10 text-center" style="background: #FAFAF8; border-bottom: 1px solid #EBEBEB;">
      <div class="max-w-3xl mx-auto">
        <p class="text-xs font-semibold uppercase tracking-widest mb-4" style="color: #9B7EBD;">Features</p>
        <h1 class="text-5xl md:text-6xl font-extrabold mb-5" style="color: #111; letter-spacing: -0.04em;">Everything you need.<br/>Nothing you don&apos;t.</h1>
        <p class="text-xl" style="color: #666;">Server-side rendering with HTMX. Build modern web apps without JavaScript complexity.</p>
      </div>
    </div>

    <div class="max-w-5xl mx-auto px-6 md:px-10 py-16 space-y-24">

      <section class="grid md:grid-cols-2 gap-12 items-center">
        <div>
          <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full mb-5" style="background: #F0EBF8; color: #7B5FA8; border: 1px solid #D4C5E8;">New in v0.3</span>
          <h2 class="text-3xl font-bold mb-4" style="color: #111; letter-spacing: -0.02em;">AI-Native &amp; Vibe Coding</h2>
          <p class="text-base leading-relaxed mb-5" style="color: #555;">
            Nex is built for the AI era. <strong style="color: #111;">Locality of Behavior (LoB)</strong> means every feature lives in one file. AI agents build full features by reading a single file.
          </p>
          <ul class="space-y-2.5">
            <li class="flex items-center gap-2.5 text-sm" style="color: #555;">
              <svg class="w-4 h-4 flex-shrink-0" style="color: #9B7EBD;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
              One file = one complete feature
            </li>
            <li class="flex items-center gap-2.5 text-sm" style="color: #555;">
              <svg class="w-4 h-4 flex-shrink-0" style="color: #9B7EBD;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
              AGENTS.md support for AI coding assistants
            </li>
            <li class="flex items-center gap-2.5 text-sm" style="color: #555;">
              <svg class="w-4 h-4 flex-shrink-0" style="color: #9B7EBD;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
              Zero boilerplate means less for AI to get wrong
            </li>
          </ul>
        </div>
        <div class="rounded-2xl overflow-hidden" style="border: 1px solid #2A2A2A; box-shadow: 0 8px 32px rgba(0,0,0,0.12);">
          <div class="px-4 py-2.5 flex items-center gap-2" style="background: #1C1C1E; border-bottom: 1px solid #2A2A2A;">
            <span class="w-3 h-3 rounded-full" style="background: #FF5F57;"></span>
            <span class="w-3 h-3 rounded-full" style="background: #FEBC2E;"></span>
            <span class="w-3 h-3 rounded-full" style="background: #28C840;"></span>
            <span class="text-xs ml-2" style="color: #666;">src/pages/tasks.ex</span>
          </div>
          {raw(@htmx_action_code)}
        </div>
      </section>

      <div style="border-top: 1px solid #EBEBEB;"></div>

      <section class="grid md:grid-cols-2 gap-12 items-center">
        <div class="order-2 md:order-1 rounded-2xl overflow-hidden" style="border: 1px solid #2A2A2A; box-shadow: 0 8px 32px rgba(0,0,0,0.12);">
          <div class="px-4 py-2.5 flex items-center gap-2" style="background: #1C1C1E; border-bottom: 1px solid #2A2A2A;">
            <span class="w-3 h-3 rounded-full" style="background: #FF5F57;"></span>
            <span class="w-3 h-3 rounded-full" style="background: #FEBC2E;"></span>
            <span class="w-3 h-3 rounded-full" style="background: #28C840;"></span>
            <span class="text-xs ml-2" style="color: #666;">file system to routes</span>
          </div>
          {raw(@routing_example)}
        </div>
        <div class="order-1 md:order-2">
          <h2 class="text-3xl font-bold mb-4" style="color: #111; letter-spacing: -0.02em;">File-based Routing</h2>
          <p class="text-base leading-relaxed mb-5" style="color: #555;">
            Your file system is your router. Drop a file in <code class="text-purple-700 bg-purple-50 px-1.5 py-0.5 rounded text-sm">src/pages/</code> and it automatically becomes a route.
          </p>
          <ul class="space-y-2.5">
            <li class="flex items-center gap-2.5 text-sm" style="color: #555;">
              <svg class="w-4 h-4 flex-shrink-0" style="color: #9B7EBD;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
              Static, dynamic [id], and catch-all [...path] routes
            </li>
            <li class="flex items-center gap-2.5 text-sm" style="color: #555;">
              <svg class="w-4 h-4 flex-shrink-0" style="color: #9B7EBD;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
              Pages in src/pages/, APIs in src/api/
            </li>
            <li class="flex items-center gap-2.5 text-sm" style="color: #555;">
              <svg class="w-4 h-4 flex-shrink-0" style="color: #9B7EBD;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
              Hot reload detects new files automatically
            </li>
          </ul>
        </div>
      </section>

      <div style="border-top: 1px solid #EBEBEB;"></div>

      <section class="grid md:grid-cols-2 gap-12 items-start">
        <div>
          <h2 class="text-3xl font-bold mb-4" style="color: #111; letter-spacing: -0.02em;">Unified Interface</h2>
          <p class="text-base leading-relaxed mb-5" style="color: #555;">
            Every module uses the same <code class="text-purple-700 bg-purple-50 px-1.5 py-0.5 rounded text-sm">use Nex</code> statement. Pages, APIs, and components all share the same interface.
          </p>
          <div class="rounded-2xl overflow-hidden" style="border: 1px solid #2A2A2A; box-shadow: 0 4px 16px rgba(0,0,0,0.1);">
            {raw(@htmx_action_code)}
          </div>
        </div>
        <div>
          <h2 class="text-3xl font-bold mb-4" style="color: #111; letter-spacing: -0.02em;">Server-Sent Events</h2>
          <p class="text-base leading-relaxed mb-5" style="color: #555;">
            Real-time streaming with <code class="text-purple-700 bg-purple-50 px-1.5 py-0.5 rounded text-sm">Nex.stream/1</code>. Perfect for AI chat, live dashboards, and progress bars.
          </p>
          <div class="rounded-2xl overflow-hidden" style="border: 1px solid #2A2A2A; box-shadow: 0 4px 16px rgba(0,0,0,0.1);">
            {raw(@sse_stream_code)}
          </div>
        </div>
      </section>

      <div style="border-top: 1px solid #EBEBEB;"></div>

      <section class="grid md:grid-cols-3 gap-6">
        <div class="p-7 rounded-2xl" style="background: #FAFAF8; border: 1px solid #EBEBEB;">
          <div class="w-10 h-10 rounded-xl flex items-center justify-center mb-4" style="background: #F0EBF8;">
            <svg class="w-5 h-5" style="color: #7B5FA8;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/></svg>
          </div>
          <h3 class="font-bold mb-2" style="color: #111;">Automatic Security</h3>
          <p class="text-sm leading-relaxed" style="color: #666;">CSRF tokens auto-injected into every form and HTMX request. Security by default, always on.</p>
        </div>
        <div class="p-7 rounded-2xl" style="background: #FAFAF8; border: 1px solid #EBEBEB;">
          <div class="w-10 h-10 rounded-xl flex items-center justify-center mb-4" style="background: #F0EBF8;">
            <svg class="w-5 h-5" style="color: #7B5FA8;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/></svg>
          </div>
          <h3 class="font-bold mb-2" style="color: #111;">Hot Reload</h3>
          <p class="text-sm leading-relaxed" style="color: #666;">Instant file change detection via WebSocket. Edit your code and see changes immediately, no build step.</p>
        </div>
        <div class="p-7 rounded-2xl" style="background: #FAFAF8; border: 1px solid #EBEBEB;">
          <div class="w-10 h-10 rounded-xl flex items-center justify-center mb-4" style="background: #F0EBF8;">
            <svg class="w-5 h-5" style="color: #7B5FA8;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01"/></svg>
          </div>
          <h3 class="font-bold mb-2" style="color: #111;">CDN-First Design</h3>
          <p class="text-sm leading-relaxed" style="color: #666;">No build step required. Use Tailwind CSS and HTMX via CDN. No Node.js, no Webpack, no npm.</p>
        </div>
      </section>
    </div>

    <div class="py-20 px-6 md:px-10 text-center" style="background: #FAFAF8; border-top: 1px solid #EBEBEB;">
      <div class="max-w-xl mx-auto">
        <h3 class="text-3xl font-bold mb-4" style="color: #111; letter-spacing: -0.02em;">Ready to build something amazing?</h3>
        <p class="text-lg mb-8" style="color: #666;">Start with our quick setup guide and explore real-world examples.</p>
        <div class="flex flex-col sm:flex-row gap-3 justify-center">
          <a href="/getting_started" class="inline-flex items-center justify-center gap-2 text-base font-semibold text-white px-7 py-3 rounded-full transition-all hover:opacity-90" style="background: linear-gradient(135deg, #9B7EBD, #7B5FA8); box-shadow: 0 4px 20px rgba(123,95,168,0.3);">
            Get Started
          </a>
          <a href="https://github.com/gofenix/nex/tree/main/examples" target="_blank" class="inline-flex items-center justify-center gap-2 text-base font-medium px-7 py-3 rounded-full transition-all hover:bg-gray-100" style="color: #444; background: white; border: 1px solid #E0E0E0;">
            View Examples
          </a>
        </div>
      </div>
    </div>
    """
  end
end
