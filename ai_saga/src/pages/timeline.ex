defmodule AiSaga.Pages.Timeline do
  use Nex

  def mount(_params) do
    {:ok, papers} =
      NexBase.from("papers")
      |> NexBase.select([:title, :slug, :abstract, :published_year, :is_paradigm_shift])
      |> NexBase.order(:published_year, :asc)
      |> NexBase.run()

    %{
      title: "AI 论文时间线",
      papers: papers
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto space-y-8">
      <a href="/" class="back-link mb-6 inline-block">
        ← 返回首页
      </a>

      <div class="page-header">
        <h1>📅 AI 论文时间线</h1>
        <p>按时间顺序探索人工智能的发展历程</p>
      </div>

      <%= if length(@papers) > 0 do %>
        <div class="relative">
          <div class="timeline-line"></div>
          <div class="space-y-6">
            <%= for paper <- @papers do %>
              <div class="relative pl-12">
                <div class="timeline-dot top-5"></div>
                <a href={"/paper/#{paper["slug"]}"} class="card block p-5">
                  <div class="flex items-center gap-3 mb-2">
                    <span class="year-tag font-bold">{paper["published_year"]}</span>
                    <%= if paper["is_paradigm_shift"] == 1 do %>
                      <span class="badge badge-yellow">范式变迁</span>
                    <% end %>
                  </div>
                  <h3 class="font-bold mb-2">{paper["title"]}</h3>
                  <p class="text-sm opacity-60 line-clamp-2">{paper["abstract"]}</p>
                </a>
              </div>
            <% end %>
          </div>
        </div>
      <% else %>
        <div class="empty-state">
          <p>暂无论文数据</p>
          <p class="hint">请稍后再试</p>
        </div>
      <% end %>
    </div>
    """
  end
end
