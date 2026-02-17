_ = """
Import CSV to PostgreSQL
Usage: mix run priv/repo/import_csv.exs
"""

Nex.Env.init()
conn = NexBase.init(url: Nex.Env.get(:database_url), start: true)

# Read CSV helper
read_csv = fn file ->
  [headers | rows] = File.read!(file) |> String.split("\n", trim: true)
  headers = String.split(headers, ",")
  Enum.map(rows, fn row ->
    values = String.split(row, ",")
    Enum.zip(headers, values) |> Map.new()
  end)
end

# Import paradigms
IO.puts("Importing paradigms...")
NexBase.query!(conn, "DELETE FROM aisaga_paradigms", [])
paradigms = read_csv.("/tmp/paradigms.csv")
Enum.each(paradigms, fn p ->
  record = %{
    name: p["name"],
    slug: p["slug"],
    description: p["description"],
    start_year: p["start_year"] |> String.to_integer(),
    end_year: (if p["end_year"] != "" and p["end_year"] != "NULL" and p["end_year"] != nil, do: String.to_integer(p["end_year"]), else: nil),
    crisis: p["crisis"],
    revolution: p["revolution"],
    created_at: p["created_at"]
  }
  NexBase.from(conn, "aisaga_paradigms") |> NexBase.insert(record) |> NexBase.run()
end)
IO.puts("Imported #{length(paradigms)} paradigms")

# Import authors
IO.puts("\nImporting authors...")
NexBase.query!(conn, "DELETE FROM aisaga_authors", [])
authors = read_csv.("/tmp/authors.csv")
Enum.each(authors, fn a ->
  record = %{
    name: a["name"],
    slug: a["slug"],
    bio: a["bio"],
    affiliation: a["affiliation"],
    birth_year: (if a["birth_year"] != "" and a["birth_year"] != "NULL", do: String.to_integer(a["birth_year"]), else: nil),
    first_paper_year: (if a["first_paper_year"] != "" and a["first_paper_year"] != "NULL", do: String.to_integer(a["first_paper_year"]), else: nil),
    influence_score: (if a["influence_score"] != "", do: String.to_integer(a["influence_score"]), else: 0)
  }
  NexBase.from(conn, "aisaga_authors") |> NexBase.insert(record) |> NexBase.run()
end)
IO.puts("Imported #{length(authors)} authors")

# Import papers
IO.puts("\nImporting papers...")
NexBase.query!(conn, "DELETE FROM aisaga_papers", [])
papers = read_csv.("/tmp/papers.csv")
IO.puts("Found #{length(papers)} papers in CSV")

Enum.each(papers, fn p ->
  try do
    paradigm_id = case p["paradigm_id"] do
      "" -> nil
      nil -> nil
      "NULL" -> nil
      val -> String.to_integer(val)
    end

    record = %{
      title: p["title"],
      slug: p["slug"],
      abstract: p["abstract"],
      arxiv_id: if p["arxiv_id"] != "" and p["arxiv_id"] != "NULL" do
        p["arxiv_id"]
      else
        nil
      end,
      published_year: String.to_integer(p["published_year"]),
      published_month: case p["published_month"] do
        "" -> nil
        nil -> nil
        "NULL" -> nil
        val -> String.to_integer(val)
      end,
      url: p["url"],
      categories: p["categories"],
      citations: case p["citations"] do
        "" -> 0
        nil -> 0
        val -> String.to_integer(val)
      end,
      history_context: p["history_context"],
      challenge: p["challenge"],
      solution: p["solution"],
      impact: p["impact"],
      paradigm_id: paradigm_id,
      is_paradigm_shift: case p["is_paradigm_shift"] do
        "1" -> 1
        "0" -> 0
        "" -> 0
        val -> String.to_integer(val)
      end,
      shift_trigger: (if p["shift_trigger"] != "" and p["shift_trigger"] != "NULL", do: p["shift_trigger"], else: nil),
      is_daily_pick: case p["is_daily_pick"] do
        "1" -> 1
        "0" -> 0
        "" -> 0
        val -> String.to_integer(val)
      end,
      daily_date: (if p["daily_date"] != "" and p["daily_date"] != "NULL", do: p["daily_date"], else: nil),
      trend_value: (if p["trend_value"] != "" and p["trend_value"] != "NULL", do: p["trend_value"], else: nil),
      prev_paradigm: (if p["prev_paradigm"] != "" and p["prev_paradigm"] != "NULL", do: p["prev_paradigm"], else: nil),
      core_contribution: (if p["core_contribution"] != "" and p["core_contribution"] != "NULL", do: p["core_contribution"], else: nil),
      core_mechanism: (if p["core_mechanism"] != "" and p["core_mechanism"] != "NULL", do: p["core_mechanism"], else: nil),
      why_it_wins: (if p["why_it_wins"] != "" and p["why_it_wins"] != "NULL", do: p["why_it_wins"], else: nil),
      subsequent_impact: (if p["subsequent_impact"] != "" and p["subsequent_impact"] != "NULL", do: p["subsequent_impact"], else: nil),
      author_destinies: (if p["author_destinies"] != "" and p["author_destinies"] != "NULL", do: p["author_destinies"], else: nil)
    }

    NexBase.from(conn, "aisaga_papers") |> NexBase.insert(record) |> NexBase.run()
  rescue
    e ->
      IO.puts("Error importing paper #{p["slug"]}: #{inspect(e)}")
  end
end)
IO.puts("Imported papers")

# Import paper_authors
IO.puts("\nImporting paper_authors...")
NexBase.query!(conn, "DELETE FROM aisaga_paper_authors", [])
paper_authors = read_csv.("/tmp/paper_authors.csv")
Enum.each(paper_authors, fn pa ->
  record = %{
    paper_id: String.to_integer(pa["paper_id"]),
    author_id: String.to_integer(pa["author_id"]),
    author_order: case pa["author_order"] do
      "" -> 1
      nil -> 1
      val -> String.to_integer(val)
    end
  }
  NexBase.from(conn, "aisaga_paper_authors") |> NexBase.insert(record) |> NexBase.run()
end)
IO.puts("Imported #{length(paper_authors)} paper_authors")

# Verify
IO.puts("\n✅ Import complete!")
{:ok, pg_papers} = conn |> NexBase.from("aisaga_papers") |> NexBase.run()
{:ok, pg_authors} = conn |> NexBase.from("aisaga_authors") |> NexBase.run()
{:ok, pg_paradigms} = conn |> NexBase.from("aisaga_paradigms") |> NexBase.run()

IO.puts("Verification:")
IO.puts("  Papers: #{length(pg_papers)}")
IO.puts("  Authors: #{length(pg_authors)}")
IO.puts("  Paradigms: #{length(pg_paradigms)}")
