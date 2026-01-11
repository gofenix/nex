# 示例 23: 推理内容 (Reasoning)
# 对应 vendor/ai/examples/ai-core/src/generate-text/openai-reasoning.ts

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)

if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

alias NexAI.Message.User

IO.puts "🚀 示例 23: 推理内容 (Reasoning)"
IO.puts "----------------------------------------"

case NexAI.generate_text(
  model: NexAI.openai("o1-preview"),
  messages: [%User{content: "How many 'r's are in the word 'strawberry'?"}]
) do
  {:ok, result} ->
    IO.puts "\n📝 Final answer:"
    IO.puts result.text

    if result.reasoning do
      IO.puts "\n🧠 Reasoning:"
      IO.puts result.reasoning
    else
      IO.puts "\n🧠 No reasoning content available"
    end

    IO.puts "\n📊 Usage:"
    IO.inspect(result.usage)
    IO.puts "\n🏁 Finish reason:"
    IO.puts result.finishReason

  {:error, reason} ->
    IO.puts "❌ Error: #{inspect(reason)}"
end
