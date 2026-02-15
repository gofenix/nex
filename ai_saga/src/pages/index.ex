defmodule AiSaga.Pages.Index do
  use Nex

  def mount(_params) do
    {:ok, paradigms} =
      NexBase.from("paradigms")
      |> NexBase.order(:start_year, :asc)
      |> NexBase.run()

    {:ok, daily} =
      NexBase.from("papers")
      |> NexBase.eq(:is_daily_pick, 1)
      |> NexBase.single()
      |> NexBase.run()

    {:ok, recent} =
      NexBase.from("papers")
      |> NexBase.order(:published_year, :desc)
      |> NexBase.limit(5)
      |> NexBase.run()

    {:ok, all_papers} =
      NexBase.from("papers")
      |> NexBase.run()

    {:ok, shifts} =
      NexBase.from("papers")
      |> NexBase.eq(:is_paradigm_shift, 1)
      |> NexBase.order(:published_year, :asc)
      |> NexBase.run()

    %{
      title: "AiSaga - 理解AI的起点",
      paradigms: paradigms,
      daily: List.first(daily || []),
      recent: recent,
      all_papers: all_papers,
      shifts: shifts
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-12">
      <div class="text-center py-8 border-b-2 border-black pb-8">
        <h1 class="text-5xl font-black mb-3 tracking-tight">🤖 AiSaga</h1>
        <p class="text-lg opacity-60 max-w-xl mx-auto">
          理解AI的起点。通过历史、范式与人物的视角，读懂每一篇重要论文。
        </p>
      </div>

      <section>
        <div class="flex items-center gap-3 mb-6">
          <span class="text-2xl">✨</span>
          <h2 class="text-2xl font-bold">今日推荐</h2>
        </div>
        <%= if @daily do %>
          <a href={"/paper/#{@daily["slug"]}"} class="block bg-[rgb(255,222,0)] p-8 border-2 border-black md-shadow hover:translate-x-1 hover:translate-y-1 transition-transform">
            <div class="flex items-center gap-3 mb-3">
              <span class="px-3 py-1 bg-black text-white text-sm font-mono">PARADIGM SHIFT</span>
              <span class="text-sm opacity-60">{@daily["published_year"]}</span>
            </div>
            <h3 class="text-2xl font-bold mb-3">{@daily["title"]}</h3>
            <p class="text-base mb-4 line-clamp-3">{@daily["abstract"]}</p>
            <div class="flex items-center justify-between">
              <span class="text-sm font-mono opacity-60">阅读更多 →</span>
              <span class="text-sm font-mono">{@daily["citations"]} citations</span>
            </div>
          </a>
        <% else %>
          <div class="bg-white p-6 border-2 border-black md-shadow">
            <p class="text-center opacity-60">暂无今日推荐</p>
          </div>
        <% end %>
      </section>

      <section>
        <div class="flex items-center gap-3 mb-6">
          <span class="text-2xl">📅</span>
          <h2 class="text-2xl font-bold">范式时间线</h2>
        </div>
        <div class="relative">
          <div class="absolute left-4 top-0 bottom-0 w-0.5 bg-black"></div>
          <div class="space-y-8">
            <%= for paradigm <- @paradigms do %>
              <div class="relative pl-12">
                <div class="absolute left-2 w-4 h-4 bg-[rgb(111,194,255)] border-2 border-black"></div>
                <a href={"/paradigm/#{paradigm["slug"]}"} class="block bg-white p-5 border-2 border-black md-shadow-sm hover:bg-gray-50">
                  <div class="flex items-center justify-between mb-2">
                    <h3 class="text-xl font-bold">{paradigm["name"]}</h3>
                    <span class="font-mono text-sm opacity-60">
                      <%= paradigm["start_year"] %> - <%= if paradigm["end_year"], do: paradigm["end_year"], else: "现在" %>
                    </span>
                  </div>
                  <p class="text-sm opacity-70 line-clamp-2">{paradigm["description"]}</p>
                </a>
              </div>
            <% end %>
          </div>
        </div>
      </section>

      <section class="bg-white p-6 border-2 border-black md-shadow">
        <div class="flex items-center gap-3 mb-4">
          <span class="text-2xl">🎲</span>
          <h2 class="text-2xl font-bold">AI自动生成论文</h2>
        </div>
        <p class="text-sm opacity-70 mb-4">
          基于已有 <%= length(@all_papers) %> 篇论文，AI将从HuggingFace热门论文中推荐并生成下一篇的深度解读。
        </p>
        <button
          hx-post="/api/generate_paper"
          hx-target="#generate-result"
          hx-swap="outerHTML"
          class="px-6 py-3 bg-[rgb(255,222,0)] border-2 border-black font-bold hover:bg-yellow-300 transition-colors"
        >
          开始生成
        </button>
        <div id="generate-result" class="mt-4"></div>
      </section>

      <section>
        <div class="flex items-center gap-3 mb-6">
          <span class="text-2xl">⚡</span>
          <h2 class="text-2xl font-bold">范式变迁时刻</h2>
        </div>
        <div class="grid md:grid-cols-2 gap-4">
          <%= for paper <- @shifts do %>
            <a href={"/paper/#{paper["slug"]}"} class="block bg-white p-5 border-2 border-black md-shadow-sm hover:translate-x-1 hover:translate-y-1 transition-transform">
              <div class="flex items-center gap-2 mb-2">
                <span class="w-2 h-2 bg-[rgb(255,222,0)]"></span>
                <span class="font-mono text-sm">{paper["published_year"]}</span>
              </div>
              <h3 class="font-bold mb-2 line-clamp-2">{paper["title"]}</h3>
              <p class="text-sm opacity-60 line-clamp-2">{paper["shift_trigger"]}</p>
            </a>
          <% end %>
        </div>
      </section>
    </div>
    """
  end
end
