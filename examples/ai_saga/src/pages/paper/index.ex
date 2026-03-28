defmodule AiSaga.Pages.Paper.Index do
  use Nex

  def mount(_params) do
    {:ok, papers} =
      NexBase.from("aisaga_papers")
      |> NexBase.select([:title, :slug, :abstract, :published_year, :is_paradigm_shift, :citations])
      |> NexBase.order(:created_at, :desc)
      |> NexBase.run()

    %{
      title: "All Papers",
      papers: papers
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto space-y-8">
      <a href="/" class="back-link mb-6 inline-block">
        ← Back to Home
      </a>

      <div class="page-header">
        <h1>All Papers</h1>
        <p class="text-base opacity-60">Explore landmark research across the field of artificial intelligence</p>
      </div>

      <div :if={length(@papers) > 0} class="space-y-4">
          <a :for={paper <- @papers} href={"/paper/#{paper["slug"]}"} class="card block p-5">
              <div class="flex items-start justify-between gap-4">
                <div class="flex-1">
                  <div class="flex items-center gap-3 mb-2">
                    <span class="year-tag">{paper["published_year"]}</span>
                    <span :if={paper["is_paradigm_shift"] == 1} class="badge badge-yellow">Paradigm shift</span>
                  </div>
                  <h3 class="font-bold mb-2 line-clamp-2">{paper["title"]}</h3>
                  <p class="text-sm opacity-60 line-clamp-2">{paper["abstract"]}</p>
                </div>
                <span class="text-sm font-mono opacity-40">{paper["citations"]} citations</span>
              </div>
            </a>
        </div>
      <div :if={length(@papers) == 0} class="empty-state">
          <p>No paper data available yet</p>
          <p class="hint">Please try again later</p>
        </div>
    </div>
    """
  end
end
