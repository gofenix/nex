defmodule BestofEx.Pages.Projects.Show do
  @moduledoc """
  Project detail page with full info, tags, and external links.
  """
  use Nex
  alias BestofEx.Components.{Avatar, TagBadge}

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
    <div class="py-8">
      <div class="container mx-auto max-w-6xl px-4">
        <!-- Back Link -->
        <div class="mb-6">
          <a href="/projects" class="text-sm text-primary hover:underline transition-smooth">← Back to Projects</a>
        </div>

        <!-- Project Card -->
        <div class="card-premium p-6">
          <!-- Header -->
          <div class="flex items-start gap-4 mb-4">
            {Avatar.render(%{name: @project["name"], size: "xl", avatar_url: @project["avatar_url"]})}
            <div class="flex-1">
              <div class="flex items-start justify-between">
                <h1 class="text-2xl md:text-3xl font-bold text-gray-900">{@project["name"]}</h1>
                <div class="text-right shrink-0 ml-4">
                  <div class="text-amber-600 font-bold text-xl">
                    {format_stars(@project["stars"] || 0)}☆
                  </div>
                  <div class="text-xs text-gray-400">GitHub Stars</div>
                </div>
              </div>
              <p class="text-gray-600 text-base mt-2 leading-relaxed">
                {@project["description"]}
              </p>
            </div>
          </div>

          <!-- Tags -->
          <div :if={@tags != []} class="flex flex-wrap gap-2 mb-6">
            <%= for tag <- @tags do %>
              {TagBadge.render(%{name: tag["name"], slug: tag["slug"]})}
            <% end %>
          </div>

          <!-- Meta Info -->
          <div :if={@project["license"] || @project["pushed_at"]} class="flex flex-wrap gap-4 text-sm text-gray-500 mb-6">
            <div :if={@project["license"]} class="flex items-center gap-1.5">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/>
              </svg>
              {@project["license"]}
            </div>
            <div :if={@project["pushed_at"]} class="flex items-center gap-1.5">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>
              Last push: {format_date(@project["pushed_at"])}
            </div>
            <div :if={@project["open_issues"]} class="flex items-center gap-1.5">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>
              {format_number(@project["open_issues"])} open issues
            </div>
          </div>

          <div class="divider my-4"></div>

          <!-- Links -->
          <div class="flex flex-wrap gap-3">
            <a :if={@project["repo_url"]} href={@project["repo_url"]} target="_blank"
               class="btn btn-outline btn-sm btn-premium gap-2">
              <svg class="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
              </svg>
              Repository
            </a>
            <a :if={@project["homepage_url"]} href={@project["homepage_url"]} target="_blank"
               class="btn btn-primary btn-sm btn-premium gap-2">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"/>
              </svg>
              Homepage
            </a>
            <!-- Hex Package Link -->
            <a href={"https://hex.pm/packages/#{String.downcase(@project["name"])}"} target="_blank"
               class="btn btn-ghost btn-sm btn-premium gap-2 text-gray-600 hover:text-primary">
              <svg class="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
              </svg>
              Hex Package
            </a>
            <!-- Documentation Link -->
            <a href={"https://hexdocs.pm/#{String.downcase(@project["name"])}"} target="_blank"
               class="btn btn-ghost btn-sm btn-premium gap-2 text-gray-600 hover:text-primary">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/>
              </svg>
              Docs
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

  defp format_date(nil), do: ""
  defp format_date(date) when is_binary(date) do
    case DateTime.from_iso8601(date) do
      {:ok, dt, _} -> Calendar.strftime(dt, "%b %d, %Y")
      _ -> String.slice(date, 0, 10)
    end
  end
  defp format_date(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%b %d, %Y")
  defp format_date(_), do: ""

  defp format_number(nil), do: "0"
  defp format_number(n) when is_integer(n) and n >= 1000 do
    "#{Float.round(n / 1000, 1)}k"
  end
  defp format_number(n), do: "#{n}"
end
