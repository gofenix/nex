defmodule AiSaga.Pages.Authors do
  use Nex

  def mount(_params) do
    {:ok, authors} = NexBase.from("authors")
    |> NexBase.order(:influence_score, :desc)
    |> NexBase.run()

    %{
      title: "重要人物",
      authors: authors
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto space-y-8">
      <a href="/" class="inline-flex items-center gap-2 text-sm font-mono opacity-60 hover:opacity-100">
        ← 返回首页
      </a>

      <h1 class="text-3xl font-black">👥 AI 领域重要人物</h1>

      <div class="grid md:grid-cols-2 gap-4">
        <%= for author <- @authors do %>
          <a href={"/author/#{author["slug"]}"} class="block bg-white p-5 border-2 border-black md-shadow-sm hover:translate-x-1 hover:translate-y-1 transition-transform">
            <div class="flex items-center gap-3 mb-2">
              <span class="text-2xl">👤</span>
              <h3 class="font-bold">{author["name"]}</h3>
            </div>
            <p class="text-sm opacity-60 mb-2">{author["affiliation"]}</p>
            <p class="text-sm opacity-80 line-clamp-2">{author["bio"]}</p>
            <div class="mt-3 text-xs font-mono opacity-50">
              影响力: {author["influence_score"]} | 首篇: {author["first_paper_year"]}年
            </div>
          </a>
        <% end %>
      </div>
    </div>
    """
  end
end
