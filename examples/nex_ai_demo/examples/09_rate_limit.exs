# 示例 9: 速率限制中间件 (RateLimit Middleware)
# 运行方式: mix run examples/09_rate_limit.exs

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)
if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

IO.puts "\n#{String.duplicate("=", 60)}"
IO.puts "示例 9: 速率限制中间件 (RateLimit Middleware)"
IO.puts "#{String.duplicate("=", 60)}\n"

IO.puts "RateLimit 中间件可以限制 API 调用频率，防止超出配额:\n"

# 创建带速率限制的模型 (使用列表语法)
_rate_limited_model = NexAI.wrap_model(
  NexAI.openai("gpt-4o"),
  [{NexAI.Middleware.RateLimit, requests_per_minute: 10}]
)

IO.puts "创建速率限制模型: 每分钟最多 10 次请求"
IO.puts ""
IO.puts "代码示例:"
IO.puts ~S"""
  _rate_limited_model = NexAI.wrap_model(
    NexAI.openai("gpt-4o"),
    [{NexAI.Middleware.RateLimit, requests_per_minute: 10}]
  )

  {:ok, result} = NexAI.generate_text(
    model: _rate_limited_model,
    messages: [...]
  )

  # 如果超过限制，会返回 {:error, :rate_limit_exceeded}
"""
