# 示例 25: 文本嵌入
# 对应 vendor/ai/examples/ai-core/src/embed/

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)

if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

IO.puts "🚀 示例 25: 文本嵌入"
IO.puts "----------------------------------------"

texts = [
  "The quick brown fox jumps over the lazy dog",
  "A fast brown fox leaps over a sleeping dog",
  "I love programming in Elixir"
]

IO.puts "\n生成嵌入向量..."

case NexAI.Provider.OpenAI.embed_many(
  texts,
  model_id: "text-embedding-3-small"
) do
  {:ok, result} ->
    IO.puts "\n✅ 嵌入生成成功!"
    IO.puts "\n嵌入向量维度: #{length(hd(result.embeddings))}"
    IO.puts "嵌入数量: #{length(result.embeddings)}"
    IO.puts "\n📊 Usage:"
    IO.inspect(result.usage)

    IO.puts "\n📏 相似度计算:"
    Enum.with_index(texts, fn text, i ->
      IO.puts "\n[#{i + 1}] #{String.slice(text, 0, 50)}..."
    end)

    # 计算第一个和第二个文本的相似度
    vec1 = Enum.at(result.embeddings, 0)
    vec2 = Enum.at(result.embeddings, 1)
    similarity = NexAI.cosine_similarity(vec1, vec2)
    IO.puts "\n文本 1 和 2 的余弦相似度: #{Float.round(similarity, 4)}"

  {:error, reason} ->
    IO.puts "❌ Error: #{inspect(reason)}"
end
