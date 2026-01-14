# 示例 12: 生命周期钩子 (Lifecycle Hooks)
# 运行方式: mix run examples/12_lifecycle.exs

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)
if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

alias NexAI.Message.User

IO.puts "\n#{String.duplicate("=", 60)}"
IO.puts "示例 12: 生命周期钩子 (on_finish, on_step_finish)"
IO.puts "#{String.duplicate("=", 60)}\n"

IO.puts "使用 on_finish 回调处理生成完成事件:\n"

{:ok, result} = NexAI.generate_text(
  model: NexAI.openai("gpt-4o"),
  messages: [%User{content: "2 + 3 = ?"}],
  on_finish: fn res ->
    IO.puts "  [on_finish] 生成完成，文本长度: #{String.length(res.text)}"
  end
)

IO.puts "最终结果: #{result.text}"

# 工具调用的 step finish 回调
IO.puts ""
IO.puts "使用 on_step_finish 回调监控工具调用步骤:\n"

weather_tool = NexAI.tool(%{
  name: "get_current_weather",
  description: "获取天气",
  parameters: %{
    type: "object",
    properties: %{location: %{type: "string"}},
    required: ["location"]
  },
  execute: fn %{"location" => loc} -> "#{loc} 天气晴朗" end
})

{:ok, _tool_result} = NexAI.generate_text(
  model: NexAI.openai("gpt-4o"),
  tools: [weather_tool],
  messages: [%User{content: "北京的天气"}],
  on_step_finish: fn step ->
    IO.puts "  [on_step_finish] Step #{step.step} 完成"
    IO.puts "    Text: #{String.slice(step.text || "", 0, 30)}..."
    if step.toolCalls, do: IO.puts("    Tool Calls: #{length(step.toolCalls)}")
  end
)

IO.puts "\n代码示例:"
IO.puts ~S"""
  {:ok, result} = NexAI.generate_text(
    model: NexAI.openai("gpt-4o"),
    messages: [...],
    on_finish: fn res ->
      IO.puts "生成完成: #{res.text}"
    end,
    on_step_finish: fn step ->
      IO.puts "Step #{step.step}: #{step.text}"
    end
  )
"""
