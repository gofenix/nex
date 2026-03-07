defmodule AiSaga.Pages.Paradigm.Slug do
  use Nex

  def mount(%{"slug" => slug}) do
    {:ok, [paradigm]} =
      NexBase.from("aisaga_paradigms")
      |> NexBase.eq(:slug, slug)
      |> NexBase.single()
      |> NexBase.run()

    # Load all papers in this paradigm.
    {:ok, papers} =
      NexBase.from("aisaga_papers")
      |> NexBase.eq(:paradigm_id, paradigm["id"])
      |> NexBase.order(:published_year, :asc)
      |> NexBase.run()

    # Load the main authors in this paradigm based on paper count.
    paper_ids = Enum.map(papers, & &1["id"])

    main_authors =
      if length(paper_ids) > 0 do
        {:ok, links} =
          NexBase.from("aisaga_paper_authors")
          |> NexBase.in_list(:paper_id, paper_ids)
          |> NexBase.run()

        author_counts =
          Enum.frequencies_by(links, & &1["author_id"])
          |> Enum.sort_by(fn {_, count} -> count end, :desc)
          |> Enum.take(6)

        author_ids = Enum.map(author_counts, &elem(&1, 0))

        if length(author_ids) > 0 do
          {:ok, authors} =
            NexBase.from("aisaga_authors")
            |> NexBase.in_list(:id, author_ids)
            |> NexBase.run()

          # Merge author statistics.
          Enum.map(authors, fn a ->
            count = Enum.find_value(author_counts, 0, fn {id, c} ->
              if id == a["id"], do: c, else: nil
            end)
            Map.put(a, "paper_count", count)
          end)
          |> Enum.sort_by(& &1["paper_count"], :desc)
        else
          []
        end
      else
        []
      end

    # Split paradigm-shift papers from regular papers.
    {paradigm_shifts, normal_papers} =
      Enum.split_with(papers, &(&1["is_paradigm_shift"] == 1))

    # Summary statistics.
    total_citations = Enum.sum(Enum.map(papers, &(&1["citations"] || 0)))

    %{
      title: paradigm["name"],
      paradigm: paradigm,
      papers: papers,
      paradigm_shifts: paradigm_shifts,
      normal_papers: normal_papers,
      main_authors: main_authors,
      stats: %{
        total_papers: length(papers),
        paradigm_shifts: length(paradigm_shifts),
        total_citations: total_citations,
        year_span: calculate_year_span(paradigm["start_year"], paradigm["end_year"])
      }
    }
  end

  defp calculate_year_span(start_year, end_year) do
    end_year = end_year || Date.utc_today().year
    end_year - start_year
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto space-y-8">
      <a href="/paradigm" class="back-link">
        ← Back to Paradigms
      </a>

      <%!-- Header --%>
      <header class="space-y-6">
        <div class="flex flex-col md:flex-row md:items-start gap-4">
          <div class="flex-shrink-0">
            <div class="w-20 h-20 bg-[rgb(111,194,255)] border-2 border-black flex items-center justify-center text-4xl">
              📚
            </div>
          </div>
          <div class="flex-1">
            <h1 class="text-3xl md:text-4xl font-black mb-3">{@paradigm["name"]}</h1>
            <p class="text-lg opacity-70 leading-relaxed">{@paradigm["description"]}</p>
          </div>
        </div>

        <%!-- Timeline and stats --%>
        <div class="flex flex-wrap items-center gap-4 text-sm">
          <div class="stat-box stat-black">
            <div class="number">{@paradigm["start_year"]} - {@paradigm["end_year"] || "Present"}</div>
            <div class="label">Active for {@stats.year_span} years</div>
          </div>
          <div class="stat-box stat-yellow">
            <div class="number">{@stats.total_papers}</div>
            <div class="label">Papers</div>
          </div>
          <div class="stat-box stat-blue">
            <div class="number">{@stats.total_citations}</div>
            <div class="label">Citations</div>
          </div>
        </div>

        <%!-- Crisis and breakthrough --%>
        <div class="grid md:grid-cols-2 gap-4">
          <div :if={@paradigm["crisis"]} class="bg-red-50 p-5 border-2 border-red-200">
              <h3 class="font-bold mb-2 text-red-700 flex items-center gap-2">
                <span>⚠️</span> Crisis and Challenges
              </h3>
              <p class="opacity-80 text-sm">{@paradigm["crisis"]}</p>
            </div>

          <div :if={@paradigm["revolution"]} class="bg-[rgb(255,222,0)] p-5 border-2 border-black">
              <h3 class="font-bold mb-2 flex items-center gap-2">
                <span>🎉</span> Breakthrough Moment
              </h3>
              <p class="opacity-80 text-sm">{@paradigm["revolution"]}</p>
            </div>
        </div>
      </header>

      <%!-- Key contributors --%>
      <section :if={length(@main_authors) > 0} class="card p-6">
          <h2 class="section-title text-xl">
            <span>👥</span> Key Contributors
          </h2>
          <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
            <a :for={author <- @main_authors} href={"/author/#{author["slug"]}"} class="flex items-center gap-3 p-3 border border-black hover:bg-gray-50 transition-colors">
                <div class="icon-box flex-shrink-0 text-lg">👤</div>
                <div class="flex-1 min-w-0">
                  <div class="font-bold text-sm truncate">{author["name"]}</div>
                  <div class="text-xs opacity-60">{author["paper_count"]} papers</div>
                </div>
              </a>
          </div>
        </section>
      <div :if={length(@main_authors) == 0} class="empty-state">
          <p>No key contributor data available yet</p>
          <p class="hint">No author information is available for this paradigm yet</p>
        </div>

      <%!-- Paradigm-shift papers --%>
      <section :if={length(@paradigm_shifts) > 0}>
          <h2 class="section-title text-2xl">
            <span>⚡</span> Paradigm-Shift Papers
            <span class="text-sm font-normal opacity-60">({length(@paradigm_shifts)})</span>
          </h2>
          <div class="space-y-3">
            <a :for={paper <- @paradigm_shifts} href={"/paper/#{paper["slug"]}"} class="card-yellow block p-5">
                <div class="flex items-start justify-between gap-4">
                  <div class="flex-1">
                    <div class="flex items-center gap-2 mb-2">
                      <span class="badge badge-black">Paradigm shift</span>
                      <span class="year-tag">{paper["published_year"]}</span>
                    </div>
                    <h3 class="font-bold mb-2">{paper["title"]}</h3>
                    <p class="text-sm opacity-70 line-clamp-2">{paper["abstract"]}</p>
                  </div>
                  <span class="text-sm font-mono opacity-40">{paper["citations"]} citations</span>
                </div>
              </a>
          </div>
        </section>

      <%!-- Important papers in this period --%>
      <section :if={length(@normal_papers) > 0}>
          <h2 class="section-title text-2xl">
            <span>📄</span> Important Papers
            <span class="text-sm font-normal opacity-60">({length(@normal_papers)})</span>
          </h2>
          <div class="space-y-3">
            <a :for={paper <- @normal_papers} href={"/paper/#{paper["slug"]}"} class="card block p-5">
                <div class="flex items-start justify-between gap-4">
                  <div class="flex-1">
                    <div class="flex items-center gap-3 mb-2">
                      <span class="year-tag">{paper["published_year"]}</span>
                    </div>
                    <h3 class="font-bold mb-2 line-clamp-2">{paper["title"]}</h3>
                    <p class="text-sm opacity-60 line-clamp-2">{paper["abstract"]}</p>
                  </div>
                  <span class="text-sm font-mono opacity-40">{paper["citations"]} citations</span>
                </div>
              </a>
          </div>
        </section>
      <div :if={length(@normal_papers) == 0} class="empty-state">
          <p>No paper data available yet</p>
          <p class="hint">No paper information is available for this paradigm yet</p>
        </div>
    </div>
    """
  end
end
