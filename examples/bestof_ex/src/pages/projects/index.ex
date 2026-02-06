defmodule BestofEx.Pages.Projects.Index do
  use Nex

  @client NexBase.client(repo: BestofEx.Repo)

  def mount(params) do
    page = String.to_integer(params["page"] || "1")
    per_page = 20

    {projects, total} = list_projects(page, per_page)
    tags = list_all_tags()

    %{
      title: "All Projects - Best of Elixir",
      projects: projects,
      page: page,
      total: total,
      per_page: per_page,
      tags: tags,
      params: params
    }
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1 class="text-3xl font-bold mb-6">All Projects ({@total})</h1>

      <div class="flex flex-wrap gap-4 mb-6">
        <form hx-get="/projects" hx-target="#projects-list" class="flex flex-wrap gap-4">
          <input type="text"
                 name="q"
                 value={@params["q"]}
                 placeholder="Search projects..."
                 class="input input-bordered input-sm w-48" />

          <select name="sort" class="select select-bordered select-sm">
            <option value="stars" selected={@params["sort"] != "newest"}>Stars</option>
            <option value="newest" selected={@params["sort"] == "newest"}>Newest</option>
          </select>

          <a :for={tag <- @tags}
             href={"/tags/#{tag["slug"]}"}
             class="badge badge-outline hover:badge-primary transition-colors">
            {tag["name"]}
          </a>
        </form>
      </div>

      <div id="projects-list" class="space-y-4">
        <div :for={{project, idx} <- Enum.with_index(@projects)} class="card bg-base-100 shadow-sm">
          <div class="card-body flex-row items-center gap-4">
            <div class="text-2xl font-bold text-base-content/30 w-8">
              {idx + 1 + (@page - 1) * @per_page}
            </div>
            <div class="flex-1">
              <h3 class="font-semibold text-lg">
                <a href={"/projects/#{project["id"]}"} class="hover:text-primary">{project["name"]}</a>
              </h3>
              <p class="text-base-content/60 text-sm">{project["description"]}</p>
            </div>
            <div class="text-center">
              <div class="text-xl font-bold">{project["stars"] || 0}</div>
              <div class="text-xs text-base-content/50">stars</div>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-8 flex justify-center gap-2">
        <a :if={@page > 1}
           href={"/projects?page=#{@page - 1}"}
           class="btn btn-sm">Previous</a>
        <span class="btn btn-sm btn-disabled">Page {@page} of {ceil(@total / @per_page)}</span>
        <a :if={@page * @per_page < @total}
           href={"/projects?page=#{@page + 1}"}
           class="btn btn-sm">Next</a>
      </div>
    </div>
    """
  end

  defp list_projects(page, per_page) do
    offset = (page - 1) * per_page

    case @client
    |> NexBase.from("projects")
    |> NexBase.order(:stars, :desc)
    |> NexBase.limit(per_page)
    |> NexBase.offset(offset)
    |> NexBase.run() do
      {:ok, projects} -> {projects, length(projects)}
      _ -> {[], 0}
    end
  end

  defp list_all_tags do
    case @client
    |> NexBase.from("tags")
    |> NexBase.order(:name, :asc)
    |> NexBase.run() do
      {:ok, tags} -> tags
      _ -> []
    end
  end
end
