defmodule BestofEx.Components.ProjectRow do
  @moduledoc """
  A single project entry in a list.
  Used on Home (hot), Projects, Tags, Trending.
  """
  use Nex
  alias BestofEx.Components.{Avatar, TagBadge}

  def render(assigns) do
    ~H"""
    <div class="project-row flex items-start gap-4 py-4 hover:bg-gray-50/80 transition-smooth group cursor-pointer">
      <!-- Rank number (if shown) -->
      <div :if={assigns[:rank]} class={"rank-badge shrink-0 pt-2 #{if @rank <= 3, do: "rank-badge-top"}"}>
        {@rank}
      </div>

      <!-- Avatar -->
      {Avatar.render(%{name: @project["name"], size: "md"})}

      <!-- Content -->
      <div class="flex-1 min-w-0">
        <div class="flex items-center gap-2">
          <a href={"/projects/#{@project["id"]}"} class="font-semibold text-primary hover:underline">
            {@project["name"]}
          </a>
          <a :if={@project["repo_url"]} href={@project["repo_url"]} target="_blank"
             class="text-gray-400 hover:text-gray-600 transition-smooth">
            <svg class="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
            </svg>
          </a>
          <a :if={@project["homepage_url"]} href={@project["homepage_url"]} target="_blank"
             class="text-gray-400 hover:text-gray-600 transition-smooth">
            <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M3 12a9 9 0 1 1 18 0 9 9 0 0 1-18 0"/>
              <path d="M3.6 9h16.8M3.6 15h16.8M12 3a15 15 0 0 1 0 18"/>
            </svg>
          </a>
        </div>

        <p class="text-sm text-gray-500 line-clamp-1 mt-0.5">
          {@project["description"]}
        </p>

        <div :if={@tags != []} class="flex flex-wrap gap-1.5 mt-2">
          <%= for tag <- @tags do %>
            {TagBadge.render(%{name: tag["name"], slug: tag["slug"]})}
          <% end %>
        </div>
      </div>

      <!-- Star count -->
      <div class="text-right shrink-0">
        <span class="star-count text-sm">
          {format_star_value(@project, @mode)}
        </span>
      </div>
    </div>
    """
  end

  defp format_star_value(project, mode) do
    value = case mode do
      :delta -> project["star_delta"] || 0
      _ -> project["stars"] || 0
    end

    formatted = cond do
      value >= 1000 -> "#{Float.round(value / 1000, 1)}k"
      true -> "#{value}"
    end

    case mode do
      :delta -> "+ #{formatted}☆"
      _ -> "#{formatted}☆"
    end
  end
end
