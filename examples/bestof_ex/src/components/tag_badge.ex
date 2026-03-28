defmodule BestofEx.Components.TagBadge do
  @moduledoc """
  Small clickable tag badge.
  """
  use Nex

  def render(assigns) do
    ~H"""
    <a href={"/tags/#{@slug}"}
       class="badge badge-premium badge-sm">
      {@name}
    </a>
    """
  end
end
