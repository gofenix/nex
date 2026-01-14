# 示例 7: 平滑流中间件 (SmoothStream Middleware)
# 运行方式: mix run examples/07_smoothing.exs

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)
if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

alias NexAI.Message.User

IO.puts "\n#{String.duplicate("=", 60)}"
IO.puts "示例 7: 平滑流中间件 (SmoothStream Middleware)"
IO.puts "#{String.duplicate("=", 60)}\n"

IO.puts "SmoothStream 中间件可以将不均匀的 Token 输出平滑化，\n"
IO.puts "提供更流畅的阅读体验:\n"

# 创建带平滑流中间件的模型
smooth_model = NexAI.wrap_model(
  NexAI.openai("gpt-4o"),
  [{NexAI.Middleware.SmoothStream, delay: 30}]
)

case NexAI.stream_text(
  model: smooth_model,
  messages: [%User{content: "用一句话解释什么是人工智能。"}]
) do
  %{full_stream: stream} ->
    IO.write "平滑输出: "
    Enum.each(stream, fn event ->
      if event.type == :text_delta, do: IO.write(event.text || event.payload)
    end)
    IO.puts ""
  error -> IO.puts "错误: #{inspect(error)}"
end

IO.puts "\n代码示例:"
IO.puts """
  smooth_model = NexAI.wrap_model(
    NexAI.openai("gpt-4o"),
    [{NexAI.Middleware.SmoothStream, delay: 30}]  # delay: 毫秒
  )

  stream = NexAI.stream_text(
    model: smooth_model,
    messages: [...]
  )

  Enum.each(stream.full_stream, fn event ->
    if event.type == :text_delta, do: IO.write(event.text)
  end)
"""
