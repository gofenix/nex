defmodule Nex.Agent.Tool.MemorySearch do
  @moduledoc """
  MemorySearch Tool — search agent memory using BM25 index.
  """

  @behaviour Nex.Agent.Tool.Behaviour

  def name, do: "memory_search"
  def description, do: "Search agent memory (daily logs, long-term memory, history) using keyword search."
  def category, do: :base

  def definition do
    %{
      name: "memory_search",
      description: """
      Search agent memory for relevant past experiences, decisions, and knowledge.
      Searches across daily logs, long-term memory (MEMORY.md), and history (HISTORY.md).
      Returns ranked results with relevance scores.
      """,
      parameters: %{
        type: "object",
        properties: %{
          query: %{
            type: "string",
            description: "Search keywords"
          },
          limit: %{
            type: "integer",
            description: "Maximum number of results (default 5)"
          },
          source: %{
            type: "string",
            enum: ["all", "daily", "memory", "history"],
            description: "Filter by source type (default: all)"
          }
        },
        required: ["query"]
      }
    }
  end

  def execute(args, _ctx) do
    query = Map.get(args, "query", "")

    if query == "" do
      {:error, "query is required"}
    else
      limit = to_int(Map.get(args, "limit", 5))

      source =
        case Map.get(args, "source", "all") do
          "daily" -> :daily
          "memory" -> :memory
          "history" -> :history
          _ -> :all
        end

      results = Nex.Agent.Memory.search(query, limit: limit, source: source)

      formatted =
        Enum.map(results, fn r ->
          %{
            score: Float.round(r[:score] || 0.0, 2),
            snippet: String.slice(r[:text] || "", 0..200),
            task: r[:task],
            date: r[:date],
            source: to_string(r[:source] || "unknown")
          }
        end)

      {:ok, %{results: formatted, total: length(formatted), query: query}}
    end
  end

  defp to_int(v) when is_integer(v), do: v
  defp to_int(v) when is_binary(v) do
    case Integer.parse(v) do
      {n, ""} -> n
      _ -> 5
    end
  end
  defp to_int(v) when is_float(v), do: trunc(v)
  defp to_int(_), do: 5
end
