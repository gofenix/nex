defmodule AiSaga.Pages.Paradigm.Index do
  use Nex

  def mount(_params) do
    {:ok, paradigms} =
      NexBase.from("paradigms")
      |> NexBase.order(:start_year, :asc)
      |> NexBase.run()

    # 为每个范式计算统计数据
    paradigms_with_stats =
      Enum.map(paradigms, fn p ->
        {:ok, papers} =
          NexBase.from("papers")
          |> NexBase.eq(:paradigm_id, p["id"])
          |> NexBase.run()

        shift_count = Enum.count(papers, &(&1["is_paradigm_shift"] == 1))
        total_citations = Enum.sum(Enum.map(papers, &(&1["citations"] || 0)))

        Map.merge(p, %{
          "paper_count" => length(papers),
          "shift_count" => shift_count,
          "total_citations" => total_citations
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
      <div class="text-center py-8">
        <a href="/" class="inline-flex items-center gap-2 text-sm font-mono opacity-60 hover:opacity-100 mb-4">
          ← 返回首页
        </a>
        <h1 class="text-4xl font-black mb-3">AI 范式演进</h1>
        <p class="text-lg opacity-60 max-w-xl mx-auto">
          从1957年感知机诞生到2026年大模型时代，探索人工智能发展的五个重要阶段
        </p>
        <div class="mt-4 text-sm font-mono opacity-40">
          {@total_paradigms} 个研究范式 · 跨越 {@total_years} 年
        </div>
      </div>

      <%!-- 时间线视图 --%>
      <div class="relative">
        <%!-- 中心时间线 --%>
        <div class="absolute left-8 md:left-1/2 md:-translate-x-1/2 top-0 bottom-0 w-1 bg-black"></div>

        <div class="space-y-8">
          <%= for {paradigm, index} <- Enum.with_index(@paradigms) do %>
            <% is_left = rem(index, 2) == 0 %>

            <div class={if is_left, do: "relative flex items-start md:flex-row", else: "relative flex items-start md:flex-row-reverse"}>
              <%!-- 节点圆点 --%>
              <div class="absolute left-8 md:left-1/2 md:-translate-x-1/2 w-4 h-4 bg-[rgb(255,222,0)] border-2 border-black z-10 mt-6"></div>

              <%!-- 年份标签 --%>
              <div class={if is_left, do: "absolute left-16 md:left-auto md:right-1/2 md:mr-8 top-5 font-mono text-sm font-bold bg-black text-white px-2 py-1", else: "absolute left-16 md:left-1/2 md:ml-8 top-5 font-mono text-sm font-bold bg-black text-white px-2 py-1"}>
                {paradigm["start_year"]}
              </div>

              <%!-- 内容卡片 --%>
              <div class={if is_left, do: "ml-20 md:ml-0 md:w-5/12 md:pr-12", else: "ml-20 md:ml-0 md:w-5/12 md:pl-12"}>
                <a href={"/paradigm/#{paradigm["slug"]}"} class="block bg-white p-5 border-2 border-black md-shadow-sm hover:translate-x-1 hover:translate-y-1 transition-transform">
                  <div class="flex items-center gap-2 mb-3">
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
                    <span class="px-2 py-1 bg-gray-100 border border-black">
                      {paradigm["paper_count"]} 篇论文
                    </span>
                    <%= if paradigm["shift_count"] > 0 do %>
                      <span class="px-2 py-1 bg-[rgb(255,222,0)] border border-black">
                        {paradigm["shift_count"]} 次突破
                      </span>
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
    </div>
    """
  end
end
