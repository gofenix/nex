defmodule BestofEx.Pages.Tags.Index do
  use Nex

  def mount(_params) do
    %{
      title: "All Tags - Best of Elixir",
      tags: list_tags_with_counts()
    }
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1 class="text-2xl font-bold mb-6">All Tags</h1>
      <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
        <a :for={tag <- @tags}
           href={"/tags/#{tag["slug"]}"}
           class="card bg-base-100 border border-base-300 hover:border-primary transition-colors cursor-pointer">
          <div class="card-body p-4 flex-row items-center justify-between">
            <span class="font-semibold">{tag["name"]}</span>
            <span class="badge badge-ghost">{tag["count"]} projects</span>
          </div>
        </a>
      </div>
      <div :if={Enum.empty?(@tags)} class="alert mt-4">
        <span>No tags yet. Run <code class="kbd kbd-sm">mix run seeds/import.exs</code> to seed data.</span>
      </div>
    </div>
    """
  end

  defp list_tags_with_counts do
    case NexBase.sql("""
      SELECT t.id, t.name, t.slug, COUNT(pt.project_id) as count
      FROM tags t
      LEFT JOIN project_tags pt ON pt.tag_id = t.id
      GROUP BY t.id, t.name, t.slug
      ORDER BY count DESC, t.name ASC
    """) do
      {:ok, tags} -> tags
      _ -> []
    end
  end
end
