defmodule BestofEx.Components.FeaturedCard do
  @moduledoc """
  Sidebar card for featured projects on the homepage.
  """
  use Nex
  alias BestofEx.Components.Avatar

  def render(assigns) do
    ~H"""
    <a href={"/projects/#{@project["id"]}"}
       class="block border border-base-200 rounded-xl p-4 text-center hover:shadow-md hover:border-primary/30 transition-all">
      <div class="flex justify-center mb-3">
        {Avatar.render(%{name: @project["name"], size: "lg"})}
      </div>
      <div class="font-semibold text-primary text-sm truncate">{@project["name"]}</div>
      <div class="text-accent text-xs font-semibold mt-1">
        + {format_delta(@project["star_delta"] || 0)}☆
      </div>
      <div :if={@tag} class="mt-2">
        <span class="badge badge-outline badge-xs">{@tag}</span>
      </div>
    </a>
    """
  end

  defp format_delta(n) when n >= 1000, do: "#{Float.round(n / 1000, 1)}k"
  defp format_delta(n), do: "#{n}"
end
