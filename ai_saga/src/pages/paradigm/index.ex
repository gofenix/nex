defmodule AiSaga.Pages.Paradigm.Index do
  use Nex

  def mount(_params) do
    {:ok, paradigms} =
      NexBase.from("paradigms")
      |> NexBase.order(:start_year, :asc)
      |> NexBase.run()

    # 一次查询获取所有范式的统计数据（避免 N+1）
    {:ok, stats} =
      NexBase.sql(
        "SELECT paradigm_id, COUNT(*) as paper_count, COALESCE(SUM(CASE WHEN is_paradigm_shift = 1 THEN 1 ELSE 0 END), 0) as shift_count, COALESCE(SUM(citations), 0) as total_citations FROM papers GROUP BY paradigm_id"
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

    # 计算总跨度
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
      title: "AI 范式演进",
      paradigms: paradigms_with_stats,
      total_paradigms: length(paradigms),
      total_years: total_years
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto space-y-10">
      <a href="/" class="back-link mb-4 inline-block">
        ← 返回首页
      </a>

      <div class="page-header">
        <h1>AI 范式演进</h1>
        <p>从1957年感知机诞生到2026年大模型时代，探索人工智能发展的五个重要阶段</p>
        <div class="meta">{@total_paradigms} 个研究范式 · 跨越 {@total_years} 年</div>
      </div>

      <%= if length(@paradigms) > 0 do %>
        <%!-- 时间线视图 --%>
        <div class="relative">
          <%!-- 中心时间线 --%>
          <div class="timeline-line"></div>

          <div class="space-y-8">
            <%= for {paradigm, index} <- Enum.with_index(@paradigms) do %>
              <% is_left = rem(index, 2) == 0 %>

              <div class={if is_left, do: "relative flex items-start md:flex-row", else: "relative flex items-start md:flex-row-reverse"}>
                <%!-- 节点圆点 --%>
                <div class="timeline-dot mt-6"></div>

                <%!-- 年份标签 --%>
                <div class={if is_left, do: "absolute left-16 md:left-auto md:right-1/2 md:mr-8 top-5 font-mono text-sm font-bold bg-black text-white px-2 py-1", else: "absolute left-16 md:left-1/2 md:ml-8 top-5 font-mono text-sm font-bold bg-black text-white px-2 py-1"}>
                  {paradigm["start_year"]}
                </div>

                <%!-- 内容卡片 --%>
                <div class={if is_left, do: "ml-20 md:ml-0 md:w-5/12 md:pr-12", else: "ml-20 md:ml-0 md:w-5/12 md:pl-12"}>
                  <a href={"/paradigm/#{paradigm["slug"]}"} class="card block p-5">
                    <div class="flex items-center gap-3 mb-3">
                      <span class="text-2xl">
                        <%= case paradigm["slug"] do %>
                          <% "perceptron" -> %> 🧠
                          <% "symbolic-ai" -> %> 🔤
                          <% "connectionism" -> %> 🔗
                          <% "deep-learning" -> %> 🎯
                          <% "transformers" -> %> ⚡
                          <% _ -> %> 📊
                        <% end %>
                      </span>
                      <h3 class="text-xl font-bold">{paradigm["name"]}</h3>
                    </div>

                    <p class="text-sm opacity-70 mb-4 line-clamp-2">{paradigm["description"]}</p>

                    <div class="flex flex-wrap gap-2 text-xs font-mono">
                      <span class="badge badge-gray">{paradigm["paper_count"]} 篇论文</span>
                      <%= if paradigm["shift_count"] > 0 do %>
                        <span class="badge badge-yellow">{paradigm["shift_count"]} 次突破</span>
                      <% end %>
                    </div>

                    <%= if paradigm["crisis"] || paradigm["revolution"] do %>
                      <div class="mt-3 pt-3 border-t border-gray-200 text-xs">
                        <%= if paradigm["crisis"] do %>
                          <span class="text-red-600 mr-3">⚠️ 面临挑战</span>
                        <% end %>
                        <%= if paradigm["revolution"] do %>
                          <span class="text-green-600">🎉 革命突破</span>
                        <% end %>
                      </div>
                    <% end %>
                  </a>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% else %>
        <div class="empty-state">
          <p>暂无范式数据</p>
          <p class="hint">请稍后再试</p>
        </div>
      <% end %>
    </div>
    """
  end
end
