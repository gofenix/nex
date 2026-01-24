defmodule BestofEx.Pages.Trending do
  use Nex

  @client NexBase.client(repo: BestofEx.Repo)

  def mount(_params) do
    projects = list_projects()

    %{
      title: "Trending - Best of Elixir",
      projects: projects
    }
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1 class="text-3xl font-bold mb-6">Trending Projects</h1>
      <div class="space-y-4">
        <.BestofEx.Components.ProjectRow.project_row :for={{project, idx} <- Enum.with_index(@projects)} project={project} rank={idx + 1} />
      </div>
      <div :if={Enum.empty?(@projects)} class="text-center py-8 text-base-content/50">
        <p>No projects yet. Run <code>mix run seeds/import.exs</code> to seed data.</p>
      </div>
    </div>
    """
  end

  defp list_projects do
    case @client
    |> NexBase.from("projects")
    |> NexBase.order(:stars, :desc)
    |> NexBase.limit(50)
    |> NexBase.run() do
      {:ok, projects} -> projects
      _ -> []
    end
  end
end
