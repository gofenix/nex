# 示例 14: 图像生成 (DALL-E)
# 运行方式: mix run examples/14_images.exs

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)
if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

IO.puts "\n#{String.duplicate("=", 60)}"
IO.puts "示例 14: 图像生成 (DALL-E 3)"
IO.puts "#{String.duplicate("=", 60)}\n"

IO.puts "使用 NexAI.generate_image/1 生成图像:\n"

IO.puts "代码示例:"
IO.puts """
  {:ok, result} = NexAI.generate_image(
    prompt: "A beautiful sunset over ocean with mountains in the background",
    model: NexAI.openai("dall-e-3"),
    size: "1024x1024",
    quality: "standard",
    style: "vivid"
  )

  # result.images 包含生成的图像 URL 列表
  Enum.each(result.images, fn image ->
    IO.puts image.url
  end)
"""

IO.puts ""
IO.puts "  [需要有效的 OpenAI API Key 和 DALL-E 配额]"
IO.puts "  支持的模型: dall-e-2, dall-e-3"
IO.puts "  支持的尺寸: dall-e-2 (256x256, 512x512, 1024x1024)"
IO.puts "               dall-e-3 (1024x1024, 1024x1792, 1792x1024)"
