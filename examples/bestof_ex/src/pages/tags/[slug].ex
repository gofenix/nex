defmodule BestofEx.Pages.Tags.Show do
  use Nex

  def mount(%{"slug" => slug}) do
    tag = get_tag(slug)
    projects = get_tag_projects(slug)

    %{
      title: "#{tag["name"] || slug} - Best of Elixir",
      tag: tag,
      projects: projects
    }
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="mb-4">
        <a href="/tags" class="link link-primary text-sm">← Back to Tags</a>
      </div>

      <div class="flex items-center gap-3 mb-6">
        <h1 class="text-2xl font-bold">{@tag["name"]}</h1>
        <span class="badge badge-primary">{length(@projects)} projects</span>
      </div>

      <div class="bg-base-100 rounded-box border border-base-300 overflow-hidden">
        <table class="table">
          <thead>
            <tr>
              <th class="w-12">#</th>
              <th>Project</th>
              <th class="text-right w-28">Stars</th>
              <th class="text-right w-24">Links</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={{project, idx} <- Enum.with_index(@projects)} class="project-row">
              <td class="text-base-content/30 font-bold">{idx + 1}</td>
              <td>
                <div>
                  <a href={"/projects/#{project["id"]}"} class="font-semibold hover:text-primary">
                    {project["name"]}
                  </a>
                  <p class="text-base-content/50 text-sm mt-0.5 line-clamp-1">{project["description"]}</p>
                </div>
              </td>
              <td class="text-right">
                <span class="flex items-center justify-end gap-1 font-semibold star-icon">
                  <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z"/></svg>
                  {format_stars(project["stars"] || 0)}
                </span>
              </td>
              <td class="text-right">
                <a :if={project["repo_url"]} href={project["repo_url"]} target="_blank" class="btn btn-ghost btn-xs">
                  GitHub
                </a>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div :if={Enum.empty?(@projects)} class="alert mt-4">
        <span>No projects with this tag yet.</span>
      </div>
    </div>
    """
  end

  defp get_tag(slug) do
    case NexBase.from("tags") |> NexBase.eq(:slug, slug) |> NexBase.run() do
      {:ok, [tag | _]} -> tag
      _ -> %{}
    end
  end

  defp get_tag_projects(slug) do
    case NexBase.sql("""
      SELECT p.id, p.name, p.description, p.stars, p.repo_url, p.homepage_url
      FROM projects p
      JOIN project_tags pt ON pt.project_id = p.id
      JOIN tags t ON t.id = pt.tag_id
      WHERE t.slug = $1
      ORDER BY p.stars DESC
    """, [slug]) do
      {:ok, projects} -> projects
      _ -> []
    end
  end

  defp format_stars(n) when n >= 1000, do: "#{Float.round(n / 1000, 1)}k"
  defp format_stars(n), do: "#{n}"
end
