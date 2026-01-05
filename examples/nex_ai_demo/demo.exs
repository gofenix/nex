# NexAI 独立脚本演示
# 运行方式: mix run demo.exs

# 1. 加载环境变量
require Dotenvy
{:ok, env} = Dotenvy.source([".env", System.get_env()])
env |> Enum.each(fn {k, v} -> System.put_env(k, v) end)

IO.puts "🔧 已加载配置:"
IO.puts "   - OpenAI Base URL: #{System.get_env("OPENAI_BASE_URL") || "默认"}"
IO.puts "   - Anthropic Base URL: #{System.get_env("ANTHROPIC_BASE_URL") || "默认"}"

alias NexAI.Message.User

IO.puts "\n🚀 [示例 1] 基础生成 (generate_text) - 使用 OpenAI"
IO.puts "---------------------------------------------------"

case NexAI.generate_text(
  model: NexAI.openai("gpt-4o"),
  messages: [%User{content: "用一句话描述 Elixir 语言。"}]
) do
  {:ok, result} ->
    IO.puts "AI 回答: #{result.text}"
    IO.puts "Token 统计: #{inspect(result.usage)}"
  {:error, reason} ->
    IO.puts "错误: #{inspect(reason)}"
end

IO.puts "\n🚀 [示例 2] 流式生成 (stream_text) - 实时打印 Token"
IO.puts "---------------------------------------------------"

case NexAI.stream_text(
  model: NexAI.openai("gpt-4o"),
  messages: [%User{content: "请写一段 50 字左右的诗。"}]
) do
  {:error, err} -> 
    IO.puts "❌ [流验证失败] #{inspect(err)}"
  result ->
    IO.write "AI 正在创作: "
    Enum.each(result.full_stream, fn event ->
      case event.type do
        :text -> 
          IO.write(event.payload)
        :error -> IO.puts "\n[流错误] #{inspect(event.payload)}"
        :stream_finish -> IO.puts "\n[流结束] 原因: #{event.payload.finishReason}"
        _ -> :ok
      end
    end)
end

IO.puts "\n🚀 [示例 3] 自动工具调用 (Multi-step Tool Use)"
IO.puts "---------------------------------------------------"

weather_tool = NexAI.tool(%{
  name: "get_current_weather",
  description: "获取指定地点的天气",
  parameters: %{
    type: "object",
    properties: %{
      location: %{type: "string", description: "城市名，如北京"}
    },
    required: ["location"]
  },
  execute: fn %{"location" => loc} ->
    "#{loc}目前天气晴朗，气温 22°C。"
  end
})

IO.puts "执行中 (允许 AI 自动调用工具并获取结果)..."
{:ok, res} = NexAI.generate_text(
  model: NexAI.openai("gpt-4o"),
  tools: [weather_tool],
  max_steps: 5,
  messages: [%User{content: "深圳的天气怎么样？适合穿什么？"}]
)

IO.puts "最终回答: #{res.text}"
IO.puts "中间步骤: #{length(res.steps)} 步"

IO.puts "\n🚀 [示例 4] 中间件 (Middleware) - 提取推理过程"
IO.puts "---------------------------------------------------"

smart_model = NexAI.Middleware.wrap_model(
  NexAI.openai("gpt-4o"),
  [{NexAI.Middleware.ExtractReasoning, tag: "thought"}]
)

{:ok, res} = NexAI.generate_text(
  model: smart_model,
  messages: [%User{content: "请解释一下什么是背压 (Backpressure)，并在回答前先在 <thought> 标签内思考。"}]
)

IO.puts "AI 的思考过程: #{res.reasoning || "未捕获到"}"
IO.puts "AI 的正式回答: #{res.text}"

IO.puts "\n🚀 [示例 5] 流式推理提取 (Streaming Reasoning Extraction)"
IO.puts "---------------------------------------------------"

smart_model = NexAI.Middleware.wrap_model(
  NexAI.openai("gpt-4o"),
  [{NexAI.Middleware.ExtractReasoning, tag: "thought"}]
)

result = NexAI.stream_text(
  model: smart_model,
  messages: [%User{content: "为什么天空是蓝色的？请在 <thought> 中先思考。"}]
)

IO.write "AI 正在思考并回答...\n"
Enum.each(result.full_stream, fn event ->
  case event.type do
    :reasoning -> 
      IO.write("\e[33m#{event.payload}\e[0m") # Yellow for reasoning
    :text -> 
      IO.write(event.payload)
    :error ->
      IO.puts "\n❌ [流错误] #{inspect(event.payload)}"
    _ -> :ok
  end
end)

IO.puts "\n\n✅ 所有演示执行完毕。"
