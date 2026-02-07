defmodule BestofEx.Pages.Trending do
  use Nex

  def mount(_params) do
    %{
      title: "Trending - Best of Elixir",
      projects: list_trending()
    }
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1 class="text-2xl font-bold mb-2">Trending Projects</h1>
      <p class="text-base-content/60 mb-6">The most popular Elixir projects, ranked by GitHub stars.</p>

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
        <span>No projects yet.</span>
      </div>
    </div>
    """
  end

  defp list_trending do
    case NexBase.from("projects") |> NexBase.order(:stars, :desc) |> NexBase.limit(20) |> NexBase.run() do
      {:ok, projects} -> projects
      _ -> []
    end
  end

  defp format_stars(n) when n >= 1000, do: "#{Float.round(n / 1000, 1)}k"
  defp format_stars(n), do: "#{n}"
end
