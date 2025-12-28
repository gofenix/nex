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
        <p class="text-lg mb-2">Hello! I'm an AI assistant</p>
        <p class="text-sm">How can I help you?</p>
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

    # Get current page_id, pass to async task
    current_page_id = Nex.Store.get_page_id()

    # Start async task to generate AI response
    Task.Supervisor.async_nolink(Chatbot.TaskSupervisor, fn ->
      Nex.Store.set_page_id(current_page_id)

      api_key = Nex.Env.get(:OPENAI_API_KEY)
      base_url = Nex.Env.get(:OPENAI_BASE_URL, "https://api.openai.com/v1")

      response = call_openai(api_key, base_url, user_message)

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
          Thinking...
        </div>
      </div>
    </div>
    """
  end

  # Poll to get AI response
  def ai_response(%{"id" => id}) do
    messages = Nex.Store.get(:chat_messages, [])
    target_id = String.to_integer(id)

    ai_msg = Enum.find(messages, fn m ->
      Map.get(m, :parent_id) == target_id and m.role == :assistant
    end)

    if ai_msg do
      # Return AI message without polling attributes to stop polling
      assigns = %{ai_msg: ai_msg}
      ~H"<.chat_message message={@ai_msg} />"
    else
      # Still thinking, return the same loading div to continue polling
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
            Thinking...
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
