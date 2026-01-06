defmodule ChatbotSse.Pages.Polling do
  @moduledoc """
  Async Polling Chatbot - Traditional short polling pattern.

  1. User submits request -> Server starts Task, returns "Thinking..."
  2. Client polls /poll status -> Server checks Task status
  3. When done -> Server returns content
  """
  use Nex
  use NexAI
  import ChatbotSse.Components.Chat.ChatMessage
  require Logger

  def mount(_params) do
    %{
      title: "Polling Chatbot",
      messages: Nex.Store.get(:polling_chat_messages, [])
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
            <h1 class="text-xl font-bold text-white">Classic Sync</h1>
            <p class="text-xs text-gray-500 font-medium tracking-wider uppercase">Async Polling Pattern</p>
          </div>
        </div>
        <div class="px-3 py-1 rounded-full bg-blue-500/10 border border-blue-500/20 text-blue-400 text-[10px] font-bold uppercase tracking-tighter">
          Polling
        </div>
      </header>

      <!-- Messages Viewport -->
      <div id="chat-container" 
           class="flex-1 overflow-y-auto pr-2 mb-6 space-y-6 scrollbar-hide"
           hx-on::after-settle="this.scrollTop = this.scrollHeight">
        <div :if={length(@messages) == 0} class="h-full flex flex-col items-center justify-center text-center opacity-40 py-20">
          <div class="w-16 h-16 rounded-3xl bg-white/5 border border-white/10 flex items-center justify-center text-3xl mb-6">⏳</div>
          <h3 class="text-lg font-bold text-white mb-2">Classic Polling</h3>
          <p class="max-w-xs text-sm">Async job processing with client-side polling. Reliable and simple.</p>
        </div>
        <.chat_message :for={msg <- Enum.reverse(@messages)} message={msg} />
      </div>

      <!-- Input Form -->
      <div class="shrink-0 relative">
        <form hx-post="/chat"
              hx-target="#chat-container"
              hx-swap="beforeend"
              hx-on::after-request="this.reset()"
              class="relative group">
          <div class="absolute -inset-1 bg-gradient-to-r from-blue-500/20 to-primary-500/20 rounded-[26px] blur opacity-0 group-focus-within:opacity-100 transition duration-500"></div>
          <input 
            type="text"
            name="message"
            required
            class="relative w-full bg-[#161b22] text-white border border-white/10 rounded-[22px] px-6 py-4 pr-16 focus:border-blue-500 focus:outline-none transition-all disabled:opacity-50 shadow-2xl placeholder-gray-600"
            placeholder="Type a message..."
            autocomplete="off">
          <button 
            type="submit" 
            class="absolute right-3 top-3 bg-blue-600 hover:bg-blue-500 text-white w-11 h-11 flex items-center justify-center rounded-xl transition-all shadow-lg active:scale-95">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path d="M10.894 2.553a1 1 0 00-1.788 0l-7 14a1 1 0 001.169 1.409l5-1.429A1 1 0 009 15.571V11a1 1 0 112 0v4.571a1 1 0 00.725.962l5 1.428a1 1 0 001.17-1.408l-7-14z" />
            </svg>
          </button>
        </form>
        
        <p class="text-[10px] text-center text-gray-600 mt-4 tracking-tight uppercase font-medium">
          Powered by Nex Polling Pattern
        </p>
      </div>
    </div>
    """
  end

  def chat(%{"message" => user_message} = _params) do
    msg_id = System.unique_integer([:positive])
    timestamp = format_time()

    user_msg = %{
      id: msg_id,
      role: :user,
      content: user_message,
      timestamp: timestamp
    }

    Nex.Store.update(:polling_chat_messages, [], &[user_msg | &1])

    # Start Async Job
    page_id = Nex.Store.get_page_id()
    job_id = "job_#{msg_id}"
    
    # Store initial status
    Nex.Store.put(job_id, :processing)
    
    # Run AI generation in background task
    Task.start(fn ->
      # Important: Set page_id in the task process so Store works
      Nex.Store.set_page_id(page_id)
      
      response = case generate_text(
        model: NexAI.openai("gpt-4o"),
        messages: [
          %{role: "system", content: "You are a friendly AI assistant, please reply in concise English."},
          %{role: "user", content: user_message}
        ]
      ) do
        {:ok, %{text: content}} -> {:ok, content}
        {:error, reason} -> {:error, inspect(reason)}
      end
      
      Nex.Store.put(job_id, {:done, response})
    end)

    # Return user message and polling indicator
    assigns = %{user_msg: user_msg, job_id: job_id}
    ~H"""
    <.chat_message message={@user_msg} />
    <div id={"poll-#{@job_id}"} 
         hx-post="/poll" 
         hx-vals={Jason.encode!(%{"job_id" => @job_id})} 
         hx-trigger="load delay:1s" 
         hx-swap="outerHTML">
       <div class="flex items-center gap-3 p-4 rounded-xl bg-white/5 border border-white/10 animate-pulse">
         <div class="w-8 h-8 rounded-full bg-blue-500/20 flex items-center justify-center">
           <div class="w-4 h-4 border-2 border-blue-500 border-t-transparent rounded-full animate-spin"></div>
         </div>
         <span class="text-sm text-gray-400">Thinking...</span>
       </div>
    </div>
    """
  end

  def poll(%{"job_id" => job_id}) do
    case Nex.Store.get(job_id) do
      :processing ->
        assigns = %{job_id: job_id}
        ~H"""
        <div id={"poll-#{@job_id}"} 
             hx-post="/poll" 
             hx-vals={Jason.encode!(%{"job_id" => @job_id})} 
             hx-trigger="load delay:1s" 
             hx-swap="outerHTML">
           <div class="flex items-center gap-3 p-4 rounded-xl bg-white/5 border border-white/10 animate-pulse">
             <div class="w-8 h-8 rounded-full bg-blue-500/20 flex items-center justify-center">
               <div class="w-4 h-4 border-2 border-blue-500 border-t-transparent rounded-full animate-spin"></div>
             </div>
             <span class="text-sm text-gray-400">Thinking...</span>
           </div>
        </div>
        """

      {:done, {:ok, content}} ->
        # Create and store AI message
        msg_id = System.unique_integer([:positive])
        ai_msg = %{
          id: msg_id,
          role: :assistant,
          content: content,
          timestamp: format_time()
        }
        
        Nex.Store.update(:polling_chat_messages, [], &[ai_msg | &1])
        Nex.Store.delete(job_id) # Cleanup job

        assigns = %{ai_msg: ai_msg}
        ~H"""
        <.chat_message message={@ai_msg} />
        """

      {:done, {:error, reason}} ->
        Nex.Store.delete(job_id) # Cleanup
        assigns = %{reason: reason}
        ~H"""
        <div class="p-4 rounded-xl bg-red-500/10 border border-red-500/20 text-red-400 text-sm">
          Error: {@reason}
        </div>
        """

      nil ->
        assigns = %{}
        ~H"""
        <div class="p-4 rounded-xl bg-yellow-500/10 border border-yellow-500/20 text-yellow-400 text-sm">
          Job expired or not found.
        </div>
        """
    end
  end

  defp format_time do
    {{year, month, day}, {hour, minute, _}} = :erlang.localtime()
    "#{year}-#{pad(month)}-#{pad(day)} #{pad(hour)}:#{pad(minute)}"
  end

  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n), do: "#{n}"
end
