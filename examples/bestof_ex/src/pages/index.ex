defmodule BestofEx.Pages.Index do
  use Nex

  def mount(_params) do
    %{
      title: "Best of Elixir",
      hot_projects: fetch_hot_projects(),
      popular_tags: fetch_popular_tags()
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-10">
      <section class="text-center py-10">
        <h1 class="text-5xl font-extrabold text-base-content mb-3">
          Best of <span class="text-primary">Elixir</span>
        </h1>
        <p class="text-lg text-base-content/60 max-w-xl mx-auto">
          A curated list of the best open-source projects in the Elixir ecosystem,
          ranked by GitHub stars.
        </p>
        <div class="mt-6 flex justify-center gap-3">
          <a href="/projects" class="btn btn-primary btn-sm">Browse All Projects</a>
          <a href="/tags" class="btn btn-outline btn-sm">Explore Tags</a>
        </div>
      </section>

      <section>
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-xl font-bold">Hot Projects</h2>
          <a href="/projects" class="link link-primary text-sm">View all →</a>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <div :for={project <- @hot_projects} class="card bg-base-100 shadow-sm hover:shadow-md transition-all border border-base-300">
            <div class="card-body p-5">
              <div class="flex items-start justify-between">
                <h3 class="card-title text-base">
                  <a href={"/projects/#{project["id"]}"} class="hover:text-primary">{project["name"]}</a>
                </h3>
                <div class="flex items-center gap-1 text-sm star-icon font-semibold">
                  <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z"/></svg>
                  {format_stars(project["stars"] || 0)}
                </div>
              </div>
              <p class="text-base-content/60 text-sm line-clamp-2 mt-1">{project["description"]}</p>
              <div class="card-actions justify-end mt-3">
                <a :if={project["repo_url"]} href={project["repo_url"]} target="_blank" class="btn btn-ghost btn-xs gap-1">
                  <svg class="w-4 h-4" viewBox="0 0 24 24" fill="currentColor"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/></svg>
                  GitHub
                </a>
              </div>
            </div>
          </div>
        </div>
        <div :if={Enum.empty?(@hot_projects)} class="alert">
          <span>No projects yet. Run <code class="kbd kbd-sm">mix run seeds/import.exs</code> to seed data.</span>
        </div>
      </section>

      <section>
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-xl font-bold">Explore by Tag</h2>
          <a href="/tags" class="link link-primary text-sm">All tags →</a>
        </div>
        <div class="flex flex-wrap gap-2">
          <a :for={tag <- @popular_tags}
             href={"/tags/#{tag["slug"]}"}
             class="badge badge-lg badge-outline hover:badge-primary gap-1 transition-colors cursor-pointer">
            {tag["name"]}
          </a>
        </div>
      </section>
    </div>
    """
  end

  defp fetch_hot_projects do
    case NexBase.from("projects") |> NexBase.order(:stars, :desc) |> NexBase.limit(6) |> NexBase.run() do
      {:ok, projects} -> projects
      _ -> []
    end
  end

  defp fetch_popular_tags do
    case NexBase.from("tags") |> NexBase.order(:name, :asc) |> NexBase.limit(12) |> NexBase.run() do
      {:ok, tags} -> tags
      _ -> []
    end
  end

  defp format_stars(n) when n >= 1000, do: "#{Float.round(n / 1000, 1)}k"
  defp format_stars(n), do: "#{n}"
end
