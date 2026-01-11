# 示例 2: 流式文本生成
# 对应 vendor/ai/examples/ai-core/src/stream-text/openai.ts

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)

if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

alias NexAI.Message.User

IO.puts "🚀 示例 2: 流式文本生成 (streamText)"
IO.puts "----------------------------------------"

result = NexAI.stream_text(
  model: NexAI.openai("gpt-4o"),
  messages: [%User{content: "Invent a new holiday and describe its traditions."}]
)

IO.write "\n📝 Streaming content: "
Enum.each(result.full_stream, fn event ->
  case event.type do
    :text_delta ->
      IO.write(event.text)
    :finish ->
      IO.puts "\n\n🏁 Finish reason: #{event.finish_reason}"
    :usage ->
      IO.puts "\n📊 Usage:"
      IO.inspect(event.usage)
    :error ->
      IO.puts "\n❌ Error: #{inspect(event.error)}"
    _ ->
      :ok
  end
end)

IO.puts "\n✅ Streaming complete"
