defmodule BestofEx.Pages.Tags.Index do
  use Nex

  @client NexBase.client(repo: BestofEx.Repo)

  def mount(_params) do
    tags = list_tags()

    %{
      title: "Tags - Best of Elixir",
      tags: tags
    }
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1 class="text-3xl font-bold mb-6">All Tags</h1>
      <div class="flex flex-wrap gap-4">
        <.BestofEx.Components.TagChip.tag_chip :for={tag <- @tags} tag={tag} />
      </div>
      <div :if={Enum.empty?(@tags)} class="text-center py-8 text-base-content/50">
        <p>No tags yet. Run <code>mix run seeds/import.exs</code> to seed data.</p>
      </div>
    </div>
    """
  end

  defp list_tags do
    case @client
    |> NexBase.from("tags")
    |> NexBase.order(:name, :asc)
    |> NexBase.run() do
      {:ok, tags} -> tags
      _ -> []
    end
  end
end
