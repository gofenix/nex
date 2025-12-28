defmodule ChatbotSse.Pages.Index do
  @moduledoc """
  SSE Stream Chatbot - Real-time streaming AI responses.

  Uses Server-Sent Events (SSE) instead of HTMX polling
  to stream AI responses character by character.
  """
  use Nex.Page
  import ChatbotSse.Partials.Chat.ChatMessage

  def mount(_params) do
    %{
      title: "SSE Chatbot",
      messages: Nex.Store.get(:chat_messages, [])
    }
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-3xl font-bold text-center text-white mb-6">SSE Chatbot</h1>

    <div id="chat-container" class="flex-1 bg-gray-800 rounded-2xl p-4 overflow-y-auto space-y-4 mb-4 h-[500px]">
      <div :if={length(@messages) == 0} class="text-center text-gray-500 py-10">
        <p class="text-lg mb-2">Hello! I'm an AI assistant</p>
        <p class="text-sm">Using SSE streaming responses, real-time content generation display</p>
      </div>
      <.chat_message :for={msg <- Enum.reverse(@messages)} message={msg} />
    </div>

    <form hx-post="/chat"
          hx-target="#chat-container"
          hx-swap="beforeend"
          hx-on::after-request="this.reset()"
          class="flex gap-3">
      <input type="text"
             name="message"
             placeholder="Enter message..."
             required
             class="flex-1 input input-bordered bg-gray-700 text-white border-gray-600 focus:border-emerald-500" />
      <button type="submit" class="btn btn-emerald">
        Send
      </button>
    </form>

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

    Nex.Store.update(:chat_messages, [], &[user_msg | &1])

    current_page_id = Nex.Store.get_page_id()

    sse_url = "/api/sse/stream?message=#{URI.encode_www_form(user_message)}&_page_id=#{current_page_id}"
    assigns = %{user_msg: user_msg, msg_id: msg_id, sse_url: sse_url}
    ~H"""
    <.chat_message message={@user_msg} />
    <div id={"ai-message-#{@msg_id}"} class="flex gap-3">
      <div class="bg-emerald-500 text-white rounded-full w-10 h-10 flex items-center justify-center shrink-0">
        <span class="text-sm">AI</span>
      </div>
      <div class="flex-1">
        <div id={"ai-content-#{@msg_id}"}
             class="bg-gray-700 text-gray-100 px-4 py-3 rounded-2xl whitespace-pre-wrap min-h-[44px]"
             hx-ext="sse"
             sse-connect={@sse_url}
             sse-swap="message">
          <span class="inline-flex gap-1">
            <span class="animate-bounce w-2 h-2 bg-gray-400 rounded-full"></span>
            <span class="animate-bounce w-2 h-2 bg-gray-400 rounded-full" style="animation-delay: 0.1s"></span>
            <span class="animate-bounce w-2 h-2 bg-gray-400 rounded-full" style="animation-delay: 0.2s"></span>
          </span>
        </div>
      </div>
    </div>
    """
  end

  defp format_time do
    {{year, month, day}, {hour, minute, _}} = :erlang.localtime()
    "#{year}-#{pad(month)}-#{pad(day)} #{pad(hour)}:#{pad(minute)}"
  end

  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n), do: "#{n}"
end
