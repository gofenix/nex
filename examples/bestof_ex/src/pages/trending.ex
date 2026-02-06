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
        <div :for={{project, idx} <- Enum.with_index(@projects)} class="card bg-base-100 shadow-sm">
          <div class="card-body flex-row items-center gap-4">
            <div class="text-2xl font-bold text-base-content/30 w-8">
              {idx + 1}
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
