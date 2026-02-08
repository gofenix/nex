defmodule BestofEx.Pages.Projects.Index do
  @moduledoc """
  All projects page with search, tag filters, and ranked list.
  """
  use Nex
  alias BestofEx.Components.ProjectRow

  def mount(params) do
    sort = params["sort"] || "stars"
    tag = params["tag"]
    q = params["q"]

    %{
      title: "All Projects - Best of Elixir",
      projects: list_projects(sort: sort, tag: tag, q: q),
      tags: list_all_tags(),
      sort: sort,
      current_tag: tag,
      query: q
    }
  end

  def render(assigns) do
    ~H"""
    <div class="py-8">
      <div class="container mx-auto max-w-6xl px-4">
        <!-- Header with Search -->
        <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
          <h1 class="text-2xl font-bold text-gray-900">All Projects</h1>

          <form action="/projects" method="get" class="relative w-full sm:w-auto">
            <input type="hidden" name="sort" value={@sort} />
            <input :if={@current_tag} type="hidden" name="tag" value={@current_tag} />
            <input type="search" name="q" value={@query} placeholder="Search projects..."
                   class="input input-sm w-full sm:w-64 pl-3 pr-8 bg-white border-gray-200 rounded-lg focus:border-primary focus:ring-2 focus:ring-primary/10" />
            <kbd class="absolute right-2 top-1/2 -translate-y-1/2 text-[10px] text-gray-400 font-sans hidden sm:inline">⌘K</kbd>
          </form>
        </div>

        <!-- Tag Filter Bar -->
        <div class="flex flex-wrap gap-2 mb-6">
          <a href="/projects" class={"badge badge-sm #{if is_nil(@current_tag), do: "bg-primary text-white border-primary", else: "badge-premium"}"}>All</a>
          <%= for tag <- @tags do %>
            <a href={"/projects?tag=#{tag["slug"]}"}
               class={"badge badge-sm #{if @current_tag == tag["slug"], do: "bg-primary text-white border-primary", else: "badge-premium"}"}>
              {tag["name"]}
            </a>
          <% end %>
        </div>

        <!-- Sort Headers -->
        <div class="flex gap-3 mb-4 text-sm items-center">
          <span class="text-gray-400">Sort by:</span>
          <a href={"/projects?sort=stars#{if @current_tag, do: "&tag=" <> @current_tag, else: ""}"}
             class={"font-medium transition-smooth #{if @sort == "stars", do: "text-primary", else: "text-gray-500 hover:text-primary"}"}>
            Stars {if @sort == "stars", do: "↓"}
          </a>
          <a href={"/projects?sort=name#{if @current_tag, do: "&tag=" <> @current_tag, else: ""}"}
             class={"font-medium transition-smooth #{if @sort == "name", do: "text-primary", else: "text-gray-500 hover:text-primary"}"}>
            Name {if @sort == "name", do: "↓"}
          </a>
        </div>

        <!-- Project List -->
        <div id="project-list" class="card-premium p-4">
          <div :if={Enum.empty?(@projects)} class="text-center py-8 text-gray-500">
            <p>No projects found.</p>
          </div>

          <%= for {project, idx} <- Enum.with_index(@projects) do %>
            {ProjectRow.render(%{project: project, tags: project["tags"] || [], rank: idx + 1})}
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp list_projects(opts) do
    sort = opts[:sort] || "stars"
    tag = opts[:tag]
    q = opts[:q]

    order_clause = case sort do
      "name" -> "ORDER BY p.name ASC"
      _ -> "ORDER BY p.stars DESC"
    end

    tag_join = if tag do
      "JOIN project_tags pt ON pt.project_id = p.id JOIN tags t ON t.id = pt.tag_id AND t.slug = '#{tag}'"
    else
      ""
    end

    search_clause = if q && q != "" do
      "AND (p.name ILIKE '%#{q}%' OR p.description ILIKE '%#{q}%')"
    else
      ""
    end

    {:ok, rows} = NexBase.sql("""
      SELECT p.id, p.name, p.description, p.repo_url, p.homepage_url, p.stars, p.avatar_url
      FROM projects p
      #{tag_join}
      WHERE 1=1 #{search_clause}
      #{order_clause}
    """)

    # Fetch tags for each project
    Enum.map(rows, fn project ->
      tags = fetch_project_tags(project["id"])
      Map.put(project, "tags", tags)
    end)
  end

  defp fetch_project_tags(project_id) do
    {:ok, rows} = NexBase.sql("""
      SELECT t.name, t.slug
      FROM tags t
      JOIN project_tags pt ON pt.tag_id = t.id
      WHERE pt.project_id = $1
      ORDER BY t.name
      LIMIT 3
    """, [project_id])

    rows
  end

  defp list_all_tags do
    case NexBase.from("tags") |> NexBase.order(:name, :asc) |> NexBase.run() do
      {:ok, tags} -> tags
      _ -> []
    end
  end
end
