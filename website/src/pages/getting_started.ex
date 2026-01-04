defmodule NexWebsite.Pages.GettingStarted do
  use Nex

  def mount(_params) do
    %{
      title: "Getting Started - Nex Framework"
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-4 py-20">
      <h1 class="text-5xl font-extrabold mb-12 tracking-tight">Get <span class="text-claude-purple">Started</span></h1>

      <div class="prose prose-lg max-w-none prose-slate">
        <h2 class="text-claude-text">1. Install the Installer</h2>
        <p>Nex comes with a convenient installer to bootstrap new projects quickly.</p>
        <div class="rounded-xl overflow-hidden mb-12">
          <pre><code class="language-bash">mix archive.install hex nex_new</code></pre>
        </div>

        <h2 class="text-claude-text">2. Create a New Project</h2>
        <p>Run the <code class="bg-gray-100 px-1 rounded">nex.new</code> Mix task to create a new project directory.</p>
        <div class="rounded-xl overflow-hidden mb-12">
          <pre><code class="language-bash">mix nex.new my_app
cd my_app</code></pre>
        </div>

        <h2 class="text-claude-text">3. Understand the Project Structure</h2>
        <p>Every Nex project follows a simple, convention-based structure.</p>
        <div class="rounded-xl overflow-hidden mb-12 bg-gray-50 p-6 border border-gray-200">
          <pre class="text-sm"><code class="language-text">my_app/
├── src/
│   ├── pages/           # Page modules (auto-routed)
│   │   ├── index.ex     # GET /
│   │   └── [id].ex      # GET /id (dynamic route)
│   ├── api/             # JSON API endpoints (Next.js style)
│   │   └── todos/
│   │       └── index.ex # GET/POST /api/todos
│   ├── components/      # Reusable UI components
│   └── layouts.ex       # Global HTML layout
├── mix.exs
└── .env                 # Environment variables</code></pre>
        </div>
        <p><strong>Key concept</strong> - Nex is AI-Native. Just drop a file in <code class="bg-gray-100 px-1 rounded">src/pages/</code> and it automatically becomes a route. No router configuration needed!</p>

        <h2 class="text-claude-text">4. Run in Development Mode</h2>
        <p>Nex includes a built-in development server with hot reloading enabled by default. Changes to your code are reflected instantly.</p>
        <div class="rounded-xl overflow-hidden mb-12">
          <pre><code class="language-bash">mix nex.dev</code></pre>
        </div>

        <p class="text-lg">Open <code class="bg-gray-100 px-1 rounded">http://localhost:4000</code> in your browser. You should see your new Nex app running!</p>

        <h2 class="text-claude-text">5. Build Your First Page</h2>
        <p>Create a new page with HTMX handlers. Pages are just Elixir modules that render HTML.</p>
        <div class="rounded-xl overflow-hidden mb-12 bg-gray-50 p-6 border border-gray-200">
          <p class="text-sm text-claude-muted">See the examples directory for complete working examples of pages with HTMX handlers, real-time streaming, and more.</p>
        </div>

        <h2 class="text-claude-text mt-16">6. Deploy with Docker</h2>
        <p>Every Nex project includes a Dockerfile. Deploy to any platform that supports containers.</p>
        <div class="rounded-xl overflow-hidden mb-8">
          <pre><code class="language-bash">docker build -t my_app .
docker run -p 4000 my_app</code></pre>
        </div>

        <p>Popular deployment platforms</p>
        <ul class="space-y-2">
          <li><strong>Railway</strong> - Connect your GitHub repo and deploy automatically</li>
          <li><strong>Fly.io</strong> - Use fly launch (Dockerfile detected automatically)</li>
          <li><strong>Render</strong> - Create a new Web Service from your repository</li>
        </ul>

        <h2 class="text-claude-text mt-16">Next Steps</h2>
        <div class="grid md:grid-cols-2 gap-6 not-prose">
          <div class="card bg-white p-6 border border-gray-200 shadow-sm">
            <h3 class="text-xl font-bold mb-3">Learn the Basics</h3>
            <p class="text-claude-muted mb-4">Understand file-based routing, HTMX integration, and state management.</p>
            <a href="/features" class="text-claude-purple font-semibold hover:underline">View Features</a>
          </div>
          <div class="card bg-white p-6 border border-gray-200 shadow-sm">
            <h3 class="text-xl font-bold mb-3">See Examples</h3>
            <p class="text-claude-muted mb-4">Explore real-world examples including chat apps, todos, and dynamic routes.</p>
            <a href="https://github.com/gofenix/nex/tree/main/examples" class="text-claude-purple font-semibold hover:underline">Browse Examples</a>
          </div>
        </div>

        <div class="bg-purple-50 p-8 rounded-3xl border border-purple-100 mt-16">
          <h3 class="text-claude-purple font-bold text-2xl mb-4 mt-0">Get Help</h3>
          <p class="mb-6">Join the community or report issues on GitHub.</p>
          <a href="https://github.com/gofenix/nex" class="btn btn-claude-purple px-8 rounded-full">Visit GitHub</a>
        </div>
      </div>
    </div>
    """
  end
end
