defmodule NexAIDemo.Pages.Index do
  use Nex

  def mount(_params) do
    %{
      title: "NexAI Demo",
      messages: [],
      input: "",
      aiResponse: "",
      isLoading: false
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto p-8" data-signals={Jason.encode!(%{messages: @messages, input: @input, aiResponse: @aiResponse, isLoading: @isLoading})}>
      <h1 class="text-3xl font-bold mb-8 text-white">NexAI Chat Demo</h1>
      
      <div class="bg-[#1f2937] rounded-xl p-6 min-h-[400px] mb-6 overflow-y-auto space-y-4 shadow-xl">
        <template x-for="msg in $messages">
          <div x-bind:class="msg.role === 'user' ? 'text-right' : 'text-left'">
            <div x-bind:class="msg.role === 'user' ? 'bg-primary-600' : 'bg-gray-700'" class="inline-block px-4 py-2 rounded-lg text-white max-w-[80%] text-left">
              <p class="whitespace-pre-wrap" x-text="msg.content"></p>
            </div>
          </div>
        </template>
        
        <div data-show="$aiResponse" class="text-left">
          <div class="bg-gray-700 inline-block px-4 py-2 rounded-lg text-emerald-400 max-w-[80%]">
            <p class="whitespace-pre-wrap" data-text="$aiResponse"></p>
          </div>
        </div>
      </div>

      <form data-on:submit.prevent="@post('/api/nex_ai/chat'); $input = ''; $isLoading = true; $aiResponse = '';" class="flex gap-2">
        <input data-bind:input class="flex-1 bg-[#161b22] text-white border border-white/10 rounded-lg px-4 py-2 focus:outline-none focus:border-primary-500" placeholder="Type your message..." autocomplete="off">
        <button type="submit" data-attr:disabled="$isLoading || !$input.trim()" class="bg-primary-600 hover:bg-primary-500 text-white px-6 py-2 rounded-lg transition-colors disabled:opacity-50">
          Send
        </button>
      </form>
    </div>
    """
  end
end
