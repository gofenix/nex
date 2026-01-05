defmodule ChatbotSse.Pages.DatastarAi do
  @moduledoc """
  AI Chatbot using Datastar integration.
  
  Demonstrates zero-JS tool calling and signal syncing with premium UI.
  """
  use Nex

  def mount(_params) do
    %{
      title: "Datastar AI Sync",
      aiResponse: "",
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
           messages: @messages, 
           input: @input, 
           aiResponse: @aiResponse, 
           aiStatus: @aiStatus,
           isLoading: @isLoading
         })}
         x-data="{}"
         x-init="
           $watch('$messages', () => {
             $nextTick(() => { const b = document.getElementById('messages-box'); b.scrollTop = b.scrollHeight; });
           });
         ">
      
      <header class="flex items-center justify-between mb-8 shrink-0">
        <div class="flex items-center gap-4">
          <a href="/" class="w-10 h-10 flex items-center justify-center rounded-xl bg-white/5 border border-white/10 hover:bg-white/10 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z" clip-rule="evenodd" />
            </svg>
          </a>
          <div>
            <h1 class="text-xl font-bold text-white">Datastar AI</h1>
            <p class="text-xs text-gray-500 font-medium tracking-wider uppercase">Zero-JS Signal Syncing</p>
          </div>
        </div>
        <div class="px-3 py-1 rounded-full bg-purple-500/10 border border-purple-500/20 text-purple-400 text-[10px] font-bold uppercase tracking-tighter">
          Hypermedia Flow
        </div>
      </header>
      
      <!-- Messages Viewport -->
      <div class="flex-1 overflow-y-auto pr-2 mb-6 space-y-6 scrollbar-hide" id="messages-box">
        <template x-if="$messages.length === 0 && !$aiResponse">
          <div class="h-full flex flex-col items-center justify-center text-center opacity-40 py-20">
            <div class="w-16 h-16 rounded-3xl bg-white/5 border border-white/10 flex items-center justify-center text-3xl mb-6">✨</div>
            <h3 class="text-lg font-bold text-white mb-2">Datastar AI Sync</h3>
            <p class="max-w-xs text-sm">Experience seamless state synchronization without writing a single line of client-side JavaScript.</p>
          </div>
        </template>

        <template x-for="msg in $messages">
          <div class="flex w-full gap-x-3" x-bind:class="msg.role === 'user' ? 'flex-row-reverse' : ''">
            <div class="flex-shrink-0">
              <div class="w-9 h-9 rounded-xl flex items-center justify-center font-bold text-sm shadow-lg border border-white/10"
                   x-bind:class="msg.role === 'user' ? 'bg-primary-600 text-white' : 'bg-[#1f2937] text-emerald-400'">
                <span x-text="msg.role === 'user' ? 'U' : 'AI'"></span>
              </div>
            </div>
            <div class="chat-bubble flex flex-col" x-bind:class="msg.role === 'user' ? 'items-end' : 'items-start'">
              <div class="px-4 py-2.5 rounded-2xl text-[15px] leading-relaxed shadow-sm border"
                   x-bind:class="msg.role === 'user' ? 'bg-primary-600 border-primary-500 text-white rounded-tr-none' : 'bg-[#1f2937] border-gray-700 text-gray-200 rounded-tl-none'">
                <p class="whitespace-pre-wrap text-left" x-text="msg.content"></p>
              </div>
            </div>
          </div>
        </template>
        
        <!-- Live AI Response (Datastar Signal) -->
        <div data-show="$aiResponse" class="flex w-full gap-x-3 items-start">
          <div class="flex-shrink-0">
            <div class="w-9 h-9 rounded-xl flex items-center justify-center font-bold text-sm shadow-lg border border-white/10 bg-[#1f2937] text-emerald-400">
              AI
            </div>
          </div>
          <div class="chat-bubble flex flex-col items-start">
            <div class="px-4 py-2.5 rounded-2xl rounded-tl-none text-[15px] leading-relaxed shadow-sm border bg-[#1f2937] border-gray-700 text-gray-200">
              <p class="whitespace-pre-wrap text-left" data-text="$aiResponse"></p>
            </div>
            <div class="flex items-center mt-2 px-1 space-x-2 text-primary-400 animate-pulse">
              <span class="text-[10px] uppercase font-bold tracking-widest" data-text="$aiStatus"></span>
            </div>
          </div>
        </div>
      </div>

      <!-- Input Form -->
      <div class="shrink-0 relative">
        <form data-on:submit.prevent="@post('/api/datastar/chat'); $input = ''; $isLoading = true; $aiResponse = '';" class="relative group">
          <div class="absolute -inset-1 bg-gradient-to-r from-purple-500/20 to-primary-500/20 rounded-[26px] blur opacity-0 group-focus-within:opacity-100 transition duration-500"></div>
          <input 
            data-bind:input 
            data-attr:disabled="$isLoading"
            class="relative w-full bg-[#161b22] text-white border border-white/10 rounded-[22px] px-6 py-4 pr-16 focus:border-purple-500 focus:outline-none transition-all disabled:opacity-50 shadow-2xl placeholder-gray-600"
            placeholder="Ask about the weather..."
            autocomplete="off">
          <button 
            type="submit" 
            data-attr:disabled="$isLoading || !$input.trim()"
            class="absolute right-3 top-3 bg-purple-600 hover:bg-purple-500 disabled:bg-gray-800 disabled:text-gray-600 text-white w-11 h-11 flex items-center justify-center rounded-xl transition-all shadow-lg active:scale-95">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path d="M10.894 2.553a1 1 0 00-1.788 0l-7 14a1 1 0 001.169 1.409l5-1.429A1 1 0 009 15.571V11a1 1 0 112 0v4.571a1 1 0 00.725.962l5 1.428a1 1 0 001.17-1.408l-7-14z" />
            </svg>
          </button>
        </form>
        <p class="text-[10px] text-center text-gray-600 mt-4 tracking-tight uppercase font-medium">
          Real-time Signal Sync powered by Nex & Datastar
        </p>
      </div>
    </div>
    """
  end
end
