defmodule NexWebsite.Pages.Index do
  use Nex
  alias NexWebsite.CodeExamples

  def mount(_params) do
    %{
      title: "Nex - The Minimalist Elixir Web Framework powered by HTMX",
      example_code: CodeExamples.get("index_page.md") |> CodeExamples.format_for_display()
    }
  end

  def render(assigns) do
    ~H"""
    <div class="hero min-h-[85vh] px-4 relative overflow-hidden">
      <!-- Decorative background elements -->
      <div class="absolute top-20 right-10 w-72 h-72 bg-claude-purple opacity-5 rounded-full blur-3xl"></div>
      <div class="absolute bottom-20 left-10 w-96 h-96 bg-claude-purple opacity-5 rounded-full blur-3xl"></div>

      <div class="hero-content text-center flex-col max-w-4xl relative z-10 animate-fade-in-up">
        <div class="badge badge-outline border-claude-purple text-claude-purple px-5 py-3 mb-8 font-semibold text-sm shadow-sm">
          ✨ v0.3.x Released - AI-Native & Docker Ready
        </div>
        <h1 class="text-5xl md:text-7xl font-extrabold tracking-tight mb-8 leading-[1.1]">
          Modern Web Apps,<br/>
          <span class="gradient-text">AI-Driven Speed.</span>
        </h1>
        <p class="text-xl md:text-2xl text-claude-muted mb-12 max-w-2xl mx-auto leading-relaxed font-medium">
          The minimalist Elixir framework built for <b>Vibe Coding</b>. Ship real products fast with AI as your co-pilot.
        </p>
        <div class="flex flex-col sm:flex-row gap-4 w-full sm:w-auto">
          <a href="/docs/getting_started" class="btn btn-claude-purple btn-lg px-10 rounded-full shadow-xl shadow-purple-200">
            Get Started
          </a>
          <a href="/docs" class="btn btn-outline btn-lg px-10 rounded-full border-2 border-claude-purple text-claude-purple hover:bg-claude-purple hover:text-white">
            Documentation
          </a>
        </div>
      </div>
    </div>

    <div class="px-4 md:px-8 py-24 max-w-7xl mx-auto">
      <div class="text-center mb-16">
        <h2 class="text-4xl font-bold mb-4">Everything You Need, <span class="text-claude-purple">Nothing You Don't</span></h2>
        <p class="text-xl text-claude-muted">Built for developers who value simplicity</p>
      </div>

      <div class="grid md:grid-cols-3 gap-8">
        <div class="card bg-white p-8 border border-gray-100 shadow-sm group">
          <div class="w-14 h-14 bg-purple-100 rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7 text-claude-purple" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 21l-1 1h8l-1-1-.75-4M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" /></svg>
          </div>
          <h3 class="text-2xl font-bold mb-4">AI-Native Design</h3>
          <p class="text-claude-muted leading-relaxed">
            Built for <b>Vibe Coding</b>. Locality of Behavior (LoB) allows AI agents to build full features by reading just one file.
          </p>
        </div>

        <div class="card bg-white p-8 border border-gray-100 shadow-sm group">
          <div class="w-14 h-14 bg-purple-100 rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7 text-claude-purple" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" /></svg>
          </div>
          <h3 class="text-2xl font-bold mb-4">Declarative Interaction</h3>
          <p class="text-claude-muted leading-relaxed">
            HTMX-first philosophy. Build reactive UIs with zero-JavaScript complexity using simple Elixir functions.
          </p>
        </div>

        <div class="card bg-white p-8 border border-gray-100 shadow-sm group">
          <div class="w-14 h-14 bg-purple-100 rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7 text-claude-purple" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" /></svg>
          </div>
          <h3 class="text-2xl font-bold mb-4">Unified Interface</h3>
          <p class="text-claude-muted leading-relaxed">
            One <code class="bg-gray-100 px-2 py-0.5 rounded text-sm">use Nex</code> for everything. Automatic module detection simplifies development and reduces boilerplate.
          </p>
        </div>
      </div>
    </div>

    <div class="bg-white py-24 border-y border-gray-100">
      <div class="max-w-7xl mx-auto px-4 md:px-8">
        <div class="flex flex-col md:flex-row items-center gap-16">
          <div class="flex-1">
            <div class="inline-block px-4 py-2 bg-purple-50 rounded-full text-sm font-semibold text-claude-purple mb-6">
              Our Philosophy
            </div>
            <h2 class="text-4xl md:text-5xl font-bold mb-6 leading-tight">Build Real Apps,<br/><span class="text-claude-purple">Not Complexity.</span></h2>
            <p class="text-lg text-claude-muted mb-8 leading-relaxed">
              Nex is built for shipping real products to production. Server-side rendering with HTMX means you build features, not infrastructure. Convention over configuration eliminates boilerplate. Get your idea from concept to live users fast.
            </p>
            <ul class="space-y-4">
              <li class="flex items-center gap-3">
                <div class="w-6 h-6 rounded-full bg-purple-100 flex items-center justify-center">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-claude-purple" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" /></svg>
                </div>
                <span class="font-medium">Convention over configuration</span>
              </li>
              <li class="flex items-center gap-3">
                <div class="w-6 h-6 rounded-full bg-purple-100 flex items-center justify-center">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-claude-purple" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" /></svg>
                </div>
                <span class="font-medium">Instant hot reloading in development</span>
              </li>
              <li class="flex items-center gap-3">
                <div class="w-6 h-6 rounded-full bg-purple-100 flex items-center justify-center">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-claude-purple" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" /></svg>
                </div>
                <span class="font-medium">Production-ready Docker deployment</span>
              </li>
            </ul>
          </div>
          <div class="flex-1 w-full">
            <div class="rounded-2xl overflow-hidden shadow-2xl">
              <%= raw @example_code %>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Examples Showcase -->
    <div class="py-24 px-4 md:px-8 bg-white border-y border-gray-100">
      <div class="max-w-7xl mx-auto">
        <div class="text-center mb-16">
          <h2 class="text-4xl md:text-5xl font-bold mb-4">See It <span class="gradient-text">In Action</span></h2>
          <p class="text-xl text-claude-muted">Real examples you can run and learn from</p>
        </div>

        <div class="grid md:grid-cols-2 gap-8">
          <div class="card bg-white p-8 border-2 border-gray-200">
            <div class="flex items-center gap-3 mb-4">
              <div class="text-3xl">💬</div>
              <h3 class="text-2xl font-bold">AI Chatbot</h3>
            </div>
            <p class="text-claude-muted mb-6 leading-relaxed">AI chat with streaming responses using polling. Learn async patterns and real-time updates.</p>
            <div class="flex gap-3">
              <span class="px-3 py-1 bg-gray-100 rounded-full text-xs font-semibold text-claude-muted">Polling</span>
              <span class="px-3 py-1 bg-gray-100 rounded-full text-xs font-semibold text-claude-muted">HTMX</span>
              <span class="px-3 py-1 bg-gray-100 rounded-full text-xs font-semibold text-claude-muted">Async</span>
            </div>
          </div>

          <div class="card bg-white p-8 border-2 border-gray-200">
            <div class="flex items-center gap-3 mb-4">
              <div class="text-3xl">🌊</div>
              <h3 class="text-2xl font-bold">Chatbot SSE</h3>
            </div>
            <p class="text-claude-muted mb-6 leading-relaxed">Real-time streaming with Server-Sent Events and HTMX SSE extension. Zero-JS streaming.</p>
            <div class="flex gap-3">
              <span class="px-3 py-1 bg-gray-100 rounded-full text-xs font-semibold text-claude-muted">SSE</span>
              <span class="px-3 py-1 bg-gray-100 rounded-full text-xs font-semibold text-claude-muted">Streaming</span>
              <span class="px-3 py-1 bg-gray-100 rounded-full text-xs font-semibold text-claude-muted">Real-time</span>
            </div>
          </div>

          <div class="card bg-white p-8 border-2 border-gray-200">
            <div class="flex items-center gap-3 mb-4">
              <div class="text-3xl">📝</div>
              <h3 class="text-2xl font-bold">Guestbook</h3>
            </div>
            <p class="text-claude-muted mb-6 leading-relaxed">Simple CRUD app with form handling and data persistence. Perfect starter example.</p>
            <div class="flex gap-3">
              <span class="px-3 py-1 bg-gray-100 rounded-full text-xs font-semibold text-claude-muted">Forms</span>
              <span class="px-3 py-1 bg-gray-100 rounded-full text-xs font-semibold text-claude-muted">CSRF</span>
              <span class="px-3 py-1 bg-gray-100 rounded-full text-xs font-semibold text-claude-muted">Store</span>
            </div>
          </div>

          <div class="card bg-white p-8 border-2 border-gray-200">
            <div class="flex items-center gap-3 mb-4">
              <div class="text-3xl">🔀</div>
              <h3 class="text-2xl font-bold">Dynamic Routes</h3>
            </div>
            <p class="text-claude-muted mb-6 leading-relaxed">Showcase of all routing patterns: static, dynamic [id], and catch-all [...path].</p>
            <div class="flex gap-3">
              <span class="px-3 py-1 bg-gray-100 rounded-full text-xs font-semibold text-claude-muted">Routing</span>
              <span class="px-3 py-1 bg-gray-100 rounded-full text-xs font-semibold text-claude-muted">Params</span>
            </div>
          </div>

          <div class="card bg-white p-8 border-2 border-gray-200">
            <div class="flex items-center gap-3 mb-4">
              <div class="text-3xl">✅</div>
              <h3 class="text-2xl font-bold">Todo App</h3>
            </div>
            <p class="text-claude-muted mb-6 leading-relaxed">Classic todo app with partial updates. Learn HTMX patterns and state management.</p>
            <div class="flex gap-3">
              <span class="px-3 py-1 bg-gray-100 rounded-full text-xs font-semibold text-claude-muted">HTMX</span>
              <span class="px-3 py-1 bg-gray-100 rounded-full text-xs font-semibold text-claude-muted">Components</span>
            </div>
          </div>
        </div>

        <div class="text-center mt-12">
          <a href="https://github.com/gofenix/nex/tree/main/examples" class="btn btn-outline btn-lg px-10 rounded-full border-2 border-claude-purple text-claude-purple hover:bg-claude-purple hover:text-white">
            View All Examples on GitHub →
          </a>
        </div>
      </div>
    </div>

    <div class="py-24 px-4 md:px-8 bg-claude-light">
      <div class="max-w-7xl mx-auto">
        <div class="text-center mb-16">
          <h2 class="text-4xl md:text-5xl font-bold mb-4">Built for <span class="gradient-text">Real Developers</span></h2>
          <p class="text-xl text-claude-muted">Not for enterprise. Not for complex SPAs. Perfect for you.</p>
        </div>

        <div class="grid md:grid-cols-3 gap-8">
          <div class="card bg-white p-10 border-2 border-purple-100 hover:border-purple-200 relative overflow-hidden">
            <div class="absolute top-0 right-0 w-32 h-32 bg-purple-50 rounded-full -mr-16 -mt-16"></div>
            <div class="relative z-10">
              <div class="text-5xl mb-6">🚀</div>
              <h3 class="text-2xl font-bold mb-4">Rapid Prototyping</h3>
              <p class="text-claude-muted leading-relaxed">Go from idea to deployed MVP in hours, not weeks. Perfect for validating ideas quickly.</p>
            </div>
          </div>

          <div class="card bg-white p-10 border-2 border-yellow-100 hover:border-yellow-200 relative overflow-hidden">
            <div class="absolute top-0 right-0 w-32 h-32 bg-yellow-50 rounded-full -mr-16 -mt-16"></div>
            <div class="relative z-10">
              <div class="text-5xl mb-6">🎯</div>
              <h3 class="text-2xl font-bold mb-4">Indie Hackers</h3>
              <p class="text-claude-muted leading-relaxed">Build and ship solo projects without the overhead of complex frameworks. Focus on your product.</p>
            </div>
          </div>

          <div class="card bg-white p-10 border-2 border-blue-100 hover:border-blue-200 relative overflow-hidden">
            <div class="absolute top-0 right-0 w-32 h-32 bg-blue-50 rounded-full -mr-16 -mt-16"></div>
            <div class="relative z-10">
              <div class="text-5xl mb-6">📊</div>
              <h3 class="text-2xl font-bold mb-4">Real-time Applications</h3>
              <p class="text-claude-muted leading-relaxed">Build live dashboards, chat apps, and streaming data applications with Server-Sent Events. Production-ready.</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Why Nex Section -->
    <div class="py-24 px-4 md:px-8 bg-white border-y border-gray-100">
      <div class="max-w-6xl mx-auto">
        <div class="text-center mb-16">
          <h2 class="text-4xl md:text-5xl font-bold mb-4">Why Choose <span class="gradient-text">Nex</span></h2>
          <p class="text-xl text-claude-muted">Compared to other frameworks and approaches</p>
        </div>

        <div class="grid md:grid-cols-3 gap-8">
          <div class="card bg-white p-8 border-2 border-purple-100 hover:border-purple-200 relative overflow-hidden group">
            <div class="absolute top-0 right-0 w-24 h-24 bg-purple-50 rounded-full -mr-12 -mt-12 group-hover:scale-110 transition-transform"></div>
            <div class="relative z-10">
              <h3 class="text-xl font-bold mb-4 text-claude-text">vs Phoenix</h3>
              <p class="text-claude-muted mb-4">Phoenix is powerful but complex. Nex is lightweight and focused on server-side rendering with HTMX. Perfect when you don't need LiveView's complexity.</p>
              <div class="text-sm text-claude-purple font-semibold">Best for: Rapid development, smaller teams</div>
            </div>
          </div>

          <div class="card bg-white p-8 border-2 border-yellow-100 hover:border-yellow-200 relative overflow-hidden group">
            <div class="absolute top-0 right-0 w-24 h-24 bg-yellow-50 rounded-full -mr-12 -mt-12 group-hover:scale-110 transition-transform"></div>
            <div class="relative z-10">
              <h3 class="text-xl font-bold mb-4 text-claude-text">vs React/Vue</h3>
              <p class="text-claude-muted mb-4">Frontend frameworks require JavaScript expertise and build complexity. Nex uses server-side rendering with HTMX for interactivity without the overhead.</p>
              <div class="text-sm text-claude-purple font-semibold">Best for: Zero JavaScript, faster development</div>
            </div>
          </div>

          <div class="card bg-white p-8 border-2 border-blue-100 hover:border-blue-200 relative overflow-hidden group">
            <div class="absolute top-0 right-0 w-24 h-24 bg-blue-50 rounded-full -mr-12 -mt-12 group-hover:scale-110 transition-transform"></div>
            <div class="relative z-10">
              <h3 class="text-xl font-bold mb-4 text-claude-text">vs Rails</h3>
              <p class="text-claude-muted mb-4">Rails is full-featured but heavyweight. Nex is minimal and convention-based, perfect for Elixir developers who want simplicity and performance.</p>
              <div class="text-sm text-claude-purple font-semibold">Best for: Elixir ecosystem, fast execution</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Production Ready Section -->
    <div class="py-24 px-4 md:px-8 bg-claude-light border-y border-gray-100">
      <div class="max-w-6xl mx-auto">
        <div class="text-center mb-16">
          <h2 class="text-4xl md:text-5xl font-bold mb-4">Production <span class="gradient-text">Ready</span></h2>
          <p class="text-xl text-claude-muted">Everything you need to ship to production</p>
        </div>

        <div class="grid md:grid-cols-2 gap-8">
          <div class="card bg-white p-8 border-2 border-purple-100 hover:border-purple-200 relative overflow-hidden">
            <div class="absolute top-0 right-0 w-32 h-32 bg-purple-50 rounded-full -mr-16 -mt-16"></div>
            <div class="relative z-10">
              <h3 class="text-2xl font-bold mb-6 text-claude-text">Deployment</h3>
              <ul class="space-y-3 text-claude-muted">
                <li class="flex items-center gap-3">
                  <svg class="w-5 h-5 text-claude-purple flex-shrink-0" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/></svg>
                  Docker-ready with optimized images
                </li>
                <li class="flex items-center gap-3">
                  <svg class="w-5 h-5 text-claude-purple flex-shrink-0" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/></svg>
                  Deploy to Railway, Fly.io, Render
                </li>
                <li class="flex items-center gap-3">
                  <svg class="w-5 h-5 text-claude-purple flex-shrink-0" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/></svg>
                  Single binary deployment
                </li>
              </ul>
            </div>
          </div>

          <div class="card bg-white p-8 border-2 border-blue-100 hover:border-blue-200 relative overflow-hidden">
            <div class="absolute top-0 right-0 w-32 h-32 bg-blue-50 rounded-full -mr-16 -mt-16"></div>
            <div class="relative z-10">
              <h3 class="text-2xl font-bold mb-6 text-claude-text">Security & Performance</h3>
              <ul class="space-y-3 text-claude-muted">
                <li class="flex items-center gap-3">
                  <svg class="w-5 h-5 text-claude-purple flex-shrink-0" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/></svg>
                  Built-in CSRF protection
                </li>
                <li class="flex items-center gap-3">
                  <svg class="w-5 h-5 text-claude-purple flex-shrink-0" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/></svg>
                  Elixir performance and reliability
                </li>
                <li class="flex items-center gap-3">
                  <svg class="w-5 h-5 text-claude-purple flex-shrink-0" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/></svg>
                  Hot reload in development
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="relative py-32 px-4 md:px-8 overflow-hidden">
      <!-- Decorative background -->
      <div class="absolute inset-0 bg-purple-50"></div>
      <div class="absolute top-0 left-0 w-96 h-96 bg-purple-100 rounded-full blur-3xl opacity-20"></div>
      <div class="absolute bottom-0 right-0 w-96 h-96 bg-purple-100 rounded-full blur-3xl opacity-20"></div>

      <div class="max-w-4xl mx-auto text-center relative z-10">
        <h2 class="text-5xl md:text-6xl font-bold mb-6 leading-tight">Ready to Build <br/><span class="gradient-text">Something Amazing?</span></h2>
        <p class="text-xl md:text-2xl text-claude-muted mb-12 max-w-2xl mx-auto">Join developers who chose simplicity over complexity.</p>
        <div class="flex flex-col sm:flex-row gap-4 justify-center">
          <a href="/getting_started" class="btn btn-claude-purple btn-lg px-12 rounded-full shadow-xl text-lg">
            Get Started Now →
          </a>
          <a href="https://github.com/gofenix/nex" class="btn btn-outline btn-lg px-12 rounded-full border-2 border-claude-purple text-claude-purple hover:bg-claude-purple hover:text-white text-lg">
            View on GitHub
          </a>
        </div>

        <div class="mt-16 flex items-center justify-center gap-8 text-sm text-claude-muted">
          <div class="flex items-center gap-2">
            <svg class="w-5 h-5 text-claude-purple" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/></svg>
            <span>MIT Licensed</span>
          </div>
          <div class="flex items-center gap-2">
            <svg class="w-5 h-5 text-claude-purple" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/></svg>
            <span>Open Source</span>
          </div>
          <div class="flex items-center gap-2">
            <svg class="w-5 h-5 text-claude-purple" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/></svg>
            <span>Production Ready</span>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
