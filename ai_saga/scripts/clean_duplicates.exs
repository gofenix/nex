# 清理重复论文的脚本
# 运行: cd ai_saga && elixir scripts/clean_duplicates.exs

# 使用 NexBase 查询和删除重复论文
# 保留每个 arxiv_id 最早创建的记录

# 查找所有重复的 arxiv_id（排除 null）
{:ok, duplicates} = NexBase.sql("""
  SELECT arxiv_id, COUNT(*) as count
  FROM papers
  WHERE arxiv_id IS NOT NULL
  GROUP BY arxiv_id
  HAVING COUNT(*) > 1
""", [])

IO.puts("找到 #{length(duplicates)} 个重复的 arxiv_id\n")

Enum.each(duplicates, fn dup ->
  arxiv_id = dup["arxiv_id"]
  count = dup["count"]

  # 跳过 null 值
  if is_nil(arxiv_id) do
    IO.puts("跳过 null arxiv_id")
  else
    IO.puts("处理: #{arxiv_id} (共 #{count} 条)")

    # 获取该 arxiv_id 的所有记录
    {:ok, papers} = NexBase.sql("""
      SELECT id, slug, created_at
      FROM papers
      WHERE arxiv_id = $1
      ORDER BY created_at ASC
    """, [arxiv_id])

    # 保留第一条，删除其他的
    [keep | to_delete] = papers

    IO.puts("  保留: id=#{keep["id"]}, slug=#{keep["slug"]}")

    Enum.each(to_delete, fn paper ->
      id = paper["id"]
      IO.puts("  删除: id=#{id}, slug=#{paper["slug"]}")

      # 先删除 paper_authors 关联
      {:ok, _} = NexBase.sql("DELETE FROM paper_authors WHERE paper_id = $1", [id])

      # 再删除论文
      {:ok, _} = NexBase.sql("DELETE FROM papers WHERE id = $1", [id])
    end)

    IO.puts("")
  end
end)

IO.puts("✅ 清理完成！")
