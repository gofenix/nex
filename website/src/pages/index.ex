defmodule NexWebsite.Pages.Index do
  use Nex.Page
  alias NexWebsite.CodeExamples

  def mount(_params) do
    %{
      title: "Nex - The Minimalist Elixir Web Framework powered by HTMX",
      example_code: CodeExamples.get("index_page.md") |> CodeExamples.format_for_display()
    }
  end

  def render(assigns) do
    ~H"""
    <div class="hero min-h-[80vh] px-4">
      <div class="hero-content text-center flex-col max-w-4xl">
        <div class="badge badge-outline border-claude-purple text-claude-purple px-4 py-3 mb-6 font-semibold">
          v0.1.0 Released
        </div>
        <h1 class="text-5xl md:text-7xl font-extrabold tracking-tight mb-8 leading-tight">
          Modern Web Apps,<br/>
          <span class="text-claude-purple">Minimum Complexity.</span>
        </h1>
        <p class="text-xl md:text-2xl text-claude-muted mb-10 max-w-2xl mx-auto leading-relaxed">
          Nex is a minimalist Elixir web framework that leverages HTMX for rich interactivity without the complexity of modern JS frameworks.
        </p>
        <div class="flex flex-col sm:flex-row gap-4 w-full sm:w-auto">
          <a href="/getting_started" class="btn btn-claude-purple btn-lg px-10 rounded-full shadow-xl shadow-purple-200">
            Get Started
          </a>
          <div class="bg-white/50 border border-gray-200 rounded-full flex items-center px-6 py-3 font-mono text-sm shadow-sm">
            <span class="text-claude-gold mr-2">$</span>
            <code class="text-gray-700">mix archive.install hex nex_new</code>
            <button class="ml-4 hover:text-claude-purple" onclick="navigator.clipboard.writeText('mix archive.install hex nex_new')">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 5H6a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2v-1M8 5a2 2 0 002 2h2a2 2 0 002-2M8 5a2 2 0 012-2h2a2 2 0 012 2m0 0h2a2 2 0 012 2v3m2 4H10m0 0l3-3m-3 3l3 3" /></svg>
            </button>
          </div>
        </div>
      </div>
    </div>

    <div class="px-4 md:px-8 py-20 max-w-7xl mx-auto">
      <div class="grid md:grid-cols-3 gap-12">
        <div class="card bg-white p-8 border border-gray-100 shadow-sm hover:shadow-md transition-shadow">
          <div class="w-12 h-12 bg-purple-100 rounded-2xl flex items-center justify-center mb-6">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-claude-purple" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" /></svg>
          </div>
          <h3 class="text-2xl font-bold mb-4">File-based Routing</h3>
          <p class="text-claude-muted leading-relaxed">
            Routes are discovered from your <code class="bg-gray-100 px-1 rounded">src/pages/</code> directory automatically. No manual router configuration needed.
          </p>
        </div>

        <div class="card bg-white p-8 border border-gray-100 shadow-sm hover:shadow-md transition-shadow">
          <div class="w-12 h-12 bg-yellow-100 rounded-2xl flex items-center justify-center mb-6">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-claude-gold" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" /></svg>
          </div>
          <h3 class="text-2xl font-bold mb-4">HTMX Powered</h3>
          <p class="text-claude-muted leading-relaxed">
            Build reactive UIs with simple Elixir functions. Nex handles the HTMX integration, letting you focus on your application logic.
          </p>
        </div>

        <div class="card bg-white p-8 border border-gray-100 shadow-sm hover:shadow-md transition-shadow">
          <div class="w-12 h-12 bg-blue-100 rounded-2xl flex items-center justify-center mb-6">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4m0 5c0 2.21-3.582 4-8 4s-8-1.79-8-4" /></svg>
          </div>
          <h3 class="text-2xl font-bold mb-4">Integrated State</h3>
          <p class="text-claude-muted leading-relaxed">
            Manage page and session state with <code class="bg-gray-100 px-1 rounded">Nex.Store</code>. Seamless data flow from server to UI.
          </p>
        </div>
      </div>
    </div>

    <div class="bg-white py-24 border-y border-gray-100">
      <div class="max-w-7xl mx-auto px-4 md:px-8">
        <div class="flex flex-col md:flex-row items-center gap-16">
          <div class="flex-1">
            <h2 class="text-4xl font-bold mb-6 leading-tight">Simplicity is the <br/><span class="text-claude-purple">Ultimate Sophistication.</span></h2>
            <p class="text-lg text-claude-muted mb-8 leading-relaxed">
              We believe that web development has become unnecessarily complex. Nex brings back the joy of building for the web by focusing on what matters: your code and your users.
            </p>
            <ul class="space-y-4">
              <li class="flex items-center gap-3">
                <div class="w-6 h-6 rounded-full bg-green-100 flex items-center justify-center">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-green-600" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" /></svg>
                </div>
                <span class="font-medium">Zero-config by default</span>
              </li>
              <li class="flex items-center gap-3">
                <div class="w-6 h-6 rounded-full bg-green-100 flex items-center justify-center">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-green-600" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" /></svg>
                </div>
                <span class="font-medium">Instant Hot Reloading</span>
              </li>
              <li class="flex items-center gap-3">
                <div class="w-6 h-6 rounded-full bg-green-100 flex items-center justify-center">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-green-600" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" /></svg>
                </div>
                <span class="font-medium">DaisyUI & Tailwind Built-in</span>
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
    """
  end
end
