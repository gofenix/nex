# 示例 5: 工具调用 (Tool Calling)
# 运行方式: mix run examples/05_tool_calling.exs

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)
if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

alias NexAI.Message.User

IO.puts "\n#{String.duplicate("=", 60)}"
IO.puts "示例 5: 工具调用 (Tool Calling)"
IO.puts "#{String.duplicate("=", 60)}\n"

# 定义天气查询工具
weather_tool = NexAI.tool(%{
  name: "get_current_weather",
  description: "获取指定地点的天气",
  parameters: %{
    type: "object",
    properties: %{
      location: %{type: "string", description: "城市名"}
    },
    required: ["location"]
  },
  execute: fn %{"location" => location} ->
    "#{location}目前天气晴朗，气温 22°C，湿度 60%。"
  end
})

# 定义计算器工具
calculator_tool = NexAI.tool(%{
  name: "calculate",
  description: "执行数学计算",
  parameters: %{
    type: "object",
    properties: %{
      expression: %{type: "string", description: "数学表达式，如 2 + 3 * 4"}
    },
    required: ["expression"]
  },
  execute: fn %{"expression" => expr} ->
    case Code.eval_string(expr) do
      {result, _} -> "计算结果: #{result}"
      _ -> "无法计算该表达式"
    end
  end
})

IO.puts "定义了两个工具: get_current_weather, calculate\n"
IO.puts "执行中 (AI 会自动判断何时调用工具)...\n"

{:ok, res} = NexAI.generate_text(
  model: NexAI.openai("gpt-4o"),
  tools: [weather_tool, calculator_tool],
  max_steps: 5,
  messages: [%User{content: "深圳天气怎么样？另外帮我算一下 100 - 25 * 3 等于多少？"}]
)

IO.puts "\n最终回答: #{res.text}"
IO.puts "工具调用步骤: #{length(res.steps)} 步"

IO.puts "\n代码示例:"
IO.puts ~S"""
  weather_tool = NexAI.tool(%{
    name: "get_current_weather",
    description: "获取指定地点的天气",
    parameters: %{
      type: "object",
      properties: %{
        location: %{type: "string", description: "城市名"}
      },
      required: ["location"]
    },
    execute: fn %{"location" => location} ->
      "#{location}天气晴朗，气温 22°C"
    end
  })

  {:ok, result} = NexAI.generate_text(
    model: NexAI.openai("gpt-4o"),
    tools: [weather_tool],
    messages: [%User{content: "北京的天气"}]
  )

  IO.puts result.text
"""
