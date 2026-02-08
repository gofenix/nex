defmodule BestofEx.Pages.Index do
  @moduledoc """
  Homepage with Hero, Hot Projects list, and Featured sidebar.
  Two-column layout following bestofjs.org design.
  """
  use Nex
  alias BestofEx.Components.{Avatar, ProjectRow, FeaturedCard}

  @elixir_projects ["Phoenix", "Ecto", "LiveView", "Nx", "Nerves", "Oban"]

  def mount(params) do
    period = params["period"] || "today"

    %{
      title: "Best of Elixir",
      hero_word: Enum.random(@elixir_projects),
      period: period,
      hot_projects: fetch_hot_projects(period),
      featured: fetch_featured(5),
      recently_added: fetch_recently_added(5),
      popular_tags: fetch_popular_tags(10),
      monthly_rankings: fetch_monthly_rankings(5)
    }
  end

  def render(assigns) do
    ~H"""
    <!-- Hero Section -->
    <section class="py-12 text-center border-b border-gray-200 bg-white">
      <div class="container mx-auto max-w-6xl px-4">
        <h1 class="text-4xl md:text-5xl font-bold text-gray-900 mb-3 tracking-tight">
          The Best of <span class="text-primary typing-cursor">{@hero_word}</span>
        </h1>
        <p class="text-base md:text-lg text-gray-500 max-w-2xl mx-auto leading-relaxed">
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
                <h2 class="text-xl font-bold flex items-center gap-2 text-gray-900">
                  <span class="text-amber-500">🔥</span> Hot Projects
                </h2>
                <p class="text-sm text-gray-500">By stars added {period_label(@period)}</p>
              </div>

              <!-- Period Filter -->
              <form hx-get="/" hx-target="#hot-section" hx-select="#hot-section">
                <select name="period" class="select select-sm text-sm bg-white border-gray-200 rounded-lg focus:border-primary focus:ring-2 focus:ring-primary/10"
                        onchange="this.form.submit()">
                  <option value="today" selected={@period == "today"}>Today</option>
                  <option value="week" selected={@period == "week"}>This Week</option>
                  <option value="month" selected={@period == "month"}>This Month</option>
                </select>
              </form>
            </div>

            <!-- Hot Projects List -->
            <div class="card-premium p-4">
              <div :if={Enum.empty?(@hot_projects)} class="text-center py-8 text-gray-500">
                <p>No hot projects yet.</p>
                <p class="text-sm mt-1">Run <code class="px-1.5 py-0.5 bg-gray-100 rounded text-xs">mix run seeds/import.exs</code> to seed data.</p>
              </div>

              <%= for project <- @hot_projects do %>
                {ProjectRow.render(%{project: project, tags: project["tags"] || []})}
              <% end %>
            </div>

            <div class="mt-4 text-right">
              <a href="/projects" class="text-sm text-primary hover:text-accent transition-smooth font-medium">View all projects →</a>
            </div>
          </div>

          <!-- Right Column: Featured Sidebar (30%) -->
          <div class="lg:col-span-4">
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-lg font-bold flex items-center gap-2 text-gray-900">
                <span class="text-amber-500">⭐</span> Featured
              </h2>
              <span class="text-xs text-gray-400">Random order</span>
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

    <!-- Row 2: Recently Added + Popular Tags -->
    <section class="py-8 border-t border-gray-100">
      <div class="container mx-auto max-w-6xl px-4">
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-8">

          <!-- Left: Recently Added -->
          <div class="lg:col-span-8">
            <div class="flex items-center justify-between mb-6">
              <div>
                <h2 class="text-xl font-bold flex items-center gap-2 text-gray-900">
                  <span class="text-green-500">🆕</span> Recently Added
                </h2>
                <p class="text-sm text-gray-500">Latest projects added to the collection</p>
              </div>
            </div>

            <div class="card-premium p-4">
              <div :if={Enum.empty?(@recently_added)} class="text-center py-8 text-gray-500">
                <p>No recent projects yet.</p>
              </div>

              <%= for project <- @recently_added do %>
                {ProjectRow.render(%{project: project, tags: project["tags"] || []})}
              <% end %>
            </div>

            <div class="mt-4 text-right">
              <a href="/projects?sort=newest" class="text-sm text-primary hover:text-accent transition-smooth font-medium">View more →</a>
            </div>
          </div>

          <!-- Right: Popular Tags -->
          <div class="lg:col-span-4">
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-lg font-bold flex items-center gap-2 text-gray-900">
                <span class="text-blue-500">🏷️</span> Popular Tags
              </h2>
            </div>

            <div class="grid grid-cols-1 gap-2">
              <%= for tag <- @popular_tags do %>
                <a href={"/tags/#{tag["slug"]}"}
                   class="card-premium flex items-center justify-between p-3 group">
                  <span class="font-medium text-primary text-sm group-hover:underline">{tag["name"]}</span>
                  <span class="badge badge-premium badge-sm">{tag["count"]}</span>
                </a>
              <% end %>
            </div>

            <div class="mt-3 text-right">
              <a href="/tags" class="text-sm text-primary hover:text-accent transition-smooth font-medium">View all tags →</a>
            </div>
          </div>

        </div>
      </div>
    </section>

    <!-- Row 3: Monthly Rankings -->
    <section class="py-8 border-t border-gray-100">
      <div class="container mx-auto max-w-6xl px-4">
        <div class="flex items-center justify-between mb-6">
          <div>
            <h2 class="text-xl font-bold flex items-center gap-2 text-gray-900">
              <span class="text-purple-500">🏆</span> Rankings {current_month_label()}
            </h2>
            <p class="text-sm text-gray-500">Top projects by stars added this month</p>
          </div>
          <a href="/trending?period=month" class="text-sm text-primary hover:text-accent transition-smooth font-medium">View full rankings →</a>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
          <%= for {project, idx} <- Enum.with_index(@monthly_rankings) do %>
            <a href={"/projects/#{project["id"]}"}
               class="card-premium p-4 text-center group relative">
              <div class="absolute top-2 left-2 text-xs font-bold text-amber-500">#{idx + 1}</div>
              <div class="flex justify-center mb-3">
                {Avatar.render(%{name: project["name"], size: "lg", avatar_url: project["avatar_url"]})}
              </div>
              <div class="font-semibold text-primary text-sm truncate group-hover:underline">{project["name"]}</div>
              <div class="text-amber-600 text-xs font-semibold mt-1">
                {format_stars(project["stars"] || 0)}☆
              </div>
              <div :if={(project["star_delta"] || 0) > 0} class="text-green-600 text-xs mt-0.5">
                +{format_stars(project["star_delta"])}
              </div>
            </a>
          <% end %>
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
      SELECT p.id, p.name, p.description, p.repo_url, p.homepage_url, p.stars, p.avatar_url,
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
      SELECT p.id, p.name, p.stars, p.avatar_url,
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

  # Fetch recently added projects
  defp fetch_recently_added(count) do
    {:ok, rows} = NexBase.sql("""
      SELECT p.id, p.name, p.description, p.repo_url, p.homepage_url, p.stars, p.avatar_url, p.added_at
      FROM projects p
      ORDER BY p.added_at DESC, p.id DESC
      LIMIT $1
    """, [count])

    Enum.map(rows, fn project ->
      tags = fetch_project_tags(project["id"])
      Map.put(project, "tags", tags)
    end)
  end

  # Fetch popular tags with project counts
  defp fetch_popular_tags(count) do
    {:ok, rows} = NexBase.sql("""
      SELECT t.name, t.slug, COUNT(pt.project_id) as count
      FROM tags t
      JOIN project_tags pt ON pt.tag_id = t.id
      GROUP BY t.id, t.name, t.slug
      ORDER BY count DESC, t.name ASC
      LIMIT $1
    """, [count])

    rows
  end

  # Fetch monthly rankings by star growth
  defp fetch_monthly_rankings(count) do
    {:ok, rows} = NexBase.sql("""
      SELECT p.id, p.name, p.stars, p.avatar_url,
             COALESCE(p.stars - ps.stars, 0) AS star_delta
      FROM projects p
      LEFT JOIN project_stats ps
        ON ps.project_id = p.id
        AND ps.recorded_at = date_trunc('month', CURRENT_DATE)::date
      ORDER BY COALESCE(p.stars - ps.stars, 0) DESC, p.stars DESC
      LIMIT $1
    """, [count])

    rows
  end

  defp current_month_label do
    date = Date.utc_today()
    month_names = ~w(January February March April May June July August September October November December)
    Enum.at(month_names, date.month - 1) <> " #{date.year}"
  end

  defp format_stars(n) when is_integer(n) and n >= 1000, do: "#{Float.round(n / 1000, 1)}k"
  defp format_stars(n), do: "#{n}"

  defp period_label("week"), do: "this week"
  defp period_label("month"), do: "this month"
  defp period_label(_), do: "yesterday"
end
