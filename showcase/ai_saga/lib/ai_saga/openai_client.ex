defmodule AiSaga.OpenAIClient do
  @moduledoc """
  OpenAI API client
  Used for paper recommendations and generating three-perspective analysis
  """

  defp model, do: System.get_env("OPENAI_MODEL") || "gpt-4o"
  defp base_url, do: System.get_env("OPENAI_BASE_URL") || "https://api.openai.com/v1"

  @doc """
  Recommend next paper based on papers summary
  """
  def recommend_paper(papers_summary, hf_candidates) do
    # First filter out already existing papers
    existing_ids = papers_summary.existing_arxiv_ids || []

    filtered_candidates =
      Enum.reject(hf_candidates, fn c ->
        clean_arxiv_id(c.id) in existing_ids
      end)

    # Use unified recommendation prompt
    prompt = build_recommendation_prompt(papers_summary, filtered_candidates)

    with {:ok, response} <- call_openai(prompt),
         recommendation = parse_recommendation(response),
         recommendation = normalize_recommendation(recommendation, filtered_candidates, response) do
      if recommendation.arxiv_id in existing_ids do
        # AI still recommended an existing paper, return error
        {:error, "AI recommended existing paper: #{recommendation.arxiv_id}"}
      else
        {:ok, recommendation}
      end
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Generate three-perspective analysis for a paper
  """
  def generate_analysis(relevant_papers, new_paper, hf_data) do
    prompt = build_analysis_prompt(relevant_papers, new_paper, hf_data)

    case call_openai(prompt) do
      {:ok, response} ->
        {:ok, parse_analysis(response)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Build recommendation prompt (handles both HuggingFace candidates and classic papers)
  # Note: hf_candidates should already be filtered to exclude existing papers
  defp build_recommendation_prompt(papers_summary, filtered_candidates) do
    # Build paradigm summary string
    paradigm_str =
      Enum.map_join(papers_summary.paradigm_summaries, "\n", fn p ->
        status = if p.count == 0, do: "⚠️ Empty", else: "#{p.count} papers"
        "- #{p.name} (#{p.start_year}-#{p.end_year || "present"}): #{status}"
      end)

    # Build existing papers arXiv ID list
    existing_ids_str =
      if length(papers_summary.existing_arxiv_ids) > 0 do
        papers_summary.existing_arxiv_ids
        |> Enum.join(", ")
      else
        "None"
      end

    # Build existing papers title list
    existing_titles_str =
      if Map.has_key?(papers_summary, :existing_titles) and
           length(papers_summary.existing_titles) > 0 do
        Enum.join(papers_summary.existing_titles, "\n")
      else
        "None"
      end

    # Build HuggingFace candidates list (already filtered, may be empty)
    candidates_str =
      if length(filtered_candidates) > 0 do
        Enum.map_join(filtered_candidates, "\n", fn p ->
          "- #{p.title} (#{p.published_at})\n  arXiv ID: #{p.id}\n  Authors: #{Enum.join(p.authors, ", ")}\n  Influence: #{p.influence_score}"
        end)
      else
        "(No new candidates)"
      end

    """
    You are an AI history expert. Based on our current paper collection, recommend the next important paper to add.

    【Our Paper Distribution】(Total: #{papers_summary.total_count} papers)
    #{paradigm_str}

    【Existing Papers】
    #{existing_titles_str}

    【Existing arXiv IDs】
    #{existing_ids_str}

    ⚠️ Important: DO NOT recommend any of the above papers! You must recommend a brand new paper not in the list.

    【HuggingFace Trending Candidates】
    #{candidates_str}

    【Recommendation Strategy】
    1. Prioritize recommending from HuggingFace candidates (if available)
    2. If candidates are empty or already added, recommend classic papers from AI history, including but not limited to:
       - Transformer architectures and variants
       - Pretrained language models (BERT, GPT series, LLaMA, etc.)
       - Computer vision classics (ResNet, VGG, AlexNet, YOLO, etc.)
       - Optimization and training techniques (Adam, Batch Normalization, Dropout, etc.)
       - Reinforcement learning milestones (DQN, AlphaGo, PPO, etc.)

    Please think from these perspectives:
    1. Historical perspective: Which paradigms are missing? What important nodes are there on the timeline?
    2. Paradigm shift: Which papers can fill gaps or drive paradigm evolution?
    3. Diversity: Consider important works from different schools, regions, and institutions

    Please recommend 1 paper in the following format:
    Title: [paper title]
    Authors: [main authors]
    Year: [publication year]
    arXiv ID: [e.g. 1706.03762, must be valid arXiv ID]
    Reason: [why recommend this? How does it fill gaps or drive history?]
    """
  end

  # Build analysis prompt (uses relevant papers, not all)
  defp build_analysis_prompt(relevant_papers, new_paper, hf_data) do
    # Build relevant papers string
    existing_str =
      Enum.map_join(relevant_papers, "\n", fn p ->
        "- #{p["published_year"]}: #{p["title"]} [#{p["paradigm"]["name"]}]"
      end)

    hf_str =
      if hf_data do
        "Influence Score: #{hf_data.influence_score}\nCommunity Discussion: #{hf_data.discussion_count}"
      else
        "No HuggingFace data"
      end

    """
    Please generate detailed three-perspective analysis content for the following paper.

    【Relevant Papers Context】(previous and subsequent years)
    #{existing_str}

    【New Paper Information】
    Title: #{new_paper.title}
    Authors: #{Enum.join(new_paper.authors, ", ")}
    Year: #{new_paper.published}
    English Abstract: #{new_paper.abstract}

    【HuggingFace Data】
    #{hf_str}

    Please generate content in the following format (all in Chinese, keep it academic and accurate but concise):

    ## 中文摘要
    Translate the English abstract into a 100-150 word Chinese academic summary, briefly summarizing core contributions.

    ## 上一个范式
    Describe the mainstream methods before this paper, with table comparison and list of dilemmas.

    ## 核心贡献
    List 2-3 core innovations, with one-sentence summary.

    ## 核心机制
    Core algorithm and key steps, can use code blocks or tables.

    ## 为什么赢了
    Comparison table with previous methods (3 dimensions).

    ## 当时面临的挑战
    Core problems faced by the field (2-3 points).

    ## 解决方案
    How the paper solves these (technical key points).

    ## 深远影响
    Specific changes and impact on the field.

    ## 后续影响
    Subsequent important works and timeline.

    ## 作者去向
    Main authors' subsequent developments (table).

    ## 历史背景
    Historical background when the paper was published (~100 words).

    Important notes:
    1. All content in Chinese
    2. Concise but professional, don't be overly verbose
    3. Use tables and lists to organize information
    """
  end

  # Call OpenAI API
  defp call_openai(prompt) do
    api_key = System.get_env("OPENAI_API_KEY")

    if is_nil(api_key) do
      {:error, "OPENAI_API_KEY not set"}
    else
      body = %{
        model: model(),
        messages: [
          %{role: "system", content: "You are an expert in AI history and research."},
          %{role: "user", content: prompt}
        ],
        temperature: 0.7,
        max_tokens: 2500
      }

      case Req.post(
             "#{base_url()}/chat/completions",
             headers: [
               {"Authorization", "Bearer #{api_key}"},
               {"Content-Type", "application/json"}
             ],
             json: body,
             receive_timeout: 60_000
           ) do
        {:ok, %{status: 200, body: response}} ->
          content =
            response["choices"] |> List.first() |> Map.get("message") |> Map.get("content")

          {:ok, content}

        {:ok, %{status: status, body: body}} ->
          {:error, "API Error #{status}: #{inspect(body)}"}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  # Parse recommendation result
  defp parse_recommendation(response) do
    lines = String.split(response, "\n")

    %{
      title: extract_value(lines, "Title:"),
      authors: extract_value(lines, "Authors:"),
      year: extract_value(lines, "Year:"),
      arxiv_id: extract_value(lines, "arXiv ID:"),
      reason: extract_value(lines, "Reason:")
    }
  end

  defp extract_value(lines, prefix) do
    line = Enum.find(lines, fn l -> String.starts_with?(l, prefix) end)

    if line do
      line |> String.replace(prefix, "") |> String.trim()
    else
      ""
    end
  end

  defp normalize_recommendation(recommendation, hf_candidates, response) do
    parsed_id = recommendation.arxiv_id |> clean_arxiv_id()
    regex_id = extract_arxiv_id_from_text(response)
    candidate_id = find_candidate_arxiv_id(hf_candidates, recommendation.title)

    resolved_id =
      [parsed_id, regex_id, candidate_id]
      |> Enum.find(&valid_arxiv_id?/1)

    Map.put(recommendation, :arxiv_id, resolved_id || recommendation.arxiv_id)
  end

  defp clean_arxiv_id(nil), do: nil

  defp clean_arxiv_id(id) when is_binary(id) do
    id
    |> String.trim()
    |> String.replace_prefix("arXiv:", "")
    |> String.replace_prefix("https://arxiv.org/abs/", "")
    |> String.replace_prefix("http://arxiv.org/abs/", "")
    |> case do
      "未提供" -> nil
      "" -> nil
      value -> value
    end
  end

  defp clean_arxiv_id(_), do: nil

  defp extract_arxiv_id_from_text(text) when is_binary(text) do
    case Regex.run(~r/\b\d{4}\.\d{4,5}(?:v\d+)?\b/, text) do
      [id] -> id
      _ -> nil
    end
  end

  defp extract_arxiv_id_from_text(_), do: nil

  defp find_candidate_arxiv_id(hf_candidates, title) do
    normalized_title = normalize_title(title)

    hf_candidates
    |> Enum.find(fn candidate -> normalize_title(candidate.title) == normalized_title end)
    |> case do
      nil -> nil
      candidate -> clean_arxiv_id(candidate.id)
    end
  end

  defp normalize_title(nil), do: ""

  defp normalize_title(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^\p{L}\p{N}]+/u, "")
  end

  defp valid_arxiv_id?(id) when is_binary(id) do
    Regex.match?(~r/^\d{4}\.\d{4,5}(?:v\d+)?$/, id)
  end

  defp valid_arxiv_id?(_), do: false

  # Parse analysis result
  defp parse_analysis(response) do
    # Split by ## to get sections
    sections =
      response
      |> String.split("## ")
      # Drop first empty string
      |> Enum.drop(1)
      |> Enum.map(fn section ->
        case String.split(section, "\n", parts: 2) do
          [title, content] -> {String.trim(title), String.trim(content)}
          [title] -> {String.trim(title), ""}
        end
      end)
      |> Map.new()

    %{
      chinese_abstract: sections["中文摘要"],
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
  end
end
