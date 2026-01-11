# 示例 20: 平滑流中间件 (SmoothStream Middleware)
# 对应 vendor/ai/examples/ai-core/src/middleware/simulate-streaming-example.ts

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)

if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

alias NexAI.Message.User

IO.puts "🚀 示例 20: 平滑流中间件 (SmoothStream Middleware)"
IO.puts "----------------------------------------"

smooth_model = NexAI.wrap_model(
  NexAI.openai("gpt-4o"),
  [{NexAI.Middleware.SmoothStream, delay: 50}]
)

result = NexAI.stream_text(
  model: smooth_model,
  messages: [%User{content: "What cities are in the United States?"}]
)

IO.write "\n📝 Streaming with smoothing: "
Enum.each(result.full_stream, fn event ->
  case event.type do
    :text_delta ->
      IO.write(event.text)
    :finish ->
      IO.puts "\n\n🏁 Finish reason: #{event.finish_reason}"
    :error ->
      IO.puts "\n❌ Error: #{inspect(event.error)}"
    _ ->
      :ok
  end
end)

IO.puts "\n✅ Streaming complete (text will appear in chunks with delays)"
