# 示例 6: 多步生成 (Multi-step Generation)
# 对应 vendor/ai/examples/ai-core/src/generate-text/openai-multi-step.ts

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)

if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

alias NexAI.Message.User

IO.puts "🚀 示例 6: 多步生成 (Multi-step Generation)"
IO.puts "----------------------------------------"

# 定义天气工具
weather_tool = NexAI.tool(%{
  name: "get_weather",
  description: "Get the current weather for a location",
  parameters: %{
    type: "object",
    properties: %{
      location: %{type: "string", description: "The city and state, e.g. San Francisco, CA"}
    },
    required: ["location"]
  },
  execute: fn %{"location" => location} ->
    %{
      location: location,
      temperature: 72 + :rand.uniform(21) - 10,
      condition: Enum.random(["sunny", "cloudy", "rainy"])
    }
  end
})

case NexAI.generate_text(
  model: NexAI.openai("gpt-4o"),
  tools: [weather_tool],
  max_steps: 5,
  messages: [%User{content: "What is the weather in San Francisco, Tokyo, and Paris?"}]
) do
  {:ok, result} ->
    IO.puts "\n📝 Final response:"
    IO.puts result.text
    IO.puts "\n📊 Steps: #{length(result.steps || [])}"
    if result.steps do
      Enum.with_index(result.steps, fn step, idx ->
        IO.puts "\n  Step #{idx + 1}:"
        IO.puts "    Type: #{step.stepType}"
        IO.puts "    Text: #{String.slice(step.text || "", 0, 100)}..."
        if step.toolCalls && length(step.toolCalls) > 0 do
          IO.puts "    Tool calls: #{length(step.toolCalls)}"
        end
        if step.toolResults && length(step.toolResults) > 0 do
          IO.puts "    Tool results: #{length(step.toolResults)}"
        end
      end)
    end
    IO.puts "\n📊 Total usage:"
    IO.inspect(result.usage)
    IO.puts "\n🏁 Finish reason:"
    IO.puts result.finishReason

  {:error, reason} ->
    IO.puts "❌ Error: #{inspect(reason)}"
end
