defmodule ChatbotSse.Pages.Index do
  @moduledoc """
  Chatbot Demo Home - Modern UI with premium card design.
  """
  use Nex

  def mount(_params) do
    %{title: "Nex.AI Ecosystem"}
  end

  def render(assigns) do
    ~H"""
    <div class="flex-1 flex flex-col items-center justify-center px-6 py-12">
      <div class="w-full max-w-5xl">
        <header class="text-center mb-16">
          <div class="inline-flex items-center px-3 py-1 rounded-full bg-primary-500/10 border border-primary-500/20 text-primary-400 text-xs font-bold tracking-widest uppercase mb-4">
            Next-Gen Framework
          </div>
          <h1 class="text-5xl md:text-6xl font-extrabold text-white mb-6 tracking-tight">
            Nex.<span class="text-primary-500">AI</span> Ecosystem
          </h1>
          <p class="text-lg text-gray-400 max-w-2xl mx-auto leading-relaxed">
            Experience the most powerful AI integration patterns for Elixir. 
            From zero-JS streaming to manual human-in-the-loop tool approval.
          </p>
        </header>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <!-- SSE Streaming Mode -->
          <.card href="/sse" 
                 title="AI SDK v6" 
                 desc="Vercel Data Stream Protocol port. Real-time streaming with Alpine.js client parsing."
                 icon="⚡"
                 color="emerald" />

          <!-- Datastar AI Mode -->
          <.card href="/datastar_ai" 
                 title="Datastar AI" 
                 desc="Hypermedia streaming with Datastar Signals. Zero client-side JS logic, pure signal syncing."
                 icon="✨"
                 color="purple" />

          <!-- Interactive Mode -->
          <.card href="/interactive" 
                 title="Interactive" 
                 desc="Human-in-the-loop pattern. Manually approve or reject AI tool calls before execution."
                 icon="✋"
                 color="yellow" />

          <!-- Classic Mode -->
          <.card href="/polling" 
                 title="Classic Sync" 
                 desc="Traditional request-response pattern. Simple, reliable, and straightforward."
                 icon="⏳"
                 color="blue" />

          <!-- Raw API Mode -->
          <.card href="/raw" 
                 title="Raw API" 
                 desc="Zero abstractions. Direct Req.post calls to the API. Pure Elixir, zero magic."
                 icon="🔗"
                 color="orange" />
        </div>

        <footer class="mt-20 text-center border-t border-white/5 pt-10">
          <p class="text-gray-500 text-sm italic">
            💡 All modes utilize your <code>OPENAI_API_KEY</code> for authentic AI interactions.
          </p>
        </footer>
      </div>
    </div>
    """
  end

  defp card(assigns) do
    ~H"""
    <a href={@href} class="group block relative h-full">
      <div class="absolute -inset-0.5 bg-gradient-to-r from-primary-500 to-emerald-500 rounded-2xl blur opacity-0 group-hover:opacity-20 transition duration-500"></div>
      <div class="relative h-full bg-[#161b22] border border-white/5 rounded-2xl p-8 hover:border-white/10 transition-all duration-300 flex flex-col">
        <div class={"w-12 h-12 rounded-xl bg-#{@color}-500/10 border border-#{@color}-500/20 flex items-center justify-center text-2xl mb-6 group-hover:scale-110 transition-transform duration-300"}>
          {@icon}
        </div>
        <h2 class="text-xl font-bold text-white mb-3 group-hover:text-primary-400 transition-colors">{@title}</h2>
        <p class="text-gray-400 text-sm leading-relaxed flex-1">{@desc}</p>
        <div class="mt-6 flex items-center text-primary-500 text-sm font-bold opacity-0 group-hover:opacity-100 transition-all duration-300 transform translate-x-[-10px] group-hover:translate-x-0">
          Explore Mode <span class="ml-2">→</span>
        </div>
      </div>
    </a>
    """
  end
end
