defmodule AiSaga.Pages.Paradigm.Index do
  use Nex

  def mount(_params) do
    {:ok, paradigms} =
      NexBase.from("paradigms")
      |> NexBase.order(:start_year, :asc)
      |> NexBase.run()

    %{
      title: "所有范式",
      paradigms: paradigms
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto space-y-8">
      <a href="/" class="inline-flex items-center gap-2 text-sm font-mono opacity-60 hover:opacity-100">
        ← 返回首页
      </a>

      <h1 class="text-3xl font-black">AI 范式演进</h1>

      <div class="space-y-6">
        <%= for paradigm <- @paradigms do %>
          <a href={"/paradigm/#{paradigm["slug"]}"} class="block bg-white p-6 border-2 border-black md-shadow-sm hover:translate-x-1 hover:translate-y-1 transition-transform">
            <div class="flex items-center justify-between mb-3">
              <h3 class="text-xl font-bold">{paradigm["name"]}</h3>
              <span class="font-mono text-sm opacity-60">
                <%= paradigm["start_year"] %> - <%= if paradigm["end_year"], do: paradigm["end_year"], else: "现在" %>
              </span>
            </div>
            <p class="opacity-70 mb-4">{paradigm["description"]}</p>
            
            <%= if paradigm["crisis"] do %>
              <div class="text-sm opacity-60 mb-2">
                <span class="font-bold">危机:</span> {paradigm["crisis"]}
              </div>
            <% end %>
            
            <%= if paradigm["revolution"] do %>
              <div class="text-sm">
                <span class="font-bold">革命:</span> {paradigm["revolution"]}
              </div>
            <% end %>
          </a>
        <% end %>
      </div>
    </div>
    """
  end
end
