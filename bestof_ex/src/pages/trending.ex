defmodule BestofEx.Pages.Trending do
  @moduledoc """
  Trending projects page with time period tabs.
  """
  use Nex
  alias BestofEx.Components.ProjectRow

  def mount(params) do
    period = params["period"] || "today"

    %{
      title: "Trending - Best of Elixir",
      period: period,
      projects: list_trending(period)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="py-8">
      <div class="container mx-auto max-w-6xl px-4">
        <!-- Header -->
        <h1 class="text-2xl font-bold mb-6 text-gray-900">Trending Projects</h1>

        <!-- Period Tabs -->
        <div class="flex gap-2 mb-6">
          <a href="/trending?period=today"
             class={"tab-premium tab #{if @period == "today", do: "tab-active"}"}>
            Today
          </a>
          <a href="/trending?period=week"
             class={"tab-premium tab #{if @period == "week", do: "tab-active"}"}>
            This Week
          </a>
          <a href="/trending?period=month"
             class={"tab-premium tab #{if @period == "month", do: "tab-active"}"}>
            This Month
          </a>
        </div>

        <!-- Project List -->
        <div id="trending-list" class="card-premium p-4">
          <div :if={Enum.empty?(@projects)} class="text-center py-8 text-gray-500">
            <p>No trending projects for this period.</p>
          </div>

          <div :for={{project, idx} <- Enum.with_index(@projects)}>
            {ProjectRow.render(%{project: project, tags: project["tags"] || [], rank: idx + 1})}
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp list_trending(period) do
    interval = case period do
      "week" -> "7 days"
      "month" -> "30 days"
      _ -> "1 day"
    end

    {:ok, rows} = NexBase.sql("""
      SELECT p.id, p.name, p.description, p.repo_url, p.homepage_url, p.stars, p.avatar_url,
             COALESCE(p.stars - ps.stars, 0) AS star_delta
      FROM bestofex_projects p
      LEFT JOIN bestofex_project_stats ps
        ON ps.project_id = p.id
        AND ps.recorded_at = CURRENT_DATE - INTERVAL '#{interval}'
      ORDER BY COALESCE(p.stars - ps.stars, 0) DESC, p.stars DESC
      LIMIT 20
    """)

    attach_tags_batch(rows)
  end

  defp attach_tags_batch(projects) do
    ids = Enum.map(projects, & &1["id"])

    if ids == [] do
      projects
    else
      placeholders = Enum.map_join(1..length(ids), ", ", fn i -> "$#{i}" end)

      {:ok, tag_rows} = NexBase.sql("""
        SELECT pt.project_id, t.name, t.slug
        FROM bestofex_tags t
        JOIN bestofex_project_tags pt ON pt.tag_id = t.id
        WHERE pt.project_id IN (#{placeholders})
        ORDER BY t.name
      """, ids)

      tags_by_project = Enum.group_by(tag_rows, & &1["project_id"])

      Enum.map(projects, fn project ->
        tags = Map.get(tags_by_project, project["id"], []) |> Enum.take(3)
        Map.put(project, "tags", tags)
      end)
    end
  end
end
