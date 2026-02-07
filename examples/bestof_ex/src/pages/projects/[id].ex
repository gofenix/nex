defmodule BestofEx.Pages.Projects.Show do
  use Nex

  def mount(%{"id" => id}) do
    project = get_project(id)
    tags = get_project_tags(id)

    %{
      title: "#{project["name"] || "Project"} - Best of Elixir",
      project: project,
      tags: tags
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto">
      <div class="mb-4">
        <a href="/projects" class="link link-primary text-sm">← Back to Projects</a>
      </div>

      <div class="card bg-base-100 border border-base-300">
        <div class="card-body">
          <div class="flex items-start justify-between">
            <div class="flex-1">
              <h1 class="text-3xl font-bold mb-2">{@project["name"]}</h1>
              <p class="text-base-content/60 text-lg">{@project["description"]}</p>
            </div>
            <div class="stat p-0 pl-6">
              <div class="stat-value text-2xl star-icon flex items-center gap-2">
                <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z"/></svg>
                {format_stars(@project["stars"] || 0)}
              </div>
              <div class="stat-desc">GitHub Stars</div>
            </div>
          </div>

          <div :if={@tags != []} class="flex flex-wrap gap-2 mt-4">
            <a :for={tag <- @tags}
               href={"/tags/#{tag["slug"]}"}
               class="badge badge-primary badge-outline">
              {tag["name"]}
            </a>
          </div>

          <div class="divider"></div>

          <div class="flex gap-3">
            <a :if={@project["repo_url"]} href={@project["repo_url"]} target="_blank" class="btn btn-outline btn-sm gap-2">
              <svg class="w-4 h-4" viewBox="0 0 24 24" fill="currentColor"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/></svg>
              Repository
            </a>
            <a :if={@project["homepage_url"]} href={@project["homepage_url"]} target="_blank" class="btn btn-primary btn-sm gap-2">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"/></svg>
              Homepage
            </a>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp get_project(id) do
    case NexBase.from("projects") |> NexBase.eq(:id, String.to_integer(id)) |> NexBase.run() do
      {:ok, [project | _]} -> project
      _ -> %{}
    end
  end

  defp get_project_tags(id) do
    case NexBase.sql("""
      SELECT t.name, t.slug FROM tags t
      JOIN project_tags pt ON pt.tag_id = t.id
      WHERE pt.project_id = $1
      ORDER BY t.name
    """, [String.to_integer(id)]) do
      {:ok, tags} -> tags
      _ -> []
    end
  end

  defp format_stars(n) when n >= 1000, do: "#{Float.round(n / 1000, 1)}k"
  defp format_stars(n), do: "#{n}"
end
