defmodule AiSaga.PaperGenerator do
  @moduledoc """
  论文生成协调器
  协调各个客户端完成论文推荐和生成
  """

  alias AiSaga.{HFClient, ArxivClient, OpenAIClient}

  @doc """
  生成新论文的完整流程
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
  获取论文统计摘要（固定大小，不随论文数量增长）
  """
  def get_papers_summary do
    # 获取所有范式
    {:ok, paradigms} = NexBase.from("paradigms")
    |> NexBase.order(:start_year, :asc)
    |> NexBase.run()

    # 获取每范式的论文数量和代表性工作
    paradigm_summaries = Enum.map(paradigms, fn paradigm ->
      {:ok, papers} = NexBase.from("papers")
      |> NexBase.eq(:paradigm_id, paradigm["id"])
      |> NexBase.order(:published_year, :asc)
      |> NexBase.run()

      count = length(papers)

      # 每范式取1-2篇代表性工作
      representatives = papers
      |> Enum.take(2)
      |> Enum.map(fn p -> "#{p["published_year"]}#{p["title"]}" end)

      %{
        name: paradigm["name"],
        start_year: paradigm["start_year"],
        end_year: paradigm["end_year"],
        count: count,
        representatives: representatives
      }
    end)

    # 获取年份范围
    {:ok, all_papers} = NexBase.from("papers")
    |> NexBase.select([:published_year])
    |> NexBase.order(:published_year, :asc)
    |> NexBase.run()

    years = Enum.map(all_papers, & &1["published_year"])

    summary = %{
      paradigm_summaries: paradigm_summaries,
      years: years,
      total_count: length(all_papers)
    }

    {:ok, summary}
  end

  @doc """
  获取与新论文相关的论文（前后几年）
  """
  def get_relevant_papers(published_date) do
    year = String.slice(published_date, 0, 4) |> String.to_integer()

    # 获取前后3年的论文
    {:ok, papers} = NexBase.from("papers")
    |> NexBase.gte(:published_year, year - 3)
    |> NexBase.lte(:published_year, year + 3)
    |> NexBase.order(:published_year, :asc)
    |> NexBase.run()

    # 添加范式信息
    papers_with_paradigm = Enum.map(papers, fn paper ->
      {:ok, [paradigm]} = NexBase.from("paradigms")
      |> NexBase.eq(:id, paper["paradigm_id"])
      |> NexBase.single()
      |> NexBase.run()

      Map.put(paper, "paradigm", paradigm)
    end)

    {:ok, papers_with_paradigm}
  end

  @doc """
  保存论文到数据库
  """
  def save_paper(arxiv_paper, analysis, recommendation) do
    # 生成slug
    author_part = List.first(arxiv_paper.authors) |> String.downcase() |> String.split(" ") |> List.last()
    year = String.slice(arxiv_paper.published, 0, 4)
    keyword = extract_keyword(arxiv_paper.title)
    slug = "#{author_part}-#{year}-#{keyword}"

    # 确定范式ID
    paradigm_id = infer_paradigm_id(year)

    # 构建论文数据
    paper_data = %{
      title: arxiv_paper.title,
      slug: slug,
      abstract: arxiv_paper.abstract,
      arxiv_id: recommendation.arxiv_id,
      published_year: String.to_integer(year),
      published_month: String.slice(arxiv_paper.published, 5, 2) |> String.to_integer(),
      url: arxiv_paper.pdf_url || "https://arxiv.org/abs/#{recommendation.arxiv_id}",
      categories: Enum.join(arxiv_paper.categories, ","),
      citations: 0,
      paradigm_id: paradigm_id,
      is_paradigm_shift: 0,
      shift_trigger: nil,

      # 三视角内容
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

    # 插入论文
    {:ok, [inserted]} = NexBase.from("papers")
    |> NexBase.insert(paper_data)
    |> NexBase.run()

    # 插入作者关系
    Enum.each(Enum.with_index(arxiv_paper.authors), fn {author_name, index} ->
      author_id = find_or_create_author(author_name)

      NexBase.from("paper_authors")
      |> NexBase.insert(%{
        paper_id: inserted["id"],
        author_id: author_id,
        author_order: index + 1
      })
      |> NexBase.run()
    end)

    {:ok, slug}
  end

  # 从标题提取关键词
  defp extract_keyword(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s]/, "")
    |> String.split()
    |> Enum.take(3)
    |> Enum.join("-")
  end

  # 根据年份推断范式ID
  defp infer_paradigm_id(year) do
    year_int = String.to_integer(year)
    cond do
      year_int < 1970 -> 1
      year_int < 1990 -> 2
      year_int < 2012 -> 3
      year_int < 2017 -> 4
      true -> 5
    end
  end

  # 查找或创建作者
  defp find_or_create_author(name) do
    slug = name |> String.downcase() |> String.replace(" ", "-")

    case NexBase.from("authors") |> NexBase.eq(:slug, slug) |> NexBase.single() |> NexBase.run() do
      {:ok, [author]} ->
        author["id"]

      _ ->
        {:ok, [inserted]} = NexBase.from("authors")
        |> NexBase.insert(%{
          name: name,
          slug: slug,
          bio: "待补充",
          affiliation: "待补充",
          influence_score: 50
        })
        |> NexBase.run()

        inserted["id"]
    end
  end
end
