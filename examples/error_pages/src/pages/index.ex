defmodule ErrorPagesExample.Pages.Index do
  use Nex

  def mount(_params) do
    %{title: "Error Pages Demo"}
  end

  def render(assigns) do
    ~H"""
    <div data-testid="error-pages-page" class="max-w-2xl mx-auto mt-12 p-8">
      <h1 class="text-3xl font-bold mb-4">Custom Error Pages Demo</h1>
      <p class="text-gray-600 mb-8">
        This example demonstrates custom error page handling in Nex 0.4.
        Click the buttons below to trigger different error responses.
      </p>

      <div class="space-y-4">
        <div class="bg-white rounded-lg shadow p-6">
          <h2 class="text-xl font-semibold mb-2">404 Not Found</h2>
          <p class="text-gray-600 mb-4">Trigger a 404 error when a page doesn't exist.</p>
          <a href="/this-page-does-not-exist" data-testid="error-pages-trigger-404" class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">
            Trigger 404
          </a>
        </div>

        <div class="bg-white rounded-lg shadow p-6">
          <h2 class="text-xl font-semibold mb-2">403 Forbidden</h2>
          <p class="text-gray-600 mb-4">Trigger a 403 error via a missing CSRF token.</p>
          <button type="button"
                  data-testid="error-pages-trigger-403"
                  onclick="triggerForbidden()"
                  class="bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600">
            Trigger 403
          </button>
        </div>

        <div class="bg-white rounded-lg shadow p-6">
          <h2 class="text-xl font-semibold mb-2">500 Internal Error</h2>
          <p class="text-gray-600 mb-4">Trigger a 500 error for server exceptions.</p>
          <a href="/cause_error" data-testid="error-pages-trigger-500" class="bg-gray-700 text-white px-4 py-2 rounded hover:bg-gray-800">
            Trigger 500
          </a>
        </div>
      </div>

      <script>
        async function triggerForbidden() {
          const response = await fetch('/forbidden', {
            method: 'POST',
            credentials: 'same-origin'
          });

          const html = await response.text();
          history.replaceState({}, '', '/forbidden');
          document.open();
          document.write(html);
          document.close();
        }
      </script>
    </div>
    """
  end
end
