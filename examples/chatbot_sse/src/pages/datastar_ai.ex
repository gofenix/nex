defmodule ChatbotSse.Pages.DatastarAi do
  @moduledoc """
  AI Chatbot using Datastar integration.
  
  Demonstrates zero-JS tool calling and signal syncing with premium UI.
  """
  use Nex
  import ChatbotSse.Components.Chat.ChatMessage

  def mount(_params) do
    %{
      title: "Datastar AI Sync",
      aiResponse: "",
      aiReasoning: "",
      aiStatus: "Ready",
      messages: Nex.Store.get(:datastar_chat_history, []),
      input: "",
      isLoading: false
    }
  end

  def render(assigns) do
    ~H"""
    <div class="flex-1 flex flex-col max-w-4xl mx-auto w-full py-8 px-4 overflow-hidden" 
         data-signals={Jason.encode!(%{
           _page_id: @_page_id,
           input: @input, 
           aiResponse: "", 
           aiReasoning: "",
           aiStatus: "Ready",
           isLoading: false,
           messages: @messages
         })}>
      <header class="flex items-center justify-between mb-8 shrink-0">
        <div class="flex items-center gap-4">
          <a href="/" class="w-10 h-10 flex items-center justify-center rounded-xl bg-white/5 border border-white/10 hover:bg-white/10 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z" clip-rule="evenodd" />
            </svg>
          </a>
          <div>
            <h1 class="text-xl font-bold text-white">Datastar AI</h1>
            <p class="text-xs text-gray-500 font-medium tracking-wider uppercase">Zero-JS Hypermedia Stream</p>
          </div>
        </div>
        <div class="px-3 py-1 rounded-full bg-purple-500/10 border border-purple-500/20 text-purple-400 text-[10px] font-bold uppercase tracking-tighter">
          Hypermedia Flow
        </div>
      </header>
      
      <!-- Messages Viewport -->
      <div id="messages-box" class="flex-1 overflow-y-auto pr-2 mb-6 space-y-6 scrollbar-hide">
        <div id="empty-state" data-show="!$aiResponse && !$aiReasoning && $messages.length === 0" class="h-full flex flex-col items-center justify-center text-center opacity-40 py-20">
          <div class="w-16 h-16 rounded-3xl bg-white/5 border border-white/10 flex items-center justify-center text-3xl mb-6">✨</div>
          <h3 class="text-lg font-bold text-white mb-2">Datastar AI Sync</h3>
          <p class="max-w-xs text-sm">Experience seamless state synchronization without writing a single line of client-side JavaScript.</p>
        </div>

        <!-- Render existing messages -->
        <div id="message-list">
          <.chat_message :for={msg <- @messages} message={msg} />
        </div>

        <!-- Streaming Response Area -->
        <div data-show="$aiResponse || $aiReasoning" class="flex w-full gap-x-3 mb-4">
          <div class="flex-shrink-0">
            <div class="w-9 h-9 rounded-xl flex items-center justify-center font-bold text-sm shadow-lg border border-white/10 bg-[#1f2937] text-emerald-400">
              AI
            </div>
          </div>
          <div class="chat-bubble flex-1 flex flex-col items-start">
            <div class="max-w-[85%] px-4 py-2.5 rounded-2xl text-[15px] leading-relaxed shadow-sm border transition-all duration-300 bg-[#1f2937] border-gray-700 text-gray-200 rounded-tl-none">
              
              <div data-show="$aiReasoning" class="mb-3 p-3 bg-white/5 border border-white/10 rounded-xl text-xs text-gray-400 font-serif italic">
                <div class="flex items-center gap-2 mb-2 opacity-60">
                  <span>Thinking...</span>
                </div>
                <p class="whitespace-pre-wrap" data-text="$aiReasoning"></p>
              </div>

              <p class="whitespace-pre-wrap text-left" data-text="$aiResponse"></p>
              
              <div class="flex items-center mt-3 pt-2 border-t border-white/5 space-x-2 text-purple-400">
                <span class="text-[9px] uppercase font-bold tracking-widest opacity-70" data-text="$aiStatus"></span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Input Form -->
      <div class="shrink-0 relative">
        <div class="relative group">
          <div class="absolute -inset-1 bg-gradient-to-r from-purple-500/20 to-primary-500/20 rounded-[26px] blur opacity-0 group-focus-within:opacity-100 transition duration-500"></div>
          <input 
            data-bind:input
            data-attr="{disabled: $isLoading}"
            data-on:keydown.enter="!$isLoading && $input.trim() && ($isLoading=true, @post('/api/datastar/chat'))"
            class="relative w-full bg-[#161b22] text-white border border-white/10 rounded-[22px] px-6 py-4 pr-16 focus:border-purple-500 focus:outline-none transition-all disabled:opacity-50 shadow-2xl placeholder-gray-600"
            placeholder="Ask about the weather..."
            autocomplete="off">
          <button 
            type="button" 
            data-on:click="!$isLoading && $input.trim() && ($isLoading=true, @post('/api/datastar/chat'))"
            data-attr="{disabled: $isLoading || !$input.trim()}"
            class="absolute right-3 top-3 bg-purple-600 hover:bg-purple-500 disabled:bg-gray-800 disabled:text-gray-600 text-white w-11 h-11 flex items-center justify-center rounded-xl transition-all shadow-lg active:scale-95">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path d="M10.894 2.553a1 1 0 00-1.788 0l-7 14a1 1 0 001.169 1.409l5-1.429A1 1 0 009 15.571V11a1 1 0 112 0v4.571a1 1 0 00.725.962l5 1.428a1 1 0 001.17-1.408l-7-14z" />
            </svg>
          </button>
        </div>
        <p class="text-[10px] text-center text-gray-600 mt-4 tracking-tight uppercase font-medium">
          Zero-JS UI Orchestration by NexAI
        </p>
      </div>
    </div>
    """
  end
end
