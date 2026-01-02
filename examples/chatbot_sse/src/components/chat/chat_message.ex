defmodule ChatbotSse.Components.Chat.ChatMessage do
  use Nex

  def chat_message(assigns) do
    assigns = Map.put(assigns, :is_user, assigns.message.role == :user)

    ~H"""
    <div class={"flex gap-3 #{if @is_user, do: "flex-row-reverse"}"}>
      <div class={if @is_user, do: "avatar placeholder", else: ""}>
        <div class={if @is_user, do: "bg-blue-500 text-white rounded-full w-10", else: "bg-emerald-500 text-white rounded-full w-10"}>
          <span class="text-sm">{if @is_user, do: "U", else: "AI"}</span>
        </div>
      </div>
      <div class={if @is_user, do: "chat-message-user", else: "chat-message-ai"}>
        <div class={if @is_user, do: "bg-blue-600 text-white", else: "bg-gray-700 text-gray-100"}>
          <p class="whitespace-pre-wrap">{@message.content}</p>
        </div>
        <span class="text-xs text-gray-500 mt-1 block">
          {@message.timestamp}
        </span>
      </div>
    </div>
    """
  end
end
