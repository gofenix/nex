# 示例 15: 文本嵌入 (Embeddings)
# 运行方式: mix run examples/15_embed.exs

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)
if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

IO.puts "\n#{String.duplicate("=", 60)}"
IO.puts "示例 15: 文本嵌入 (Embeddings)"
IO.puts "#{String.duplicate("=", 60)}\n"

IO.puts "使用 Embeddings API 将文本转换为向量:\n"

IO.puts "代码示例:"
IO.puts """
  # 单文本嵌入
  {:ok, result} = NexAI.embed(
    value: "Hello world",
    model: NexAI.openai("text-embedding-3-small")
  )

  # result.embedding 是 1536 维向量
  vec = result.embedding

  # 批量嵌入
  {:ok, result} = NexAI.embed_many(
    values: ["Hello", "World", "Elixir"],
    model: NexAI.openai("text-embedding-3-small")
  )

  # result.embeddings 是向量列表
  vectors = result.embeddings

  # 计算余弦相似度
  similarity = NexAI.cosine_similarity(vec1, vec2)
  # 返回 -1 到 1，值越大表示越相似
"""

IO.puts ""
IO.puts "  [Embeddings API 需要有效的 OpenAI API Key]"
IO.puts "  支持的模型: text-embedding-3-small, text-embedding-3-large, text-embedding-ada-002"
