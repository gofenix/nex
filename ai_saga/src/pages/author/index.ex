defmodule AiSaga.Pages.Author.Index do
  use Nex

  def mount(_params) do
    {:ok, authors} =
      NexBase.from("authors")
      |> NexBase.select([:name, :slug, :bio, :affiliation, :influence_score, :first_paper_year])
      |> NexBase.order(:influence_score, :desc)
      |> NexBase.run()

    # 区分知名人物和普通作者
    {featured, others} = Enum.split_with(authors, fn a -> (a["influence_score"] || 0) >= 80 end)

    # 计算统计数据
    total_authors = length(authors)
    {:ok, [%{"count" => total_papers}]} =
      NexBase.sql("SELECT COUNT(*) as count FROM papers")

    %{
      title: "重要人物",
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
        ← 返回首页
      </a>

      <div class="page-header">
        <h1>AI 领域重要人物</h1>
        <p>从感知机之父到Transformer发明者，探索推动人工智能发展的关键人物</p>
        <div class="meta">{@stats.total_authors} 位学者 · {@stats.total_papers} 篇论文</div>
      </div>

      <%= if length(@featured) > 0 or length(@others) > 0 do %>
        <%!-- 知名人物 - 大图展示 --%>
        <%= if length(@featured) > 0 do %>
          <section>
            <h2 class="section-title text-xl">
              <span>⭐</span>
              领军人物
              <span class="text-sm font-normal opacity-60">({@stats.featured_count} 位)</span>
            </h2>
            <div class="grid md:grid-cols-2 gap-4">
              <%= for author <- @featured do %>
                <a href={"/author/#{author["slug"]}"} class="card-yellow block p-6">
                  <div class="flex items-start gap-4">
                    <div class="icon-box-yellow flex-shrink-0 text-3xl">👤</div>
                    <div class="flex-1 min-w-0">
                      <h3 class="font-bold text-lg mb-1 truncate">{author["name"]}</h3>
                      <p class="text-sm opacity-70 mb-2 line-clamp-1">{author["affiliation"]}</p>
                      <p class="text-sm opacity-90 line-clamp-2 mb-3">{author["bio"]}</p>
                      <div class="flex items-center gap-3 text-xs font-mono">
                        <span class="badge badge-black">影响力 {author["influence_score"]}</span>
                        <span class="opacity-60">首篇 {author["first_paper_year"]}年</span>
                      </div>
                    </div>
                  </div>
                </a>
              <% end %>
            </div>
          </section>
        <% end %>

        <%!-- 其他作者 - 紧凑展示 --%>
        <%= if length(@others) > 0 do %>
          <section>
            <h2 class="section-title text-xl">
              <span>👥</span>
              其他贡献者
              <span class="text-sm font-normal opacity-60">({length(@others)} 位)</span>
            </h2>
            <div class="grid md:grid-cols-3 gap-3">
              <%= for author <- @others do %>
                <a href={"/author/#{author["slug"]}"} class="card block p-4">
                  <div class="flex items-center gap-2 mb-2">
                    <span class="text-xl">👤</span>
                    <h3 class="font-bold text-sm truncate">{author["name"]}</h3>
                  </div>
                  <p class="text-xs opacity-60 mb-2 line-clamp-1">{author["affiliation"] || "暂无机构信息"}</p>
                  <div class="text-xs font-mono opacity-40">
                    影响力: {author["influence_score"] || 50}
                  </div>
                </a>
              <% end %>
            </div>
          </section>
        <% end %>
      <% else %>
        <div class="empty-state">
          <p>暂无作者数据</p>
          <p class="hint">请稍后再试</p>
        </div>
      <% end %>
    </div>
    """
  end
end
