defmodule TodosApi.Pages.Index do
  use Nex.Page

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-8">
      <div class="mb-8">
        <h1 class="text-4xl font-bold mb-2">Todos API</h1>
        <p class="text-gray-600">RESTful JSON API - 100% aligned with Next.js API Routes</p>
      </div>

      <!-- Quick Start -->
      <div class="mb-8 p-6 bg-gradient-to-r from-blue-50 to-indigo-50 border border-blue-200 rounded-lg">
        <h2 class="text-xl font-semibold mb-3">🚀 Quick Start</h2>
        <div class="space-y-2 text-sm">
          <div class="flex items-center gap-2">
            <code class="bg-white px-3 py-1 rounded border">GET /api/todos</code>
            <span class="text-gray-600">List all todos</span>
          </div>
          <div class="flex items-center gap-2">
            <code class="bg-white px-3 py-1 rounded border">POST /api/todos</code>
            <span class="text-gray-600">Create a new todo</span>
          </div>
          <div class="flex items-center gap-2">
            <code class="bg-white px-3 py-1 rounded border">GET /api/todos/[id]</code>
            <span class="text-gray-600">Get a specific todo</span>
          </div>
          <div class="flex items-center gap-2">
            <code class="bg-white px-3 py-1 rounded border">PUT /api/todos/[id]</code>
            <span class="text-gray-600">Update a todo</span>
          </div>
          <div class="flex items-center gap-2">
            <code class="bg-white px-3 py-1 rounded border">DELETE /api/todos/[id]</code>
            <span class="text-gray-600">Delete a todo</span>
          </div>
        </div>
      </div>

      <!-- Next.js Comparison -->
      <div class="mb-8">
        <h2 class="text-2xl font-semibold mb-4">📊 Next.js API Routes Comparison</h2>
        <div class="overflow-x-auto">
          <table class="w-full border-collapse border border-gray-300">
            <thead class="bg-gray-100">
              <tr>
                <th class="border border-gray-300 px-4 py-2 text-left">Feature</th>
                <th class="border border-gray-300 px-4 py-2 text-left">Next.js</th>
                <th class="border border-gray-300 px-4 py-2 text-left">Nex</th>
              </tr>
            </thead>
            <tbody class="text-sm">
              <tr>
                <td class="border border-gray-300 px-4 py-2 font-mono">req.query</td>
                <td class="border border-gray-300 px-4 py-2"><code class="bg-gray-100 px-2 py-1 rounded">req.query.id</code></td>
                <td class="border border-gray-300 px-4 py-2"><code class="bg-gray-100 px-2 py-1 rounded">req.query["id"]</code></td>
              </tr>
              <tr>
                <td class="border border-gray-300 px-4 py-2 font-mono">req.body</td>
                <td class="border border-gray-300 px-4 py-2"><code class="bg-gray-100 px-2 py-1 rounded">req.body.text</code></td>
                <td class="border border-gray-300 px-4 py-2"><code class="bg-gray-100 px-2 py-1 rounded">req.body["text"]</code></td>
              </tr>
              <tr>
                <td class="border border-gray-300 px-4 py-2 font-mono">res.json()</td>
                <td class="border border-gray-300 px-4 py-2"><code class="bg-gray-100 px-2 py-1 rounded">res.json(&#123;data&#125;)</code></td>
                <td class="border border-gray-300 px-4 py-2"><code class="bg-gray-100 px-2 py-1 rounded">Nex.json(%&#123;data: ...&#125;)</code></td>
              </tr>
              <tr>
                <td class="border border-gray-300 px-4 py-2 font-mono">res.status()</td>
                <td class="border border-gray-300 px-4 py-2"><code class="bg-gray-100 px-2 py-1 rounded">res.status(201)</code></td>
                <td class="border border-gray-300 px-4 py-2"><code class="bg-gray-100 px-2 py-1 rounded">Nex.json(..., status: 201)</code></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- API Examples -->
      <div class="mb-8">
        <h2 class="text-2xl font-semibold mb-4">💡 API Examples</h2>

        <!-- GET /api/todos -->
        <div class="mb-6 p-4 bg-white border rounded-lg">
          <h3 class="font-semibold mb-2">GET /api/todos</h3>
          <p class="text-sm text-gray-600 mb-3">List all todos with optional filtering</p>
          <div class="space-y-2">
            <div>
              <div class="text-xs text-gray-500 mb-1">Request:</div>
              <code class="block bg-gray-900 text-green-400 p-3 rounded text-sm">
                curl http://localhost:4000/api/todos?completed=false&limit=10
              </code>
            </div>
            <div>
              <div class="text-xs text-gray-500 mb-1">Response:</div>
              <code class="block bg-gray-900 text-green-400 p-3 rounded text-sm">
                &#123;
                  "data": [...],
                  "count": 5
                &#125;
              </code>
            </div>
          </div>
        </div>

        <!-- POST /api/todos -->
        <div class="mb-6 p-4 bg-white border rounded-lg">
          <h3 class="font-semibold mb-2">POST /api/todos</h3>
          <p class="text-sm text-gray-600 mb-3">Create a new todo</p>
          <div class="space-y-2">
            <div>
              <div class="text-xs text-gray-500 mb-1">Request:</div>
              <code class="block bg-gray-900 text-green-400 p-3 rounded text-sm overflow-x-auto">
                curl -X POST http://localhost:4000/api/todos \
                  -H "Content-Type: application/json" \
                  -d '&#123;"text": "Buy groceries"&#125;'
              </code>
            </div>
            <div>
              <div class="text-xs text-gray-500 mb-1">Response (201 Created):</div>
              <code class="block bg-gray-900 text-green-400 p-3 rounded text-sm">
                &#123;
                  "data": &#123;
                    "id": 123,
                    "text": "Buy groceries",
                    "completed": false,
                    "created_at": "2025-12-31T13:45:00Z"
                  &#125;
                &#125;
              </code>
            </div>
          </div>
        </div>

        <!-- PUT /api/todos/[id] -->
        <div class="mb-6 p-4 bg-white border rounded-lg">
          <h3 class="font-semibold mb-2">PUT /api/todos/[id]</h3>
          <p class="text-sm text-gray-600 mb-3">Update a todo</p>
          <div class="space-y-2">
            <div>
              <div class="text-xs text-gray-500 mb-1">Request:</div>
              <code class="block bg-gray-900 text-green-400 p-3 rounded text-sm overflow-x-auto">
                curl -X PUT http://localhost:4000/api/todos/123 \
                  -H "Content-Type: application/json" \
                  -d '&#123;"completed": true&#125;'
              </code>
            </div>
          </div>
        </div>

        <!-- DELETE /api/todos/[id] -->
        <div class="mb-6 p-4 bg-white border rounded-lg">
          <h3 class="font-semibold mb-2">DELETE /api/todos/[id]</h3>
          <p class="text-sm text-gray-600 mb-3">Delete a todo</p>
          <div class="space-y-2">
            <div>
              <div class="text-xs text-gray-500 mb-1">Request:</div>
              <code class="block bg-gray-900 text-green-400 p-3 rounded text-sm">
                curl -X DELETE http://localhost:4000/api/todos/123
              </code>
            </div>
            <div>
              <div class="text-xs text-gray-500 mb-1">Response:</div>
              <code class="block bg-gray-900 text-green-400 p-3 rounded text-sm">
                204 No Content
              </code>
            </div>
          </div>
        </div>
      </div>

      <!-- Code Example -->
      <div class="mb-8">
        <h2 class="text-2xl font-semibold mb-4">&#x1F4DD; Code Example</h2>
        <div class="bg-gray-900 text-gray-100 p-4 rounded-lg overflow-x-auto">
          <pre class="text-sm"><code>
            defmodule TodosApi.Api.Todos.Index do
              def get(req) do
                # Query parameters - Next.js style
                completed_filter = req.query["completed"]
                limit = req.query["limit"]

                todos = get_todos(completed_filter, limit)
                Nex.json(%&#123;data: todos, count: length(todos)&#125;)
              end

              def post(req) do
                # Request body - Next.js style
                text = req.body["text"]

                todo = create_todo(text)
                Nex.json(%&#123;data: todo&#125;, status: 201)
              end
            end
          </code></pre>
        </div>
      </div>

      <!-- Footer -->
      <div class="text-center text-sm text-gray-500 mt-12">
        <p>Built with Nex Framework - 100% aligned with Next.js API Routes</p>
      </div>
    </div>
    """
  end

end
