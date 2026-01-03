defmodule DatastarDemo.Pages.Chat do
  use Nex

  def mount(_params) do
    %{
      title: "SSE Chat - Datastar Demo",
      messages: Nex.Store.get(:messages, [])
    }
  end

  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow p-8 max-w-3xl mx-auto">
      <h2 class="text-3xl font-bold text-gray-800 mb-6">SSE Streaming Chat Demo</h2>

      <div class="mb-6">
        <h3 class="text-lg font-semibold text-gray-700 mb-2">特性 4: SSE 流式响应</h3>
        <p class="text-sm text-gray-600 mb-4">使用 Server-Sent Events 实现 AI 流式响应</p>
      </div>

      <div
        data-signals="{
          message: '',
          isLoading: false
        }"
      >
        <div id="chat-messages" class="bg-gray-50 rounded-lg p-4 h-96 overflow-y-auto mb-4 space-y-3">
          <div :if={length(@messages) == 0} class="text-center text-gray-500 py-10">
            <p class="text-lg mb-2">👋 你好！我是 AI 助手</p>
            <p class="text-sm">发送消息开始对话</p>
          </div>

          <div :for={msg <- Enum.reverse(@messages)} class="flex gap-3">
            <div class={"rounded-full w-10 h-10 flex items-center justify-center shrink-0 #{if msg.role == :user, do: "bg-blue-500", else: "bg-green-500"} text-white"}>
              <span class="text-sm">{if msg.role == :user, do: "You", else: "AI"}</span>
            </div>
            <div class="flex-1">
              <div class={"px-4 py-3 rounded-lg #{if msg.role == :user, do: "bg-blue-100", else: "bg-green-100"}"}>
                {msg.content}
              </div>
              <div class="text-xs text-gray-500 mt-1">{msg.timestamp}</div>
            </div>
          </div>
        </div>

        <form data-on:submit.prevent="@post('/chat/send')" class="flex gap-3">
          <input
            type="text"
            data-bind:message
            placeholder="输入消息..."
            data-attr:disabled="$isLoading"
            class="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
          />
          <button
            type="submit"
            data-attr:disabled="!$message || $isLoading"
            class="px-6 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition disabled:bg-gray-300 disabled:cursor-not-allowed">
            <span data-show="!$isLoading">发送</span>
            <span data-show="$isLoading">发送中...</span>
          </button>
        </form>

        <div class="mt-6 p-4 bg-blue-50 rounded">
          <p class="text-sm text-gray-700">
            <strong>SSE 流式特性：</strong><br>
            • 后端使用 SSE (Server-Sent Events) 逐字推送响应<br>
            • 前端实时显示流式内容，无需轮询<br>
            • 使用信号控制加载状态和输入框禁用<br>
            • 完美适配 AI 聊天场景
          </p>
        </div>
      </div>
    </div>
    """
  end

  def send(req) do
    signals = req.body
    user_message = signals["message"] || ""

    msg_id = System.unique_integer([:positive])
    timestamp = format_time()

    user_msg = %{
      id: msg_id,
      role: :user,
      content: user_message,
      timestamp: timestamp
    }

    Nex.Store.update(:messages, [], &[user_msg | &1])

    sse_url = "/api/chat/stream?msg_id=#{msg_id}"
    assigns = %{user_msg: user_msg, msg_id: msg_id, sse_url: sse_url}

    ~H"""
    <div class="flex gap-3">
      <div class="bg-blue-500 rounded-full w-10 h-10 flex items-center justify-center shrink-0 text-white">
        <span class="text-sm">You</span>
      </div>
      <div class="flex-1">
        <div class="px-4 py-3 rounded-lg bg-blue-100">
          {@user_msg.content}
        </div>
        <div class="text-xs text-gray-500 mt-1">{@user_msg.timestamp}</div>
      </div>
    </div>

    <div id={"ai-message-#{@msg_id}"} class="flex gap-3">
      <div class="bg-green-500 rounded-full w-10 h-10 flex items-center justify-center shrink-0 text-white">
        <span class="text-sm">AI</span>
      </div>
      <div class="flex-1">
        <div
          id={"ai-content-#{@msg_id}"}
          class="px-4 py-3 rounded-lg bg-green-100 min-h-[44px]"
          data-on:load="@get('{@sse_url}')">
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
