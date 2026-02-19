defmodule NexWebsite.Pages.GettingStarted do
  use Nex

  @hello_example """
  <div style="background: #1C1C1E; padding: 1rem 1.5rem; overflow-x: auto;"><pre><code style="color: #E8E8E8; font-family: monospace; font-size: 0.8rem; line-height: 1.65;">defmodule MyApp.Pages.Hello do
    use Nex

    def mount(_params) do
      %{count: Nex.Store.get(:count, 0)}
    end

    def increment(_params) do
      count = Nex.Store.update(:count, 0, &amp;(&amp;1 + 1))
      ~H"&lt;span id=\\"count\\"&gt;{count}&lt;/span&gt;"
    end

    def render(assigns) do
      ~H\"""
      &lt;div class="p-8"&gt;
        &lt;h1&gt;Count: &lt;span id="count"&gt;{@count}&lt;/span&gt;&lt;/h1&gt;
        &lt;button hx-post="/increment" hx-target="#count"&gt;Click me&lt;/button&gt;
      &lt;/div&gt;
      \"""
    end
  end</code></pre></div>
  """

  @structure_example """
  <div style="background: #1C1C1E; padding: 1rem 1.5rem; overflow-x: auto;"><pre><code style="color: #E8E8E8; font-family: monospace; font-size: 0.8rem; line-height: 1.7;">my_app/
  |-- src/
  |   |-- pages/           # Page modules (auto-routed)
  |   |   |-- index.ex     # GET /
  |   |   `-- [id].ex      # GET /:id (dynamic)
  |   |-- api/             # JSON API endpoints
  |   |   `-- todos.ex     # GET/POST /api/todos
  |   |-- components/      # Reusable UI components
  |   `-- layouts.ex       # Global HTML layout
  |-- priv/                # Static assets, migrations
  |-- mix.exs
  `-- .env                 # Environment variables</code></pre></div>
  """

  def mount(_params) do
    %{
      title: "Quick Start - Nex Framework",
      hello_example: @hello_example,
      structure_example: @structure_example
    }
  end

  def render(assigns) do
    ~H"""
    <div class="py-20 px-6 md:px-10 text-center" style="background: #FAFAF8; border-bottom: 1px solid #EBEBEB;">
      <div class="max-w-3xl mx-auto">
        <p class="text-xs font-semibold uppercase tracking-widest mb-4" style="color: #9B7EBD; letter-spacing: 0.12em;">Quick Start</p>
        <h1 class="text-5xl md:text-6xl font-extrabold mb-5" style="color: #111; letter-spacing: -0.04em;">Up and running<br/>in 2 minutes.</h1>
        <p class="text-xl" style="color: #666;">Install the generator, create a project, and start building. No configuration required.</p>
      </div>
    </div>

    <div class="max-w-3xl mx-auto px-6 md:px-10 py-16">
      <div class="space-y-12">

        <div class="flex gap-6">
          <div class="flex-shrink-0 w-9 h-9 rounded-full flex items-center justify-center text-sm font-bold text-white" style="background: linear-gradient(135deg, #9B7EBD, #7B5FA8);">1</div>
          <div class="flex-1 pt-1">
            <h2 class="text-xl font-bold mb-2" style="color: #111;">Install the project generator</h2>
            <p class="text-sm mb-4" style="color: #666;">Install <code class="text-purple-700 bg-purple-50 px-1.5 py-0.5 rounded">nex_new</code> as a Mix archive. You only need to do this once.</p>
            <div class="rounded-xl overflow-hidden" style="border: 1px solid #2A2A2A; box-shadow: 0 4px 16px rgba(0,0,0,0.1);">
              <div class="px-4 py-2.5 flex items-center gap-2" style="background: #1C1C1E; border-bottom: 1px solid #2A2A2A;">
                <span class="w-3 h-3 rounded-full" style="background: #FF5F57;"></span>
                <span class="w-3 h-3 rounded-full" style="background: #FEBC2E;"></span>
                <span class="w-3 h-3 rounded-full" style="background: #28C840;"></span>
                <span class="text-xs ml-2" style="color: #666;">terminal</span>
              </div>
              <pre style="background: #1C1C1E; margin: 0; padding: 1rem 1.5rem;"><code style="color: #E8E8E8; font-family: monospace; font-size: 0.875rem;">mix archive.install hex nex_new</code></pre>
            </div>
          </div>
        </div>

        <div class="flex gap-6">
          <div class="flex-shrink-0 w-9 h-9 rounded-full flex items-center justify-center text-sm font-bold text-white" style="background: linear-gradient(135deg, #9B7EBD, #7B5FA8);">2</div>
          <div class="flex-1 pt-1">
            <h2 class="text-xl font-bold mb-2" style="color: #111;">Create a new project</h2>
            <p class="text-sm mb-4" style="color: #666;">Run <code class="text-purple-700 bg-purple-50 px-1.5 py-0.5 rounded">mix nex.new</code> to scaffold a new project with everything you need.</p>
            <div class="rounded-xl overflow-hidden" style="border: 1px solid #2A2A2A; box-shadow: 0 4px 16px rgba(0,0,0,0.1);">
              <div class="px-4 py-2.5 flex items-center gap-2" style="background: #1C1C1E; border-bottom: 1px solid #2A2A2A;">
                <span class="w-3 h-3 rounded-full" style="background: #FF5F57;"></span>
                <span class="w-3 h-3 rounded-full" style="background: #FEBC2E;"></span>
                <span class="w-3 h-3 rounded-full" style="background: #28C840;"></span>
                <span class="text-xs ml-2" style="color: #666;">terminal</span>
              </div>
              <pre style="background: #1C1C1E; margin: 0; padding: 1rem 1.5rem;"><code style="color: #E8E8E8; font-family: monospace; font-size: 0.875rem;">mix nex.new my_app
    cd my_app</code></pre>
            </div>
          </div>
        </div>

        <div class="flex gap-6">
          <div class="flex-shrink-0 w-9 h-9 rounded-full flex items-center justify-center text-sm font-bold text-white" style="background: linear-gradient(135deg, #9B7EBD, #7B5FA8);">3</div>
          <div class="flex-1 pt-1">
            <h2 class="text-xl font-bold mb-2" style="color: #111;">Understand the structure</h2>
            <p class="text-sm mb-4" style="color: #666;">Every Nex project follows a simple, convention-based layout. Your file system is your router.</p>
            <div class="rounded-xl overflow-hidden" style="border: 1px solid #2A2A2A; box-shadow: 0 4px 16px rgba(0,0,0,0.1);">
              <div class="px-4 py-2.5 flex items-center gap-2" style="background: #1C1C1E; border-bottom: 1px solid #2A2A2A;">
                <span class="w-3 h-3 rounded-full" style="background: #FF5F57;"></span>
                <span class="w-3 h-3 rounded-full" style="background: #FEBC2E;"></span>
                <span class="w-3 h-3 rounded-full" style="background: #28C840;"></span>
                <span class="text-xs ml-2" style="color: #666;">my_app/</span>
              </div>
              {raw(@structure_example)}
            </div>
            <p class="text-sm mt-3 p-3 rounded-lg" style="color: #555; background: #F0EBF8; border: 1px solid #D4C5E8;">
              <strong style="color: #7B5FA8;">Key concept:</strong> Drop a file in <code class="text-purple-700 bg-white px-1 rounded">src/pages/</code> and it automatically becomes a route.
            </p>
          </div>
        </div>

        <div class="flex gap-6">
          <div class="flex-shrink-0 w-9 h-9 rounded-full flex items-center justify-center text-sm font-bold text-white" style="background: linear-gradient(135deg, #9B7EBD, #7B5FA8);">4</div>
          <div class="flex-1 pt-1">
            <h2 class="text-xl font-bold mb-2" style="color: #111;">Start the dev server</h2>
            <p class="text-sm mb-4" style="color: #666;">Nex includes a built-in dev server with hot reload. Changes to your code are reflected instantly.</p>
            <div class="rounded-xl overflow-hidden" style="border: 1px solid #2A2A2A; box-shadow: 0 4px 16px rgba(0,0,0,0.1);">
              <div class="px-4 py-2.5 flex items-center gap-2" style="background: #1C1C1E; border-bottom: 1px solid #2A2A2A;">
                <span class="w-3 h-3 rounded-full" style="background: #FF5F57;"></span>
                <span class="w-3 h-3 rounded-full" style="background: #FEBC2E;"></span>
                <span class="w-3 h-3 rounded-full" style="background: #28C840;"></span>
                <span class="text-xs ml-2" style="color: #666;">terminal</span>
              </div>
              <pre style="background: #1C1C1E; margin: 0; padding: 1rem 1.5rem;"><code style="color: #E8E8E8; font-family: monospace; font-size: 0.875rem;">mix nex.dev</code></pre>
            </div>
            <p class="text-sm mt-3" style="color: #666;">Open <code class="text-purple-700 bg-purple-50 px-1.5 py-0.5 rounded">http://localhost:4000</code> in your browser.</p>
          </div>
        </div>

        <div class="flex gap-6">
          <div class="flex-shrink-0 w-9 h-9 rounded-full flex items-center justify-center text-sm font-bold text-white" style="background: linear-gradient(135deg, #9B7EBD, #7B5FA8);">5</div>
          <div class="flex-1 pt-1">
            <h2 class="text-xl font-bold mb-2" style="color: #111;">Build your first page</h2>
            <p class="text-sm mb-4" style="color: #666;">Create <code class="text-purple-700 bg-purple-50 px-1.5 py-0.5 rounded">src/pages/hello.ex</code> and it is immediately available at <code class="text-purple-700 bg-purple-50 px-1.5 py-0.5 rounded">/hello</code>.</p>
            <div class="rounded-xl overflow-hidden" style="border: 1px solid #2A2A2A; box-shadow: 0 4px 16px rgba(0,0,0,0.1);">
              <div class="px-4 py-2.5 flex items-center gap-2" style="background: #1C1C1E; border-bottom: 1px solid #2A2A2A;">
                <span class="w-3 h-3 rounded-full" style="background: #FF5F57;"></span>
                <span class="w-3 h-3 rounded-full" style="background: #FEBC2E;"></span>
                <span class="w-3 h-3 rounded-full" style="background: #28C840;"></span>
                <span class="text-xs ml-2" style="color: #666;">src/pages/hello.ex</span>
              </div>
              {raw(@hello_example)}
            </div>
          </div>
        </div>

        <div class="flex gap-6">
          <div class="flex-shrink-0 w-9 h-9 rounded-full flex items-center justify-center text-sm font-bold text-white" style="background: linear-gradient(135deg, #9B7EBD, #7B5FA8);">6</div>
          <div class="flex-1 pt-1">
            <h2 class="text-xl font-bold mb-2" style="color: #111;">Deploy</h2>
            <p class="text-sm mb-4" style="color: #666;">Every Nex project includes an optimized Dockerfile. Deploy to any container platform in minutes.</p>
            <div class="rounded-xl overflow-hidden" style="border: 1px solid #2A2A2A; box-shadow: 0 4px 16px rgba(0,0,0,0.1);">
              <div class="px-4 py-2.5 flex items-center gap-2" style="background: #1C1C1E; border-bottom: 1px solid #2A2A2A;">
                <span class="w-3 h-3 rounded-full" style="background: #FF5F57;"></span>
                <span class="w-3 h-3 rounded-full" style="background: #FEBC2E;"></span>
                <span class="w-3 h-3 rounded-full" style="background: #28C840;"></span>
                <span class="text-xs ml-2" style="color: #666;">terminal</span>
              </div>
              <pre style="background: #1C1C1E; margin: 0; padding: 1rem 1.5rem;"><code style="color: #E8E8E8; font-family: monospace; font-size: 0.875rem;"># Fly.io
    fly launch

    # Docker
    docker build -t my_app .
    docker run -p 4000:4000 my_app</code></pre>
            </div>
          </div>
        </div>

      </div>

      <div class="mt-20 pt-12" style="border-top: 1px solid #EBEBEB;">
        <h2 class="text-2xl font-bold mb-8" style="color: #111; letter-spacing: -0.02em;">What next?</h2>
        <div class="grid md:grid-cols-2 gap-5">
          <a href="/docs/tutorial_01_first_page" class="group p-6 rounded-2xl transition-all hover:-translate-y-0.5" style="background: #FAFAF8; border: 1px solid #EBEBEB; text-decoration: none;">
            <div class="flex items-center gap-3 mb-2">
              <div class="w-8 h-8 rounded-lg flex items-center justify-center" style="background: #F0EBF8;">
                <svg class="w-4 h-4" style="color: #7B5FA8;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/></svg>
              </div>
              <h3 class="font-bold" style="color: #111;">Tutorials</h3>
            </div>
            <p class="text-sm" style="color: #666;">Step-by-step guides covering pages, actions, forms, state, and routing.</p>
          </a>
          <a href="/features" class="group p-6 rounded-2xl transition-all hover:-translate-y-0.5" style="background: #FAFAF8; border: 1px solid #EBEBEB; text-decoration: none;">
            <div class="flex items-center gap-3 mb-2">
              <div class="w-8 h-8 rounded-lg flex items-center justify-center" style="background: #F0EBF8;">
                <svg class="w-4 h-4" style="color: #7B5FA8;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"/></svg>
              </div>
              <h3 class="font-bold" style="color: #111;">Core Features</h3>
            </div>
            <p class="text-sm" style="color: #666;">Deep dive into file routing, SSE streaming, state management, and security.</p>
          </a>
          <a href="https://github.com/gofenix/nex/tree/main/examples" target="_blank" class="group p-6 rounded-2xl transition-all hover:-translate-y-0.5" style="background: #FAFAF8; border: 1px solid #EBEBEB; text-decoration: none;">
            <div class="flex items-center gap-3 mb-2">
              <div class="w-8 h-8 rounded-lg flex items-center justify-center" style="background: #F0EBF8;">
                <svg class="w-4 h-4" style="color: #7B5FA8;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"/></svg>
              </div>
              <h3 class="font-bold" style="color: #111;">Example Projects</h3>
            </div>
            <p class="text-sm" style="color: #666;">Clone and run real apps: AI chatbot, todo list, guestbook, and more.</p>
          </a>
          <a href="https://github.com/gofenix/nex/discussions" target="_blank" class="group p-6 rounded-2xl transition-all hover:-translate-y-0.5" style="background: #FAFAF8; border: 1px solid #EBEBEB; text-decoration: none;">
            <div class="flex items-center gap-3 mb-2">
              <div class="w-8 h-8 rounded-lg flex items-center justify-center" style="background: #F0EBF8;">
                <svg class="w-4 h-4" style="color: #7B5FA8;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 8h2a2 2 0 012 2v6a2 2 0 01-2 2h-2v4l-4-4H9a1.994 1.994 0 01-1.414-.586m0 0L11 14h4a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2v4l.586-.586z"/></svg>
              </div>
              <h3 class="font-bold" style="color: #111;">Community</h3>
            </div>
            <p class="text-sm" style="color: #666;">Ask questions, share projects, and get help from the Nex community on GitHub.</p>
          </a>
        </div>
      </div>
    </div>
    """
  end
end
