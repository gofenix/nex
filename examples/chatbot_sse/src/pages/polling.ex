defmodule ChatbotSse.Pages.Polling do
  @moduledoc """
  Synchronous Chatbot - Traditional request-response pattern.

  Directly waits for AI response in the action handler,
  demonstrating the simplest approach without SSE or async tasks.
  """
  use Nex
  import ChatbotSse.Components.Chat.ChatMessage

  def mount(_params) do
    %{
      title: "Polling Chatbot",
      messages: Nex.Store.get(:polling_chat_messages, [])
    }
  end

  def render(assigns) do
    ~H"""
    <div class="mb-4">
      <a href="/" class="text-gray-400 hover:text-white flex items-center gap-2">
        ← Back to Home
      </a>
    </div>

    <h1 class="text-3xl font-bold text-center text-white mb-2">Synchronous Chatbot</h1>
    <p class="text-center text-gray-400 mb-6 text-sm">Traditional request-response pattern</p>

    <div id="chat-container" class="flex-1 bg-gray-800 rounded-2xl p-4 overflow-y-auto space-y-4 mb-4 h-[500px]">
      <div :if={length(@messages) == 0} class="text-center text-gray-500 py-10">
        <p class="text-lg mb-2">Hello! I'm an AI assistant</p>
        <p class="text-sm">Using synchronous request-response</p>
      </div>
      <.chat_message :for={msg <- @messages} message={msg} />
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
             class="flex-1 input input-bordered bg-gray-700 text-white border-gray-600 focus:border-blue-500" />
      <button type="submit" class="btn bg-blue-500 hover:bg-blue-600 text-white border-0">
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

    Nex.Store.update(:polling_chat_messages, [], &[user_msg | &1])

    # 直接调用 OpenAI API，等待响应
    api_key = Nex.Env.get(:OPENAI_API_KEY)
    base_url = Nex.Env.get(:OPENAI_BASE_URL, "https://api.openai.com/v1")

    response = call_openai(api_key, base_url, user_message)

    ai_msg = %{
      id: msg_id + 1,
      role: :assistant,
      content: response,
      timestamp: format_time()
    }

    Nex.Store.update(:polling_chat_messages, [], &[ai_msg | &1])

    # 返回用户消息和 AI 响应
    assigns = %{user_msg: user_msg, ai_msg: ai_msg}
    ~H"""
    <.chat_message message={@user_msg} />
    <.chat_message message={@ai_msg} />
    """
  end

  defp call_openai(api_key, base_url, user_message) do
    messages = [
      %{
        "role" => "system",
        "content" => "You are a friendly AI assistant, please reply in concise English."
      },
      %{
        "role" => "user",
        "content" => user_message
      }
    ]

    body = %{
      "model" => "gpt-3.5-turbo",
      "messages" => messages
    }

    base_url = String.trim_trailing(base_url, "/")
    url = "#{base_url}/chat/completions"

    case Req.post(url, json: body, auth: {:bearer, api_key}) do
      {:ok, %{status: 200, body: %{"choices" => [%{"message" => %{"content" => content}} | _]}}} ->
        content

      {:ok, %{status: status}} ->
        "Request failed (HTTP #{status})"

      {:error, reason} ->
        "Request failed: #{inspect(reason)}"
    end
  end

  defp format_time do
    {{year, month, day}, {hour, minute, _}} = :erlang.localtime()
    "#{year}-#{pad(month)}-#{pad(day)} #{pad(hour)}:#{pad(minute)}"
  end

  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n), do: "#{n}"
end
