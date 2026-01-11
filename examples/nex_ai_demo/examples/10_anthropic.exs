# 示例 10: Anthropic Claude (via OpenAI-compatible endpoint)
# 对应 vendor/ai/examples/ai-core/src/generate-text/anthropic.ts
# 注意：此示例使用 OpenAI provider 调用 Claude 模型，适用于 OpenAI 兼容端点

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)

if key = System.get_env("ANTHROPIC_API_KEY"), do: Application.put_env(:nex_ai, :anthropic_api_key, key)

alias NexAI.Message.User

IO.puts "🚀 示例 10: Anthropic Claude"
IO.puts "----------------------------------------"

case NexAI.generate_text(
  model: NexAI.openai("claude-3-5-sonnet-20241022"),
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
