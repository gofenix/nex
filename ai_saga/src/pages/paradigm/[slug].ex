defmodule AiSaga.Pages.Paradigm.Slug do
  use Nex

  def mount(%{"slug" => slug}) do
    {:ok, [paradigm]} =
      NexBase.from("paradigms")
      |> NexBase.eq(:slug, slug)
      |> NexBase.single()
      |> NexBase.run()

    {:ok, papers} =
      NexBase.from("papers")
      |> NexBase.eq(:paradigm_id, paradigm["id"])
      |> NexBase.order(:published_year, :asc)
      |> NexBase.run()

    %{
      title: paradigm["name"],
      paradigm: paradigm,
      papers: papers
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto space-y-8">
      <a href="/" class="inline-flex items-center gap-2 text-sm font-mono opacity-60 hover:opacity-100">
        ← 返回首页
      </a>

      <header class="space-y-4">
        <div class="flex items-center gap-3">
          <span class="text-4xl">📚</span>
          <h1 class="text-4xl font-black">{@paradigm["name"]}</h1>
        </div>
        <p class="text-lg opacity-80">{@paradigm["description"]}</p>

        <div class="flex items-center gap-6 text-sm font-mono opacity-60">
          <span>{@paradigm["start_year"]} - <%= if @paradigm["end_year"], do: @paradigm["end_year"], else: "现在" %></span>
        </div>

        <%= if @paradigm["crisis"] do %>
          <div class="bg-red-50 p-4 border-2 border-black">
            <h3 class="font-bold mb-2">⚠️ 危机</h3>
            <p class="opacity-80">{@paradigm["crisis"]}</p>
          </div>
        <% end %>

        <%= if @paradigm["revolution"] do %>
          <div class="bg-[rgb(255,222,0)] p-4 border-2 border-black">
            <h3 class="font-bold mb-2">🎉 革命</h3>
            <p class="opacity-80">{@paradigm["revolution"]}</p>
          </div>
        <% end %>
      </header>

      <section>
        <h2 class="text-2xl font-bold mb-6">该时期的论文</h2>
        <div class="space-y-4">
          <%= for paper <- @papers do %>
            <a href={"/paper/#{paper["slug"]}"} class="block bg-white p-5 border-2 border-black md-shadow-sm hover:translate-x-1 hover:translate-y-1 transition-transform">
              <div class="flex items-start justify-between gap-4">
                <div class="flex-1">
                  <div class="flex items-center gap-2 mb-2">
                    <span class="font-mono text-sm opacity-60">{paper["published_year"]}</span>
                    <%= if paper["is_paradigm_shift"] == 1 do %>
                      <span class="px-2 py-0.5 bg-[rgb(255,222,0)] border border-black text-xs font-mono">范式变迁</span>
                    <% end %>
                  </div>
                  <h3 class="font-bold mb-2 line-clamp-2">{paper["title"]}</h3>
                  <p class="text-sm opacity-60 line-clamp-2">{paper["abstract"]}</p>
                </div>
                <span class="text-sm font-mono opacity-40">{paper["citations"]}</span>
              </div>
            </a>
          <% end %>
        </div>
      </section>
    </div>
    """
  end
end
