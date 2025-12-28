defmodule NexWebsite.Pages.Features do
  use Nex.Page
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
    <div class="max-w-4xl mx-auto px-4 py-20">
      <h1 class="text-5xl font-extrabold mb-12 tracking-tight">Core <span class="text-claude-purple">Features</span></h1>

      <div class="space-y-24">
        <section>
          <h2 class="text-3xl font-bold mb-6">File-based Routing</h2>
          <p class="text-lg text-claude-muted mb-8 leading-relaxed">
            Nex automatically discovers routes from your file system. No need to manually define routes in a central router file. Just create a file, and it's instantly accessible.
          </p>
          <div class="rounded-xl overflow-hidden">
            <%= raw @file_routing_code %>
          </div>
        </section>

        <section>
          <h2 class="text-3xl font-bold mb-6">HTMX Integrated</h2>
          <p class="text-lg text-claude-muted mb-8 leading-relaxed">
            Every page in Nex is an HTMX endpoint by default. POST requests to a page automatically map to public functions in your module, making partial updates trivial.
          </p>
          <div class="rounded-xl overflow-hidden">
            <%= raw @htmx_action_code %>
          </div>
        </section>

        <section>
          <h2 class="text-3xl font-bold mb-6">Built-in State Management</h2>
          <p class="text-lg text-claude-muted mb-8 leading-relaxed">
            <code class="bg-gray-100 px-1 rounded">Nex.Store</code> provides a simple key-value store tied to the user's page session. Perfect for handling form state, navigation history, and real-time updates without a database.
          </p>
        </section>

        <section>
          <h2 class="text-3xl font-bold mb-6">Server-Sent Events (SSE)</h2>
          <p class="text-lg text-claude-muted mb-8 leading-relaxed">
            Real-time updates are a first-class citizen in Nex. Use the <code class="bg-gray-100 px-1 rounded">Nex.SSE</code> behavior to create streaming endpoints for live dashboards, chat apps, or progress bars.
          </p>
          <div class="rounded-xl overflow-hidden">
            <%= raw @sse_stream_code %>
          </div>
        </section>

        <section>
          <h2 class="text-3xl font-bold mb-6">Built-in Security</h2>
          <p class="text-lg text-claude-muted mb-8 leading-relaxed">
            Security shouldn't be an afterthought. Nex comes with automatic CSRF protection for all POST requests. Use <code class="bg-gray-100 px-1 rounded">csrf_input_tag/0</code> in your forms and Nex handles the rest.
          </p>
        </section>
      </div>
    </div>
    """
  end
end
