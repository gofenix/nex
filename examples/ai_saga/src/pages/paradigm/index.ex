defmodule AiSaga.Pages.Paradigm.Index do
  use Nex

  def mount(_params) do
    {:ok, paradigms} =
      NexBase.from("aisaga_paradigms")
      |> NexBase.order(:start_year, :asc)
      |> NexBase.run()

    # Load all paradigm statistics in one query to avoid N+1 queries.
    {:ok, stats} =
      NexBase.sql(
        "SELECT paradigm_id, COUNT(*) as paper_count, COALESCE(SUM(CASE WHEN is_paradigm_shift = 1 THEN 1 ELSE 0 END), 0) as shift_count, COALESCE(SUM(citations), 0) as total_citations FROM aisaga_papers GROUP BY paradigm_id"
      )

    stats_map = Map.new(stats, fn s -> {s["paradigm_id"], s} end)

    paradigms_with_stats =
      Enum.map(paradigms, fn p ->
        s = Map.get(stats_map, p["id"], %{"paper_count" => 0, "shift_count" => 0, "total_citations" => 0})
        Map.merge(p, %{
          "paper_count" => s["paper_count"],
          "shift_count" => s["shift_count"],
          "total_citations" => s["total_citations"]
        })
      end)

    # Compute the total span.
    total_years =
      if length(paradigms) > 0 do
        first = List.first(paradigms)["start_year"]
        last = List.last(paradigms)
        last_year = last["end_year"] || Date.utc_today().year
        last_year - first
      else
        0
      end

    %{
      title: "AI Paradigm Evolution",
      paradigms: paradigms_with_stats,
      total_paradigms: length(paradigms),
      total_years: total_years
    }
  end

  defp paradigm_icon("perceptron"), do: "🧠"
  defp paradigm_icon("symbolic-ai"), do: "🔤"
  defp paradigm_icon("connectionism"), do: "🔗"
  defp paradigm_icon("deep-learning"), do: "🎯"
  defp paradigm_icon("transformers"), do: "⚡"
  defp paradigm_icon(_), do: "📊"

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto space-y-10">
      <a href="/" class="back-link mb-4 inline-block">
        ← Back to Home
      </a>

      <div class="page-header">
        <h1>AI Paradigm Evolution</h1>
        <p>Explore five major stages in the evolution of artificial intelligence, from the Perceptron in 1957 to the era of foundation models.</p>
        <div class="meta">{@total_paradigms} research paradigms · spanning {@total_years} years</div>
      </div>

      <div :if={length(@paradigms) > 0} class="relative">
          <div class="timeline-line"></div>
          <div class="space-y-8">
            <div :for={{paradigm, index} <- Enum.with_index(@paradigms)}
                 class={if rem(index, 2) == 0, do: "relative flex items-start md:flex-row", else: "relative flex items-start md:flex-row-reverse"}>
                <div class="timeline-dot mt-6"></div>
                <div class={if rem(index, 2) == 0, do: "absolute left-16 md:left-auto md:right-1/2 md:mr-8 top-5 font-mono text-sm font-bold bg-black text-white px-2 py-1", else: "absolute left-16 md:left-1/2 md:ml-8 top-5 font-mono text-sm font-bold bg-black text-white px-2 py-1"}>
                  {paradigm["start_year"]}
                </div>
                <div class={if rem(index, 2) == 0, do: "ml-20 md:ml-0 md:w-5/12 md:pr-12", else: "ml-20 md:ml-0 md:w-5/12 md:pl-12"}>
                  <a href={"/paradigm/#{paradigm["slug"]}"} class="card block p-5">
                    <div class="flex items-center gap-3 mb-3">
                      <span class="text-2xl">{paradigm_icon(paradigm["slug"])}</span>
                      <h3 class="text-xl font-bold">{paradigm["name"]}</h3>
                    </div>
                    <p class="text-sm opacity-70 mb-4 line-clamp-2">{paradigm["description"]}</p>
                    <div class="flex flex-wrap gap-2 text-xs font-mono">
                      <span class="badge badge-gray">{paradigm["paper_count"]} papers</span>
                      <span :if={paradigm["shift_count"] > 0} class="badge badge-yellow">{paradigm["shift_count"]} breakthroughs</span>
                    </div>
                    <div :if={paradigm["crisis"] || paradigm["revolution"]} class="mt-3 pt-3 border-t border-gray-200 text-xs">
                        <span :if={paradigm["crisis"]} class="text-red-600 mr-3">⚠️ Challenges</span>
                        <span :if={paradigm["revolution"]} class="text-green-600">🎉 Breakthrough</span>
                      </div>
                  </a>
                </div>
              </div>
          </div>
        </div>
      <div :if={length(@paradigms) == 0} class="empty-state">
          <p>No paradigm data available yet</p>
          <p class="hint">Please try again later</p>
        </div>
    </div>
    """
  end
end
