# 示例 5: 工具调用 (Tool Calling)
# 对应 vendor/ai/examples/ai-core/src/generate-text/openai-tool-call.ts

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)

if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

alias NexAI.Message.User

IO.puts "🚀 示例 5: 工具调用 (Tool Calling)"
IO.puts "----------------------------------------"

# 定义天气工具
weather_tool = NexAI.tool(%{
  name: "weather",
  description: "Get the weather in a location",
  parameters: %{
    type: "object",
    properties: %{
      location: %{
        type: "string",
        description: "The location to get the weather for"
      }
    },
    required: ["location"]
  },
  execute: fn %{"location" => location} ->
    conditions = [
      %{name: "sunny", min_temp: -5, max_temp: 35},
      %{name: "snowy", min_temp: -10, max_temp: 0},
      %{name: "rainy", min_temp: 0, max_temp: 15},
      %{name: "cloudy", min_temp: 5, max_temp: 25}
    ]
    condition = Enum.random(conditions)
    temp = condition.min_temp + :rand.uniform(condition.max_temp - condition.min_temp + 1) - 1
    %{
      location: location,
      condition: condition.name,
      temperature: temp
    }
  end
})

# 定义城市景点工具
city_attractions_tool = NexAI.tool(%{
  name: "cityAttractions",
  description: "Get attractions in a city",
  parameters: %{
    type: "object",
    properties: %{
      city: %{type: "string"}
    },
    required: ["city"]
  },
  execute: fn %{"city" => city} ->
    attractions = ["Museum", "Park", "Historic Center", "Shopping District"]
    %{
      city: city,
      attractions: Enum.take_random(attractions, 3)
    }
  end
})

case NexAI.generate_text(
  model: NexAI.openai("gpt-3.5-turbo"),
  max_tokens: 512,
  tools: [weather_tool, city_attractions_tool],
  messages: [%User{content: "What is the weather in San Francisco and what attractions should I visit?"}]
) do
  {:ok, result} ->
    IO.puts "\n📝 Final response:"
    IO.puts result.text
    IO.puts "\n🔧 Tool calls:"
    Enum.each(result.toolCalls, fn tc ->
      IO.puts "  - #{tc.toolName}: #{inspect(tc.args)}"
    end)
    IO.puts "\n📊 Tool results:"
    Enum.each(result.toolResults, fn tr ->
      IO.puts "  - #{tr.toolName}: #{inspect(tr.result)}"
    end)
    IO.puts "\n📊 Usage:"
    IO.inspect(result.usage)
    IO.puts "\n🏁 Finish reason:"
    IO.puts result.finishReason

  {:error, reason} ->
    IO.puts "❌ Error: #{inspect(reason)}"
end
