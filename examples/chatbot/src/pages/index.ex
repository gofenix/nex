defmodule Chatbot.Pages.Index do
  use Nex.Page
  import Chatbot.Partials.Chat.ChatMessage

  def mount(_params) do
    %{
      title: "AI Chatbot",
      messages: Nex.Store.get(:chat_messages, [])
    }
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-3xl font-bold text-center text-white mb-6">AI Chatbot</h1>

    <div id="chat-container" class="flex-1 bg-gray-800 rounded-2xl p-4 overflow-y-auto space-y-4 mb-4">
      <div :if={length(@messages) == 0} class="text-center text-gray-500 py-10">
        <p class="text-lg mb-2">你好！我是 AI 助手</p>
        <p class="text-sm">有什么可以帮助你的吗？</p>
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
             placeholder="输入消息..."
             required
             class="flex-1 input input-bordered bg-gray-700 text-white border-gray-600 focus:border-emerald-500" />
      <button type="submit" class="btn btn-emerald">
        发送
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

    # 获取当前 page_id，传递给异步任务
    current_page_id = Nex.Store.get_page_id()

    # 启动异步任务生成 AI 响应
    Task.Supervisor.async_nolink(Chatbot.TaskSupervisor, fn ->
      # 在异步任务中设置 page_id，确保数据存储在同一个隔离空间
      Nex.Store.set_page_id(current_page_id)

      api_key = Nex.Env.get(:OPENAI_API_KEY)
      base_url = Nex.Env.get(:OPENAI_BASE_URL, "https://api.openai.com/v1")

      response = if api_key == nil or api_key == "" do
                    simulate_ai_response(user_message)
                  else
                    call_openai(api_key, base_url, user_message)
                  end

      ai_msg = %{
        id: msg_id + 1,
        role: :assistant,
        content: response,
        parent_id: msg_id,
        timestamp: format_time()
      }

      Nex.Store.update(:chat_messages, [], &[ai_msg | &1])
    end)

    assigns = %{user_msg: user_msg, msg_id: msg_id}
    ~H"""
    <.chat_message message={@user_msg} />
    <div id={"ai-loading-#{@msg_id}"} hx-post="/ai_response" hx-vals={Jason.encode!(%{id: @msg_id})} hx-trigger="load delay:500ms, every 500ms" hx-swap="outerHTML" class="flex gap-3">
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
          正在思考...
        </div>
      </div>
    </div>
    """
  end

  # 轮询获取 AI 响应
  def ai_response(%{"id" => id}) do
    messages = Nex.Store.get(:chat_messages, [])
    target_id = String.to_integer(id)

    ai_msg = Enum.find(messages, fn m ->
      Map.get(m, :parent_id) == target_id and m.role == :assistant
    end)

    if ai_msg do
      # 返回 AI 消息，不带轮询属性，停止轮询
      assigns = %{ai_msg: ai_msg}
      ~H"<.chat_message message={@ai_msg} />"
    else
      # 还在思考中，返回相同的 loading div 继续轮询
      assigns = %{msg_id: target_id}
      ~H"""
      <div id={"ai-loading-#{@msg_id}"} hx-post="/ai_response" hx-vals={Jason.encode!(%{id: @msg_id})} hx-trigger="load delay:500ms" hx-swap="outerHTML" class="flex gap-3">
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
            正在思考...
          </div>
        </div>
      </div>
      """
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
