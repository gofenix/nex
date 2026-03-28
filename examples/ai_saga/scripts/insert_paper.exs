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
  prev_paradigm: sections["Previous Paradigm"],
  core_contribution: sections["Core Contribution"],
  core_mechanism: sections["Core Mechanism"],
  why_it_wins: sections["Why It Won"],
  challenge: sections["Challenges at the Time"],
  solution: sections["Solution"],
  impact: sections["Long-Term Impact"],
  subsequent_impact: sections["Subsequent Influence"],
  author_destinies: sections["Author Trajectories"],
  history_context: sections["Historical Context"]
}

# Insert to database
NexBase.from("aisaga_papers")
|> NexBase.eq(:slug, slug)
|> NexBase.update(paper_data)
|> NexBase.run()

IO.puts("✅ Paper #{slug} updated in database!")
