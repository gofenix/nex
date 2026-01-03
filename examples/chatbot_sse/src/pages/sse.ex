defmodule ChatbotSse.Pages.Sse do
  @moduledoc """
  SSE Stream Chatbot - Real-time streaming AI responses.

  Uses Server-Sent Events (SSE) instead of HTMX polling
  to stream AI responses character by character.
  """
  use Nex
  import ChatbotSse.Components.Chat.ChatMessage

  def mount(_params) do
    %{
      title: "SSE Chatbot",
      messages: Nex.Store.get(:sse_chat_messages, [])
    }
  end

  def render(assigns) do
    ~H"""
    <div class="mb-4">
      <a href="/" class="text-gray-400 hover:text-white flex items-center gap-2">
        ← Back to Home
      </a>
    </div>

    <h1 class="text-3xl font-bold text-center text-white mb-2">SSE Streaming Chatbot</h1>
    <p class="text-center text-gray-400 mb-6 text-sm">Using Server-Sent Events for real-time streaming</p>

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

    Nex.Store.update(:sse_chat_messages, [], &[user_msg | &1])

    # Store the pending message for SSE to pick up
    # Use ETS directly since SSE is a different request with different page_id
    current_page_id = Nex.Store.get_page_id()
    :ets.insert(:chatbot_sse_pending, {msg_id, %{
      msg_id: msg_id,
      message: user_message,
      page_id: current_page_id
    }})

    sse_url = "/api/sse/stream?msg_id=#{msg_id}&_page_id=#{current_page_id}"
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
             sse-swap="message"
             sse-close="close"
             hx-on:htmx:sse-close="
               const content = this.textContent.trim();
               if (content && content !== '...') {
                 htmx.ajax('POST', '/save_ai_response', {
                   values: {msg_id: #{@msg_id}, content: content}
                 });
               }
             ">
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

  def save_ai_response(%{"msg_id" => msg_id_str, "content" => content} = _params) do
    msg_id = String.to_integer(msg_id_str)
    timestamp = format_time()

    ai_msg = %{
      id: msg_id,
      role: :assistant,
      content: content,
      timestamp: timestamp
    }

    Nex.Store.update(:sse_chat_messages, [], &[ai_msg | &1])

    # Return empty HTML response
    Nex.html("")
  end

  defp format_time do
    {{year, month, day}, {hour, minute, _}} = :erlang.localtime()
    "#{year}-#{pad(month)}-#{pad(day)} #{pad(hour)}:#{pad(minute)}"
  end

  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n), do: "#{n}"
end
