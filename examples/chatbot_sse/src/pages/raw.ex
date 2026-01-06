defmodule ChatbotSse.Pages.Raw do
  @moduledoc """
  Raw API Call Mode - Zero SDK.
  
  Demonstrates how to manually call the LLM API using `Req` without any 
  Nex.AI abstractions. This is the most basic way to integrate AI.
  """
  use Nex
  import ChatbotSse.Components.Chat.ChatMessage

  def mount(_params) do
    %{
      title: "Raw API AI",
      messages: Nex.Store.get(:raw_messages, [])
    }
  end

  def render(assigns) do
    ~H"""
    <div class="flex-1 flex flex-col max-w-4xl mx-auto w-full py-8 px-4 overflow-hidden">
      <header class="flex items-center justify-between mb-8 shrink-0">
        <div class="flex items-center gap-4">
          <a href="/" class="w-10 h-10 flex items-center justify-center rounded-xl bg-white/5 border border-white/10 hover:bg-white/10 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z" clip-rule="evenodd" />
            </svg>
          </a>
          <div>
            <h1 class="text-xl font-bold text-white">Raw API</h1>
            <p class="text-xs text-gray-500 font-medium tracking-wider uppercase">Direct Req Implementation</p>
          </div>
        </div>
        <div class="px-3 py-1 rounded-full bg-orange-500/10 border border-orange-500/20 text-orange-400 text-[10px] font-bold uppercase tracking-tighter">
          Zero Abstractions
        </div>
      </header>

      <!-- Messages Viewport -->
      <div id="chat-viewport" 
           class="flex-1 overflow-y-auto pr-2 mb-6 space-y-6 scrollbar-hide"
           hx-on::after-settle="this.scrollTop = this.scrollHeight">
        <div :if={length(@messages) == 0} class="h-full flex flex-col items-center justify-center text-center opacity-40 py-20">
          <div class="w-16 h-16 rounded-3xl bg-white/5 border border-white/10 flex items-center justify-center text-3xl mb-6">🔗</div>
          <h3 class="text-lg font-bold text-white mb-2">Zero SDK Interaction</h3>
          <p class="max-w-xs text-sm">Directly calling the LLM endpoint using <code>Req</code>. No magic, just standard HTTP.</p>
        </div>
        
        <.chat_message :for={msg <- Enum.reverse(@messages)} message={msg} />
      </div>

      <!-- Input Form -->
      <div class="shrink-0 relative">
        <form hx-post="/raw/chat"
              hx-target="#chat-viewport"
              hx-swap="beforeend"
              hx-indicator="#loading-indicator"
              hx-on::after-request="this.reset()"
              class="relative group">
          <div class="absolute -inset-1 bg-gradient-to-r from-orange-500/20 to-red-500/20 rounded-[26px] blur opacity-0 group-focus-within:opacity-100 transition duration-500"></div>
          <input 
            type="text"
            name="message"
            required
            class="relative w-full bg-[#161b22] text-white border border-white/10 rounded-[22px] px-6 py-4 pr-16 focus:border-orange-500 focus:outline-none transition-all disabled:opacity-50 shadow-2xl placeholder-gray-600"
            placeholder="Send a manual request..."
            autocomplete="off">
          <button 
            type="submit" 
            class="absolute right-3 top-3 bg-orange-600 hover:bg-orange-500 text-white w-11 h-11 flex items-center justify-center rounded-xl transition-all shadow-lg active:scale-95">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path d="M10.894 2.553a1 1 0 00-1.788 0l-7 14a1 1 0 001.169 1.409l5-1.429A1 1 0 009 15.571V11a1 1 0 112 0v4.571a1 1 0 00.725.962l5 1.428a1 1 0 001.17-1.408l-7-14z" />
            </svg>
          </button>
        </form>

        <!-- Loading Indicator -->
        <div id="loading-indicator" class="htmx-indicator absolute -top-12 left-0 right-0 flex justify-center">
          <div class="bg-[#1f2937] border border-gray-700 px-4 py-2 rounded-full flex items-center gap-2 shadow-xl">
            <span class="flex gap-1">
              <span class="animate-bounce w-1.5 h-1.5 bg-orange-500 rounded-full"></span>
              <span class="animate-bounce w-1.5 h-1.5 bg-orange-500 rounded-full" style="animation-delay: 0.1s"></span>
              <span class="animate-bounce w-1.5 h-1.5 bg-orange-500 rounded-full" style="animation-delay: 0.2s"></span>
            </span>
            <span class="text-[10px] text-gray-400 font-bold uppercase tracking-widest">Awaiting API</span>
          </div>
        </div>

        <p class="text-[10px] text-center text-gray-600 mt-4 tracking-tight uppercase font-medium">
          Pure Elixir Req.post Implementation
        </p>
      </div>
    </div>
    """
  end

  # --- Actions ---

  def chat(%{"message" => content}) do
    msg_id = System.unique_integer([:positive])
    user_msg = %{id: msg_id, role: :user, content: content, timestamp: format_time()}
    Nex.Store.update(:raw_messages, [], &[user_msg | &1])

    # 1. Manual configuration
    api_key = Nex.Env.get(:OPENAI_API_KEY)
    base_url = Nex.Env.get(:OPENAI_BASE_URL, "https://api.openai.com/v1")
    url = String.trim_trailing(base_url, "/") <> "/chat/completions"

    # 2. Prepare History
    # Get all messages, reverse to chronological order, and map to OpenAI format
    history = Nex.Store.get(:raw_messages, [])
              |> Enum.reverse()
              |> Enum.map(fn m -> 
                %{"role" => to_string(m.role), "content" => m.content} 
              end)

    # 3. Manual Request Construction
    body = %{
      "model" => "gpt-4o",
      "messages" => [
        %{"role" => "system", "content" => "You are a helpful assistant. Reply in concise Chinese."}
        | history
      ]
    }

    # 4. Manual API Call using Req
    response = Req.post(url, 
      json: body, 
      auth: {:bearer, api_key},
      receive_timeout: 30_000
    )

    # 4. Manual Response Parsing
    case response do
      {:ok, %{status: 200, body: %{"choices" => [%{"message" => %{"content" => ai_content}} | _]}}} ->
        ai_msg = %{
          id: System.unique_integer([:positive]), 
          role: :assistant, 
          content: ai_content, 
          timestamp: format_time()
        }
        Nex.Store.update(:raw_messages, [], &[ai_msg | &1])
        
        assigns = %{user_msg: user_msg, ai_msg: ai_msg}
        ~H"""
        <.chat_message message={@user_msg} />
        <.chat_message message={@ai_msg} />
        """

      {:ok, %{status: status, body: error_body}} ->
        Nex.html("<p class='text-red-500'>API Error (HTTP #{status}): #{inspect(error_body)}</p>")

      {:error, reason} ->
        Nex.html("<p class='text-red-500'>Network Error: #{inspect(reason)}</p>")
    end
  end

  # --- Helpers ---

  defp format_time do
    {{year, month, day}, {hour, minute, _}} = :erlang.localtime()
    "#{year}-#{pad(month)}-#{pad(day)} #{pad(hour)}:#{pad(minute)}"
  end

  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n), do: "#{n}"
end
