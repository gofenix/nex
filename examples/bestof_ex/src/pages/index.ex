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
          <div :for={project <- @hot_projects} class="card bg-base-100 shadow-sm hover:shadow-md transition-shadow">
            <div class="card-body">
              <h3 class="card-title text-lg">
                <a href={"/projects/#{project["id"]}"} class="hover:text-primary">{project["name"]}</a>
              </h3>
              <p class="text-base-content/60 text-sm line-clamp-2">{project["description"]}</p>
              <div class="flex items-center justify-between mt-4 text-sm">
                <span class="flex items-center gap-1 text-base-content/50">
                  <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                  </svg>
                  {project["stars"] || 0}
                </span>
                <a :if={project["repo_url"]} href={project["repo_url"]} target="_blank" class="btn btn-ghost btn-xs">
                  GitHub
                </a>
              </div>
            </div>
          </div>
        </div>
        <div :if={Enum.empty?(@hot_projects)} class="text-center py-8 text-base-content/50">
          <p>No projects yet. Run <code>mix run seeds/import.exs</code> to seed data.</p>
        </div>
      </section>

      <section>
        <h2 class="text-2xl font-bold mb-6">Popular Tags</h2>
        <div class="flex flex-wrap gap-2">
          <a :for={tag <- @popular_tags}
             href={"/tags/#{tag["slug"]}"}
             class="badge badge-outline hover:badge-primary transition-colors">
            {tag["name"]}
          </a>
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
