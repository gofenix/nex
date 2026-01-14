# 示例 17: UI 协议适配 (Vercel / DataStar)
# 运行方式: mix run examples/17_ui_protocols.exs

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)
if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

IO.puts "\n#{String.duplicate("=", 60)}"
IO.puts "示例 17: UI 协议适配 (Vercel / DataStar)"
IO.puts "#{String.duplicate("=", 60)}\n"

IO.puts "NexAI 支持多种前端协议，方便与不同框架集成:\n"

IO.puts "1. Vercel AI SDK Data Stream 格式:"
IO.puts """
  stream = NexAI.stream_text(
    model: NexAI.openai("gpt-4o"),
    messages: [%User{content: "你好"}]
  )

  # 转换为 Vercel AI SDK 兼容格式
  vercel_stream = NexAI.to_data_stream(stream)

  # 用于 @ai-sdk/react, @ai-sdk/vue 等前端库
  # 返回 SSE 格式的 stream
"""

IO.puts ""
IO.puts "2. DataStar 协议格式 (HTMX + SSE):"
IO.puts """
  stream = NexAI.stream_text(
    model: NexAI.openai("gpt-4o"),
    messages: [%User{content: "你好"}]
  )

  # 转换为 DataStar SSE 信号格式
  datastar_stream = NexAI.to_datastar(stream, signal: "aiResponse")

  # 适用于 HTMX + Server-Sent Events
  # 可直接与 DataStar 前端集成
"""

IO.puts ""
IO.puts "  NexAI 协议转换:"
IO.puts "  - NexAI.to_data_stream/1 - Vercel AI SDK"
IO.puts "  - NexAI.to_datastar/2   - DataStar (HTMX)"
