defmodule DatastarDemo.Pages.Requests do
  use Nex

  def mount(_params) do
    %{title: "Lesson 4: Backend Requests"}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow p-8 max-w-3xl mx-auto">
      <h2 class="text-3xl font-bold text-gray-800 mb-4">Lesson 4: Backend Requests</h2>
      <p class="text-gray-600 mb-6">Send signals to backend and handle responses</p>

      <div class="mb-8 p-6 border-2 border-orange-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Example 1: @post Request</h3>
        <p class="text-sm text-gray-600 mb-4">Fetch data from backend with @post</p>

        <button
          data-on:click="@post('/requests/fetch_message')"
          class="px-4 py-2 bg-blue-500 text-white rounded">
          Fetch Message
        </button>
        <div id="message" class="mt-4 p-4 bg-gray-50 rounded">Waiting for message...</div>
      </div>

      <div class="mb-8 p-6 border-2 border-orange-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Example 2: @post Request</h3>
        <p class="text-sm text-gray-600 mb-4">Send data to backend with @post</p>

        <div data-signals="{inputValue: ''}" class="space-y-4">
          <input
            type="text"
            data-on:input="$inputValue = event.target.value"
            placeholder="Enter text"
            class="w-full px-4 py-2 border rounded"/>
          <button
            data-on:click="@post('/requests/process', {text: $inputValue})"
            class="px-4 py-2 bg-green-500 text-white rounded">
            Process
          </button>
          <div id="result" class="p-4 bg-gray-50 rounded">Result will appear here</div>
        </div>
      </div>

      <div class="mb-8 p-6 border-2 border-orange-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Example 3: Sending Signals</h3>
        <p class="text-sm text-gray-600 mb-4">Send signal values to backend</p>

        <div data-signals="{count: 0}" class="space-y-4">
          <div class="flex gap-2 items-center">
            <button data-on:click="$count--" class="px-3 py-2 bg-red-500 text-white rounded">-</button>
            <span class="text-2xl font-bold" data-text="$count"></span>
            <button data-on:click="$count++" class="px-3 py-2 bg-green-500 text-white rounded">+</button>
          </div>
          <button
            data-on:click="@post('/requests/save_count', {count: $count})"
            class="px-4 py-2 bg-purple-500 text-white rounded">
            Save Count
          </button>
          <div id="save_status" class="p-4 bg-gray-50 rounded">Status will appear here</div>
        </div>
      </div>

      <div class="mb-8 p-6 border-2 border-orange-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Example 4: Merge Strategies</h3>
        <p class="text-sm text-gray-600 mb-4">Different ways to merge backend responses</p>

        <div class="space-y-4">
          <button
            data-on:click="@post('/requests/append_item')"
            class="px-4 py-2 bg-blue-500 text-white rounded">
            Append Item
          </button>
          <div id="items" class="p-4 bg-gray-50 rounded space-y-2" data-merge="append">
            <div class="text-sm text-gray-500">Items will be appended here</div>
          </div>
        </div>
      </div>

      <div class="mb-8 p-6 border-2 border-orange-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Example 5: Error Handling</h3>
        <p class="text-sm text-gray-600 mb-4">Handle backend errors gracefully</p>

        <button
          data-on:click="@post('/requests/might_fail')"
          class="px-4 py-2 bg-red-500 text-white rounded">
          Try Request
        </button>
        <div id="error_area" class="mt-4 p-4 bg-gray-50 rounded">Response will appear here</div>
      </div>

      <div class="p-6 bg-gradient-to-r from-orange-50 to-blue-50 rounded-lg">
        <h3 class="text-xl font-bold text-gray-800 mb-3">Summary</h3>
        <ul class="space-y-2 text-sm text-gray-700">
          <li>@get(url) - Fetch data from backend</li>
          <li>@post(url, data) - Send data to backend</li>
          <li>Send signals to backend in request body</li>
          <li>Backend returns HTML that replaces matching elements by id</li>
          <li>Merge strategies control how responses are applied</li>
          <li>Use data-on:click to trigger requests</li>
          <li>Responses update DOM via morphing</li>
        </ul>
      </div>
    </div>
    """
  end

  def fetch_message(_params) do
    assigns = %{}
    ~H"""
    <div id="message" class="p-4 bg-green-50 rounded">
      <p class="text-green-800">Message from backend: Hello from the server!</p>
    </div>
    """
  end

  def process(_params) do
    assigns = %{}
    ~H"""
    <div id="result" class="p-4 bg-blue-50 rounded">
      <p class="text-blue-800">Processed successfully!</p>
    </div>
    """
  end

  def save_count(_params) do
    assigns = %{}
    ~H"""
    <div id="save_status" class="p-4 bg-green-50 rounded">
      <p class="text-green-800">Count saved to backend!</p>
    </div>
    """
  end

  def append_item(_params) do
    assigns = %{}
    ~H"""
    <div id="items" data-merge="append">
      <div class="text-sm text-blue-600">Item appended at <%= DateTime.utc_now() |> DateTime.to_string() %></div>
    </div>
    """
  end

  def might_fail(_params) do
    assigns = %{}
    ~H"""
    <div id="error_area" class="p-4 bg-green-50 rounded">
      <p class="text-green-800">Request succeeded!</p>
    </div>
    """
  end
end
