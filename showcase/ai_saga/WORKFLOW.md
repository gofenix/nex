# AiSaga Paper Addition Workflow

## Overview

AiSaga supports AI-generated three-lens content for papers. You only need to provide the paper’s basic information, and AI will generate complete historical, paradigm-shift, and human-lens analysis.

## Workflow

### Step 1: Prepare paper information

Edit `scripts/add_paper.exs` and fill in the basic paper information:

```elixir
paper_info = %{
  title: "Paper title",
  authors: ["Author 1", "Author 2"],
  year: 2023,
  url: "https://arxiv.org/abs/xxxx.xxxxx",
  abstract: "Paper abstract",
  paradigm_id: 5,
  is_paradigm_shift: 1,
  shift_trigger: "Description of the paradigm-shift trigger"
}
```

### Step 2: Generate the AI prompt

Run the script to generate the prompt:

```bash
mix run scripts/add_paper.exs
```

Example output:

```
================================================================================
New Paper Information
================================================================================
Title: Diffusion Models Beat GANs on Image Synthesis
Authors: Prafulla Dhariwal, Alex Nichol
Year: 2021
Link: https://arxiv.org/abs/2105.05233

================================================================================
AI Prompt (copy to ChatGPT/Claude)
================================================================================
Please generate detailed three-perspective analysis content for the following AI paper:

Paper Title: Diffusion Models Beat GANs on Image Synthesis
Authors: Prafulla Dhariwal, Alex Nichol
Publication Year: 2021
...

================================================================================
Suggested URL Slug: dhariwal-2021-diffusion
================================================================================
```

### Step 3: Generate content with AI

1. Copy the generated prompt
2. Paste it into ChatGPT-4, Claude, or another AI assistant
3. Wait for the full content to be generated, usually within 30-60 seconds

### Step 4: Save the AI response

Save the AI-generated Markdown content to a file:

```bash
# Create a file and paste the AI-generated content
cat > dhariwal-2021-diffusion.md << 'EOF'
[Paste the AI-generated content here]
EOF
```

Example content format:

```markdown
## Previous Paradigm
**Previous Paradigm: GANs + VAEs**

Before diffusion models, the mainstream paradigm for image generation was:

GANs (Generative Adversarial Networks) + VAEs (Variational Autoencoders)

| Component | Contribution | Problem |
|-----------|--------------|---------|
| **GANs** | High-quality image generation | Unstable training, mode collapse |
| **VAEs** | Stable training | Lower image quality, blur |

**Challenges at the time:**
- GAN training was difficult and required careful hyperparameter tuning
- Models could not cover all data modes
...

## Core Contribution
...
```

### Step 5: Insert into the database

Run the insert script to save the content into the database:

```bash
mix run scripts/insert_paper.exs dhariwal-2021-diffusion dhariwal-2021-diffusion.md
```

### Step 6: Verify

Open the page and verify the result:

```
http://localhost:4000/paper/dhariwal-2021-diffusion
```

## Paradigm ID Reference

| ID | Paradigm Name | Time Range |
|----|---------------|------------|
| 1 | Perceptron and Connectionism | 1957-1969 |
| 2 | Symbolic AI and Expert Systems | 1970-1987 |
| 3 | Statistical Learning and SVM | 1990-2012 |
| 4 | Deep Learning | 2012-2020 |
| 5 | Foundation Models and Transformers | 2017-Present |

## AI Prompt Template

If you do not want to use the script, you can use the following template directly:

```
Please generate detailed three-perspective analysis content for the following AI paper:

Paper Title: [Paper title]
Authors: [Author list]
Publication Year: [Year]
Paper Link: [arXiv link]
Abstract: [Abstract]

Please generate content in the following Markdown format:

## Previous Paradigm
Describe the mainstream methods before this paper, including:
- Main technology stack, using a table to compare components, contributions, and problems
- The main difficulties at the time

## Core Contribution
- Breakthrough insights, citing key sentences
- 2-3 core innovations
- A one-sentence summary

## Core Mechanism
- Core formulas, using code blocks if helpful
- Step-by-step breakdown, using tables if helpful
- Key design components

## Why It Won
- A comparison table with previous methods
- Key advantages

## Challenges at the Time
Briefly describe the core problems faced by the field

## Solution
Briefly describe how the paper solved these problems

## Long-Term Impact
Briefly describe the paper’s impact on the field

## Subsequent Influence
- A paradigm transition table, such as era, core idea, and representative work
- A timeline of important subsequent work

## Author Trajectories
- A table of the main authors’ subsequent developments
- Notable quotes, if any

## Historical Context
Describe the historical background and research motivation at the time of publication

Please generate the result in English and keep it academically accurate.
```

## Notes

1. **AI quality**: Use ChatGPT-4 or Claude-3.5-Sonnet or stronger models when possible
2. **Human review**: AI-generated content may still need review and light editing
3. **Academic accuracy**: Verify important facts, especially author trajectories and subsequent influence
4. **Images**: AI does not generate images here; add them manually if needed

## Batch Addition

If you need to add multiple papers in bulk, you can:

1. Create a paper list file
2. Write a loop script to process them automatically
3. Or use an AI tool's batch-processing workflow

Example bulk script approach:
```elixir
papers = [
  %{title: "...", authors: [...], ...},
  %{title: "...", authors: [...], ...},
  # ...
]

Enum.each(papers, fn paper ->
  prompt = generate_prompt(paper)
  # Call the AI API to generate content
  # Save to the database
end)
```

## File Structure

```
ai_saga/
├── scripts/
│   ├── add_paper.exs      # Generate the AI prompt
│   └── insert_paper.exs   # Insert into the database
├── priv/repo/
│   └── seeds_all_papers.exs  # Existing 10-paper dataset
└── WORKFLOW.md            # This document
```

## Example

The existing 10 papers were all produced with this workflow. You can refer to:
- Transformer (2017)
- BERT (2018)
- GPT-3 (2020)
- ...

See `priv/repo/seeds_all_papers.exs` for the exact format.
