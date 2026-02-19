defmodule NexWebsite.Pages.Index do
  use Nex
  alias NexWebsite.CodeExamples
  alias NexWebsite.Components.{HomeHero, HomeFeatures, HomePhilosophy, HomeExamples, HomeComparison, HomeCta}

  def mount(_params) do
    %{
      title: "Nex — The Elixir Framework for the AI Era",
      example_code: CodeExamples.get("index_page.md") |> CodeExamples.format_for_display()
    }
  end

  def render(assigns) do
    ~H"""
    {HomeHero.render(assigns)}
    {HomeFeatures.render(assigns)}
    {HomePhilosophy.render(assigns)}
    {HomeExamples.render(assigns)}
    {HomeComparison.render(assigns)}
    {HomeCta.render(assigns)}
    """
  end
end
