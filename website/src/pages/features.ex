defmodule NexWebsite.Pages.Features do
  use Nex
  alias NexWebsite.CodeExamples

  def mount(_params) do
    %{
      title: "Features - Nex Framework",
      file_routing_code: CodeExamples.get("file_routing.md") |> CodeExamples.format_for_display(),
      htmx_action_code: CodeExamples.get("htmx_action.md") |> CodeExamples.format_for_display(),
      sse_stream_code: CodeExamples.get("sse_stream.md") |> CodeExamples.format_for_display()
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto px-4 py-20">
      <div class="text-center mb-16">
        <h1 class="text-5xl md:text-6xl font-extrabold mb-6 tracking-tight">Core <span class="gradient-text">Features</span></h1>
        <p class="text-xl text-claude-muted max-w-2xl mx-auto">Server-side rendering with HTMX. Everything you need to build modern web apps without JavaScript complexity.</p>
      </div>

      <div class="space-y-24">
        <!-- Docker Ready - NEW in v0.3.x -->
        <section class="bg-purple-50 p-10 rounded-3xl border-2 border-purple-100">
          <div class="flex items-center gap-3 mb-6">
            <div class="badge badge-lg bg-purple-500 text-white border-none">v0.3.x Released</div>
            <h2 class="text-3xl font-bold">🤖 AI-Native & Vibe Coding</h2>
          </div>
          <p class="text-lg text-claude-muted mb-6 leading-relaxed">
            Nex is built for the AI era. With <b>Locality of Behavior (LoB)</b> and zero-config routing, AI agents can build full features by reading a single file. No more context loss between routers, controllers, and templates.
          </p>
          <div class="bg-white p-6 rounded-xl border border-gray-200">
            <pre class="text-sm"><code class="language-text">
            # One file, one feature.
            # AI reads src/pages/my_feature.ex and understands everything.
            </code></pre>
          </div>
        </section>

        <section>
          <h2 class="text-3xl font-bold mb-6">📁 File-based Routing</h2>
          <p class="text-lg text-claude-muted mb-8 leading-relaxed">
            Routes are automatically discovered from your file system. Drop a file in <code class="bg-gray-100 px-2 py-1 rounded text-sm">src/pages/</code>, get a route. Support for dynamic routes like <code class="bg-gray-100 px-2 py-1 rounded text-sm">[id]</code> and catch-all <code class="bg-gray-100 px-2 py-1 rounded text-sm">[...path]</code>.
          </p>
          <div class="rounded-xl overflow-hidden shadow-lg">
            <%= raw @file_routing_code %>
          </div>
        </section>

        <section>
          <h2 class="text-3xl font-bold mb-6">⚡ Unified Interface</h2>
          <p class="text-lg text-claude-muted mb-8 leading-relaxed">
            Every module in Nex uses the same <code class="bg-gray-100 px-2 py-1 rounded text-sm">use Nex</code> statement. Whether it's a Page, API, or UI Component, the framework automatically imports what you need based on the file path.
          </p>
          <div class="rounded-xl overflow-hidden shadow-lg">
            <%= raw @htmx_action_code %>
          </div>
        </section>

        <section>
          <h2 class="text-3xl font-bold mb-6">📡 JSON APIs (Next.js Style)</h2>
          <p class="text-lg text-claude-muted mb-8 leading-relaxed">
            Build REST APIs that follow modern standards. Nex API routes use a <code class="bg-gray-100 px-2 py-1 rounded text-sm">req</code> object aligned with Next.js API Routes, providing <code class="bg-gray-100 px-1 rounded text-sm">req.query</code> and <code class="bg-gray-100 px-1 rounded text-sm">req.body</code> for clean parameter handling.
          </p>
          <div class="bg-purple-50 p-6 rounded-xl border border-purple-200">
            <div class="flex items-start gap-3">
              <svg class="w-6 h-6 text-claude-purple mt-1" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/></svg>
              <div>
                <h4 class="font-bold text-claude-text mb-2">Convention-based routing</h4>
                <p class="text-claude-muted">Drop files in src/api/ and they automatically become endpoints. Support for dynamic routes like /api/todos/[id].</p>
              </div>
            </div>
          </div>
        </section>

        <section>
          <h2 class="text-3xl font-bold mb-6">💾 Built-in State Management</h2>
          <p class="text-lg text-claude-muted mb-8 leading-relaxed">
            <code class="bg-gray-100 px-2 py-1 rounded text-sm">Nex.Store</code> provides a simple key-value store tied to the user's page session. Perfect for form state, shopping carts, and temporary data without a database.
          </p>
          <div class="grid md:grid-cols-2 gap-6">
            <div class="card bg-white p-6 border border-gray-200">
              <h4 class="font-bold mb-3">Page-scoped</h4>
              <p class="text-sm text-claude-muted">Data isolated per user session</p>
            </div>
            <div class="card bg-white p-6 border border-gray-200">
              <h4 class="font-bold mb-3">Zero config</h4>
              <p class="text-sm text-claude-muted">Works out of the box</p>
            </div>
          </div>
        </section>

        <section>
          <h2 class="text-3xl font-bold mb-6">🔄 Server-Sent Events (SSE)</h2>
          <p class="text-lg text-claude-muted mb-8 leading-relaxed">
            Real-time streaming is a first-class citizen. Use <code class="bg-gray-100 px-2 py-1 rounded text-sm">Nex.stream/1</code> for live dashboards, chat apps, AI streaming, or progress bars.
          </p>
          <div class="rounded-xl overflow-hidden shadow-lg">
            <%= raw @sse_stream_code %>
          </div>
        </section>

        <section>
          <h2 class="text-3xl font-bold mb-6">🛡️ Built-in Security</h2>
          <p class="text-lg text-claude-muted mb-8 leading-relaxed">
            Security by default. Automatic CSRF protection for all POST requests. Just use <code class="bg-gray-100 px-2 py-1 rounded text-sm">csrf_input_tag/0</code> in your forms.
          </p>
          <div class="bg-purple-50 p-6 rounded-xl border border-purple-200">
            <div class="flex items-start gap-3">
              <svg class="w-6 h-6 text-claude-purple mt-1" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/></svg>
              <div>
                <h4 class="font-bold text-claude-text mb-2">Production-ready security</h4>
                <p class="text-claude-muted">CSRF tokens automatically generated and validated. No configuration required.</p>
              </div>
            </div>
          </div>
        </section>

        <section>
          <h2 class="text-3xl font-bold mb-6">🔥 Hot Reload</h2>
          <p class="text-lg text-claude-muted mb-8 leading-relaxed">
            Instant file change detection via WebSocket. Edit your code and see changes immediately without manual refresh. Works in development mode automatically.
          </p>
        </section>

        <section>
          <h2 class="text-3xl font-bold mb-6">🎨 CDN-First Design</h2>
          <p class="text-lg text-claude-muted mb-8 leading-relaxed">
            No build step required. Use Tailwind CSS and DaisyUI via CDN. Focus on building features, not configuring bundlers.
          </p>
        </section>
      </div>

      <div class="mt-24 text-center bg-purple-50 p-12 rounded-3xl border border-purple-100">
        <h3 class="text-3xl font-bold mb-4">Ready to build something amazing?</h3>
        <p class="text-xl text-claude-muted mb-8">Start with our quick setup guide and explore real-world examples.</p>
        <div class="flex flex-col sm:flex-row gap-4 justify-center">
          <a href="/getting_started" class="btn btn-claude-purple btn-lg px-10 rounded-full">Get Started</a>
          <a href="https://github.com/gofenix/nex/tree/main/examples" class="btn btn-outline btn-lg px-10 rounded-full border-2 border-claude-purple text-claude-purple hover:bg-claude-purple hover:text-white">View Examples</a>
        </div>
      </div>
    </div>
    """
  end
end
