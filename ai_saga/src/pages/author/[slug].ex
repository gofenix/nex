defmodule AiSaga.Pages.Author.Slug do
  use Nex

  def mount(%{"slug" => slug}) do
    {:ok, [author]} =
      NexBase.from("authors")
      |> NexBase.eq(:slug, slug)
      |> NexBase.single()
      |> NexBase.run()

    # 获取作者的论文
    {:ok, links} =
      NexBase.from("paper_authors")
      |> NexBase.eq(:author_id, author["id"])
      |> NexBase.order(:author_order, :asc)
      |> NexBase.run()

    papers =
      Enum.map(links, fn link ->
        {:ok, [p]} =
          NexBase.from("papers")
          |> NexBase.eq(:id, link["paper_id"])
          |> NexBase.single()
          |> NexBase.run()

        p
      end)

    # 获取合作者（共同发表论文的其他作者）
    paper_ids = Enum.map(papers, & &1["id"])

    collaborators =
      if length(paper_ids) > 0 do
        {:ok, all_links} =
          NexBase.from("paper_authors")
          |> NexBase.in(:paper_id, paper_ids)
          |> NexBase.neq(:author_id, author["id"])
          |> NexBase.run()

        collaborator_ids = Enum.map(all_links, & &1["author_id"]) |> Enum.uniq()

        if length(collaborator_ids) > 0 do
          {:ok, collab_authors} =
            NexBase.from("authors")
            |> NexBase.in(:id, collaborator_ids)
            |> NexBase.run()

          # 统计合作次数
          collab_counts = Enum.frequencies(Enum.map(all_links, & &1["author_id"]))

          Enum.map(collab_authors, fn a ->
            Map.put(a, "collab_count", collab_counts[a["id"]] || 0)
          end)
          |> Enum.sort_by(& &1["collab_count"], :desc)
          |> Enum.take(6)
        else
          []
        end
      else
        []
      end

    # 计算统计数据
    paradigm_shifts = Enum.filter(papers, &(&1["is_paradigm_shift"] == 1))
    total_citations = Enum.sum(Enum.map(papers, &(&1["citations"] || 0)))

    %{
      title: author["name"],
      author: author,
      papers: papers,
      collaborators: collaborators,
      stats: %{
        total_papers: length(papers),
        paradigm_shifts: length(paradigm_shifts),
        total_citations: total_citations,
        avg_citations: if(length(papers) > 0, do: div(total_citations, length(papers)), else: 0)
      }
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto space-y-8">
      <a href="/author" class="inline-flex items-center gap-2 text-sm font-mono opacity-60 hover:opacity-100">
        ← 返回人物列表
      </a>

      <%!-- 头部信息卡片 --%>
      <header class="bg-white border-2 border-black p-6 md:p-8 md-shadow">
        <div class="flex flex-col md:flex-row md:items-start gap-6">
          <div class="flex-shrink-0">
            <div class="w-24 h-24 bg-[rgb(255,222,0)] border-2 border-black flex items-center justify-center text-5xl">
              👤
            </div>
          </div>

          <div class="flex-1 space-y-4">
            <div>
              <h1 class="text-3xl md:text-4xl font-black mb-2">{@author["name"]}</h1>
              <p class="text-lg opacity-70">{@author["bio"]}</p>
            </div>

            <div class="flex flex-wrap items-center gap-4 text-sm">
              <%= if @author["affiliation"] do %>
                <span class="px-3 py-1 bg-gray-100 border border-black">{@author["affiliation"]}</span>
              <% end %>
              <%= if @author["first_paper_year"] do %>
                <span class="font-mono opacity-60">首篇论文: {@author["first_paper_year"]}年</span>
              <% end %>
            </div>

            <%!-- 影响力指标 --%>
            <div class="flex flex-wrap gap-4 pt-4 border-t border-gray-200">
              <div class="text-center px-4 py-2 bg-[rgb(255,222,0)]/20 border border-black">
                <div class="text-2xl font-black">{@author["influence_score"] || 50}</div>
                <div class="text-xs opacity-60">影响力分数</div>
              </div>
              <div class="text-center px-4 py-2 bg-[rgb(111,194,255)]/20 border border-black">
                <div class="text-2xl font-black">{@stats.total_papers}</div>
                <div class="text-xs opacity-60">发表论文</div>
              </div>
              <div class="text-center px-4 py-2 bg-[rgb(255,160,160)]/20 border border-black">
                <div class="text-2xl font-black">{@stats.total_citations}</div>
                <div class="text-xs opacity-60">总引用数</div>
              </div>
              <%= if @stats.paradigm_shifts > 0 do %>
                <div class="text-center px-4 py-2 bg-black text-white border border-black">
                  <div class="text-2xl font-black">{@stats.paradigm_shifts}</div>
                  <div class="text-xs opacity-80">范式突破</div>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </header>

      <%!-- 合作者网络 --%>
      <%= if length(@collaborators) > 0 do %>
        <section class="bg-white border-2 border-black p-6">
          <h2 class="text-xl font-bold mb-4 flex items-center gap-2">
            <span>🤝</span> 主要合作者
          </h2>
          <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
            <%= for collab <- @collaborators do %>
              <a href={"/author/#{collab["slug"]}"} class="flex items-center gap-3 p-3 border border-black hover:bg-gray-50 transition-colors">
                <div class="w-10 h-10 bg-gray-200 border border-black flex items-center justify-center text-lg">
                  👤
                </div>
                <div class="flex-1 min-w-0">
                  <div class="font-bold text-sm truncate">{collab["name"]}</div>
                  <div class="text-xs opacity-60">{collab["collab_count"]} 篇合作</div>
                </div>
              </a>
            <% end %>
          </div>
        </section>
      <% end %>

      <%!-- 论文列表 --%>
      <section>
        <h2 class="text-2xl font-bold mb-6 flex items-center gap-2">
          <span>📝</span> 发表论文
          <span class="text-sm font-normal opacity-60">({@stats.total_papers} 篇)</span>
        </h2>
        <div class="space-y-4">
          <%= for paper <- @papers do %>
            <a href={"/paper/#{paper["slug"]}"} class="block bg-white p-5 border-2 border-black md-shadow-sm hover:translate-x-1 hover:translate-y-1 transition-transform">
              <div class="flex items-start justify-between gap-4">
                <div class="flex-1">
                  <div class="flex items-center gap-2 mb-2">
                    <span class="font-mono text-sm opacity-60">{paper["published_year"]}</span>
                    <%= if paper["is_paradigm_shift"] == 1 do %>
                      <span class="px-2 py-0.5 bg-[rgb(255,222,0)] border border-black text-xs font-mono">范式突破</span>
                    <% end %>
                  </div>
                  <h3 class="font-bold mb-2 line-clamp-2">{paper["title"]}</h3>
                  <p class="text-sm opacity-60 line-clamp-2">{paper["abstract"]}</p>
                </div>
                <div class="text-right">
                  <span class="text-sm font-mono opacity-40 block">{paper["citations"]} 引用</span>
                </div>
              </div>
            </a>
          <% end %>
        </div>
      </section>
    </div>
    """
  end
end
