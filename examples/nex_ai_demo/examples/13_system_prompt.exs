# 示例 13: 系统提示词 (System Prompt)
# 运行方式: mix run examples/13_system_prompt.exs

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)
if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

alias NexAI.Message.User

IO.puts "\n#{String.duplicate("=", 60)}"
IO.puts "示例 13: 系统提示词 (System Prompt)"
IO.puts "#{String.duplicate("=", 60)}\n"

IO.puts "使用 system 参数设置 AI 的行为人设:\n"

{:ok, sys_result} = NexAI.generate_text(
  model: NexAI.openai("gpt-4o"),
  system: "你是一个诗人，总是用意大利语回答，并将回答格式化为诗歌。",
  messages: [%User{content: "介绍一下你自己。"}]
)

IO.puts "AI 诗人回答:"
IO.puts "  #{String.replace(sys_result.text, "\n", "\n  ")}"

IO.puts "\n代码示例:"
IO.puts """
  {:ok, result} = NexAI.generate_text(
    model: NexAI.openai("gpt-4o"),
    system: "你是一个专业的技术写作助手，使用简洁明了的语言。",
    messages: [%User{content: "解释什么是函数式编程"}]
  )

  IO.puts result.text
"""
