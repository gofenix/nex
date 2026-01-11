# 示例 24: 图像生成
# 对应 vendor/ai/examples/ai-core/src/generate-image/

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)

if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

IO.puts "🚀 示例 24: 图像生成"
IO.puts "----------------------------------------"

case NexAI.Provider.OpenAI.generate_image(
  "A futuristic city with flying cars at sunset, digital art style",
  model_id: "dall-e-3"
) do
  {:ok, result} ->
    IO.puts "\n🖼️ Image generated!"
    IO.puts "URL: #{result.url}"
    IO.puts "Revised prompt: #{result.revised_prompt}"
    IO.puts "\n📊 Usage:"
    IO.inspect(result.usage)

  {:error, reason} ->
    IO.puts "❌ Error: #{inspect(reason)}"
end
