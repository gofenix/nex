defmodule ErrorShowcase.Pages.Index do
  use Nex

  def mount(_params) do
    %{
      title: "Error Handling Showcase"
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-6">
      <h1 class="text-4xl font-bold mb-2 text-gray-800">Error Handling Showcase</h1>
      <p class="text-gray-600 mb-8">Nex intelligently handles errors based on request type. Click the buttons below to see different error responses.</p>

      <div class="grid md:grid-cols-2 gap-6 mb-8">
        <!-- HTMX Request Errors -->
        <div class="bg-white rounded-lg shadow-md p-6">
          <h2 class="text-xl font-semibold mb-4 text-gray-700">HTMX Request Errors</h2>
          <p class="text-sm text-gray-600 mb-4">
            When HTMX makes a request and gets an error, Nex returns an HTML fragment (not a full page).
            This prevents breaking the current page layout.
          </p>
          <div class="space-y-2" hx-ext="response-targets">
            <button hx-get="/path-that-does-not-exist"
                    hx-target-404="#htmx-result"
                    hx-target-500="#htmx-result"
                    hx-swap="innerHTML"
                    class="w-full px-4 py-2 bg-orange-500 text-white rounded hover:bg-orange-600">
              Trigger Real 404 (HTMX)
            </button>
            <button hx-get="/trigger_crash"
                    hx-target-404="#htmx-result"
                    hx-target-500="#htmx-result"
                    hx-swap="innerHTML"
                    class="w-full px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600">
              Trigger Real 500 (HTMX)
            </button>
            <div id="htmx-result" class="mt-4 p-4 bg-gray-50 rounded border border-gray-200 min-h-[100px]">
              <p class="text-gray-500 text-sm">Error response will appear here...</p>
            </div>
          </div>
        </div>

        <!-- API Request Errors -->
        <div class="bg-white rounded-lg shadow-md p-6">
          <h2 class="text-xl font-semibold mb-4 text-gray-700">API Request Errors</h2>
          <p class="text-sm text-gray-600 mb-4">
            When the client expects JSON (Accept: application/json), Nex returns a JSON error response.
            Perfect for API clients and AJAX requests.
          </p>
        <div class="space-y-2">
          <button onclick="fetchJson('/api/non-existent')"
                  class="w-full px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600">
            Trigger Real 404 (JSON)
          </button>
          <button onclick="fetchJson('/api/trigger_crash')"
                  class="w-full px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600">
            Trigger Real 500 (JSON)
          </button>
          <div id="api-result" class="mt-4 p-4 bg-gray-50 rounded border border-gray-200 min-h-[100px]">
            <p class="text-gray-500 text-sm">JSON response will appear here...</p>
          </div>
        </div>
        </div>
      </div>

      <div class="bg-white rounded-lg shadow-md p-6 mb-8">
        <h2 class="text-xl font-semibold mb-4 text-gray-700">Browser Navigation Errors</h2>
        <p class="text-sm text-gray-600 mb-4">
          When you navigate directly to an error URL (not via HTMX), Nex returns a full HTML error page with styling.
          This provides a good user experience even for direct navigation.
        </p>
        <div class="space-y-2">
          <a href="/some-random-page"
             class="block px-4 py-2 bg-orange-500 text-white rounded hover:bg-orange-600 text-center">
            Navigate to Non-existent Page (404)
          </a>
          <a href="/trigger_crash"
             class="block px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600 text-center">
            Navigate to Crashing Page (500)
          </a>
        </div>
      </div>

      <!-- Info Section -->
      <div class="bg-blue-50 border border-blue-200 rounded-lg p-6">
        <h3 class="font-semibold text-blue-900 mb-3">How Nex Smart Error Handling Works</h3>
        <div class="space-y-3 text-sm text-blue-800">
          <div>
            <strong>1. HTMX Requests (hx-request header)</strong>
            <p class="text-blue-700 mt-1">→ Returns HTML fragment (no full page) to prevent layout breaking</p>
          </div>
          <div>
            <strong>2. API Requests (Accept: application/json)</strong>
            <p class="text-blue-700 mt-1">→ Returns JSON error with status code and message</p>
          </div>
          <div>
            <strong>3. Browser Navigation</strong>
            <p class="text-blue-700 mt-1">→ Returns full HTML error page with Tailwind styling</p>
          </div>
          <div>
            <strong>4. Development Mode</strong>
            <p class="text-blue-700 mt-1">→ Includes detailed error information and stack traces</p>
          </div>
        </div>
      </div>
    </div>

    <script>
      function fetchJson(url) {
        fetch(url, {
          headers: {
            'Accept': 'application/json'
          }
        })
        .then(response => {
          return response.json().then(data => {
            return { status: response.status, data: data };
          });
        })
        .then(({status, data}) => {
          const color = status >= 400 ? 'text-red-600' : 'text-green-600';
          document.getElementById('api-result').innerHTML =
            `<div class="${color} font-bold mb-2">Status: ${status}</div>` +
            '<pre class="text-sm overflow-auto bg-gray-900 text-emerald-400 p-2 rounded">' +
            JSON.stringify(data, null, 2) +
            '</pre>';
        })
        .catch(error => {
          document.getElementById('api-result').innerHTML =
            '<p class="text-red-600 font-bold">Fetch Error</p>' +
            '<p class="text-sm text-red-500">' + error.message + '</p>';
        });
      }
    </script>
    """
  end
end
