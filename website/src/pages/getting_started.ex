defmodule NexWebsite.Pages.GettingStarted do
  use Nex.Page

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

        <h2 class="text-claude-text">3. Run in Development Mode</h2>
        <p>Nex includes a built-in development server with hot reloading enabled by default.</p>
        <div class="rounded-xl overflow-hidden mb-12">
          <pre><code class="language-bash">mix nex.dev</code></pre>
        </div>

        <div class="bg-purple-50 p-8 rounded-3xl border border-purple-100 mt-16">
          <h3 class="text-claude-purple font-bold text-2xl mb-4 mt-0">Ready to build?</h3>
          <p class="mb-6">Check out the <a href="/features" class="font-bold underline">Features</a> page to see what's possible with Nex.</p>
          <a href="https://github.com/fenix/nex/tree/main/examples" class="btn btn-claude-purple px-8 rounded-full">Explore Examples</a>
        </div>
      </div>
    </div>
    """
  end
end
