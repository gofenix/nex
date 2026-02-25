defmodule AiSaga.HFClient do
  @moduledoc """
  HuggingFace Papers API client
  Fetches trending papers in the AI/LLM domain
  """

  @base_url "https://huggingface.co/api/daily_papers"

  @doc """
  Get trending papers list
  """
  def get_trending_papers(limit \\ 20) do
    url = "#{@base_url}?limit=#{limit}"

    case Req.get(url, receive_timeout: 30_000) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, parse_papers(body)}

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get papers for a specific date
  """
  def get_papers_by_date(date, limit \\ 20) do
    url = "#{@base_url}?date=#{date}&limit=#{limit}"

    case Req.get(url, receive_timeout: 30_000) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, parse_papers(body)}

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get paper details (including influence score)
  """
  def get_paper_details(arxiv_id) do
    # Look up from daily_papers list
    case get_trending_papers(100) do
      {:ok, papers} ->
        case Enum.find(papers, fn p -> p.id == arxiv_id end) do
          nil ->
            # If not found in HuggingFace, return default data
            {:ok,
             %{
               id: arxiv_id,
               title: "",
               authors: [],
               published_at: "",
               influence_score: 0,
               discussion_count: 0
             }}

          paper ->
            {:ok, paper}
        end

      {:error, _reason} ->
        # Return default data when HuggingFace API fails
        {:ok,
         %{
           id: arxiv_id,
           title: "",
           authors: [],
           published_at: "",
           influence_score: 0,
           discussion_count: 0
         }}
    end
  end

  # Parse paper list
  defp parse_papers(body) when is_list(body) do
    Enum.map(body, &parse_paper/1)
  end

  defp parse_papers(_), do: []

  # Parse single paper - new API format includes nested paper field
  defp parse_paper(item) when is_map(item) do
    # New API returns: %{"paper" => %{...}, "publishedAt" => ..., ...}
    paper_data = item["paper"] || item

    %{
      id: paper_data["id"],
      title: paper_data["title"],
      authors: extract_authors(paper_data["authors"]),
      published_at: item["publishedAt"] || paper_data["publishedAt"],
      abstract: paper_data["summary"] || item["summary"],
      tags: paper_data["ai_keywords"] || [],
      influence_score: item["upvotes"] || 0,
      citations_count: 0,
      github_stars: paper_data["githubStars"] || 0,
      discussion_count: item["numComments"] || 0
    }
  end

  # Extract author name list
  defp extract_authors(nil), do: []

  defp extract_authors(authors) when is_list(authors) do
    Enum.map(authors, fn author ->
      case author do
        %{"name" => name} -> name
        name when is_binary(name) -> name
        _ -> "Unknown"
      end
    end)
  end

  defp extract_authors(_), do: []
end
