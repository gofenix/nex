defmodule BestofEx.Pages.Index do
  use Nex

  @client NexBase.client(repo: BestofEx.Repo)

  def mount(_params) do
    hot_projects = fetch_hot_projects()
    popular_tags = fetch_popular_tags()

    %{
      title: "Best of Elixir",
      hot_projects: hot_projects,
      popular_tags: popular_tags
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-12">
      <section class="text-center py-12">
        <h1 class="text-4xl font-bold text-base-content mb-4">The Best of Elixir</h1>
        <p class="text-lg text-base-content/60 max-w-2xl mx-auto">
          A curated list of the best Elixir libraries and tools for your next project.
        </p>
      </section>

      <section>
        <h2 class="text-2xl font-bold mb-6">Hot Projects</h2>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <.BestofEx.Components.ProjectCard.project_card :for={project <- @hot_projects} project={project} />
        </div>
        <div :if={Enum.empty?(@hot_projects)} class="text-center py-8 text-base-content/50">
          <p>No projects yet. Run <code>mix run seeds/import.exs</code> to seed data.</p>
        </div>
      </section>

      <section>
        <h2 class="text-2xl font-bold mb-6">Popular Tags</h2>
        <div class="flex flex-wrap gap-2">
          <.BestofEx.Components.TagChip.tag_chip :for={tag <- @popular_tags} tag={tag} />
        </div>
        <div :if={Enum.empty?(@popular_tags)} class="text-center py-8 text-base-content/50">
          <p>No tags yet. Run <code>mix run seeds/import.exs</code> to seed data.</p>
        </div>
      </section>
    </div>
    """
  end

  defp fetch_hot_projects do
    case @client
    |> NexBase.from("projects")
    |> NexBase.order(:stars, :desc)
    |> NexBase.limit(6)
    |> NexBase.run() do
      {:ok, projects} -> projects
      _ -> []
    end
  end

  defp fetch_popular_tags do
    case @client
    |> NexBase.from("tags")
    |> NexBase.order(:name, :asc)
    |> NexBase.limit(10)
    |> NexBase.run() do
      {:ok, tags} -> tags
      _ -> []
    end
  end
end
