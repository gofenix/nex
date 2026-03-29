defmodule DatastarDemo.Pages.Index do
  use Nex

  def mount(_params) do
    %{title: "Datastar Demo — Nex Framework"}
  end

  def render(assigns) do
    ~H"""
    <div data-testid="datastar-page" class="space-y-10">

      <div class="text-center mb-4">
        <h1 class="text-4xl font-bold mb-2">Nex + Datastar</h1>
        <p class="text-base-content/70">Reactive signals, backend morphing, and SSE streaming</p>
      </div>

      <!-- Section 1: Reactive Signals (client-only) -->
      <section data-testid="datastar-signals-section" class="card bg-base-100 shadow-sm border border-base-300">
        <div class="card-body">
          <h2 class="card-title text-xl mb-4">1. Reactive Signals</h2>
          <p class="text-base-content/60 mb-4">
            Client-side reactivity with <code>data-signals</code>, <code>data-bind</code>, and <code>data-text</code>.
          </p>

          <div data-signals='{ "name": "Nex" }'>
            <div class="form-control w-full max-w-xs mb-3">
              <label class="label"><span class="label-text">Your name</span></label>
              <input
                type="text"
                data-testid="datastar-name-input"
                data-bind:name
                class="input input-bordered w-full max-w-xs"
                placeholder="Type your name..."
              />
            </div>
            <p data-testid="datastar-greeting" class="text-lg">
              Hello, <span class="font-bold text-primary" data-text="$name"></span>!
            </p>
          </div>
        </div>
      </section>

      <!-- Section 2: Backend Morphing -->
      <section data-testid="datastar-morph-section" class="card bg-base-100 shadow-sm border border-base-300">
        <div class="card-body">
          <h2 class="card-title text-xl mb-4">2. Backend Morphing</h2>
          <p class="text-base-content/60 mb-4">
            Send data to the server with <code>@post</code>, receive HTML fragments that morph into the DOM.
          </p>

          <div data-signals='{ "query": "" }'>
            <div class="flex gap-2 mb-4">
              <input
                type="text"
                data-testid="datastar-query-input"
                data-bind:query
                class="input input-bordered flex-1"
                placeholder="Enter text to process..."
              />
              <button
                data-testid="datastar-morph-btn"
                data-on:click="@post('/api/process', {text: $query})"
                class="btn btn-primary"
              >
                Process
              </button>
            </div>
            <div id="result" data-testid="datastar-result" class="p-4 bg-base-200 rounded-lg text-base-content/60">
              Waiting for input...
            </div>
          </div>
        </div>
      </section>

      <!-- Section 3: SSE Streaming -->
      <section data-testid="datastar-stream-section" class="card bg-base-100 shadow-sm border border-base-300">
        <div class="card-body">
          <h2 class="card-title text-xl mb-4">3. SSE Streaming</h2>
          <p class="text-base-content/60 mb-4">
            Real-time updates via Server-Sent Events using the Datastar protocol.
          </p>

          <div data-signals='{ "streamCount": 0 }'>
            <button
              data-testid="datastar-stream-btn"
              data-on:click="@get('/api/stream')"
              class="btn btn-secondary mb-4"
            >
              Start Stream
            </button>

            <div class="flex items-center gap-4 mb-4">
              <span class="text-base-content/60">Events received:</span>
              <span data-testid="datastar-stream-count" class="badge badge-lg badge-primary" data-text="$streamCount">0</span>
            </div>

            <div id="feed" data-testid="datastar-feed" class="space-y-2 p-4 bg-base-200 rounded-lg min-h-[80px]">
              <p class="text-base-content/40 italic">Stream events will appear here...</p>
            </div>
          </div>
        </div>
      </section>

    </div>
    """
  end
end
