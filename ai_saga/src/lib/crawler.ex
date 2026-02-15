defmodule AiSaga.Crawler do
  def fetch_papers(count \\ 100) do
    categories = ["cs.AI", "cs.LG", "cs.CL", "cs.CV", "stat.ML"]
    papers = []

    Enum.reduce(1..10, papers, fn _page, acc ->
      cat = Enum.random(categories)
      start = Enum.count(acc)
      url = "http://export.arxiv.org/api/query?search_query=cat:#{cat}&start=#{start}&max_results=15&sortBy=submittedDate&sortOrder=descending"

      case Req.get(url) do
        {:ok, response} ->
          new_papers = parse_feed(response.body)
          acc ++ new_papers

        {:error, _} ->
          acc
      end
    end)
    |> Enum.take(count)
    |> Enum.each(&save_paper/1)

    IO.puts("Fetched #{count} papers from arXiv!")
  end

  defp parse_feed(xml) do
    entry_regex = ~r/<entry>(.*?)<\/entry>/s
    title_regex = ~r/<title>(.*?)<\/title>/s
    summary_regex = ~r/<summary>(.*?)<\/summary>/s
    id_regex = ~r/<id>http:\/\/arxiv\.org\/abs\/(.*?)<\/id>/
    published_regex = ~r/<published>(.*?)<\/published>/
    category_regex = ~r/<category term="([^"]*)"/
    author_regex = ~r/<author>\s*<name>(.*?)<\/name>/s

    Regex.scan(entry_regex, xml)
    |> Enum.map(fn [_, entry] ->
      title = Regex.run(title_regex, entry) |> List.last() |> String.replace("\n", " ") |> String.trim()
      abstract = Regex.run(summary_regex, entry) |> List.last() |> String.replace("\n", " ") |> String.trim()
      arxiv_id = Regex.run(id_regex, entry) |> List.last()
      published = Regex.run(published_regex, entry) |> List.last()
      cats = Regex.scan(category_regex, entry) |> Enum.map(fn [_, c] -> c end)
      authors = Regex.scan(author_regex, entry) |> Enum.map(fn [_, a] -> a end)

      %{
        title: title,
        abstract: abstract,
        arxiv_id: arxiv_id,
        published_at: published,
        url: "http://arxiv.org/abs/#{arxiv_id}",
        categories: Enum.join(cats, ", "),
        authors: Enum.join(authors, ", ")
      }
    end)
  end

  defp save_paper(paper) do
    existing = NexBase.from("papers")
    |> NexBase.eq(:arxiv_id, paper[:arxiv_id])
    |> NexBase.run()

    case existing do
      {:ok, []} ->
        NexBase.from("papers")
        |> NexBase.insert(paper)
        |> NexBase.run()
      _ -> :skip
    end
  end
end
