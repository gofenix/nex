defmodule AiSaga.Pages.Timeline do
  use Nex

  def mount(_params) do
    {:ok, papers} = NexBase.from("papers")
    |> NexBase.order(:published_year, :asc)
    |> NexBase.run()

    %{
      title: "AI 论文时间线",
      papers: papers
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto space-y-8">
      <a href="/" class="inline-flex items-center gap-2 text-sm font-mono opacity-60 hover:opacity-100">
        ← 返回首页
      </a>

      <h1 class="text-3xl font-black">📅 AI 论文时间线</h1>

      <div class="relative">
        <div class="absolute left-4 top-0 bottom-0 w-0.5 bg-black"></div>
        <div class="space-y-6">
          <%= for paper <- @papers do %>
            <div class="relative pl-12">
              <div class="absolute left-2 w-4 h-4 bg-[rgb(255,222,0)] border-2 border-black"></div>
              <a href={"/paper/#{paper["slug"]}"} class="block bg-white p-5 border-2 border-black md-shadow-sm hover:translate-x-1 hover:translate-y-1 transition-transform">
                <div class="flex items-center gap-2 mb-2">
                  <span class="font-mono text-lg font-bold">{paper["published_year"]}</span>
                  <%= if paper["is_paradigm_shift"] == 1 do %>
                    <span class="px-2 py-0.5 bg-[rgb(255,222,0)] border border-black text-xs font-mono">范式变迁</span>
                  <% end %>
                </div>
                <h3 class="font-bold mb-2">{paper["title"]}</h3>
                <p class="text-sm opacity-60 line-clamp-2">{paper["abstract"]}</p>
              </a>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
