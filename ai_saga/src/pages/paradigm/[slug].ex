defmodule AiSaga.Pages.Paradigm.Slug do
  use Nex

  def mount(%{"slug" => slug}) do
    {:ok, [paradigm]} =
      NexBase.from("paradigms")
      |> NexBase.eq(:slug, slug)
      |> NexBase.single()
      |> NexBase.run()

    # 获取该范式的所有论文
    {:ok, papers} =
      NexBase.from("papers")
      |> NexBase.eq(:paradigm_id, paradigm["id"])
      |> NexBase.order(:published_year, :asc)
      |> NexBase.run()

    # 获取该范式的主要作者（基于论文数量）
    paper_ids = Enum.map(papers, & &1["id"])

    main_authors =
      if length(paper_ids) > 0 do
        {:ok, links} =
          NexBase.from("paper_authors")
          |> NexBase.in(:paper_id, paper_ids)
          |> NexBase.run()

        author_counts =
          Enum.frequencies_by(links, & &1["author_id"])
          |> Enum.sort_by(fn {_, count} -> count end, :desc)
          |> Enum.take(6)

        author_ids = Enum.map(author_counts, &elem(&1, 0))

        if length(author_ids) > 0 do
          {:ok, authors} =
            NexBase.from("authors")
            |> NexBase.in(:id, author_ids)
            |> NexBase.run()

          # 合并统计信息
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

    # 区分范式突破论文和普通论文
    {paradigm_shifts, normal_papers} =
      Enum.split_with(papers, &(&1["is_paradigm_shift"] == 1))

    # 统计数据
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
      <a href="/paradigm" class="inline-flex items-center gap-2 text-sm font-mono opacity-60 hover:opacity-100">
        ← 返回范式列表
      </a>

      <%!-- 头部信息区 --%>
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

        <%!-- 时间线和统计 --%>
        <div class="flex flex-wrap items-center gap-4 text-sm">
          <div class="px-4 py-2 bg-black text-white font-mono">
            {@paradigm["start_year"]} - <%= if @paradigm["end_year"], do: @paradigm["end_year"], else: "现在" %>
            <span class="opacity-60">(持续 {@stats.year_span} 年)</span>
          </div>
          <div class="px-4 py-2 bg-[rgb(255,222,0)] border-2 border-black font-mono">
            {@stats.total_papers} 篇论文
          </div>
          <div class="px-4 py-2 bg-[rgb(111,194,255)] border-2 border-black font-mono">
            {@stats.total_citations} 总引用
          </div>
        </div>

        <%!-- 危机与革命 --%>
        <div class="grid md:grid-cols-2 gap-4">
          <%= if @paradigm["crisis"] do %>
            <div class="bg-red-50 p-5 border-2 border-red-200">
              <h3 class="font-bold mb-2 text-red-700 flex items-center gap-2">
                <span>⚠️</span> 危机与挑战
              </h3>
              <p class="opacity-80 text-sm">{@paradigm["crisis"]}</p>
            </div>
          <% end %>

          <%= if @paradigm["revolution"] do %>
            <div class="bg-[rgb(255,222,0)] p-5 border-2 border-black">
              <h3 class="font-bold mb-2 flex items-center gap-2">
                <span>🎉</span> 革命性突破
              </h3>
              <p class="opacity-80 text-sm">{@paradigm["revolution"]}</p>
            </div>
          <% end %>
        </div>
      </header>

      <%!-- 核心贡献者 --%>
      <%= if length(@main_authors) > 0 do %>
        <section class="bg-white border-2 border-black p-6">
          <h2 class="text-xl font-bold mb-4 flex items-center gap-2">
            <span>👥</span> 核心贡献者
          </h2>
          <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
            <%= for author <- @main_authors do %>
              <a href={"/author/#{author["slug"]}"} class="flex items-center gap-3 p-3 border border-black hover:bg-gray-50 transition-colors">
                <div class="w-10 h-10 bg-gray-200 border border-black flex items-center justify-center text-lg">
                  👤
                </div>
                <div class="flex-1 min-w-0">
                  <div class="font-bold text-sm truncate">{author["name"]}</div>
                  <div class="text-xs opacity-60">{author["paper_count"]} 篇论文</div>
                </div>
              </a>
            <% end %>
          </div>
        </section>
      <% end %>

      <%!-- 范式突破论文 --%>
      <%= if length(@paradigm_shifts) > 0 do %>
        <section>
          <h2 class="text-2xl font-bold mb-4 flex items-center gap-2">
            <span>⚡</span> 范式突破
            <span class="text-sm font-normal opacity-60">({length(@paradigm_shifts)} 篇)</span>
          </h2>
          <div class="space-y-3">
            <%= for paper <- @paradigm_shifts do %>
              <a href={"/paper/#{paper["slug"]}"} class="block bg-[rgb(255,222,0)] p-5 border-2 border-black md-shadow-sm hover:translate-x-1 hover:translate-y-1 transition-transform">
                <div class="flex items-start justify-between gap-4">
                  <div class="flex-1">
                    <div class="flex items-center gap-2 mb-2">
                      <span class="px-2 py-0.5 bg-black text-white text-xs font-mono">范式突破</span>
                      <span class="font-mono text-sm opacity-60">{paper["published_year"]}</span>
                    </div>
                    <h3 class="font-bold mb-2">{paper["title"]}</h3>
                    <p class="text-sm opacity-70 line-clamp-2">{paper["abstract"]}</p>
                  </div>
                  <span class="text-sm font-mono opacity-40">{paper["citations"]} 引用</span>
                </div>
              </a>
            <% end %>
          </div>
        </section>
      <% end %>

      <%!-- 该时期重要论文 --%>
      <section>
        <h2 class="text-2xl font-bold mb-4 flex items-center gap-2">
          <span>📄</span> 重要论文
          <span class="text-sm font-normal opacity-60">({length(@normal_papers)} 篇)</span>
        </h2>
        <div class="space-y-3">
          <%= for paper <- @normal_papers do %>
            <a href={"/paper/#{paper["slug"]}"} class="block bg-white p-5 border-2 border-black md-shadow-sm hover:translate-x-1 hover:translate-y-1 transition-transform">
              <div class="flex items-start justify-between gap-4">
                <div class="flex-1">
                  <div class="flex items-center gap-2 mb-2">
                    <span class="font-mono text-sm opacity-60">{paper["published_year"]}</span>
                  </div>
                  <h3 class="font-bold mb-2 line-clamp-2">{paper["title"]}</h3>
                  <p class="text-sm opacity-60 line-clamp-2">{paper["abstract"]}</p>
                </div>
                <span class="text-sm font-mono opacity-40">{paper["citations"]} 引用</span>
              </div>
            </a>
          <% end %>
        </div>
      </section>
    </div>
    """
  end
end
