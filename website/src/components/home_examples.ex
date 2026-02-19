defmodule NexWebsite.Components.HomeExamples do
  use Nex

  def render(assigns) do
    ~H"""
    <section class="py-24 px-6 md:px-10" style="background: white; border-top: 1px solid #EBEBEB;">
      <div class="max-w-5xl mx-auto">
        <div class="text-center mb-14">
          <p class="text-xs font-semibold uppercase tracking-widest mb-3" style="color: #9B7EBD; letter-spacing: 0.12em;">Examples</p>
          <h2 class="text-4xl font-bold mb-3" style="color: #111; letter-spacing: -0.03em;">See it in action</h2>
          <p class="text-lg" style="color: #666;">Real projects you can clone and run locally</p>
        </div>

        <div class="grid md:grid-cols-3 gap-5">
          <a href="https://github.com/gofenix/nex/tree/main/examples/chatbot_sse" target="_blank" class="group p-6 rounded-2xl transition-all hover:-translate-y-0.5" style="background: #FAFAF8; border: 1px solid #EBEBEB; text-decoration: none;">
            <div class="text-2xl mb-3">🌊</div>
            <h3 class="font-bold mb-1.5 group-hover:text-claude-purple transition-colors" style="color: #111;">AI Chat Streaming</h3>
            <p class="text-sm mb-4" style="color: #666;">Real-time AI responses with SSE and native EventSource. Zero-latency token streaming.</p>
            <div class="flex gap-2 flex-wrap">
              <span class="text-xs px-2 py-0.5 rounded-full" style="background: #F0EBF8; color: #7B5FA8;">SSE</span>
              <span class="text-xs px-2 py-0.5 rounded-full" style="background: #F5F5F0; color: #666;">Streaming</span>
            </div>
          </a>

          <a href="https://github.com/gofenix/nex/tree/main/examples/todos" target="_blank" class="group p-6 rounded-2xl transition-all hover:-translate-y-0.5" style="background: #FAFAF8; border: 1px solid #EBEBEB; text-decoration: none;">
            <div class="text-2xl mb-3">✅</div>
            <h3 class="font-bold mb-1.5 group-hover:text-claude-purple transition-colors" style="color: #111;">Todo App</h3>
            <p class="text-sm mb-4" style="color: #666;">Full CRUD with partial DOM updates. The classic example, done the Nex way.</p>
            <div class="flex gap-2 flex-wrap">
              <span class="text-xs px-2 py-0.5 rounded-full" style="background: #F0EBF8; color: #7B5FA8;">HTMX</span>
              <span class="text-xs px-2 py-0.5 rounded-full" style="background: #F5F5F0; color: #666;">Store</span>
            </div>
          </a>

          <a href="https://github.com/gofenix/nex/tree/main/examples/counter" target="_blank" class="group p-6 rounded-2xl transition-all hover:-translate-y-0.5" style="background: #FAFAF8; border: 1px solid #EBEBEB; text-decoration: none;">
            <div class="text-2xl mb-3">🔢</div>
            <h3 class="font-bold mb-1.5 group-hover:text-claude-purple transition-colors" style="color: #111;">Counter</h3>
            <p class="text-sm mb-4" style="color: #666;">The simplest possible Nex app. A great starting point to understand the core concepts.</p>
            <div class="flex gap-2 flex-wrap">
              <span class="text-xs px-2 py-0.5 rounded-full" style="background: #F0EBF8; color: #7B5FA8;">Beginner</span>
              <span class="text-xs px-2 py-0.5 rounded-full" style="background: #F5F5F0; color: #666;">Actions</span>
            </div>
          </a>

          <a href="https://github.com/gofenix/nex/tree/main/examples" target="_blank" class="group p-6 rounded-2xl transition-all hover:-translate-y-0.5" style="background: #FAFAF8; border: 1px solid #EBEBEB; text-decoration: none;">
            <div class="text-2xl mb-3">📝</div>
            <h3 class="font-bold mb-1.5 group-hover:text-claude-purple transition-colors" style="color: #111;">Guestbook</h3>
            <p class="text-sm mb-4" style="color: #666;">Form handling, CSRF protection, and server-side state. A complete mini-app.</p>
            <div class="flex gap-2 flex-wrap">
              <span class="text-xs px-2 py-0.5 rounded-full" style="background: #F0EBF8; color: #7B5FA8;">Forms</span>
              <span class="text-xs px-2 py-0.5 rounded-full" style="background: #F5F5F0; color: #666;">CSRF</span>
            </div>
          </a>

          <a href="https://github.com/gofenix/nex/tree/main/examples" target="_blank" class="group p-6 rounded-2xl transition-all hover:-translate-y-0.5" style="background: #FAFAF8; border: 1px solid #EBEBEB; text-decoration: none;">
            <div class="text-2xl mb-3">🔀</div>
            <h3 class="font-bold mb-1.5 group-hover:text-claude-purple transition-colors" style="color: #111;">Dynamic Routes</h3>
            <p class="text-sm mb-4" style="color: #666;">All routing patterns: static, dynamic <code class="text-xs bg-gray-100 px-1 rounded">[id]</code>, and catch-all <code class="text-xs bg-gray-100 px-1 rounded">[...path]</code>.</p>
            <div class="flex gap-2 flex-wrap">
              <span class="text-xs px-2 py-0.5 rounded-full" style="background: #F0EBF8; color: #7B5FA8;">Routing</span>
              <span class="text-xs px-2 py-0.5 rounded-full" style="background: #F5F5F0; color: #666;">Params</span>
            </div>
          </a>

          <a href="https://github.com/gofenix/nex/tree/main/examples" target="_blank" class="group p-6 rounded-2xl flex flex-col items-center justify-center text-center transition-all hover:-translate-y-0.5" style="background: #F0EBF8; border: 1px dashed #D4C5E8; text-decoration: none; min-height: 160px;">
            <svg class="w-8 h-8 mb-3" style="color: #9B7EBD;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 4v16m8-8H4"/></svg>
            <span class="font-semibold text-sm" style="color: #7B5FA8;">View all examples</span>
            <span class="text-xs mt-1" style="color: #9B7EBD;">on GitHub →</span>
          </a>
        </div>
      </div>
    </section>
    """
  end
end
