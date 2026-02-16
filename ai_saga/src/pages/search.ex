defmodule AiSaga.Pages.Search do
  use Nex

  def mount(params) do
    query = params["q"] || ""
    paradigm_slug = params["paradigm"] || ""
    year_from = params["year_from"] || ""
    year_to = params["year_to"] || ""
    sort_by = params["sort"] || "relevance"

    # 获取所有范式用于筛选
    {:ok, paradigms} =
      NexBase.from("paradigms")
      |> NexBase.order(:start_year, :asc)
      |> NexBase.run()

    # 构建搜索查询
    papers = search_papers(query, paradigm_slug, year_from, year_to, sort_by)

    %{
      title: if(query != "", do: "搜索: #{query}", else: "搜索论文"),
      query: query,
      paradigm_slug: paradigm_slug,
      year_from: year_from,
      year_to: year_to,
      sort_by: sort_by,
      paradigms: paradigms,
      papers: papers
    }
  end

  defp search_papers(query, paradigm_slug, year_from, year_to, sort_by) do
    # 基础查询
    base_query =
      if query != "" do
        NexBase.from("papers")
        |> NexBase.ilike(:title, "%#{query}%")
      else
        NexBase.from("papers")
      end

    # 范式筛选
    query_with_paradigm =
      if paradigm_slug != "" do
        # 先获取范式ID
        case NexBase.from("paradigms") |> NexBase.eq(:slug, paradigm_slug) |> NexBase.single() |> NexBase.run() do
          {:ok, [paradigm]} ->
            base_query |> NexBase.eq(:paradigm_id, paradigm["id"])
          _ ->
            base_query
        end
      else
        base_query
      end

    # 年份筛选
    query_with_year =
      query_with_paradigm
      |> maybe_add_year_filter(year_from, :gte, :published_year)
      |> maybe_add_year_filter(year_to, :lte, :published_year)

    # 排序
    final_query =
      case sort_by do
        "year_asc" ->
          query_with_year |> NexBase.order(:published_year, :asc)
        "year_desc" ->
          query_with_year |> NexBase.order(:published_year, :desc)
        "citations" ->
          query_with_year |> NexBase.order(:citations, :desc)
        _ ->
          query_with_year |> NexBase.order(:published_year, :desc)
      end

    case final_query |> NexBase.limit(50) |> NexBase.run() do
      {:ok, papers} -> papers
      _ -> []
    end
  end

  defp maybe_add_year_filter(query, year_str, _op, _field) when year_str == "" or is_nil(year_str), do: query
  defp maybe_add_year_filter(query, year_str, op, field) do
    case Integer.parse(year_str) do
      {year, _} ->
        if op == :gte do
          NexBase.where(query, "#{field} >= ?", [year])
        else
          NexBase.where(query, "#{field} <= ?", [year])
        end
      :error ->
        query
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto space-y-8">
      <a href="/" class="back-link mb-6 inline-block">
        ← 返回首页
      </a>

      <div class="page-header">
        <h1>🔍 搜索论文</h1>
        <p>通过关键词、范式或年份筛选找到你感兴趣的论文</p>
      </div>

      <%!-- 搜索表单 --%>
      <form action="/search" method="get" class="space-y-4">
        <%!-- 关键词搜索 --%>
        <div class="flex gap-3">
          <input
            type="text"
            name="q"
            value={@query}
            placeholder="输入论文标题关键词..."
            class="flex-1 px-4 py-3 border-2 border-black bg-white focus:outline-none focus:ring-2 focus:ring-[rgb(255,222,0)]"
            autofocus
          />
          <button type="submit" class="px-6 py-3 bg-[rgb(255,222,0)] border-2 border-black font-bold hover:bg-yellow-300 transition-colors">
            搜索
          </button>
        </div>

        <%!-- 筛选条件 --%>
        <div class="grid md:grid-cols-4 gap-3 bg-gray-50 p-4 border-2 border-black">
          <%!-- 范式筛选 --%>
          <div>
            <label class="block text-xs font-mono opacity-60 mb-1">研究范式</label>
            <select name="paradigm" class="w-full px-3 py-2 border-2 border-black bg-white focus:outline-none focus:ring-2 focus:ring-[rgb(255,222,0)]">
              <option value="">全部范式</option>
              <%= for paradigm <- @paradigms do %>
                <option value={paradigm["slug"]} selected={@paradigm_slug == paradigm["slug"]}>
                  {paradigm["name"]}
                </option>
              <% end %>
            </select>
          </div>

          <%!-- 年份范围 --%>
          <div>
            <label class="block text-xs font-mono opacity-60 mb-1">起始年份</label>
            <input
              type="number"
              name="year_from"
              value={@year_from}
              placeholder="1950"
              class="w-full px-3 py-2 border-2 border-black bg-white focus:outline-none focus:ring-2 focus:ring-[rgb(255,222,0)]"
            />
          </div>

          <div>
            <label class="block text-xs font-mono opacity-60 mb-1">结束年份</label>
            <input
              type="number"
              name="year_to"
              value={@year_to}
              placeholder="2026"
              class="w-full px-3 py-2 border-2 border-black bg-white focus:outline-none focus:ring-2 focus:ring-[rgb(255,222,0)]"
            />
          </div>

          <%!-- 排序方式 --%>
          <div>
            <label class="block text-xs font-mono opacity-60 mb-1">排序方式</label>
            <select name="sort" class="w-full px-3 py-2 border-2 border-black bg-white focus:outline-none focus:ring-2 focus:ring-[rgb(255,222,0)]">
              <option value="relevance" selected={@sort_by == "relevance"}>相关度</option>
              <option value="year_desc" selected={@sort_by == "year_desc"}>最新优先</option>
              <option value="year_asc" selected={@sort_by == "year_asc"}>最早优先</option>
              <option value="citations" selected={@sort_by == "citations"}>引用数</option>
            </select>
          </div>
        </div>
      </form>

      <%!-- 搜索结果 --%>
      <%= if @query != "" or @paradigm_slug != "" or @year_from != "" or @year_to != "" do %>
        <div class="flex items-center justify-between">
          <p class="text-sm font-mono opacity-60">
            找到 <%= length(@papers) %> 篇论文
          </p>

          <%!-- 快速筛选标签 --%>
          <div class="flex gap-2">
            <%= if @paradigm_slug != "" do %>
              <% paradigm = Enum.find(@paradigms, fn p -> p["slug"] == @paradigm_slug end) %>
              <%= if paradigm do %>
                <span class="px-2 py-1 bg-[rgb(111,194,255)] text-xs border border-black">
                  {paradigm["name"]}
                </span>
              <% end %>
            <% end %>
            <%= if @year_from != "" or @year_to != "" do %>
              <span class="px-2 py-1 bg-gray-200 text-xs border border-black">
                <%= @year_from %><%= if @year_from != "" and @year_to != "", do: "-", else: "" %><%= @year_to %>
              </span>
            <% end %>
          </div>
        </div>

        <%= if length(@papers) > 0 do %>
          <div class="space-y-4">
            <%= for paper <- @papers do %>
              <a href={"/paper/#{paper["slug"]}"} class="card block p-5">
                <div class="flex items-start justify-between gap-4">
                  <div class="flex-1">
                    <div class="flex items-center gap-3 mb-2">
                      <span class="year-tag">{paper["published_year"]}</span>
                      <%= if paper["is_paradigm_shift"] == 1 do %>
                        <span class="badge badge-yellow">范式突破</span>
                      <% end %>
                    </div>
                    <h2 class="font-bold mb-2 line-clamp-2">{paper["title"]}</h2>
                    <p class="text-sm opacity-60 line-clamp-2 mb-3">{paper["abstract"]}</p>
                    <div class="flex items-center gap-4 text-xs font-mono opacity-50">
                      <span>{paper["citations"]} 引用</span>
                    </div>
                  </div>
                </div>
              </a>
            <% end %>
          </div>
        <% else %>
          <div class="empty-state">
            <p>没有找到符合条件的论文</p>
            <p class="hint">请尝试调整搜索条件</p>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end
end
