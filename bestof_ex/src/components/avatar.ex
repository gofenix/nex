defmodule BestofEx.Components.Avatar do
  @moduledoc """
  Letter avatar component for projects without logos.
  Generates a colored square with project initials.
  """
  use Nex

  @palette [
    "#4B275F", "#6B3FA0", "#E44D26", "#3B82F6",
    "#10B981", "#8B5CF6", "#EC4899", "#F59E0B",
    "#06B6D4", "#EF4444", "#14B8A6", "#A855F7"
  ]

  def render(assigns) do
    ~H"""
    <div :if={assigns[:avatar_url]} class={"rounded-lg shrink-0 overflow-hidden #{size_class(@size)}"}>
      <img src={@avatar_url} alt={@name} class="w-full h-full object-cover" loading="lazy" />
    </div>
    <div :if={!assigns[:avatar_url]} class={"rounded-lg flex items-center justify-center text-white font-bold shrink-0 #{size_class(@size)}"}
         style={"background-color: #{color_for(@name)}"}>
      {initials(@name)}
    </div>
    """
  end

  defp size_class(size) do
    case size do
      "sm" -> "w-8 h-8 text-xs"
      "md" -> "w-10 h-10 text-sm"
      "lg" -> "w-14 h-14 text-base"
      "xl" -> "w-16 h-16 text-lg"
      _ -> "w-10 h-10 text-sm"
    end
  end

  defp initials(name) do
    name
    |> String.split(~r/[\s_-]/, trim: true)
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
  end

  defp color_for(name) do
    index = :erlang.phash2(name, length(@palette))
    Enum.at(@palette, index)
  end
end
