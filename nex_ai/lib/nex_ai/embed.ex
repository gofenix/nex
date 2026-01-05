defmodule NexAI.Embed do
  @moduledoc "Embedding utilities for NexAI."
  alias NexAI.Provider.OpenAI

  def embed(opts) do
    model = opts[:model] || OpenAI
    case model.embed_many([opts[:value]], opts) do
      {:ok, [embedding]} -> {:ok, %{embedding: embedding}}
      error -> error
    end
  end

  def embed_many(opts) do
    model = opts[:model] || OpenAI
    case model.embed_many(opts[:values], opts) do
      {:ok, embeddings} -> {:ok, %{embeddings: embeddings}}
      error -> error
    end
  end

  def cosine_similarity(v1, v2) when is_list(v1) and is_list(v2) do
    if length(v1) != length(v2), do: raise ArgumentError, "Vectors must have the same length"
    dot = Enum.zip(v1, v2) |> Enum.map(fn {a, b} -> a * b end) |> Enum.sum()
    m1 = :math.sqrt(Enum.map(v1, &(&1 * &1)) |> Enum.sum())
    m2 = :math.sqrt(Enum.map(v2, &(&1 * &1)) |> Enum.sum())
    if m1 == 0 or m2 == 0, do: 0.0, else: dot / (m1 * m2)
  end
end
