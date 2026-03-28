defmodule NexWebsite.ExamplesCatalog do
  @repo_root Path.expand("../../..", __DIR__)
  @catalog_path Path.join(@repo_root, "examples/catalog.exs")
  @catalog @catalog_path |> Code.eval_file() |> elem(0)

  def all do
    @catalog
  end

  def featured(limit \\ nil) do
    featured =
      @catalog
      |> Enum.filter(& &1.featured)

    if is_integer(limit), do: Enum.take(featured, limit), else: featured
  end

  def github_url(slug) do
    "https://github.com/gofenix/nex/tree/main/examples/#{slug}"
  end
end
