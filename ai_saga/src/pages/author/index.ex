defmodule AiSaga.Pages.Author.Index do
  use Nex

  def mount(_params) do
    {:ok, authors} =
      NexBase.from("authors")
      |> NexBase.order(:influence_score, :desc)
      |> NexBase.run()

    # 区分知名人物和普通作者
    {featured, others} = Enum.split_with(authors, fn a -> (a["influence_score"] || 0) >= 80 end)

    # 计算统计数据
    total_authors = length(authors)
    total_papers =
      case NexBase.from("papers") |> NexBase.run() do
        {:ok, papers} -> length(papers)
        _ -> 0
      end

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
      <div class="text-center py-8">
        <a href="/" class="inline-flex items-center gap-2 text-sm font-mono opacity-60 hover:opacity-100 mb-4">
          ← 返回首页
        </a>
        <h1 class="text-4xl font-black mb-3">AI 领域重要人物</h1>
        <p class="text-lg opacity-60 max-w-xl mx-auto">
          从感知机之父到Transformer发明者，探索推动人工智能发展的关键人物
        </p>
        <div class="mt-4 text-sm font-mono opacity-40">
          {@stats.total_authors} 位学者 · {@stats.total_papers} 篇论文
        </div>
      </div>

      <%!-- 知名人物 - 大图展示 --%>
      <%= if length(@featured) > 0 do %>
        <section>
          <h2 class="text-xl font-bold mb-6 flex items-center gap-2">
            <span class="text-2xl">⭐</span>
            领军人物
            <span class="text-sm font-normal opacity-60">({@stats.featured_count} 位)</span>
          </h2>
          <div class="grid md:grid-cols-2 gap-4">
            <%= for author <- @featured do %>
              <a href={"/author/#{author["slug"]}"} class="block bg-[rgb(255,222,0)] p-6 border-2 border-black md-shadow hover:translate-x-1 hover:translate-y-1 transition-transform">
                <div class="flex items-start gap-4">
                  <div class="w-16 h-16 bg-white border-2 border-black flex items-center justify-center text-3xl flex-shrink-0">
                    👤
                  </div>
                  <div class="flex-1 min-w-0">
                    <h3 class="font-bold text-lg mb-1 truncate">{author["name"]}</h3>
                    <p class="text-sm opacity-70 mb-2 line-clamp-1">{author["affiliation"]}</p>
                    <p class="text-sm opacity-90 line-clamp-2 mb-3">{author["bio"]}</p>
                    <div class="flex items-center gap-3 text-xs font-mono">
                      <span class="px-2 py-1 bg-white border border-black">
                        影响力 {author["influence_score"]}
                      </span>
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
          <h2 class="text-xl font-bold mb-6 flex items-center gap-2">
            <span class="text-2xl">👥</span>
            其他贡献者
            <span class="text-sm font-normal opacity-60">({length(@others)} 位)</span>
          </h2>
          <div class="grid md:grid-cols-3 gap-3">
            <%= for author <- @others do %>
              <a href={"/author/#{author["slug"]}"} class="block bg-white p-4 border-2 border-black md-shadow-sm hover:translate-x-0.5 hover:translate-y-0.5 transition-transform">
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
    </div>
    """
  end
end
