defmodule ChatbotSse.Pages.Index do
  @moduledoc """
  Chatbot Demo Home - Choose between SSE streaming or HTMX polling modes.
  """
  use Nex

  def mount(_params) do
    %{
      title: "Chatbot Demo"
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto">
      <h1 class="text-4xl font-bold text-center text-white mb-4">AI Chatbot Demo</h1>
      <p class="text-center text-gray-400 mb-12">Choose your preferred interaction mode</p>

      <div class="grid md:grid-cols-2 gap-6">
        <!-- SSE Streaming Mode -->
        <a href="/sse" class="block group">
          <div class="bg-gray-800 rounded-2xl p-8 border-2 border-emerald-500 hover:border-emerald-400 transition-all hover:shadow-lg hover:shadow-emerald-500/20">
            <div class="flex items-center gap-4 mb-4">
              <div class="bg-emerald-500 text-white rounded-full w-16 h-16 flex items-center justify-center text-2xl">
                ⚡
              </div>
              <div>
                <h2 class="text-2xl font-bold text-white">SSE Streaming</h2>
                <p class="text-emerald-400 text-sm">Real-time character-by-character</p>
              </div>
            </div>
            <p class="text-gray-300 mb-4">
              Experience real-time AI responses with Server-Sent Events (SSE).
              Watch as the AI generates responses character by character, just like ChatGPT.
            </p>
            <ul class="space-y-2 text-sm text-gray-400">
              <li class="flex items-center gap-2">
                <span class="text-emerald-500">✓</span>
                Real-time streaming responses
              </li>
              <li class="flex items-center gap-2">
                <span class="text-emerald-500">✓</span>
                Character-by-character display
              </li>
              <li class="flex items-center gap-2">
                <span class="text-emerald-500">✓</span>
                Better user experience
              </li>
              <li class="flex items-center gap-2">
                <span class="text-emerald-500">✓</span>
                Persistent connection
              </li>
            </ul>
            <div class="mt-6 text-emerald-400 group-hover:text-emerald-300 flex items-center gap-2">
              Try SSE Mode
              <span class="group-hover:translate-x-1 transition-transform">→</span>
            </div>
          </div>
        </a>

        <!-- Synchronous Mode -->
        <a href="/polling" class="block group">
          <div class="bg-gray-800 rounded-2xl p-8 border-2 border-blue-500 hover:border-blue-400 transition-all hover:shadow-lg hover:shadow-blue-500/20">
            <div class="flex items-center gap-4 mb-4">
              <div class="bg-blue-500 text-white rounded-full w-16 h-16 flex items-center justify-center text-2xl">
                ⏳
              </div>
              <div>
                <h2 class="text-2xl font-bold text-white">Synchronous</h2>
                <p class="text-blue-400 text-sm">Traditional request-response</p>
              </div>
            </div>
            <p class="text-gray-300 mb-4">
              Classic synchronous approach where the server waits for the AI response
              before returning. Simple and straightforward implementation.
            </p>
            <ul class="space-y-2 text-sm text-gray-400">
              <li class="flex items-center gap-2">
                <span class="text-blue-500">✓</span>
                Direct wait for response
              </li>
              <li class="flex items-center gap-2">
                <span class="text-blue-500">✓</span>
                Simplest implementation
              </li>
              <li class="flex items-center gap-2">
                <span class="text-blue-500">✓</span>
                Single request-response
              </li>
              <li class="flex items-center gap-2">
                <span class="text-blue-500">✓</span>
                No persistent connection
              </li>
            </ul>
            <div class="mt-6 text-blue-400 group-hover:text-blue-300 flex items-center gap-2">
              Try Synchronous Mode
              <span class="group-hover:translate-x-1 transition-transform">→</span>
            </div>
          </div>
        </a>
      </div>

      <div class="mt-12 p-6 bg-gray-800 rounded-xl border border-gray-700">
        <h3 class="text-lg font-semibold text-white mb-3">📚 What This Demo Shows</h3>
        <ul class="space-y-2 text-gray-300 text-sm">
          <li class="flex items-start gap-2">
            <span class="text-emerald-500 mt-1">•</span>
            <span><strong>Multi-page routing:</strong> Two different chat implementations in the same app</span>
          </li>
          <li class="flex items-start gap-2">
            <span class="text-emerald-500 mt-1">•</span>
            <span><strong>Action resolution:</strong> Each page has its own <code class="bg-gray-700 px-1 rounded">chat</code> action</span>
          </li>
          <li class="flex items-start gap-2">
            <span class="text-emerald-500 mt-1">•</span>
            <span><strong>SSE streaming:</strong> Real-time server-to-client communication</span>
          </li>
          <li class="flex items-start gap-2">
            <span class="text-emerald-500 mt-1">•</span>
            <span><strong>Synchronous mode:</strong> Traditional request-response pattern</span>
          </li>
        </ul>
      </div>

      <div class="mt-6 text-center text-gray-500 text-sm">
        <p>💡 Tip: Both modes require <code class="bg-gray-700 px-2 py-1 rounded">OPENAI_API_KEY</code> in your <code class="bg-gray-700 px-2 py-1 rounded">.env</code> file</p>
      </div>
    </div>
    """
  end
end
