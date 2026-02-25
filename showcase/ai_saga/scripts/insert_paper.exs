_ = """
Usage: mix run scripts/insert_paper.exs <slug> <markdown_file>

Insert AI-generated paper content into database

Parameters:
  slug - URL identifier (e.g., dhariwal-2021-diffusion)
  markdown_file - Path to AI-generated Markdown file
"""

Nex.Env.init()
NexBase.init(url: Nex.Env.get(:database_url), start: true)

# Parse command line arguments
[slug, markdown_file | _] = System.argv()

IO.puts("Reading file: #{markdown_file}")
content = File.read!(markdown_file)

# Parse Markdown content
# Assume AI returns in fixed format, we need to extract each section
parse_markdown_sections = fn content ->
  content
  |> String.split(~r/\n##\s+/)
  # Drop first empty string
  |> Enum.drop(1)
  |> Enum.map(fn section ->
    [title | lines] = String.split(section, "\n", parts: 2)
    {String.trim(title), String.trim(List.first(lines) || "")}
  end)
  |> Map.new()
end

sections = parse_markdown_sections.(content)

IO.puts("Parsed sections:")
Enum.each(sections, fn {key, _} -> IO.puts("  - #{key}") end)

# Build paper data
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

# Insert to database
NexBase.from("aisaga_papers")
|> NexBase.eq(:slug, slug)
|> NexBase.update(paper_data)
|> NexBase.run()

IO.puts("✅ Paper #{slug} updated in database!")
