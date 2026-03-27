defmodule RatelimitExample.Pages.Index do
  use Nex

  def mount(_params) do
    %{title: "Rate Limit Demo"}
  end

  def render(assigns) do
    ~H"""
    <div data-testid="ratelimit-page" class="max-w-2xl mx-auto">
      <h1 class="text-3xl font-bold mb-4">Rate Limiting Demo</h1>
      <p class="text-gray-600 mb-6">
        This example demonstrates Nex.RateLimit from Nex 0.4.
        The API endpoint is limited to 5 requests per minute.
      </p>

      <div class="bg-white rounded-lg shadow p-6 mb-6">
        <h2 class="text-xl font-semibold mb-4">Test Rate Limiting</h2>
        
        <div class="flex gap-2 mb-4">
          <button 
            hx-get="/api/status" 
            hx-target="#result"
            data-testid="ratelimit-request"
            class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">
            Make Request
          </button>
          
          <button 
            onclick="makeMultipleRequests()"
            data-testid="ratelimit-burst"
            class="bg-purple-500 text-white px-4 py-2 rounded hover:bg-purple-600">
            Make 6 Rapid Requests
          </button>
        </div>

        <div id="result" data-testid="ratelimit-result" class="bg-gray-50 p-4 rounded min-h-[100px]">
          <p class="text-gray-500">Click "Make Request" to see rate limiting in action...</p>
        </div>
      </div>

      <div class="bg-white rounded-lg shadow p-6">
        <h2 class="text-xl font-semibold mb-4">Rate Limit Headers</h2>
        <p class="text-gray-600 mb-4">
          Each response includes these headers:
        </p>
        <ul class="list-disc list-inside text-gray-700 space-y-1">
          <li><code>X-RateLimit-Limit</code> - Maximum requests allowed</li>
          <li><code>X-RateLimit-Remaining</code> - Remaining requests in window</li>
        </ul>
      </div>
    </div>

    <script>
      async function makeMultipleRequests() {
        const resultDiv = document.getElementById('result');
        resultDiv.innerHTML = '<p class="text-blue-600">Sending 6 requests...</p>';
        
        for (let i = 1; i <= 6; i++) {
          try {
            const response = await fetch('/api/status');
            const data = await response.json();
            const remaining = response.headers.get('X-RateLimit-Remaining');
            const limit = response.headers.get('X-RateLimit-Limit');
            
            if (response.status === 429) {
              resultDiv.innerHTML += `<p class="text-red-600">Request ${i}: Rate limited! Try again in ${data.retry_after}s</p>`;
            } else {
              resultDiv.innerHTML += `<p class="text-green-600">Request ${i}: Success! (${remaining}/${limit} remaining)</p>`;
            }
          } catch (e) {
            resultDiv.innerHTML += `<p class="text-red-600">Request ${i}: Error - ${e.message}</p>`;
          }
          
          // Small delay between requests
          await new Promise(r => setTimeout(r, 100));
        }
      }
    </script>
    """
  end
end
