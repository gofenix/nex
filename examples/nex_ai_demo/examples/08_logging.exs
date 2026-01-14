# 示例 8: 日志中间件 (Logging Middleware)
# 运行方式: mix run examples/08_logging.exs

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)
if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

alias NexAI.Message.User

IO.puts "\n#{String.duplicate("=", 60)}"
IO.puts "示例 8: 日志中间件 (Logging Middleware)"
IO.puts "#{String.duplicate("=", 60)}\n"

IO.puts "使用 Logging 中间件记录请求和响应的详细信息:\n"

# 创建带日志中间件的模型 (使用列表语法)
logged_model = NexAI.wrap_model(
  NexAI.openai("gpt-4o"),
  [{NexAI.Middleware.Logging, level: :info}]
)

{:ok, result} = NexAI.generate_text(
  model: logged_model,
  messages: [%User{content: "什么是函数式编程？"}]
)

IO.puts "\n回答: #{String.slice(result.text, 0, 50)}..."

IO.puts "\n代码示例:"
IO.puts ~S"""
  logged_model = NexAI.wrap_model(
    NexAI.openai("gpt-4o"),
    [{NexAI.Middleware.Logging, level: :info}]
  )

  {:ok, result} = NexAI.generate_text(
    model: logged_model,
    messages: [%User{content: "你的问题"}]
  )

  # 日志会输出:
  # - 请求 ID
  # - 模型名称
  # - Token 使用量
  # - 响应时间
"""
