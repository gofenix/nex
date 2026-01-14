# 示例 18: 重试中间件 (Retry Middleware)
# 运行方式: mix run examples/18_retry.exs

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)
if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

IO.puts "\n#{String.duplicate("=", 60)}"
IO.puts "示例 18: 重试中间件 (Retry Middleware)"
IO.puts "#{String.duplicate("=", 60)}\n"

IO.puts "使用 Retry 中间件自动重试失败的请求:\n"

# 创建带重试中间件的模型 (使用列表语法)
_retry_model = NexAI.wrap_model(
  NexAI.openai("gpt-4o"),
  [
    {NexAI.Middleware.Retry,
     max_retries: 3,
     initial_delay: 1000,
     max_delay: 10000,
     backoff: 2.0}
  ]
)

IO.puts "创建重试模型: 最多重试 3 次，指数退避\n"

IO.puts "代码示例:"
IO.puts ~S"""
  _retry_model = NexAI.wrap_model(
    NexAI.openai("gpt-4o"),
    [
      {NexAI.Middleware.Retry,
       max_retries: 3,        # 最大重试次数
       initial_delay: 1000,   # 初始延迟 (毫秒)
       max_delay: 10000,      # 最大延迟 (毫秒)
       backoff: 2.0}          # 退避倍数
    ]
  )

  {:ok, result} = NexAI.generate_text(
    model: _retry_model,
    messages: [...]
  )

  # 会自动重试以下错误:
  # - 429 (rate limit)
  # - 500 (server error)
  # - 503 (service unavailable)
  # - 网络超时
"""

IO.puts ""
IO.puts "组合使用多个中间件:"
IO.puts ~S"""
  model = NexAI.openai("gpt-4o")
  |> NexAI.wrap_model([{NexAI.Middleware.Logging, level: :info}])
  |> NexAI.wrap_model([{NexAI.Middleware.Retry, max_retries: 2}])
  |> NexAI.wrap_model([{NexAI.Middleware.RateLimit, requests_per_minute: 60}])
"""
