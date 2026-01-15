defmodule Bestofex.Pages.Index do
  use Nex

  def mount(_params) do
    %{
      title: "Welcome to Bestofex",
      count: Nex.Store.get(:count, 0)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-8 max-w-2xl mx-auto">
      <div class="text-center py-12 bg-base-100 rounded-3xl shadow-sm border border-base-300">
        <h1 class="text-5xl font-black mb-4 tracking-tight text-primary">Nex + HTMX</h1>
        <p class="text-lg text-base-content/60 mb-8">
          The simplest way to build modern web apps with Elixir.
        </p>

        <div class="flex flex-col items-center gap-4">
          <div id="counter-display" class="stat place-items-center bg-base-200 rounded-xl w-48 py-4 border border-base-300">
            <div class="stat-title text-base-content/50 uppercase tracking-widest text-xs font-bold">Current Count</div>
            <div class="stat-value text-4xl font-mono tracking-tighter">{@count}</div>
          </div>

          <div class="flex gap-2">
            <button
              class="btn btn-primary btn-lg shadow-lg"
              hx-post="/increment"
              hx-target="#counter-display"
              hx-indicator="#loading-spinner"
            >
              Increment
            </button>

            <button
              class="btn btn-ghost btn-lg"
              hx-post="/reset"
              hx-target="#counter-display"
            >
              Reset
            </button>
          </div>

          <div id="loading-spinner" class="htmx-indicator">
            <span class="loading loading-spinner loading-sm text-primary"></span>
          </div>
        </div>
      </div>

      <div class="grid md:grid-cols-2 gap-6">
        <Bestofex.Components.Card.card title="📁 Folder Routing" icon="⚡️">
          No router files. Just create a file in <code>src/pages/</code>.
        </Bestofex.Components.Card.card>

        <Bestofex.Components.Card.card title="🧩 UI Components" icon="📦">
          Composable components with slots. See <code>src/components/</code>.
        </Bestofex.Components.Card.card>
      </div>

      <div class="alert alert-info shadow-sm border-none bg-blue-50 text-blue-800">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-6 h-6"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
        <span>Check <code>AGENTS.md</code> to see how to pair Nex with AI agents.</span>
      </div>
    </div>
    """
  end

  # --- Actions (Intent-Driven) ---

  def increment(_params) do
    # 1. Update Truth
    new_count = Nex.Store.update(:count, 0, &(&1 + 1))

    # 2. Render surgical update
    assigns = %{count: new_count}
    ~H"""
    <div class="stat-title text-base-content/50 uppercase tracking-widest text-xs font-bold">Current Count</div>
    <div class="stat-value text-4xl font-mono tracking-tighter text-primary animate-bounce-short">{@count}</div>
    """
  end

  def reset(_params) do
    Nex.Store.put(:count, 0)

    assigns = %{count: 0}
    ~H"""
    <div class="stat-title text-base-content/50 uppercase tracking-widest text-xs font-bold">Current Count</div>
    <div class="stat-value text-4xl font-mono tracking-tighter">{@count}</div>
    """
  end
end
