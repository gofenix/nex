# 示例 16: 推理内容提取 (ExtractReasoning Middleware)
# 运行方式: mix run examples/16_reasoning.exs

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)
if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

IO.puts "\n#{String.duplicate("=", 60)}"
IO.puts "示例 16: 推理内容提取 (ExtractReasoning Middleware)"
IO.puts "#{String.duplicate("=", 60)}\n"

IO.puts "使用 ExtractReasoning 中间件提取 o1 等模型的推理过程:\n"

IO.puts "代码示例:"
IO.puts ~S"""
  reasoning_model = NexAI.wrap_model(
    NexAI.openai("o1"),  # 或 o1-mini
    [{NexAI.Middleware.ExtractReasoning, mode: :separate}]
  )

  stream = NexAI.stream_text(
    model: reasoning_model,
    messages: [%User{content: "解决这个数学问题: 2x + 5 = 15, 求 x"}]
  )

  # reasoning_content 包含推理过程
  # text 包含最终回答
  Enum.each(stream.full_stream, fn event ->
    if event.type == :reasoning_delta do
      IO.puts "推理: #{event.content}"
    end
    if event.type == :text_delta do
      IO.puts "回答: #{event.text}"
    end
  end)
"""

IO.puts ""
IO.puts "  注意: 此功能需要支持推理内容的模型 (如 OpenAI o1, o1-mini, o3-mini)"
IO.puts "  ExtractReasoning 中间件将推理内容与最终回答分离输出"
