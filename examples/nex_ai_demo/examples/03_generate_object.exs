# 示例 3: 结构化输出 (generateObject)
# 对应 vendor/ai/examples/ai-core/src/generate-object/openai.ts

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)

if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

alias NexAI.Message.User

IO.puts "🚀 示例 3: 结构化输出 (generateObject)"
IO.puts "----------------------------------------"

schema = %{
  type: "object",
  properties: %{
    recipe: %{
      type: "object",
      properties: %{
        name: %{type: "string"},
        ingredients: %{
          type: "array",
          items: %{
            type: "object",
            properties: %{
              name: %{type: "string"},
              amount: %{type: "string"}
            },
            required: ["name", "amount"]
          }
        },
        steps: %{
          type: "array",
          items: %{type: "string"}
        }
      },
      required: ["name", "ingredients", "steps"]
    }
  }
}

case NexAI.generate_text(
  model: NexAI.openai("gpt-4o"),
  messages: [%User{content: "Generate a lasagna recipe."}],
  output: %{mode: :object, schema: schema}
) do
  {:ok, result} ->
    # result.object is set by process_object_result
    IO.puts "\n📝 Recipe object:"
    if result.object do
      IO.puts Jason.encode!(result.object, pretty: true)
    else
      IO.puts "No object found in response"
      IO.puts "Raw text: #{String.slice(result.text || "", 0, 200)}..."
    end
    IO.puts "\n📊 Token usage:"
    IO.inspect(result.usage)
    IO.puts "\n🏁 Finish reason:"
    IO.puts result.finishReason

  {:error, reason} ->
    IO.puts "❌ Error: #{inspect(reason)}"
end
