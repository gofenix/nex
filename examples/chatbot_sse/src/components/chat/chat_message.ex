defmodule ChatbotSse.Components.Chat.ChatMessage do
  use Nex

  def chat_message(assigns) do
    assigns = Map.put(assigns, :is_user, assigns.message.role == :user)

    ~H"""
    <div class={"flex w-full mb-4 gap-x-3 #{if @is_user, do: "flex-row-reverse"}"}>
      <div class="flex-shrink-0">
        <div class={"w-9 h-9 rounded-xl flex items-center justify-center font-bold text-sm shadow-lg border border-white/10 #{if @is_user, do: "bg-primary-600 text-white", else: "bg-[#1f2937] text-emerald-400"}"}>
          {if @is_user, do: "U", else: "AI"}
        </div>
      </div>
      <div class={"chat-bubble flex flex-col #{if @is_user, do: "items-end", else: "items-start"}"}>
        <div class={"px-4 py-2.5 rounded-2xl text-[15px] leading-relaxed shadow-sm border #{if @is_user, do: "bg-primary-600 border-primary-500 text-white rounded-tr-none", else: "bg-[#1f2937] border-gray-700 text-gray-200 rounded-tl-none"}"}>
          <p class="whitespace-pre-wrap">{@message.content}</p>
        </div>
        <div class="flex items-center mt-1.5 px-1 space-x-2 opacity-40">
          <span class="text-[10px] uppercase font-medium tracking-wider">{@message.timestamp}</span>
        </div>
      </div>
    </div>
    """
  end
end
