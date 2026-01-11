# 示例 4: 流式结构化输出 (streamObject)
# 对应 vendor/ai/examples/ai-core/src/stream-object/openai.ts

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)

if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

alias NexAI.Message.User

IO.puts "🚀 示例 4: 流式结构化输出 (streamObject)"
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

result = NexAI.stream_text(
  model: NexAI.openai("gpt-4o"),
  messages: [%User{content: "Generate a lasagna recipe."}],
  output: %{mode: :object, schema: schema}
)

IO.write "\n📝 Streaming object: "
Enum.each(result.full_stream, fn event ->
  case event.type do
    :text_delta ->
      IO.write(event.text)
    :object_delta ->
      # Streaming structured output sends object_delta events with payload
      if event.payload do
        IO.write(".")
      end
    :finish ->
      IO.puts "\n\n🏁 Finish reason: #{event.finish_reason}"
    :usage ->
      IO.puts "\n📊 Usage:"
      IO.inspect(event.usage)
    :error ->
      IO.puts "\n❌ Error: #{inspect(event.error)}"
    _ ->
      :ok
  end
end)

# Note: Streaming structured output produces partial JSON chunks
# For complete structured output, use generate_text with output schema (see example 03)

# Collect text_delta and object_delta events
text_parts = Enum.filter(result.full_stream, fn e -> e.type == :text_delta end) |> Enum.map(fn e -> e.text end)
object_deltas = Enum.filter(result.full_stream, fn e -> e.type == :object_delta end) |> Enum.map(fn e -> e.payload end)

text = Enum.join(text_parts, "")
IO.puts "\n📝 Text deltas: #{length(text_parts)}"
IO.puts "📝 Object deltas: #{length(object_deltas)}"
IO.puts "📝 Accumulated text length: #{String.length(text)} chars"

# Display the last (most complete) object_delta if available
if length(object_deltas) > 0 do
  last_obj = List.last(object_deltas)
  IO.puts "\n📝 Last object delta (most complete):"
  IO.puts Jason.encode!(last_obj, pretty: true)
else
  # Fallback: try to parse JSON from accumulated text
  clean_text = text |> String.replace(~r/^```json\s*/, "") |> String.replace(~r/\s*```$/, "") |> String.trim()
  if String.length(clean_text) > 0 do
    IO.puts "\n📝 Text content:"
    IO.puts String.slice(clean_text, 0, 500)
  end
end

IO.puts "\n💡 For complete structured output, use generate_text with output schema (example 03)"
