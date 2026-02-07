defmodule BestofEx.Pages.Index do
  @moduledoc """
  Homepage with Hero, Hot Projects list, and Featured sidebar.
  Two-column layout following bestofjs.org design.
  """
  use Nex
  alias BestofEx.Components.{ProjectRow, FeaturedCard}

  @elixir_projects ["Phoenix", "Ecto", "LiveView", "Nx", "Nerves", "Oban"]

  def mount(params) do
    period = params["period"] || "today"

    %{
      title: "Best of Elixir",
      hero_word: Enum.random(@elixir_projects),
      period: period,
      hot_projects: fetch_hot_projects(period),
      featured: fetch_featured(5)
    }
  end

  def render(assigns) do
    ~H"""
    <!-- Hero Section -->
    <section class="py-12 text-center border-b border-base-200 bg-gradient-to-b from-base-100 to-base-50">
      <div class="container mx-auto max-w-6xl px-4">
        <h1 class="text-4xl md:text-5xl font-bold text-base-content mb-3">
          The Best of <span class="text-primary typing-cursor">{@hero_word}</span>
        </h1>
        <p class="text-base md:text-lg text-base-content/60 max-w-2xl mx-auto leading-relaxed">
          A place to find the best open-source projects in the Elixir ecosystem:
          Phoenix, Ecto, LiveView, Nx, Nerves, Oban...
        </p>
      </div>
    </section>

    <!-- Main Content -->
    <section class="py-8">
      <div class="container mx-auto max-w-6xl px-4">
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-8">

          <!-- Left Column: Hot Projects (70%) -->
          <div class="lg:col-span-8" id="hot-section">
            <div class="flex items-center justify-between mb-6">
              <div>
                <h2 class="text-xl font-bold flex items-center gap-2">
                  <span>🔥</span> Hot Projects
                </h2>
                <p class="text-sm text-base-content/50">By stars added {period_label(@period)}</p>
              </div>

              <!-- Period Filter -->
              <form hx-get="/" hx-target="#hot-section" hx-select="#hot-section">
                <select name="period" class="select select-bordered select-sm text-sm"
                        onchange="this.form.submit()">
                  <option value="today" selected={@period == "today"}>Today</option>
                  <option value="week" selected={@period == "week"}>This Week</option>
                  <option value="month" selected={@period == "month"}>This Month</option>
                </select>
              </form>
            </div>

            <!-- Hot Projects List -->
            <div class="bg-base-100 rounded-xl border border-base-200 p-4">
              <div :if={Enum.empty?(@hot_projects)} class="text-center py-8 text-base-content/50">
                <p>No hot projects yet.</p>
                <p class="text-sm mt-1">Run <code class="kbd kbd-sm">mix run seeds/import.exs</code> to seed data.</p>
              </div>

              <%= for project <- @hot_projects do %>
                {ProjectRow.render(%{project: project, tags: project["tags"] || [], mode: :delta})}
              <% end %>
            </div>

            <div class="mt-4 text-right">
              <a href="/projects" class="link link-primary text-sm">View all projects →</a>
            </div>
          </div>

          <!-- Right Column: Featured Sidebar (30%) -->
          <div class="lg:col-span-4">
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-lg font-bold flex items-center gap-2">
                <span>⭐</span> Featured
              </h2>
              <span class="text-xs text-base-content/50">Random order</span>
            </div>

            <div class="grid grid-cols-1 gap-3">
              <%= for project <- @featured do %>
                {FeaturedCard.render(%{project: project, tag: project["primary_tag"]})}
              <% end %>
            </div>
          </div>

        </div>
      </div>
    </section>
    """
  end

  # Fetch hot projects with star delta for the given period
  defp fetch_hot_projects(period) do
    interval = case period do
      "week" -> "7 days"
      "month" -> "30 days"
      _ -> "1 day"
    end

    {:ok, rows} = NexBase.sql("""
      SELECT p.id, p.name, p.description, p.repo_url, p.homepage_url, p.stars,
             COALESCE(p.stars - ps.stars, 0) AS star_delta
      FROM projects p
      LEFT JOIN project_stats ps
        ON ps.project_id = p.id
        AND ps.recorded_at = CURRENT_DATE - INTERVAL '#{interval}'
      ORDER BY COALESCE(p.stars - ps.stars, 0) DESC, p.stars DESC
      LIMIT 10
    """)

    # Fetch tags for each project
    Enum.map(rows, fn project ->
      tags = fetch_project_tags(project["id"])
      Map.put(project, "tags", tags)
    end)
  end

  # Fetch random featured projects
  defp fetch_featured(count) do
    {:ok, rows} = NexBase.sql("""
      SELECT p.id, p.name, p.stars,
             COALESCE(p.stars - ps.stars, 0) AS star_delta,
             (SELECT t.name FROM tags t
              JOIN project_tags pt ON pt.tag_id = t.id
              WHERE pt.project_id = p.id
              LIMIT 1) AS primary_tag
      FROM projects p
      LEFT JOIN project_stats ps
        ON ps.project_id = p.id
        AND ps.recorded_at = CURRENT_DATE - INTERVAL '1 day'
      ORDER BY RANDOM()
      LIMIT $1
    """, [count])

    rows
  end

  # Fetch tags for a project
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

  defp period_label("week"), do: "this week"
  defp period_label("month"), do: "this month"
  defp period_label(_), do: "yesterday"
end
