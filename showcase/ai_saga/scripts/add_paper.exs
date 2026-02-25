_ = """
Usage: mix run scripts/add_paper.exs

This script demonstrates how to add a new paper to AiSaga:
1. User provides basic paper information
2. Generate AI prompt
3. User sends prompt to AI (ChatGPT, Claude, etc.)
4. Save AI-generated content to database
"""

# Example: add a new paper
paper_info = %{
  title: "Diffusion Models Beat GANs on Image Synthesis",
  authors: ["Prafulla Dhariwal", "Alex Nichol"],
  year: 2021,
  url: "https://arxiv.org/abs/2105.05233",
  abstract:
    "We show that diffusion models can achieve image sample quality superior to the current state-of-the-art generative models, including GANs. We achieve this by improving the U-Net architecture and introducing classifier guidance.",
  paradigm_id: 5,
  is_paradigm_shift: 1,
  shift_trigger: "Diffusion models surpass GANs as new paradigm for image generation"
}

IO.puts("=" |> String.duplicate(80))
IO.puts("New Paper Information")
IO.puts("=" |> String.duplicate(80))
IO.puts("Title: #{paper_info.title}")
IO.puts("Authors: #{Enum.join(paper_info.authors, ", ")}")
IO.puts("Year: #{paper_info.year}")
IO.puts("Link: #{paper_info.url}")
IO.puts("")

# Generate slug
author_part =
  paper_info.authors |> List.first() |> String.downcase() |> String.split(" ") |> List.last()

keyword =
  paper_info.title
  |> String.downcase()
  |> String.replace(~r/[^a-z0-9\s]/, "")
  |> String.split()
  |> Enum.take(3)
  |> Enum.join("-")

slug = "#{author_part}-#{paper_info.year}-#{keyword}"

# Generate prompt
prompt = """
Please generate detailed three-perspective analysis content for the following AI paper:

Paper Title: #{paper_info.title}
Authors: #{Enum.join(paper_info.authors, ", ")}
Publication Year: #{paper_info.year}
Paper Link: #{paper_info.url}
Abstract: #{paper_info.abstract}

Please generate content in the following format (using Markdown):

## Previous Paradigm
Describe the mainstream methods before this paper appeared:
- Main technology stack (compare components, contributions, problems with a table)
- Challenges at that time

## Core Contributions
- Breakthrough insights (cite key sentences)
- 2-3 core innovations
- One-sentence summary

## Core Mechanism
- Core formula (using code blocks)
- Step-by-step breakdown (using tables)
- Key design components

## Why It Won
- Comparison table with previous methods
- Key advantages

## Challenges Faced at the Time
Briefly describe the core problems faced by the field

## Solution
Briefly describe how the paper solved these problems

## Significant Impact
Briefly describe the impact on the field

## Subsequent Impact
- Paradigm shift table (era, core work, representative work)
- Timeline of subsequent important work

## Author Destinies
- Table listing main authors' subsequent developments
- Notable quotes (if any)

## Historical Background
Describe the historical context and research motivation when the paper was published

Please generate content in Chinese, maintaining academic accuracy.
"""

IO.puts("=" |> String.duplicate(80))
IO.puts("AI Prompt (copy to ChatGPT/Claude)")
IO.puts("=" |> String.duplicate(80))
IO.puts(prompt)
IO.puts("")

IO.puts("=" |> String.duplicate(80))
IO.puts("Suggested URL Slug: #{slug}")
IO.puts("=" |> String.duplicate(80))
IO.puts("")

IO.puts("Usage Instructions:")
IO.puts("1. Copy the above prompt and send to AI (ChatGPT-4, Claude, etc.)")
IO.puts("2. Save AI's response to a file, e.g., #{slug}.md")
IO.puts("3. Run: mix run scripts/insert_paper.exs #{slug} #{slug}.md")
