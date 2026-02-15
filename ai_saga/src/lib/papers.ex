defmodule AiSaga.Papers do
  @data_path "data/papers.json"

  def init do
    File.mkdir_p!("data")
    unless File.exists?(@data_path), do: File.write!(@data_path, "[]")
  end

  def all do
    @data_path
    |> File.read!()
    |> Jason.decode!()
  end

  def get(id) when is_integer(id) do
    all()
    |> Enum.find(fn p -> p["id"] == id end)
  end

  def get_by_arxiv(arxiv_id) do
    all()
    |> Enum.find(fn p -> p["arxiv_id"] == arxiv_id end)
  end

  def insert(paper) do
    papers = all()
    new_id = if papers == [], do: 1, else: Enum.max_by(papers, & &1["id"])["id"] + 1
    new_paper = Map.put(paper, "id", new_id)
    updated = papers ++ [new_paper]
    File.write!(@data_path, Jason.encode!(updated))
    new_paper
  end

  def search(query) do
    q = String.downcase(query)
    all()
    |> Enum.filter(fn p ->
      title = p["title"] || ""
      abstract = p["abstract"] || ""
      String.contains?(String.downcase(title), q) or String.contains?(String.downcase(abstract), q)
    end)
  end
end
