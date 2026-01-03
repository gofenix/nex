defmodule DatastarDemo.API.Chat do
  use Nex

  def stream(req) do
    msg_id = req.query["msg_id"] |> String.to_integer()

    Nex.stream(fn send ->
      ai_response = simulate_ai_response()
      timestamp = format_time()

      accumulated = ""
      for token <- ai_response do
        Process.sleep(50)
        accumulated = accumulated <> token

        send.(~s"""
        event: datastar-patch-elements
        data: selector #ai-content-#{msg_id}
        data: elements <div id="ai-content-#{msg_id}" class="px-4 py-3 rounded-lg bg-green-100">#{accumulated}</div>

        """)
      end

      ai_msg = %{
        id: msg_id,
        role: :assistant,
        content: accumulated,
        timestamp: timestamp
      }

      Nex.Store.update(:messages, [], &[ai_msg | &1])

      send.(~s"""
      event: datastar-patch-signals
      data: signals {"isLoading": false, "message": ""}

      """)
    end)
  end

  defp simulate_ai_response do
    responses = [
      "你好！我是一个 AI 助手。",
      "这是一个 Datastar SSE 流式响应的演示。",
      "我可以逐字显示响应内容，",
      "就像真实的 AI 对话一样！",
      "Datastar 原生支持 SSE，非常适合这种场景。"
    ]

    Enum.random(responses)
    |> String.graphemes()
  end

  defp format_time do
    {{year, month, day}, {hour, minute, _}} = :erlang.localtime()
    "#{year}-#{pad(month)}-#{pad(day)} #{pad(hour)}:#{pad(minute)}"
  end

  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n), do: "#{n}"
end
