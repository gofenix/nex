defmodule BestofEx.Components.TagChip do
  use Nex

  def tag_chip(assigns) do
    ~H"""
    <a href={"/tags/#{@tag["slug"]}"}
       class="badge badge-outline hover:badge-primary transition-colors">
      {@tag["name"]}
    </a>
    """
  end
end
