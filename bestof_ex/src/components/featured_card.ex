defmodule BestofEx.Components.FeaturedCard do
  @moduledoc """
  Sidebar card for featured projects on the homepage.
  """
  use Nex
  alias BestofEx.Components.Avatar

  def render(assigns) do
    ~H"""
    <a href={"/projects/#{@project["id"]}"}
       class="card-premium block p-4 text-center group">
      <div class="flex justify-center mb-3">
        {Avatar.render(%{name: @project["name"], size: "lg", avatar_url: @project["avatar_url"]})}
      </div>
      <div class="font-semibold text-primary text-sm truncate group-hover:underline">{@project["name"]}</div>
      <div class="text-amber-600 text-xs font-semibold mt-1">
        {format_stars(@project["stars"] || 0)}☆
      </div>
      <div :if={@tag} class="mt-2">
        <span class="badge badge-premium badge-sm">{@tag}</span>
      </div>
    </a>
    """
  end

  defp format_stars(n) when is_integer(n) and n >= 1000, do: "#{Float.round(n / 1000, 1)}k"
  defp format_stars(n), do: "#{n}"
end
