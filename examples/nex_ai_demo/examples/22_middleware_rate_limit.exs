# 示例 22: 限流中间件 (Rate Limit Middleware)
# 对应 vendor/ai/examples/ai-core/src/middleware/your-cache-middleware.ts

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)

if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

alias NexAI.Message.User

IO.puts "🚀 示例 22: 限流中间件 (Rate Limit Middleware)"
IO.puts "----------------------------------------"

rate_limited_model = NexAI.wrap_model(
  NexAI.openai("gpt-4o"),
  [{NexAI.Middleware.RateLimit, max_requests: 2, window_ms: 5000}]
)

IO.puts "发送 3 个请求（限制：2 个请求 / 5 秒）"
IO.puts ""

Enum.each(1..3, fn i ->
  IO.puts "请求 #{i}..."
  start_time = System.monotonic_time(:millisecond)

  case NexAI.generate_text(
    model: rate_limited_model,
    messages: [%User{content: "Say hello in #{i} word(s)."}]
  ) do
    {:ok, result} ->
    elapsed = System.monotonic_time(:millisecond) - start_time
    IO.puts "  ✅ 完成 (耗时: #{elapsed}ms): #{String.trim(result.text)}"
  {:error, reason} ->
    IO.puts "  ❌ 错误: #{inspect(reason)}"
  end

  Process.sleep(1000)
end)

IO.puts "\n✅ 限流中间件测试完成"
