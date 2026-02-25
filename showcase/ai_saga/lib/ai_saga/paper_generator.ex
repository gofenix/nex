defmodule AiSaga.PaperGenerator do
  @moduledoc """
  Paper generation coordinator
  Coordinates clients to complete paper recommendation and generation
  """

  alias AiSaga.{HFClient, ArxivClient, OpenAIClient}

  @doc """
  Complete flow to generate and save a new paper
  """
  def generate_and_save do
    with {:ok, papers_summary} <- get_papers_summary(),
         {:ok, hf_candidates} <- HFClient.get_trending_papers(20),
         {:ok, recommendation} <- OpenAIClient.recommend_paper(papers_summary, hf_candidates),
         {:ok, arxiv_papers} <- ArxivClient.get_paper_by_id(recommendation.arxiv_id),
         new_paper = List.first(arxiv_papers),
         {:ok, hf_data} <- HFClient.get_paper_details(recommendation.arxiv_id),
         {:ok, relevant_papers} <- get_relevant_papers(new_paper.published),
         {:ok, analysis} <- OpenAIClient.generate_analysis(relevant_papers, new_paper, hf_data),
         {:ok, slug} <- save_paper(new_paper, analysis, recommendation) do
      {:ok, %{slug: slug, title: new_paper.title, reason: recommendation.reason}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get papers summary statistics (fixed size, doesn't grow with paper count)
  """
  def get_papers_summary do
    # Get all paradigms
    {:ok, paradigms} =
      NexBase.from("aisaga_paradigms")
      |> NexBase.order(:start_year, :asc)
      |> NexBase.run()

    # Fetch all papers with key fields in one query (avoid N+1)
    {:ok, all_papers} =
      NexBase.from("aisaga_papers")
      |> NexBase.select([:published_year, :arxiv_id, :title, :paradigm_id])
      |> NexBase.order(:published_year, :asc)
      |> NexBase.run()

    # Group by paradigm and calculate statistics
    papers_by_paradigm = Enum.group_by(all_papers, & &1["paradigm_id"])

    paradigm_summaries =
      Enum.map(paradigms, fn paradigm ->
        papers = Map.get(papers_by_paradigm, paradigm["id"], [])

        representatives =
          papers
          |> Enum.take(2)
          |> Enum.map(fn p -> "#{p["published_year"]}#{p["title"]}" end)

        %{
          name: paradigm["name"],
          start_year: paradigm["start_year"],
          end_year: paradigm["end_year"],
          count: length(papers),
          representatives: representatives
        }
      end)

    years = Enum.map(all_papers, & &1["published_year"])

    # Collect all existing arXiv IDs (filter out nil)
    existing_arxiv_ids =
      all_papers
      |> Enum.map(& &1["arxiv_id"])
      |> Enum.filter(&(&1 != nil))

    # Collect all existing paper titles
    existing_titles =
      all_papers
      |> Enum.map(fn p -> "#{p["published_year"]}: #{p["title"]}" end)

    summary = %{
      paradigm_summaries: paradigm_summaries,
      years: years,
      total_count: length(all_papers),
      existing_arxiv_ids: existing_arxiv_ids,
      existing_titles: existing_titles
    }

    {:ok, summary}
  end

  @doc """
  Get papers relevant to the new paper (previous and subsequent years)
  """
  def get_relevant_papers(published_date) do
    year = String.slice(published_date, 0, 4) |> String.to_integer()

    # Get papers from 3 years before and after
    {:ok, papers} =
      NexBase.from("aisaga_papers")
      |> NexBase.gte(:published_year, year - 3)
      |> NexBase.lte(:published_year, year + 3)
      |> NexBase.order(:published_year, :asc)
      |> NexBase.run()

    # Fetch all needed paradigms in one query (avoid N+1)
    paradigm_ids = papers |> Enum.map(& &1["paradigm_id"]) |> Enum.uniq()

    {:ok, paradigms} =
      if length(paradigm_ids) > 0 do
        NexBase.from("aisaga_paradigms")
        |> NexBase.in_list(:id, paradigm_ids)
        |> NexBase.run()
      else
        {:ok, []}
      end

    paradigm_map = Map.new(paradigms, fn p -> {p["id"], p} end)

    papers_with_paradigm =
      Enum.map(papers, fn paper ->
        paradigm = Map.get(paradigm_map, paper["paradigm_id"], %{})
        Map.put(paper, "paradigm", paradigm)
      end)

    {:ok, papers_with_paradigm}
  end

  @doc """
  Save paper to database
  """
  def save_paper(arxiv_paper, analysis, recommendation) do
    # Normalize new paper title
    normalized_new_title = normalize_title(arxiv_paper.title)

    # Get all existing paper titles
    {:ok, existing_papers} =
      NexBase.from("aisaga_papers")
      |> NexBase.select([:title, :slug])
      |> NexBase.run()

    # Check for duplicate title (compare after normalization)
    duplicate =
      Enum.find(existing_papers, fn p ->
        normalize_title(p["title"]) == normalized_new_title
      end)

    if duplicate do
      # Found duplicate, return error
      {:error, "Paper already exists: #{duplicate["slug"]}"}
    else
      # No duplicate, proceed with insert
      # Generate slug
      author_part =
        List.first(arxiv_paper.authors) |> String.downcase() |> String.split(" ") |> List.last()

      year = String.slice(arxiv_paper.published, 0, 4)
      keyword = extract_keyword(arxiv_paper.title)
      base_slug = "#{author_part}-#{year}-#{keyword}"
      slug = ensure_unique_slug(base_slug)

      # Determine paradigm ID
      paradigm_id = infer_paradigm_id(year)

      # Build paper data
      paper_data = %{
        title: arxiv_paper.title,
        slug: slug,
        abstract: analysis.chinese_abstract || arxiv_paper.abstract,
        arxiv_id: recommendation.arxiv_id,
        published_year: String.to_integer(year),
        published_month: String.slice(arxiv_paper.published, 5, 2) |> String.to_integer(),
        url: arxiv_paper.pdf_url || "https://arxiv.org/abs/#{recommendation.arxiv_id}",
        categories: Enum.join(arxiv_paper.categories, ","),
        citations: 0,
        paradigm_id: paradigm_id,
        is_paradigm_shift: 0,
        shift_trigger: nil,

        # Three-perspective content
        prev_paradigm: analysis.prev_paradigm,
        core_contribution: analysis.core_contribution,
        core_mechanism: analysis.core_mechanism,
        why_it_wins: analysis.why_it_wins,
        challenge: analysis.challenge,
        solution: analysis.solution,
        impact: analysis.impact,
        subsequent_impact: analysis.subsequent_impact,
        author_destinies: analysis.author_destinies,
        history_context: analysis.history_context
      }

      with {:ok, _} <- NexBase.from("papers") |> NexBase.insert(paper_data) |> NexBase.run(),
           {:ok, inserted} <- get_paper_by_slug(slug),
           :ok <- insert_paper_authors(inserted["id"], arxiv_paper.authors) do
        {:ok, slug}
      else
        {:error, reason} -> {:error, reason}
      end
    end
  end

  # Extract keywords from title
  defp extract_keyword(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s]/, "")
    |> String.split()
    |> Enum.take(3)
    |> Enum.join("-")
  end

  # Ensure slug uniqueness
  defp ensure_unique_slug(base_slug, suffix \\ 0) do
    candidate = if suffix == 0, do: base_slug, else: "#{base_slug}-#{suffix}"

    case NexBase.from("papers")
         |> NexBase.eq(:slug, candidate)
         |> NexBase.single()
         |> NexBase.run() do
      {:ok, []} -> candidate
      {:ok, [_paper]} -> ensure_unique_slug(base_slug, suffix + 1)
      {:error, _} -> candidate
    end
  end

  # Infer paradigm ID from year
  defp infer_paradigm_id(year) do
    year_int = String.to_integer(year)

    # Dynamically fetch paradigms from DB and match by year range
    {:ok, paradigms} =
      NexBase.from("aisaga_paradigms")
      |> NexBase.order(:start_year, :asc)
      |> NexBase.run()

    # Find matching paradigm: published_year >= start_year AND (no end_year OR <= end_year)
    matching =
      Enum.find(paradigms, fn p ->
        start_year = p["start_year"] || 0
        end_year = p["end_year"]

        year_int >= start_year && (is_nil(end_year) || year_int <= end_year)
      end)

    case matching do
      nil ->
        # If no match, return the newest paradigm (last one)
        List.last(paradigms)["id"]

      paradigm ->
        paradigm["id"]
    end
  end

  # Find or create author
  defp find_or_create_author(name) do
    slug = name |> String.downcase() |> String.replace(" ", "-")

    case NexBase.from("aisaga_authors")
         |> NexBase.eq(:slug, slug)
         |> NexBase.single()
         |> NexBase.run() do
      {:ok, [author]} ->
        {:ok, author["id"]}

      {:ok, []} ->
        insert_author(name, slug)

      _ ->
        insert_author(name, slug)
    end
  end

  defp get_paper_by_slug(slug) do
    case NexBase.from("papers") |> NexBase.eq(:slug, slug) |> NexBase.single() |> NexBase.run() do
      {:ok, [paper]} -> {:ok, paper}
      {:ok, []} -> {:error, "paper insert succeeded but paper lookup failed"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp insert_paper_authors(paper_id, authors) do
    Enum.reduce_while(Enum.with_index(authors), :ok, fn {author_name, index}, _acc ->
      with {:ok, author_id} <- find_or_create_author(author_name),
           {:ok, _} <-
             NexBase.from("aisaga_paper_authors")
             |> NexBase.insert(%{
               paper_id: paper_id,
               author_id: author_id,
               author_order: index + 1
             })
             |> NexBase.run() do
        {:cont, :ok}
      else
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp insert_author(name, slug) do
    with {:ok, _} <-
           NexBase.from("authors")
           |> NexBase.insert(%{
             name: name,
             slug: slug,
             bio: "TBD",
             affiliation: "TBD",
             influence_score: 50
           })
           |> NexBase.run(),
         {:ok, [inserted]} <-
           NexBase.from("authors")
           |> NexBase.eq(:slug, slug)
           |> NexBase.single()
           |> NexBase.run() do
      {:ok, inserted["id"]}
    else
      {:ok, []} -> {:error, "author insert succeeded but author lookup failed"}
      {:error, reason} -> {:error, reason}
    end
  end

  # Normalize paper title (for deduplication comparison)
  defp normalize_title(title) do
    title
    |> String.downcase()
    # Remove punctuation
    |> String.replace(~r/[^\p{L}\p{N}\s]/u, "")
    # Merge multiple spaces into one
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
