# 示例 7: 多轮对话聊天机器人
# 对应 vendor/ai/examples/ai-core/src/stream-text/openai-chatbot.ts

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)

if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

alias NexAI.Message.User

IO.puts "🚀 示例 7: 多轮对话聊天机器人"
IO.puts "----------------------------------------"
IO.puts "输入 'quit' 退出"
IO.puts ""

# 定义天气工具
weather_tool = NexAI.tool(%{
  name: "weather",
  description: "Get the weather in a location",
  parameters: %{
    type: "object",
    properties: %{
      location: %{type: "string", description: "The location to get the weather for"}
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

# 聊天循环函数
defmodule Chatbot do
  def run(messages, step_count, weather_tool) when step_count >= 5 do
    IO.puts "\n🏁 Reached maximum steps (5)"
  end

  def run(messages, step_count, weather_tool) do
    IO.write "You: "
    input = IO.gets("") |> String.trim()

    if input == "quit" do
      IO.puts "\n👋 Goodbye!"
    else
      user_message = %NexAI.Message.User{content: input}
      new_messages = messages ++ [user_message]

      case NexAI.stream_text(
        model: NexAI.openai("gpt-4o"),
        tools: [weather_tool],
        max_steps: 5 - step_count,
        messages: new_messages
      ) do
        {:error, err} ->
          IO.puts "❌ Error: #{inspect(err)}"
          run(messages, step_count, weather_tool)

        result ->
          IO.write "\nAssistant: "
          Enum.each(result.full_stream, fn event ->
            case event.type do
              :text_delta -> IO.write(event.text)
              :tool_call_start ->
                IO.puts "\n\n🔧 Calling tool: #{event.toolName}"
                IO.write "  Args: "
              :tool_call_delta -> IO.write(event.argsDelta)
              :tool_call_finish ->
                IO.puts "\n  Result: #{inspect(event.content)}"
              :finish -> IO.puts "\n\n🏁 Finish: #{event.finish_reason}"
              :error -> IO.puts "\n❌ Error: #{inspect(event.error)}"
              _ -> :ok
            end
          end)

          # 获取响应消息并继续对话
          case result do
            %{response_messages: response_messages} when is_list(response_messages) ->
              run(new_messages ++ response_messages, step_count + 1, weather_tool)
            _ ->
              run(new_messages, step_count + 1, weather_tool)
          end
      end
    end
  end
end

# 启动聊天
IO.puts "\n🤖 Chatbot started! (Type 'quit' to exit)"
Chatbot.run([], 0, weather_tool)
