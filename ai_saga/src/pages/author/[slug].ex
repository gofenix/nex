defmodule AiSaga.Pages.Author.Slug do
  use Nex

  def mount(%{"slug" => slug}) do
    {:ok, [author]} = NexBase.from("authors")
    |> NexBase.eq(:slug, slug)
    |> NexBase.single()
    |> NexBase.run()

    {:ok, links} = NexBase.from("paper_authors")
    |> NexBase.eq(:author_id, author["id"])
    |> NexBase.order(:author_order, :asc)
    |> NexBase.run()

    papers = Enum.map(links, fn link ->
      {:ok, [p]} = NexBase.from("papers")
      |> NexBase.eq(:id, link["paper_id"])
      |> NexBase.single()
      |> NexBase.run()
      p
    end)

    %{
      title: author["name"],
      author: author,
      papers: papers
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto space-y-8">
      <a href="/" class="inline-flex items-center gap-2 text-sm font-mono opacity-60 hover:opacity-100">
        ← 返回首页
      </a>

      <header class="space-y-4">
        <div class="flex items-center gap-3">
          <span class="text-4xl">👤</span>
          <h1 class="text-4xl font-black">{@author["name"]}</h1>
        </div>
        <p class="text-lg">{@author["bio"]}</p>

        <div class="flex items-center gap-6 text-sm font-mono opacity-60">
          <span>{@author["affiliation"]}</span>
          <span>•</span>
          <span>影响力分数: {@author["influence_score"]}</span>
          <span>•</span>
          <span>首篇论文: {@author["first_paper_year"]}年</span>
        </div>
      </header>

      <section>
        <h2 class="text-2xl font-bold mb-6">论文</h2>
        <div class="space-y-4">
          <%= for paper <- @papers do %>
            <a href={"/paper/#{paper["slug"]}"} class="block bg-white p-5 border-2 border-black md-shadow-sm hover:translate-x-1 hover:translate-y-1 transition-transform">
              <div class="flex items-start justify-between gap-4">
                <div class="flex-1">
                  <div class="flex items-center gap-2 mb-2">
                    <span class="font-mono text-sm opacity-60">{paper["published_year"]}</span>
                    <%= if paper["is_paradigm_shift"] == 1 do %>
                      <span class="px-2 py-0.5 bg-[rgb(255,222,0)] border border-black text-xs font-mono">范式变迁</span>
                    <% end %>
                  </div>
                  <h3 class="font-bold mb-2 line-clamp-2">{paper["title"]}</h3>
                </div>
                <span class="text-sm font-mono opacity-40">{paper["citations"]}</span>
              </div>
            </a>
          <% end %>
        </div>
      </section>
    </div>
    """
  end
end
