defmodule AiSaga.ArxivClient do
  @moduledoc """
  arXiv API客户端
  获取论文完整信息
  """

  @base_url "http://export.arxiv.org/api/query"

  @doc """
  根据arXiv ID获取论文详情
  """
  def get_paper_by_id(arxiv_id) do
    url = "#{@base_url}?id_list=#{arxiv_id}&max_results=1"

    case Req.get(url, headers: [{"Accept", "application/atom+xml"}]) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, parse_atom_feed(body)}

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  搜索论文
  """
  def search_papers(query, max_results \\ 10) do
    encoded_query = URI.encode_www_form(query)
    url = "#{@base_url}?search_query=#{encoded_query}&max_results=#{max_results}&sortBy=relevance&sortOrder=descending"

    case Req.get(url) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, parse_atom_feed(body)}

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # 解析Atom feed
  defp parse_atom_feed(body) do
    # 简单解析，提取关键信息
    entries = extract_entries(body)
    Enum.map(entries, &parse_entry/1)
  end

  defp extract_entries(body) do
    # 按<entry>标签分割
    body
    |> String.split("<entry>")
    |> Enum.drop(1)  # 去掉第一个非entry部分
    |> Enum.map(fn entry ->
      case String.split(entry, "</entry>") do
        [content | _] -> content
        _ -> ""
      end
    end)
  end

  defp parse_entry(entry) do
    raw_id = extract_tag(entry, "id")

    %{
      arxiv_id: clean_arxiv_id(raw_id),
      title: extract_tag(entry, "title"),
      authors: extract_authors(entry),
      abstract: extract_tag(entry, "summary"),
      published: extract_tag(entry, "published"),
      updated: extract_tag(entry, "updated"),
      categories: extract_categories(entry),
      pdf_url: extract_pdf_url(entry)
    }
  end

  # 从 URL 中提取纯净的 arXiv ID
  defp clean_arxiv_id(nil), do: nil
  defp clean_arxiv_id(url) when is_binary(url) do
    # 从 http://arxiv.org/abs/2005.14165v4 提取 2005.14165
    case Regex.run(~r/(\d{4}\.\d{4,5})(?:v\d+)?/, url) do
      [_, id] -> id
      _ -> url
    end
  end

  defp extract_tag(entry, tag) do
    case Regex.run(~r/<#{tag}[^>]*>(.*?)<\/#{tag}>/s, entry) do
      [_, content] -> content |> String.trim()
      _ -> nil
    end
  end

  defp extract_authors(entry) do
    Regex.scan(~r/<author>.*?<name>(.*?)<\/name>.*?<\/author>/s, entry)
    |> Enum.map(fn [_, name] -> name end)
  end

  defp extract_categories(entry) do
    Regex.scan(~r/<category term="([^"]+)"/, entry)
    |> Enum.map(fn [_, cat] -> cat end)
  end

  defp extract_pdf_url(entry) do
    case Regex.run(~r/<link title="pdf" href="([^"]+)"/, entry) do
      [_, url] -> url
      _ -> nil
    end
  end
end
