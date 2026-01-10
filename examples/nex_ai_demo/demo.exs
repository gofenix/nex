# NexAI 独立脚本演示
# 运行方式: mix run demo.exs

# 1. 加载环境变量
require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
# 显式同步到 System.put_env 确保当前进程可见
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)

# 确保 nex_ai 能够读取到配置
if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)
if url = System.get_env("OPENAI_BASE_URL"), do: Application.put_env(:nex_ai, :openai_base_url, url)

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

IO.puts "\n🚀 [示例 4] 平滑流 (SmoothStream Middleware)"
IO.puts "---------------------------------------------------"

smooth_model = NexAI.wrap_model(
  NexAI.openai("gpt-4o"),
  [{NexAI.Middleware.SmoothStream, delay: 50}]
)

case NexAI.stream_text(
  model: smooth_model,
  messages: [%User{content: "用 20 字描述什么是平滑流。"}]
) do
  %{full_stream: stream} ->
    IO.write "平滑输出中: "
    Enum.each(stream, fn event ->
      if event.type == :text, do: IO.write(event.payload)
    end)
    IO.puts ""
  error -> IO.puts "错误: #{inspect(error)}"
end

IO.puts "\n🚀 [示例 5] 结构化输出 (stream_object) + 生命周期钩子"
IO.puts "---------------------------------------------------"

case NexAI.stream_text(
  model: NexAI.openai("gpt-4o"),
  messages: [%User{content: "生成一个只有 name 和 age 的 JSON 对象，name 是张三，age 是 20。"}],
  output: %{mode: :object, schema: %{type: "object", properties: %{name: %{type: "string"}, age: %{type: "integer"}}}},
  on_token: fn obj -> IO.puts("\n[钩子] 收到增量对象: #{inspect(obj)}") end
) do
  %{full_stream: stream} ->
    IO.write "最终解析中... "
    Enum.each(stream, fn event ->
      if event.type == :object_delta, do: IO.write(".")
    end)
    IO.puts "\n完成。"
  error -> IO.puts "错误: #{inspect(error)}"
end

IO.puts "\n\n✅ 所有演示执行完毕。"
