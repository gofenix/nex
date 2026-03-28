defmodule AiSaga.Pages.Timeline do
  use Nex

  def mount(_params) do
    {:ok, papers} =
      NexBase.from("aisaga_papers")
      |> NexBase.select([:title, :slug, :abstract, :published_year, :is_paradigm_shift])
      |> NexBase.order(:published_year, :asc)
      |> NexBase.run()

    %{
      title: "AI Paper Timeline",
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
        <h1>📅 AI Paper Timeline</h1>
        <p>Explore the development of artificial intelligence in chronological order</p>
      </div>

      <div :if={length(@papers) > 0} class="relative">
          <div class="timeline-line"></div>
          <div class="space-y-6">
            <div :for={paper <- @papers} class="relative pl-12">
                <div class="timeline-dot top-5"></div>
                <a href={"/paper/#{paper["slug"]}"} class="card block p-5">
                  <div class="flex items-center gap-3 mb-2">
                    <span class="year-tag font-bold">{paper["published_year"]}</span>
                    <span :if={paper["is_paradigm_shift"] == 1} class="badge badge-yellow">Paradigm shift</span>
                  </div>
                  <h3 class="font-bold mb-2">{paper["title"]}</h3>
                  <p class="text-sm opacity-60 line-clamp-2">{paper["abstract"]}</p>
                </a>
              </div>
          </div>
        </div>
      <div :if={length(@papers) == 0} class="empty-state">
          <p>No paper data available yet</p>
          <p class="hint">Please try again later</p>
        </div>
    </div>
    """
  end
end
