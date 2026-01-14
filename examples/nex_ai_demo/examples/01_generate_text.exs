# 示例 1: 基础文本生成 (generate_text)
# 运行方式: mix run examples/01_generate_text.exs

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)
if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

alias NexAI.Message.User

IO.puts "\n#{String.duplicate("=", 60)}"
IO.puts "示例 1: 基础文本生成 (generate_text)"
IO.puts "#{String.duplicate("=", 60)}\n"

IO.puts "使用 NexAI.generate_text/1 进行简单的文本生成:\n"

case NexAI.generate_text(
  model: NexAI.openai("gpt-4o"),
  messages: [%User{content: "用一句话描述 Elixir 语言。"}]
) do
  {:ok, result} ->
    IO.puts "AI 回答: #{result.text}"
    IO.puts "Token 统计: prompt=#{result.usage.promptTokens}, completion=#{result.usage.completionTokens}"
  {:error, reason} ->
    IO.puts "错误: #{inspect(reason)}"
end

IO.puts "\n代码示例:"
IO.puts ~S"""
  alias NexAI.Message.User

  {:ok, result} = NexAI.generate_text(
    model: NexAI.openai("gpt-4o"),
    messages: [%User{content: "用一句话描述 Elixir 语言。"}]
  )

  IO.puts result.text
  IO.puts "Tokens: #{result.usage.promptTokens} + #{result.usage.completionTokens}"
"""
