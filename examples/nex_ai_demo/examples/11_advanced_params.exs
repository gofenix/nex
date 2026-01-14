# 示例 11: 高级参数 (temperature, max_tokens, stop)
# 运行方式: mix run examples/11_advanced_params.exs

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)
if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

alias NexAI.Message.User

IO.puts "\n#{String.duplicate("=", 60)}"
IO.puts "示例 11: 高级参数 (temperature, max_tokens, stop)"
IO.puts "#{String.duplicate("=", 60)}\n"

IO.puts "temperature=0 (确定性输出):"
{:ok, r1} = NexAI.generate_text(
  model: NexAI.openai("gpt-4o"),
  messages: [%User{content: "1+1 等于几？"}],
  temperature: 0.0,
  max_tokens: 5
)
IO.puts "  → #{r1.text}"

IO.puts ""
IO.puts "temperature=1.5 (创造性输出):"
{:ok, r2} = NexAI.generate_text(
  model: NexAI.openai("gpt-4o"),
  messages: [%User{content: "用比喻描述编程。"}],
  temperature: 1.5,
  max_tokens: 50
)
IO.puts "  → #{r2.text}"

IO.puts ""
IO.puts "stop 序列 (提前停止):"
{:ok, r3} = NexAI.generate_text(
  model: NexAI.openai("gpt-4o"),
  messages: [%User{content: "列出 5 个编程语言: 1. 2. 3. 4. 5."}],
  stop: ["5."]
)
IO.puts "  → #{r3.text}"

IO.puts "\n代码示例:"
IO.puts """
  {:ok, result} = NexAI.generate_text(
    model: NexAI.openai("gpt-4o"),
    messages: [...],
    temperature: 0.7,      # 0.0-2.0, 越低越确定
    max_tokens: 100,       # 最大生成 token 数
    top_p: 0.9,            # 核采样
    frequency_penalty: 0.0, # 频率惩罚
    presence_penalty: 0.0,  # 存在惩罚
    stop: ["用户:", "结束"] # 停止序列
  )
"""
