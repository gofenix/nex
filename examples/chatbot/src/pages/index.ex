defmodule Chatbot.Pages.Index do
  use Nex.Page
  import Chatbot.Partials.Chat.ChatMessage

  def mount(_params) do
    %{
      title: "AI Chatbot",
      messages: Nex.Store.get(:chat_messages, []),
      loading: false
    }
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-3xl font-bold text-center text-white mb-6">AI Chatbot</h1>

    <div id="chat-container"
         class="flex-1 bg-gray-800 rounded-2xl p-4 overflow-y-auto space-y-4 mb-4"
         hx-ext="ws"
         ws-connect="/ws/chat">
      <div :if={length(@messages) == 0} class="text-center text-gray-500 py-10">
        <p class="text-lg mb-2">你好！我是 AI 助手</p>
        <p class="text-sm">有什么可以帮助你的吗？</p>
      </div>
      <.chat_message :for={msg <- @messages} message={msg} />
      <div :if={@loading} id="loading-indicator">
        <.loading_indicator />
      </div>
    </div>

    <form hx-post="/chat"
          hx-target="#chat-container"
          hx-swap="beforeend"
          hx-on::before-request="document.getElementById('loading-indicator')?.remove()"
          hx-on::htmx:after-request="this.reset(); setTimeout(() => document.getElementById('chat-container').scrollTop = document.getElementById('chat-container').scrollHeight, 100)"
          class="flex gap-3">
      <input type="text"
             name="message"
             placeholder="输入消息..."
             required
             class="flex-1 input input-bordered bg-gray-700 text-white border-gray-600 focus:border-emerald-500" />
      <button type="submit"
              class="btn btn-emerald">
        发送
      </button>
    </form>
    """
  end

  def chat(%{"message" => user_message} = _params) do
    user_msg = %{
      role: :user,
      content: user_message,
      timestamp: format_time()
    }

    Nex.Store.update(:chat_messages, [], &[user_msg | &1])

    # Get AI response from OpenAI
    ai_response = get_ai_response(user_message)

    ai_msg = %{
      role: :assistant,
      content: ai_response,
      timestamp: format_time()
    }

    Nex.Store.update(:chat_messages, [], &[ai_msg | &1])

    # Return the new messages as HEEx fragment
    assigns = %{user_msg: user_msg, ai_msg: ai_msg}
    ~H"<div><.chat_message message={@user_msg} /><.chat_message message={@ai_msg} /></div>"
  end

  defp get_ai_response(user_message) do
    api_key = Nex.Env.get(:OPENAI_API_KEY)
    base_url = Nex.Env.get(:OPENAI_BASE_URL, "https://api.openai.com/v1")

    IO.puts("[DEBUG] OPENAI_API_KEY: #{inspect(api_key)}")
    IO.puts("[DEBUG] OPENAI_BASE_URL: #{inspect(base_url)}")

    if api_key == nil or api_key == "" do
      IO.puts("[DEBUG] Using simulated AI response")
      simulate_ai_response(user_message)
    else
      IO.puts("[DEBUG] Calling OpenAI API")
      call_openai(api_key, base_url, user_message)
    end
  end

  defp call_openai(api_key, base_url, user_message) do
    messages = [
      %{
        "role" => "system",
        "content" => "你是一个友好的AI助手，请用简洁的中文回复。"
      },
      %{
        "role" => "user",
        "content" => user_message
      }
    ]

    body = Jason.encode!(%{
      "model" => "gpt-3.5-turbo",
      "messages" => messages
    })

    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{api_key}"}
    ]

    url = "#{base_url}/chat/completions"

    case :hackney.post(url, headers, body, []) do
      {:ok, 200, _headers, body_ref} ->
        {:ok, body} = :hackney.body(body_ref)
        Jason.decode!(body)["choices"] |> List.first() |> get_in(["message", "content"])

      {:ok, status, _headers, _body_ref} ->
        "请求失败 (HTTP #{status})"

      {:error, reason} ->
        "请求失败: #{inspect(reason)}"
    end
  end

  defp simulate_ai_response(user_input) do
    input = String.downcase(user_input)

    cond do
      String.contains?(input, "你好") ->
        "你好！很高兴见到你。有什么我可以帮助你的吗？"

      String.contains?(input, "名字") ->
        "我是 Nex 框架演示的 AI 聊天机器人，使用 Elixir 和 HTMX 构建。"

      String.contains?(input, "天气") ->
        "抱歉，我无法获取实时天气信息。但你可以问我其他问题！"

      String.contains?(input, "你是谁") or String.contains?(input, "是什么") ->
        "我是一个简单的 AI 聊天机器人演示。Nex 是一个极简的 Elixir HTMX 框架，让服务器端渲染变得简单。"

      String.contains?(input, "帮助") or String.contains?(input, "功能") ->
        "我可以：\n- 回答简单问题\n- 陪你聊天\n- 介绍 Nex 框架\n\n试着问我更多问题吧！"

      true ->
        "这是一个模拟回复。在实际应用中，你可以接入 OpenAI API 来获得真正的 AI 能力。"
    end
  end

  defp format_time do
    {{year, month, day}, {hour, minute, _}} = :erlang.localtime()
    "#{year}-#{pad(month)}-#{pad(day)} #{pad(hour)}:#{pad(minute)}"
  end

  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n), do: "#{n}"
end
