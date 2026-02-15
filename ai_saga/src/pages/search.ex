defmodule AiSaga.Pages.Search do
  use Nex

  def mount(%{"q" => query}) do
    {:ok, papers} =
      NexBase.from("papers")
      |> NexBase.ilike(:title, "%#{query}%")
      |> NexBase.order(:published_year, :desc)
      |> NexBase.limit(50)
      |> NexBase.run()

    %{
      title: "搜索: #{query}",
      query: query,
      papers: papers
    }
  end

  def mount(_params) do
    %{
      title: "搜索论文",
      query: "",
      papers: []
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto space-y-8">
      <a href="/" class="inline-flex items-center gap-2 text-sm font-mono opacity-60 hover:opacity-100">
        ← 返回首页
      </a>

      <h1 class="text-3xl font-black">🔍 搜索论文</h1>

      <form action="/search" method="get" class="flex gap-3">
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
      </form>

      <%= if @query != "" do %>
        <p class="text-sm font-mono opacity-60">找到 <%= length(@papers) %> 篇关于 "<%= @query %>" 的论文</p>

        <div class="space-y-4">
          <%= for paper <- @papers do %>
            <a href={"/paper/#{paper["slug"]}"} class="block bg-white p-5 border-2 border-black md-shadow-sm hover:translate-x-1 hover:translate-y-1 transition-transform">
              <div class="flex items-center gap-2 mb-2">
                <span class="font-mono text-sm opacity-60">{paper["published_year"]}</span>
                <%= if paper["is_paradigm_shift"] == 1 do %>
                  <span class="px-2 py-0.5 bg-[rgb(255,222,0)] border border-black text-xs font-mono">范式变迁</span>
                <% end %>
              </div>
              <h2 class="font-bold mb-2 line-clamp-2">{paper["title"]}</h2>
              <p class="text-sm opacity-60 line-clamp-2">{paper["abstract"]}</p>
            </a>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
