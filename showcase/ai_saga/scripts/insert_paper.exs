_ = """
 Usage: mix run scripts/insert_paper.exs <slug> <markdown_file>

 将AI生成的论文内容插入数据库

 参数:
   slug - URL标识（如：dhariwal-2021-diffusion）
   markdown_file - AI生成的Markdown文件路径
"""

Nex.Env.init()
NexBase.init(url: Nex.Env.get(:database_url), start: true)

# 解析命令行参数
[slug, markdown_file | _] = System.argv()

IO.puts("读取文件: #{markdown_file}")
content = File.read!(markdown_file)

# 解析Markdown内容
# 假设AI按照固定格式返回，我们需要提取各个部分
parse_markdown_sections = fn content ->
  content
  |> String.split(~r/\n##\s+/)
  |> Enum.drop(1)  # 去掉第一个空字符串
  |> Enum.map(fn section ->
    [title | lines] = String.split(section, "\n", parts: 2)
    {String.trim(title), String.trim(List.first(lines) || "")}
  end)
  |> Map.new()
end

sections = parse_markdown_sections.(content)

IO.puts("解析到以下部分:")
Enum.each(sections, fn {key, _} -> IO.puts("  - #{key}") end)

# 构建论文数据
paper_data = %{
  slug: slug,
  prev_paradigm: sections["上一个范式"],
  core_contribution: sections["核心贡献"],
  core_mechanism: sections["核心机制"],
  why_it_wins: sections["为什么赢了"],
  challenge: sections["当时面临的挑战"],
  solution: sections["解决方案"],
  impact: sections["深远影响"],
  subsequent_impact: sections["后续影响"],
  author_destinies: sections["作者去向"],
  history_context: sections["历史背景"]
}

# 插入数据库
NexBase.from("aisaga_papers")
|> NexBase.eq(:slug, slug)
|> NexBase.update(paper_data)
|> NexBase.run()

IO.puts("✅ 论文 #{slug} 已更新到数据库！")
