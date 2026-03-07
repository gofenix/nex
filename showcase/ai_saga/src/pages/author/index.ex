defmodule AiSaga.Pages.Author.Index do
  use Nex

  def mount(_params) do
    {:ok, authors} =
      NexBase.from("aisaga_authors")
      |> NexBase.select([:name, :slug, :bio, :affiliation, :influence_score, :first_paper_year])
      |> NexBase.order(:influence_score, :desc)
      |> NexBase.run()

    # Split featured figures from other authors.
    {featured, others} = Enum.split_with(authors, fn a -> (a["influence_score"] || 0) >= 80 end)

    # Compute summary statistics.
    total_authors = length(authors)
    {:ok, [%{"count" => total_papers}]} =
      NexBase.sql("SELECT COUNT(*) as count FROM aisaga_papers")

    %{
      title: "Key Figures",
      featured: featured,
      others: others,
      stats: %{
        total_authors: total_authors,
        featured_count: length(featured),
        total_papers: total_papers
      }
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto space-y-10">
      <a href="/" class="back-link mb-4 inline-block">
        ← Back to Home
      </a>

      <div class="page-header">
        <h1>Key Figures in AI</h1>
        <p>From the father of the Perceptron to the inventors of the Transformer, explore the people who shaped the progress of artificial intelligence.</p>
        <div class="meta">{@stats.total_authors} scholars · {@stats.total_papers} papers</div>
      </div>

      <section :if={length(@featured) > 0}>
            <h2 class="section-title text-xl">
              <span>⭐</span>
              Leading Figures
              <span class="text-sm font-normal opacity-60">({@stats.featured_count})</span>
            </h2>
            <div class="grid md:grid-cols-2 gap-4">
              <a :for={author <- @featured} href={"/author/#{author["slug"]}"} class="card-yellow block p-6">
                  <div class="flex items-start gap-4">
                    <div class="icon-box-yellow flex-shrink-0 text-3xl">👤</div>
                    <div class="flex-1 min-w-0">
                      <h3 class="font-bold text-lg mb-1 truncate">{author["name"]}</h3>
                      <p class="text-sm opacity-70 mb-2 line-clamp-1">{author["affiliation"]}</p>
                      <p class="text-sm opacity-90 line-clamp-2 mb-3">{author["bio"]}</p>
                      <div class="flex items-center gap-3 text-xs font-mono">
                        <span class="badge badge-black">Influence {author["influence_score"]}</span>
                        <span class="opacity-60">First paper {author["first_paper_year"]}</span>
                      </div>
                    </div>
                  </div>
                </a>
            </div>
          </section>

      <section :if={length(@others) > 0}>
            <h2 class="section-title text-xl">
              <span>👥</span>
              Other Contributors
              <span class="text-sm font-normal opacity-60">({length(@others)})</span>
            </h2>
            <div class="grid md:grid-cols-3 gap-3">
              <a :for={author <- @others} href={"/author/#{author["slug"]}"} class="card block p-4">
                  <div class="flex items-center gap-2 mb-2">
                    <span class="text-xl">👤</span>
                    <h3 class="font-bold text-sm truncate">{author["name"]}</h3>
                  </div>
                  <p class="text-xs opacity-60 mb-2 line-clamp-1">{author["affiliation"] || "No affiliation available"}</p>
                  <div class="text-xs font-mono opacity-40">
                    Influence: {author["influence_score"] || 50}
                  </div>
                </a>
            </div>
          </section>

      <div :if={length(@featured) == 0 and length(@others) == 0} class="empty-state">
          <p>No author data available yet</p>
          <p class="hint">Please try again later</p>
        </div>
    </div>
    """
  end
end
