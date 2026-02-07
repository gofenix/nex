defmodule BestofEx.Components.TagBadge do
  @moduledoc """
  Small clickable tag badge.
  """
  use Nex

  def render(assigns) do
    ~H"""
    <a href={"/tags/#{@slug}"}
       class="badge badge-outline badge-sm hover:bg-primary hover:text-white hover:border-primary transition-colors">
      {@name}
    </a>
    """
  end
end
