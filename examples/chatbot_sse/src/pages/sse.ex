defmodule ChatbotSse.Pages.Sse do
  @moduledoc """
  SSE Chatbot - Nex.AI (Vercel AI SDK Port) Implementation.
  
  This page demonstrates a pixel-perfect port of the Vercel AI SDK v6 
  using Alpine.js as the client-side state manager and protocol parser.
  """
  use Nex

  def mount(_params) do
    %{
      title: "AI SDK v6 Protocol"
    }
  end

  def render(assigns) do
    ~H"""
    <div class="flex-1 flex flex-col max-w-4xl mx-auto w-full py-8 px-4 overflow-hidden" x-data="chat()">
      <header class="flex items-center justify-between mb-8 shrink-0">
        <div class="flex items-center gap-4">
          <a href="/" class="w-10 h-10 flex items-center justify-center rounded-xl bg-white/5 border border-white/10 hover:bg-white/10 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z" clip-rule="evenodd" />
            </svg>
          </a>
          <div>
            <h1 class="text-xl font-bold text-white">AI SDK v6 Port</h1>
            <p class="text-xs text-gray-500 font-medium tracking-wider uppercase">Vercel Data Stream Protocol</p>
          </div>
        </div>
        <div class="px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-[10px] font-bold uppercase tracking-tighter">
          Live Streaming
        </div>
      </header>
      
      <!-- Messages Viewport -->
      <div class="flex-1 overflow-y-auto pr-2 mb-6 space-y-6 scrollbar-hide" id="messages-box">
        <template x-if="messages.length === 0">
          <div class="h-full flex flex-col items-center justify-center text-center opacity-40 py-20">
            <div class="w-16 h-16 rounded-3xl bg-white/5 border border-white/10 flex items-center justify-center text-3xl mb-6">⚡</div>
            <h3 class="text-lg font-bold text-white mb-2">Nex.AI Protocol Test</h3>
            <p class="max-w-xs text-sm">Start a conversation to see the Vercel Data Stream Protocol in action.</p>
          </div>
        </template>

        <template x-for="(msg, index) in messages" x-bind:key="index">
          <div class="flex w-full gap-x-3" x-bind:class="msg.role === 'user' ? 'flex-row-reverse' : ''">
            <div class="flex-shrink-0">
              <div class="w-9 h-9 rounded-xl flex items-center justify-center font-bold text-sm shadow-lg border border-white/10"
                   x-bind:class="msg.role === 'user' ? 'bg-primary-600 text-white' : 'bg-[#1f2937] text-emerald-400'">
                <span x-text="msg.role === 'user' ? 'U' : 'AI'"></span>
              </div>
            </div>
            <div class="chat-bubble flex flex-col" x-bind:class="msg.role === 'user' ? 'items-end' : 'items-start'">
              <div class="px-4 py-2.5 rounded-2xl text-[15px] leading-relaxed shadow-sm border transition-all duration-300"
                   x-bind:class="msg.role === 'user' ? 'bg-primary-600 border-primary-500 text-white rounded-tr-none' : 'bg-[#1f2937] border-gray-700 text-gray-200 rounded-tl-none'">
                <p class="whitespace-pre-wrap text-left" x-text="msg.content"></p>
                
                <!-- Tool Call Indicators -->
                <template x-if="msg.toolCalls && msg.role === 'assistant'">
                  <div class="mt-3 pt-3 border-t border-white/5 space-y-2">
                    <template x-for="tc in msg.toolCalls">
                      <div class="flex items-center gap-2 text-[11px] font-mono text-emerald-400 bg-black/20 px-2 py-1 rounded">
                        <span class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                        <span x-text="'Calling ' + tc.function.name + '...'"></span>
                      </div>
                    </template>
                  </div>
                </template>
              </div>
            </div>
          </div>
        </template>

        <div x-show="isLoading && !isStreaming" class="flex gap-3">
          <div class="bg-[#1f2937] text-emerald-400 border border-white/10 rounded-xl w-9 h-9 flex items-center justify-center font-bold text-sm">AI</div>
          <div class="bg-[#1f2937] border border-gray-700 px-4 py-2.5 rounded-2xl rounded-tl-none flex items-center h-10">
            <span class="inline-flex gap-1.5">
              <span class="animate-bounce w-1.5 h-1.5 bg-gray-500 rounded-full"></span>
              <span class="animate-bounce w-1.5 h-1.5 bg-gray-500 rounded-full" style="animation-delay: 0.1s"></span>
              <span class="animate-bounce w-1.5 h-1.5 bg-gray-500 rounded-full" style="animation-delay: 0.2s"></span>
            </span>
          </div>
        </div>
      </div>

      <!-- Input Form -->
      <div class="shrink-0 relative">
        <form @submit.prevent="handleSubmit" class="relative group">
          <div class="absolute -inset-1 bg-gradient-to-r from-primary-500/20 to-emerald-500/20 rounded-[26px] blur opacity-0 group-focus-within:opacity-100 transition duration-500"></div>
          <input 
            x-model="input" 
            x-bind:disabled="isLoading"
            class="relative w-full bg-[#161b22] text-white border border-white/10 rounded-[22px] px-6 py-4 pr-16 focus:border-primary-500 focus:outline-none transition-all disabled:opacity-50 shadow-2xl placeholder-gray-600"
            placeholder="Type a message (e.g. 'Check weather in London')"
            autocomplete="off">
          <button 
            type="submit" 
            x-bind:disabled="isLoading || !input.trim()"
            class="absolute right-3 top-3 bg-primary-600 hover:bg-primary-500 disabled:bg-gray-800 disabled:text-gray-600 text-white w-11 h-11 flex items-center justify-center rounded-xl transition-all shadow-lg active:scale-95">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path d="M10.894 2.553a1 1 0 00-1.788 0l-7 14a1 1 0 001.169 1.409l5-1.429A1 1 0 009 15.571V11a1 1 0 112 0v4.571a1 1 0 00.725.962l5 1.428a1 1 0 001.17-1.408l-7-14z" />
            </svg>
          </button>
        </form>
        <p class="text-[10px] text-center text-gray-600 mt-4 tracking-tight uppercase font-medium">
          Powered by Nex.AI Data Stream Protocol v6
        </p>
      </div>
    </div>

    <script>
      function chat() {
        return {
          messages: [],
          input: '',
          isLoading: false,
          isStreaming: false,

          async handleSubmit() {
            if (!this.input.trim()) return;
            
            const userContent = this.input;
            this.input = '';
            this.messages.push({ role: 'user', content: userContent });
            this.isLoading = true;
            this.isStreaming = false;

            this.$nextTick(() => this.scrollToBottom());

            try {
              const url = new URL('/api/sse/stream', window.location.origin);
              url.searchParams.set('message', userContent);
              url.searchParams.set('msg_id', Date.now());
              
              const response = await fetch(url);
              if (!response.ok) throw new Error('Network response was not ok');

              const reader = response.body.getReader();
              const decoder = new TextDecoder();
              
              // New AI message placeholder
              this.messages.push({ role: 'assistant', content: '', toolCalls: [] });
              const aiMsgIndex = this.messages.length - 1;
              this.isStreaming = true;

              let buffer = '';
              while (true) {
                const { done, value } = await reader.read();
                if (done) break;
                
                buffer += decoder.decode(value, { stream: true });
                let lines = buffer.split('\n');
                buffer = lines.pop();

                for (const line of lines) {
                  const trimmed = line.trim();
                  if (!trimmed) continue;

                  const sepIdx = trimmed.indexOf(':');
                  if (sepIdx === -1) continue;

                  const prefix = trimmed.substring(0, sepIdx);
                  const payload = trimmed.substring(sepIdx + 1);

                  try {
                    const data = JSON.parse(payload);
                    switch (prefix) {
                      case '0': // Text
                        this.messages[aiMsgIndex].content += data;
                        break;
                      case '3': // Tool Call
                        this.messages[aiMsgIndex].toolCalls.push(data);
                        break;
                      case '4': // Tool Result
                        // Optionally show results
                        console.log('Tool Result:', data);
                        break;
                      case '2': // Error
                        this.messages[aiMsgIndex].content += "\n[Error: " + data + "]";
                        break;
                    }
                    this.scrollToBottom();
                  } catch (e) {
                    console.error('Protocol parse error:', e, trimmed);
                  }
                }
              }
            } catch (err) {
              console.error('Fetch error:', err);
              this.messages.push({ role: 'assistant', content: "Sorry, I encountered an error: " + err.message });
            } finally {
              this.isLoading = false;
              this.isStreaming = false;
              this.scrollToBottom();
            }
          },

          scrollToBottom() {
            const box = document.getElementById('messages-box');
            if (box) box.scrollTop = box.scrollHeight;
          }
        }
      }
    </script>
    """
  end
end
