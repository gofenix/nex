defmodule NexWebsite.Components.HomeFeatures do
  use Nex

  def render(assigns) do
    ~H"""
    <section class="py-24 px-6 md:px-10" style="background: white; border-top: 1px solid #EBEBEB;">
      <div class="max-w-5xl mx-auto">
        <div class="text-center mb-16">
          <p class="text-xs font-semibold uppercase tracking-widest mb-3" style="color: #9B7EBD; letter-spacing: 0.12em;">Why Nex</p>
          <h2 class="text-4xl md:text-5xl font-bold mb-4" style="color: #111; letter-spacing: -0.03em;">Everything you need.<br/>Nothing you don't.</h2>
          <p class="text-lg max-w-xl mx-auto" style="color: #666;">Convention over configuration. One file per feature. Zero boilerplate.</p>
        </div>

        <div class="grid md:grid-cols-3 gap-6">
          <div class="p-7 rounded-2xl" style="background: #FAFAF8; border: 1px solid #EBEBEB;">
            <div class="w-10 h-10 rounded-xl flex items-center justify-center mb-5" style="background: #F0EBF8;">
              <svg class="w-5 h-5" style="color: #7B5FA8;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 21l-1 1h8l-1-1-.75-4M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/></svg>
            </div>
            <h3 class="text-lg font-bold mb-2" style="color: #111;">AI-Native by Design</h3>
            <p class="text-sm leading-relaxed" style="color: #666;">Locality of Behavior means every feature lives in one file. AI agents read one file and understand everything — no context switching between routers, controllers, and views.</p>
          </div>

          <div class="p-7 rounded-2xl" style="background: #FAFAF8; border: 1px solid #EBEBEB;">
            <div class="w-10 h-10 rounded-xl flex items-center justify-center mb-5" style="background: #F0EBF8;">
              <svg class="w-5 h-5" style="color: #7B5FA8;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"/></svg>
            </div>
            <h3 class="text-lg font-bold mb-2" style="color: #111;">Zero-Config Routing</h3>
            <p class="text-sm leading-relaxed" style="color: #666;">Drop a file in <code class="text-purple-700 bg-purple-50 px-1 rounded text-xs">src/pages/</code> and it's a route. Dynamic <code class="text-purple-700 bg-purple-50 px-1 rounded text-xs">[id]</code> and catch-all <code class="text-purple-700 bg-purple-50 px-1 rounded text-xs">[...path]</code> routes work out of the box.</p>
          </div>

          <div class="p-7 rounded-2xl" style="background: #FAFAF8; border: 1px solid #EBEBEB;">
            <div class="w-10 h-10 rounded-xl flex items-center justify-center mb-5" style="background: #F0EBF8;">
              <svg class="w-5 h-5" style="color: #7B5FA8;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/></svg>
            </div>
            <h3 class="text-lg font-bold mb-2" style="color: #111;">Automatic Security</h3>
            <p class="text-sm leading-relaxed" style="color: #666;">CSRF protection is fully automatic. Nex injects tokens into every form and HTMX request — no <code class="text-purple-700 bg-purple-50 px-1 rounded text-xs">csrf_input_tag()</code>, no <code class="text-purple-700 bg-purple-50 px-1 rounded text-xs">hx-headers</code>, no boilerplate.</p>
          </div>

          <div class="p-7 rounded-2xl" style="background: #FAFAF8; border: 1px solid #EBEBEB;">
            <div class="w-10 h-10 rounded-xl flex items-center justify-center mb-5" style="background: #F0EBF8;">
              <svg class="w-5 h-5" style="color: #7B5FA8;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4"/></svg>
            </div>
            <h3 class="text-lg font-bold mb-2" style="color: #111;">Built-in Database</h3>
            <p class="text-sm leading-relaxed" style="color: #666;">NexBase gives you PostgreSQL and SQLite with a fluent query builder and raw SQL — no custom Repo module, no Ecto config files. Just <code class="text-purple-700 bg-purple-50 px-1 rounded text-xs">NexBase.from("users") |> NexBase.run()</code>.</p>
          </div>

          <div class="p-7 rounded-2xl" style="background: #FAFAF8; border: 1px solid #EBEBEB;">
            <div class="w-10 h-10 rounded-xl flex items-center justify-center mb-5" style="background: #F0EBF8;">
              <svg class="w-5 h-5" style="color: #7B5FA8;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
            </div>
            <h3 class="text-lg font-bold mb-2" style="color: #111;">Real-Time Streaming</h3>
            <p class="text-sm leading-relaxed" style="color: #666;">First-class SSE support with <code class="text-purple-700 bg-purple-50 px-1 rounded text-xs">Nex.stream/1</code>. Perfect for AI chat, live dashboards, and progress updates. Works with native <code class="text-purple-700 bg-purple-50 px-1 rounded text-xs">EventSource</code>.</p>
          </div>

          <div class="p-7 rounded-2xl" style="background: #FAFAF8; border: 1px solid #EBEBEB;">
            <div class="w-10 h-10 rounded-xl flex items-center justify-center mb-5" style="background: #F0EBF8;">
              <svg class="w-5 h-5" style="color: #7B5FA8;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/></svg>
            </div>
            <h3 class="text-lg font-bold mb-2" style="color: #111;">Docker-Ready</h3>
            <p class="text-sm leading-relaxed" style="color: #666;">Every new project includes an optimized Dockerfile. Deploy to Fly.io, Railway, or Render in minutes. No Node.js, no build pipeline, no bundler configuration.</p>
          </div>
        </div>
      </div>
    </section>
    """
  end
end
