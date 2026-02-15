defmodule AiSaga.OpenAIClient do
  @moduledoc """
  OpenAI API客户端
  用于推荐论文和生成三视角分析
  """

  defp model, do: System.get_env("OPENAI_MODEL") || "gpt-4o"
  defp base_url, do: System.get_env("OPENAI_BASE_URL") || "https://api.openai.com/v1"

  @doc """
  基于论文统计摘要推荐下一篇论文
  """
  def recommend_paper(papers_summary, hf_candidates) do
    prompt = build_recommendation_prompt(papers_summary, hf_candidates)

    case call_openai(prompt) do
      {:ok, response} ->
        recommendation =
          response
          |> parse_recommendation()
          |> normalize_recommendation(hf_candidates, response)

        if valid_arxiv_id?(recommendation.arxiv_id) do
          {:ok, recommendation}
        else
          {:error, "No valid arXiv ID found in recommendation"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  生成论文的三视角分析
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

  # 构建推荐Prompt（使用统计摘要，固定大小）
  defp build_recommendation_prompt(papers_summary, hf_candidates) do
    # 构建范式统计字符串
    paradigm_str = Enum.map_join(papers_summary.paradigm_summaries, "\n", fn p ->
      status = if p.count == 0, do: "⚠️ 空白", else: "#{p.count}篇"
      "- #{p.name} (#{p.start_year}-#{p.end_year || "现在"}): #{status}"
    end)

    # 构建已有论文的 arXiv ID 列表
    existing_ids_str = if length(papers_summary.existing_arxiv_ids) > 0 do
      papers_summary.existing_arxiv_ids
      |> Enum.join(", ")
    else
      "无"
    end

    candidates_str = Enum.map_join(hf_candidates, "\n", fn p ->
      "- #{p.title} (#{p.published_at})\n  arXiv ID: #{p.id}\n  作者: #{Enum.join(p.authors, ", ")}\n  影响力: #{p.influence_score}"
    end)

    """
    你是AI历史专家。请基于我们的论文收藏现状，从HuggingFace热门候选中推荐下一篇应该添加的重要论文。

    【我们已有的论文分布】（共#{papers_summary.total_count}篇）
    #{paradigm_str}

    【已收藏的论文 arXiv ID】
    #{existing_ids_str}

    ⚠️ 重要：请不要推荐上述已有 arXiv ID 列表中的论文，必须推荐全新的论文。

    【HuggingFace热门候选】
    #{candidates_str}

    请从以下角度思考：
    1. 历史视角：哪些范式是空白？时间线上还有哪些重要节点？
    2. 范式变迁：哪些论文能填补空白或推动范式演进？
    3. 多样性：考虑不同学派、地区、机构的重要工作

    请推荐1篇论文，格式如下：
    标题: [论文标题]
    作者: [主要作者]
    年份: [发表年份]
    arXiv ID: [如 1706.03762，必须是候选列表中的有效ID]
    推荐理由: [为什么选这篇？它如何填补空白或推动历史？]
    """
  end

  # 构建分析Prompt（使用相关论文，而非全部）
  defp build_analysis_prompt(relevant_papers, new_paper, hf_data) do
    # 构建相关论文字符串
    existing_str = Enum.map_join(relevant_papers, "\n", fn p ->
      "- #{p["published_year"]}: #{p["title"]} [#{p["paradigm"]["name"]}]"
    end)

    hf_str = if hf_data do
      "影响力分数: #{hf_data.influence_score}\n社区讨论: #{hf_data.discussion_count}"
    else
      "无HuggingFace数据"
    end

    """
    请为以下论文生成详细的三视角分析内容。

    【相关论文上下文】（前后几年）
    #{existing_str}

    【新论文信息】
    标题: #{new_paper.title}
    作者: #{Enum.join(new_paper.authors, ", ")}
    年份: #{new_paper.published}
    摘要: #{new_paper.abstract}

    【HuggingFace数据】
    #{hf_str}

    请按照以下格式生成内容（使用Markdown格式）：

    ## 上一个范式
    描述这篇论文出现之前的主流方法，包括：
    - 主流技术栈（用表格对比组件、贡献、问题）
    - 当时的困境

    ## 核心贡献
    - 突破性洞察（引用关键句子）
    - 2-3个核心创新点
    - 一句话总结

    ## 核心机制
    - 核心公式（用代码块）
    - 步骤拆解（用表格）
    - 关键设计组件

    ## 为什么赢了
    - 与之前方法的对比表格
    - 关键优势

    ## 当时面临的挑战
    简洁描述领域面临的核心问题

    ## 解决方案
    简洁描述论文如何解决这些问题

    ## 深远影响
    简洁描述对领域的影响

    ## 后续影响
    - 范式转换表格（时代、核心、代表工作）
    - 后续重要工作的时间线

    ## 作者去向
    - 表格列出主要作者的后续发展
    - 名言引用（如果有）

    ## 历史背景
    描述论文发表时的时代背景、研究动机

    请用中文生成，保持学术性和准确性。
    """
  end

  # 调用OpenAI API
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
        max_tokens: 4000
      }

      case Req.post(
        "#{base_url()}/chat/completions",
        headers: [
          {"Authorization", "Bearer #{api_key}"},
          {"Content-Type", "application/json"}
        ],
        json: body
      ) do
        {:ok, %{status: 200, body: response}} ->
          content = response["choices"] |> List.first() |> Map.get("message") |> Map.get("content")
          {:ok, content}

        {:ok, %{status: status, body: body}} ->
          {:error, "API Error #{status}: #{inspect(body)}"}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  # 解析推荐结果
  defp parse_recommendation(response) do
    lines = String.split(response, "\n")

    %{
      title: extract_value(lines, "标题:"),
      authors: extract_value(lines, "作者:"),
      year: extract_value(lines, "年份:"),
      arxiv_id: extract_value(lines, "arXiv ID:"),
      reason: extract_value(lines, "推荐理由:")
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

  # 解析分析结果
  defp parse_analysis(response) do
    # 按##分割各个部分
    sections = response
    |> String.split("## ")
    |> Enum.drop(1)  # 去掉第一个空字符串
    |> Enum.map(fn section ->
      case String.split(section, "\n", parts: 2) do
        [title, content] -> {String.trim(title), String.trim(content)}
        [title] -> {String.trim(title), ""}
      end
    end)
    |> Map.new()

    %{
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
