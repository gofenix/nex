defmodule AiSaga.Pages.Search do
  use Nex

  def mount(%{"q" => query}) do
    papers = NexBase.from("papers")
    |> NexBase.ilike(:title, "%#{query}%")
    |> NexBase.order(:published_at, :desc)
    |> NexBase.limit(50)
    |> NexBase.run()

    %{
      title: "Search: #{query}",
      query: query,
      papers: papers |> elem(1)
    }
  end

  def mount(_params) do
    %{
      title: "Search Papers",
      query: "",
      papers: []
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto space-y-6">
      <a href="/" class="btn btn-ghost btn-sm">← Back</a>

      <form action="/search" method="get" class="flex gap-2">
        <input
          type="text"
          name="q"
          value={@query}
          placeholder="Search papers..."
          class="input input-bordered w-full max-w-md"
          autofocus
        />
        <button type="submit" class="btn btn-primary">Search</button>
      </form>

      <%= if @query != "" do %>
        <p class="text-base-content/60">Found <%= length(@papers) %> papers for "<%= @query %>"</p>

        <div class="space-y-4">
          <%= for paper <- @papers do %>
            <a href={"/paper/#{paper["id"]}"} class="block bg-base-200 p-6 rounded-2xl hover:bg-base-300 transition border border-base-300">
              <h2 class="text-xl font-bold mb-2 line-clamp-2">{paper["title"]}</h2>
              <p class="text-sm text-base-content/60 mb-3 line-clamp-2">{paper["abstract"]}</p>
              <div class="flex flex-wrap gap-2 text-xs">
                <span class="badge badge-neutral">{paper["categories"]}</span>
              </div>
            </a>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
