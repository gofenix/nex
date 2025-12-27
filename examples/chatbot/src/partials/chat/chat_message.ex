defmodule Chatbot.Partials.Chat.ChatMessage do
  use Nex.Partial

  @doc """
  Render a single chat message.

  ## Usage

      alias Chatbot.Partials.Chat.ChatMessage

      <ChatMessage.chat_message message={message} />
  """
  def chat_message(assigns) do
    is_user = @message.role == :user
    ~H"""
    <div class={"flex gap-3 #{if is_user, do: "flex-row-reverse"}"}>
      <div class={if is_user, do: "avatar placeholder", else: ""}>
        <div class={if is_user, do: "bg-blue-500 text-white rounded-full w-10", else: "bg-emerald-500 text-white rounded-full w-10"}>
          <span class="text-sm">{if is_user, do: "U", else: "AI"}</span>
        </div>
      </div>
      <div class={if is_user, do: "chat-message-user", else: "chat-message-ai"}>
        <div class={if is_user, do: "bg-blue-600 text-white", else: "bg-gray-700 text-gray-100"}>
          <p class="whitespace-pre-wrap">{@message.content}</p>
        </div>
        <span class="text-xs text-gray-500 mt-1 block">
          {@message.timestamp}
        </span>
      </div>
    </div>
    """
  end

  @doc """
  Render loading indicator for AI response.
  """
  def loading_indicator(assigns) do
    ~H"""
    <div class="flex gap-3">
      <div class="bg-emerald-500 text-white rounded-full w-10 flex items-center justify-center">
        <span class="text-sm">AI</span>
      </div>
      <div class="chat-message-ai">
        <div class="bg-gray-700 text-gray-400 px-4 py-3 rounded-2xl">
          <span class="inline-flex gap-1">
            <span class="animate-bounce w-2 h-2 bg-gray-400 rounded-full"></span>
            <span class="animate-bounce w-2 h-2 bg-gray-400 rounded-full delay-75"></span>
            <span class="animate-bounce w-2 h-2 bg-gray-400 rounded-full delay-150"></span>
          </span>
        </div>
      </div>
    </div>
    """
  end
end
