# 示例 10: 多 Provider 对比 (OpenAI vs Anthropic)
# 运行方式: mix run examples/10_provider.exs

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)
if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)
if anthropic_key = System.get_env("ANTHROPIC_API_KEY"), do: Application.put_env(:nex_ai, :anthropic_api_key, anthropic_key)

alias NexAI.Message.User

IO.puts "\n#{String.duplicate("=", 60)}"
IO.puts "示例 10: 多 Provider 对比"
IO.puts "#{String.duplicate("=", 60)}\n"

IO.puts "使用 OpenAI (GPT-4o):"
case NexAI.generate_text(
  model: NexAI.openai("gpt-4o"),
  messages: [%User{content: "用一个词回答: Elixir 的特点？"}]
) do
  {:ok, result} -> IO.puts "  → #{result.text}"
  {:error, _} -> IO.puts "  → [OpenAI 失败，跳过]"
end

IO.puts ""
IO.puts "使用 Anthropic (Claude-3-5-sonnet-latest):"
anthropic_model = "claude-3-5-sonnet-latest"
case NexAI.generate_text(
  model: NexAI.anthropic(anthropic_model),
  messages: [%User{content: "用一个词回答: Elixir 的特点？"}]
) do
  {:ok, result} -> IO.puts "  → #{result.text}"
  {:error, err} -> IO.puts "  → [Anthropic 失败: #{err.status || "配置错误"}]"
end

IO.puts "\n代码示例:"
IO.puts """
  # OpenAI
  openai_model = NexAI.openai("gpt-4o")

  # Anthropic
  anthropic_model = NexAI.anthropic("claude-3-5-sonnet-latest")

  # 切换 provider
  {:ok, result} = NexAI.generate_text(
    model: openai_model,  # 或 anthropic_model
    messages: [...]
  )
"""
