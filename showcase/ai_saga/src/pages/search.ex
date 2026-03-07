defmodule AiSaga.Pages.Search do
  use Nex

  def mount(params) do
    query = params["q"] || ""
    paradigm_slug = params["paradigm"] || ""
    year_from = params["year_from"] || ""
    year_to = params["year_to"] || ""
    sort_by = params["sort"] || "relevance"

    # Load all paradigms for filtering.
    {:ok, paradigms} =
      NexBase.from("aisaga_paradigms")
      |> NexBase.order(:start_year, :asc)
      |> NexBase.run()

    # Build the search query.
    papers = search_papers(query, paradigm_slug, year_from, year_to, sort_by)

    %{
      title: if(query != "", do: "Search: #{query}", else: "Search Papers"),
      query: query,
      paradigm_slug: paradigm_slug,
      year_from: year_from,
      year_to: year_to,
      sort_by: sort_by,
      paradigms: paradigms,
      papers: papers
    }
  end

  defp search_papers(query, paradigm_slug, year_from, year_to, sort_by) do
    # Base query.
    base_query =
      if query != "" do
        NexBase.from("aisaga_papers")
        |> NexBase.select([:title, :slug, :abstract, :published_year, :is_paradigm_shift, :citations])
        |> NexBase.ilike(:title, "%#{query}%")
      else
        NexBase.from("aisaga_papers")
        |> NexBase.select([:title, :slug, :abstract, :published_year, :is_paradigm_shift, :citations])
      end

    # Paradigm filter.
    query_with_paradigm =
      if paradigm_slug != "" do
        # Load the paradigm ID first.
        case NexBase.from("aisaga_paradigms") |> NexBase.select([:id]) |> NexBase.eq(:slug, paradigm_slug) |> NexBase.single() |> NexBase.run() do
          {:ok, [paradigm]} ->
            base_query |> NexBase.eq(:paradigm_id, paradigm["id"])
          _ ->
            base_query
        end
      else
        base_query
      end

    # Year range filter.
    query_with_year =
      query_with_paradigm
      |> maybe_add_year_filter(year_from, :gte, :published_year)
      |> maybe_add_year_filter(year_to, :lte, :published_year)

    # Sorting.
    final_query =
      case sort_by do
        "year_asc" ->
          query_with_year |> NexBase.order(:published_year, :asc)
        "year_desc" ->
          query_with_year |> NexBase.order(:published_year, :desc)
        "citations" ->
          query_with_year |> NexBase.order(:citations, :desc)
        _ ->
          query_with_year |> NexBase.order(:published_year, :desc)
      end

    case final_query |> NexBase.limit(50) |> NexBase.run() do
      {:ok, papers} -> papers
      _ -> []
    end
  end

  defp maybe_add_year_filter(query, year_str, _op, _field) when year_str == "" or is_nil(year_str), do: query
  defp maybe_add_year_filter(query, year_str, op, _field) do
    case Integer.parse(year_str) do
      {year, _} ->
        if op == :gte do
          NexBase.gte(query, :published_year, year)
        else
          NexBase.lte(query, :published_year, year)
        end
      :error ->
        query
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto space-y-8">
      <a href="/" class="back-link mb-6 inline-block">
        ← Back to Home
      </a>

      <div class="page-header">
        <h1>🔍 Search Papers</h1>
        <p>Find papers by filtering with keywords, paradigms, or publication years</p>
      </div>

      <%!-- Search form --%>
      <form action="/search" method="get" class="space-y-4">
        <%!-- Keyword search --%>
        <div class="flex gap-3">
          <input
            type="text"
            name="q"
            value={@query}
            placeholder="Enter paper title keywords..."
            class="flex-1 px-4 py-3 border-2 border-black bg-white focus:outline-none focus:ring-2 focus:ring-[rgb(255,222,0)]"
            autofocus
          />
          <button type="submit" class="px-6 py-3 bg-[rgb(255,222,0)] border-2 border-black font-bold hover:bg-yellow-300 transition-colors">
            Search
          </button>
        </div>

        <%!-- Filters --%>
        <div class="grid md:grid-cols-4 gap-3 bg-gray-50 p-4 border-2 border-black">
          <%!-- Paradigm filter --%>
          <div>
            <label class="block text-xs font-mono opacity-60 mb-1">Research Paradigm</label>
            <select name="paradigm" class="w-full px-3 py-2 border-2 border-black bg-white focus:outline-none focus:ring-2 focus:ring-[rgb(255,222,0)]">
              <option value="">All Paradigms</option>
              <option :for={paradigm <- @paradigms} value={paradigm["slug"]} selected={@paradigm_slug == paradigm["slug"]}>
                  {paradigm["name"]}
                </option>
            </select>
          </div>

          <%!-- Year range --%>
          <div>
            <label class="block text-xs font-mono opacity-60 mb-1">Start Year</label>
            <input
              type="number"
              name="year_from"
              value={@year_from}
              placeholder="1950"
              class="w-full px-3 py-2 border-2 border-black bg-white focus:outline-none focus:ring-2 focus:ring-[rgb(255,222,0)]"
            />
          </div>

          <div>
            <label class="block text-xs font-mono opacity-60 mb-1">End Year</label>
            <input
              type="number"
              name="year_to"
              value={@year_to}
              placeholder="2026"
              class="w-full px-3 py-2 border-2 border-black bg-white focus:outline-none focus:ring-2 focus:ring-[rgb(255,222,0)]"
            />
          </div>

          <%!-- Sort order --%>
          <div>
            <label class="block text-xs font-mono opacity-60 mb-1">Sort By</label>
            <select name="sort" class="w-full px-3 py-2 border-2 border-black bg-white focus:outline-none focus:ring-2 focus:ring-[rgb(255,222,0)]">
              <option value="relevance" selected={@sort_by == "relevance"}>Relevance</option>
              <option value="year_desc" selected={@sort_by == "year_desc"}>Newest First</option>
              <option value="year_asc" selected={@sort_by == "year_asc"}>Oldest First</option>
              <option value="citations" selected={@sort_by == "citations"}>Citation Count</option>
            </select>
          </div>
        </div>
      </form>

      <%!-- Search results --%>
      <div :if={@query != "" or @paradigm_slug != "" or @year_from != "" or @year_to != ""}>
        <div class="flex items-center justify-between">
          <p class="text-sm font-mono opacity-60">
            Found {length(@papers)} papers
          </p>
          <div class="flex gap-2">
            <span :if={@paradigm_slug != "" and Enum.find(@paradigms, fn p -> p["slug"] == @paradigm_slug end)}
                  class="px-2 py-1 bg-[rgb(111,194,255)] text-xs border border-black">
                  {(Enum.find(@paradigms, fn p -> p["slug"] == @paradigm_slug end) || %{})["name"]}
                </span>
            <span :if={@year_from != "" or @year_to != ""} class="px-2 py-1 bg-gray-200 text-xs border border-black">
                {@year_from}{if @year_from != "" and @year_to != "", do: "-", else: ""}{@year_to}
              </span>
          </div>
        </div>

        <div :if={length(@papers) > 0} class="space-y-4">
            <a :for={paper <- @papers} href={"/paper/#{paper["slug"]}"} class="card block p-5">
                <div class="flex items-start justify-between gap-4">
                  <div class="flex-1">
                    <div class="flex items-center gap-3 mb-2">
                      <span class="year-tag">{paper["published_year"]}</span>
                      <span :if={paper["is_paradigm_shift"] == 1} class="badge badge-yellow">Paradigm shift</span>
                    </div>
                    <h2 class="font-bold mb-2 line-clamp-2">{paper["title"]}</h2>
                    <p class="text-sm opacity-60 line-clamp-2 mb-3">{paper["abstract"]}</p>
                    <div class="flex items-center gap-4 text-xs font-mono opacity-50">
                      <span>{paper["citations"]} citations</span>
                    </div>
                  </div>
                </div>
              </a>
          </div>
        <div :if={length(@papers) == 0} class="empty-state">
            <p>No papers matched your filters</p>
            <p class="hint">Try adjusting your search criteria</p>
          </div>
      </div>
    </div>
    """
  end
end
