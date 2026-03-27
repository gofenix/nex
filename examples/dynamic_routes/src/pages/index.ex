defmodule DynamicRoutes.Pages.Index do
  use Nex

  def mount(_params) do
    %{
      title: "Dynamic Routes Example"
    }
  end

  def render(assigns) do
    ~H"""
    <div data-testid="dynamic-routes-page" class="space-y-8">
      <div>
        <h1 class="text-3xl font-bold text-gray-800 mb-4">Dynamic Routes Example</h1>
        <p class="text-gray-600">Showcasing Nex framework's dynamic routing capabilities</p>
      </div>

      <div class="grid md:grid-cols-2 gap-6">
        <!-- User-related routes -->
        <div class="bg-white rounded-lg p-6 shadow">
          <h2 class="text-xl font-semibold mb-4">User Routes</h2>
          <div class="space-y-3">
            <div>
              <code class="text-sm bg-gray-100 px-2 py-1 rounded">src/pages/users/[id].ex</code>
              <p class="text-sm text-gray-600 mt-1">Matches: /users/123, /users/456</p>
              <a href="/users/1" data-testid="dynamic-user-link" class="text-blue-600 hover:underline text-sm">→ View User 1</a>
            </div>
          </div>
        </div>

        <!-- Post-related routes -->
        <div class="bg-white rounded-lg p-6 shadow">
          <h2 class="text-xl font-semibold mb-4">Post Routes</h2>
          <div class="space-y-3">
            <div>
              <code class="text-sm bg-gray-100 px-2 py-1 rounded">src/pages/posts/[slug].ex</code>
              <p class="text-sm text-gray-600 mt-1">Matches: /posts/hello-world, /posts/my-first-post</p>
              <a href="/posts/hello-world" data-testid="dynamic-post-link" class="text-blue-600 hover:underline text-sm">→ View "hello-world"</a>
            </div>
          </div>
        </div>

        <!-- Wildcard routes -->
        <div class="bg-white rounded-lg p-6 shadow">
          <h2 class="text-xl font-semibold mb-4">Wildcard Routes</h2>
          <div class="space-y-3">
            <div>
              <code class="text-sm bg-gray-100 px-2 py-1 rounded">src/pages/docs/[...path].ex</code>
              <p class="text-sm text-gray-600 mt-1">Matches: /docs/* (any level)</p>
              <a href="/docs/getting-started/install" data-testid="dynamic-doc-link" class="text-blue-600 hover:underline text-sm">→ View Documentation</a>
            </div>
          </div>
        </div>

        <!-- API routes -->
        <div class="bg-white rounded-lg p-6 shadow">
          <h2 class="text-xl font-semibold mb-4">API Routes</h2>
          <div class="space-y-3">
            <div>
              <code class="text-sm bg-gray-100 px-2 py-1 rounded">src/api/users/[id].ex</code>
              <p class="text-sm text-gray-600 mt-1">API: GET /api/users/123</p>
              <button
                hx-get="/api/users/1"
                hx-target="#api-result"
                data-testid="dynamic-api-button"
                class="bg-blue-500 text-white px-3 py-1 rounded text-sm hover:bg-blue-600">
                Test API
              </button>
              <div id="api-result" data-testid="dynamic-api-result" class="mt-2"></div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
