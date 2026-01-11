# 示例 1: 基础文本生成
# 对应 vendor/ai/examples/ai-core/src/generate-text/openai.ts

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)

if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

alias NexAI.Message.User

IO.puts "🚀 示例 1: 基础文本生成 (generateText)"
IO.puts "----------------------------------------"

case NexAI.generate_text(
  model: NexAI.openai("gpt-4o"),
  messages: [%User{content: "Invent a new holiday and describe its traditions."}]
) do
  {:ok, result} ->
    IO.puts "\n📝 Content:"
    IO.puts result.text
    IO.puts "\n📊 Usage:"
    IO.inspect(result.usage)
    IO.puts "\n🏁 Finish reason:"
    IO.puts result.finishReason

  {:error, reason} ->
    IO.puts "❌ Error: #{inspect(reason)}"
end
