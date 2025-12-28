defmodule DynamicRoutes.Pages.Docs.Path do
  use Nex.Page

  def mount(%{"path" => path}) do
    path_string = Enum.join(path, "/")
    content = get_doc_content(path_string)

    %{
      title: "Documentation - #{path_string || "Home"}",
      path: path,
      path_string: path_string,
      content: content,
      params_display: ~s(%{"path" => #{inspect(path)}})
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <nav class="text-sm text-gray-500">
        <a href="/" class="hover:text-gray-700">Home</a>
        <span class="mx-2">/</span>
        <span>Documentation</span>
        <span class="mx-2">/</span>
        <span>{@path_string || "Home"}</span>
      </nav>

      <div class="bg-white rounded-lg p-6 shadow">
        <h1 class="text-2xl font-bold mb-4">Documentation: {@path_string || "Home"}</h1>

        <div class="bg-yellow-50 border border-yellow-200 p-4 rounded mb-6">
          <h3 class="font-semibold text-yellow-800 mb-2">⚠️ Wildcard Route Example</h3>
          <p class="text-sm text-yellow-700">
            This page uses <code class="bg-yellow-100 px-1">[...path]</code> wildcard route,
            which can match paths at any level.
          </p>
        </div>

        <div class="prose max-w-none">
          <div class="bg-gray-50 p-4 rounded mb-6">
            <h3 class="font-mono text-sm mb-2">Route Parsing</h3>
            <div class="space-y-2 text-sm">
              <div>
                <span class="text-gray-600">File Path:</span>
                <br>
                <code class="text-xs">docs/[...path].ex</code>
              </div>
              <div>
                <span class="text-gray-600">Match Examples:</span>
                <br>
                <code class="text-xs">/docs/getting-started</code><br>
                <code class="text-xs">/docs/api/users</code><br>
                <code class="text-xs">/docs/tutorials/basics/installation</code>
              </div>
              <div>
                <span class="text-gray-600">Extracted Path:</span>
                <br>
                <code class="text-xs">path: ["getting-started"]</code><br>
                <code class="text-xs">path: ["api", "users"]</code><br>
                <code class="text-xs">path: ["tutorials", "basics", "installation"]</code>
              </div>
            </div>
          </div>

          <div class="space-y-4">
            <p>
              Current path: <code class="bg-gray-100 px-2 py-1 rounded">/{@path_string}</code>
            </p>

            <p>
              Extracted path parameters:
            </p>

            <pre class="bg-gray-100 p-3 rounded text-sm">{@params_display}</pre>

            <div class="mt-6">
              <h2 class="text-xl font-semibold mb-3">Documentation Content</h2>
              <div class="bg-blue-50 p-4 rounded">
                <p>{@content}</p>
              </div>
            </div>
          </div>
        </div>

        <div class="mt-8">
          <h2 class="text-xl font-semibold mb-4">Other Documentation Pages</h2>
          <div class="grid md:grid-cols-2 gap-4">
            <a href="/docs/getting-started" class="block p-4 border rounded hover:bg-gray-50">
              <h3 class="font-semibold">Getting Started</h3>
              <p class="text-sm text-gray-600">Get started with Nex framework in 5 minutes</p>
            </a>
            <a href="/docs/api/overview" class="block p-4 border rounded hover:bg-gray-50">
              <h3 class="font-semibold">API Documentation</h3>
              <p class="text-sm text-gray-600">Complete API reference</p>
            </a>
            <a href="/docs/tutorials/basics" class="block p-4 border rounded hover:bg-gray-50">
              <h3 class="font-semibold">Basic Tutorials</h3>
              <p class="text-sm text-gray-600">Learn from scratch</p>
            </a>
            <a href="/docs/advanced/custom-hooks" class="block p-4 border rounded hover:bg-gray-50">
              <h3 class="font-semibold">Advanced Guide</h3>
              <p class="text-sm text-gray-600">Custom hooks and extensions</p>
            </a>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Return different documentation content based on path
  defp get_doc_content(path_string) do
    case path_string do
      nil -> "Welcome to Nex framework documentation! Select a section to get started."
      "getting-started" -> "This is the quick start guide, including installation, configuration, and your first Hello World application."
      "api" -> "API documentation overview, containing all available functions and modules."
      "api" <> rest -> "API documentation: #{rest} - Detailed API explanations and examples."
      "tutorials" -> "Collection of tutorials, a complete learning path from basics to advanced."
      "tutorials" <> rest -> "Tutorial: #{rest} - Step-by-step practical guide."
      "advanced" -> "Advanced topics, including performance optimization, extension development, etc."
      "advanced" <> rest -> "Advanced: #{rest} - In-depth exploration of specific topics."
      _ -> "Documentation page: #{path_string} - Content is being written..."
    end
  end
end
