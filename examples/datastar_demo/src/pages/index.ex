defmodule DatastarDemo.Pages.Index do
  use Nex

  def mount(_params) do
    %{title: "Lesson 1: Getting Started"}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow p-8 max-w-3xl mx-auto">
      <h2 class="text-3xl font-bold text-gray-800 mb-4">Lesson 1: Getting Started</h2>

      <div class="mb-8 p-6 border-2 border-gray-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Example 1: data-on attribute</h3>
        <p class="text-sm text-gray-600 mb-4">Official example from Datastar guide</p>

        <button
          data-on:click="alert('I am sorry Dave. I am afraid I cannot do that.')"
          class="px-6 py-3 bg-blue-500 text-white rounded-lg hover:bg-blue-600">
          Open the pod bay doors, HAL.
        </button>

        <div class="mt-4 p-3 bg-gray-50 rounded text-sm">
          <p class="font-semibold mb-2">Key point:</p>
          <p>data-on can listen to any event and execute Datastar expressions</p>
        </div>
      </div>

      <div class="mb-8 p-6 border-2 border-gray-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Example 2: Patching Elements</h3>
        <p class="text-sm text-gray-600 mb-4">Backend-driven DOM updates via morphing</p>

        <button
          data-on:click="@post('/open_doors')"
          class="px-6 py-3 bg-purple-500 text-white rounded-lg hover:bg-purple-600 mb-4">
          Open the pod bay doors, HAL.
        </button>

        <div id="hal" class="p-4 bg-gray-50 rounded-lg text-center">Waiting for command...</div>

        <div class="mt-4 p-3 bg-gray-50 rounded text-sm">
          <p class="font-semibold mb-2">How it works</p>
          <p>Button with data-on:click sends @get request to backend endpoint. Backend returns HTML fragment with matching id. Datastar morphs the DOM by id.</p>
        </div>

        <div class="mt-3 p-3 bg-blue-50 rounded text-sm">
          <p class="font-semibold mb-2">Key concepts</p>
          <ul class="ml-4 space-y-1">
            <li>1. Datastar sends @get request to backend</li>
            <li>2. Backend returns HTML with content-type text/html</li>
            <li>3. Datastar matches elements by id (morphing)</li>
            <li>4. Only changed parts of DOM are updated</li>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  def open_doors(_params) do
    assigns = %{}
    ~H"""
    <div id="hal" class="p-4 bg-red-50 border border-red-200 rounded-lg text-center">
      <p class="text-red-800 font-bold">I am sorry, Dave. I am afraid I cannot do that.</p>
    </div>
    """
  end
end
