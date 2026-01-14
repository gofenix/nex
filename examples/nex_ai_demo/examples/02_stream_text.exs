# 示例 2: 流式文本生成 (stream_text)
# 运行方式: mix run examples/02_stream_text.exs

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)
if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

alias NexAI.Message.User

IO.puts "\n#{String.duplicate("=", 60)}"
IO.puts "示例 2: 流式文本生成 (stream_text)"
IO.puts "#{String.duplicate("=", 60)}\n"

IO.puts "使用 NexAI.stream_text/1 实现实时流式输出:\n"

case NexAI.stream_text(
  model: NexAI.openai("gpt-4o"),
  messages: [%User{content: "请用 50 字描述什么是 Elixir。"}]
) do
  {:error, err} ->
    IO.puts "❌ 流验证失败: #{inspect(err)}"
  result ->
    IO.write "AI 正在创作: "
    Enum.each(result.full_stream, fn event ->
      case event.type do
        :text_delta -> IO.write(event.text || event.payload)
        :reasoning_delta -> IO.write("[推理:#{event.content}]")
        :error -> IO.puts "\n[流错误] #{inspect(event.payload)}"
        :stream_finish -> IO.puts "\n[流结束] finish_reason=#{event.payload.finishReason}"
        _ -> :ok
      end
    end)
end

IO.puts "\n\n代码示例:"
IO.puts """
  alias NexAI.Message.User

  {:ok, stream} = NexAI.stream_text(
    model: NexAI.openai("gpt-4o"),
    messages: [%User{content: "请用 50 字描述什么是 Elixir。"}]
  )

  Enum.each(stream.full_stream, fn event ->
    if event.type == :text_delta do
      IO.write(event.text)
    end
  end)
"""
