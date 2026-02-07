defmodule BestofEx.Pages.Tags.Index do
  @moduledoc """
  All tags page with grid of tag cards showing project counts.
  """
  use Nex

  def mount(_params) do
    %{
      title: "All Tags - Best of Elixir",
      tags: list_tags_with_counts()
    }
  end

  def render(assigns) do
    ~H"""
    <div class="py-8">
      <div class="container mx-auto max-w-6xl px-4">
        <h1 class="text-2xl font-bold mb-6">All Tags</h1>

        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
          <%= for tag <- @tags do %>
            <a href={"/tags/#{tag["slug"]}"}
               class="card bg-base-100 border border-base-200 hover:border-primary hover:shadow-md transition-all cursor-pointer">
              <div class="card-body p-4 flex-row items-center justify-between">
                <span class="font-semibold text-primary">{tag["name"]}</span>
                <span class="badge badge-outline badge-sm">{tag["count"]} projects</span>
              </div>
            </a>
          <% end %>
        </div>

        <div :if={Enum.empty?(@tags)} class="text-center py-8 text-base-content/50">
          <p>No tags yet.</p>
          <p class="text-sm mt-1">Run <code class="kbd kbd-sm">mix run seeds/import.exs</code> to seed data.</p>
        </div>
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
