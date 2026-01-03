defmodule DatastarDemo.Pages.Tao do
  use Nex

  def mount(_params) do
    %{title: "Lesson 5: The Tao of Datastar"}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow p-8 max-w-3xl mx-auto">
      <h2 class="text-3xl font-bold text-gray-800 mb-4">Lesson 5: The Tao of Datastar</h2>
      <p class="text-gray-600 mb-6">Design philosophy and best practices</p>

      <div class="mb-8 p-6 border-2 border-red-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Principle 1: Hypermedia First</h3>
        <p class="text-gray-700 mb-4">
          Datastar embraces the hypermedia approach. The server returns HTML fragments, not JSON.
          This keeps the rendering logic on the backend where it belongs.
        </p>
        <div class="p-4 bg-red-50 rounded text-sm text-gray-700">
          Backend returns HTML with matching ids. Datastar morphs the DOM intelligently.
        </div>
      </div>

      <div class="mb-8 p-6 border-2 border-red-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Principle 2: Frontend Reactivity</h3>
        <p class="text-gray-700 mb-4">
          Not everything needs a backend call. Use signals for frontend state that doesnt need persistence.
          This reduces server load and improves responsiveness.
        </p>
        <div class="p-4 bg-red-50 rounded text-sm text-gray-700">
          Use data-signals for UI state. Use @get/@post only when you need backend data.
        </div>
      </div>

      <div class="mb-8 p-6 border-2 border-red-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Principle 3: Minimal JavaScript</h3>
        <p class="text-gray-700 mb-4">
          Datastar lets you build interactive UIs without writing JavaScript.
          Use data attributes to declare behavior, not imperative code.
        </p>
        <div class="p-4 bg-red-50 rounded text-sm text-gray-700">
          Declarative: data-on:click, data-bind, data-show. No event listeners needed.
        </div>
      </div>

      <div class="mb-8 p-6 border-2 border-red-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Principle 4: Progressive Enhancement</h3>
        <p class="text-gray-700 mb-4">
          Start with a working server-rendered page. Add interactivity with Datastar on top.
          If JavaScript fails, the page still works.
        </p>
        <div class="p-4 bg-red-50 rounded text-sm text-gray-700">
          Server renders initial HTML. Datastar enhances with interactivity.
        </div>
      </div>

      <div class="mb-8 p-6 border-2 border-red-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Principle 5: Morphing Over Replacement</h3>
        <p class="text-gray-700 mb-4">
          Datastar uses morphing to intelligently update the DOM. It preserves form state,
          focus, and animations while updating only what changed.
        </p>
        <div class="p-4 bg-red-50 rounded text-sm text-gray-700">
          Smart DOM diffing. Only changed elements are updated. Form state is preserved.
        </div>
      </div>

      <div class="mb-8 p-6 border-2 border-red-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Principle 6: Server-Driven Updates</h3>
        <p class="text-gray-700 mb-4">
          The server decides what to send. The client applies it. This gives you full control
          over business logic and keeps sensitive operations on the backend.
        </p>
        <div class="p-4 bg-red-50 rounded text-sm text-gray-700">
          Backend controls what gets updated. Client is just a renderer.
        </div>
      </div>

      <div class="mb-8 p-6 border-2 border-red-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Best Practices</h3>
        <ul class="space-y-3 text-gray-700">
          <li>Use semantic HTML. Datastar works with standard HTML elements.</li>
          <li>Use id attributes on elements you want to update.</li>
          <li>Keep signals simple. Complex state belongs on the backend.</li>
          <li>Use data-on for user interactions. Use @get/@post for backend calls.</li>
          <li>Return HTML from backend, not JSON.</li>
          <li>Use data-signals for temporary UI state like modals, dropdowns.</li>
          <li>Use backend state for persistent data like user preferences.</li>
          <li>Combine frontend reactivity with backend updates for best UX.</li>
        </ul>
      </div>

      <div class="p-6 bg-gradient-to-r from-red-50 to-blue-50 rounded-lg">
        <h3 class="text-xl font-bold text-gray-800 mb-3">Summary</h3>
        <p class="text-gray-700 mb-4">
          Datastar combines the best of both worlds: server-side rendering for reliability and
          frontend reactivity for responsiveness. It embraces hypermedia, keeps JavaScript minimal,
          and lets you build modern interactive applications with simple, declarative syntax.
        </p>
        <p class="text-sm text-gray-600">
          The Tao of Datastar is simplicity, pragmatism, and developer happiness.
        </p>
      </div>
    </div>
    """
  end
end
