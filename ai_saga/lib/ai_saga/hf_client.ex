defmodule AiSaga.HFClient do
  @moduledoc """
  HuggingFace Papers API客户端
  获取大模型领域的热门论文
  """

  @base_url "https://huggingface.co/api/daily_papers"

  @doc """
  获取热门论文列表
  """
  def get_trending_papers(limit \\ 20) do
    url = "#{@base_url}?limit=#{limit}"

    case Req.get(url) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, parse_papers(body)}

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  获取特定日期的论文
  """
  def get_papers_by_date(date, limit \\ 20) do
    url = "#{@base_url}?date=#{date}&limit=#{limit}"

    case Req.get(url) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, parse_papers(body)}

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  获取论文详情（含影响力分数）
  """
  def get_paper_details(arxiv_id) do
    # 从daily_papers列表中查找
    case get_trending_papers(100) do
      {:ok, papers} ->
        paper = Enum.find(papers, fn p -> p.id == arxiv_id end)
        if paper, do: {:ok, paper}, else: {:error, "Paper not found"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # 解析论文列表
  defp parse_papers(body) when is_list(body) do
    Enum.map(body, &parse_paper/1)
  end

  defp parse_papers(_), do: []

  # 解析单篇论文 - 新API格式包含嵌套的paper字段
  defp parse_paper(item) when is_map(item) do
    # 新API返回的格式: %{"paper" => %{...}, "publishedAt" => ..., ...}
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

  # 提取作者名称列表
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

  # 解析论文详情
  defp parse_paper_detail(paper) do
    parse_paper(paper)
  end
end
