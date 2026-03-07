# Detailed Paper Data Template

Organize each paper using three major analytical lenses.

## Basic Information
- `title`: Paper title
- `slug`: URL-friendly identifier
- `abstract`: English abstract or summary
- `arxiv_id`: arXiv ID
- `published_year`: Publication year
- `published_month`: Publication month
- `url`: Paper URL
- `categories`: Paper categories
- `citations`: Citation count
- `paradigm_id`: Related paradigm ID
- `is_paradigm_shift`: Whether it marks a paradigm shift (`1` or `0`)
- `shift_trigger`: Description of the paradigm-shift trigger

## I. Historical Lens

### `prev_paradigm` (Previous Paradigm)
Describe the paradigm before this paper appeared:
- Main technology stack
- Contributions and problems of each component
- The key difficulties of the time

Example format:

```markdown
**Previous Paradigm: XXX + YYY + ZZZ**

Before XXX, the mainstream paradigm for ... was:

| Component | Contribution | Problem |
|-----------|--------------|---------|
| **XXX** | ... | ... |
| **YYY** | ... | ... |

**Challenges of the alternatives:**
- Strengths: ...
- Weaknesses: ...
```

### `core_contribution` (Core Contribution)
Describe the paper’s core breakthroughs:
- Key insights, including important original wording when helpful
- Three core innovations
- A one-sentence summary

### `core_mechanism` (Core Mechanism)
Describe the technical implementation details:
- Core formulas
- Step-by-step tables
- Key design components

### `why_it_wins` (Why It Won)
Explain why the work succeeded:
- Comparison tables with previous methods
- Hardware-friendliness analysis
- How it laid the foundation for scaling

## II. Paradigm Shift Lens

### `challenge` (Challenges at the Time)
Briefly describe the core problems the field faced.

### `solution` (Solution)
Briefly describe how the paper addressed those problems.

### `impact` (Long-Term Impact)
Briefly describe the paper’s impact on the field.

## III. Human Lens

### `author_destinies` (Author Trajectories)
List the major authors’ later developments in table form:

```markdown
| Author | Later Development |
|--------|-------------------|
| **Name** | Destination / achievement |
```

You can also include notable quotes.

## IV. Subsequent Influence

### `subsequent_impact` (Subsequent Influence)
- Paradigm transition tables
- Timelines of important later work
- Impact on different subfields

## V. Historical Context

### `history_context` (Historical Context)
Describe the background at the time of publication:
- The state of technology
- Team composition
- Research motivation

---

## Example: Transformer

See `/priv/repo/seeds_transformer.exs` for a complete example filled out using this template.

When adding a new paper:
1. Copy `seeds_transformer.exs`
2. Fill in the content using this template
3. Run `mix run priv/repo/seeds_xxx.exs`
