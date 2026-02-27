defmodule Nex.Agent.Memory do
  @moduledoc """
  Agent memory system - daily logs with BM25 search.

  ## Structure

      ~/.nex/agent/workspace/
      ├── memory/
      │   ├── 2026-02-27.md
      │   ├── 2026-02-26.md
      │   └── ...

  ## Usage

      # Append to today's log
      :ok = Nex.Agent.Memory.append("Task: Fix login", "Success", %{tool: "bash", command: "..."})
      
      # Search memories
      results = Nex.Agent.Memory.search("login bug")
      
      # Get today's entries
      entries = Nex.Agent.Memory.today()
  """

  @workspace_path Path.join(System.get_env("HOME", "~"), ".nex/agent/workspace")
  @memory_dir Path.join(@workspace_path, "memory")

  @doc """
  Get the memory workspace path.
  """
  @spec workspace_path() :: String.t()
  def workspace_path, do: @workspace_path

  @doc """
  Initialize memory directory structure.
  """
  @spec init() :: :ok
  def init do
    File.mkdir_p!(@memory_dir)
    :ok
  end

  @doc """
  Append an entry to today's memory log.

  ## Parameters

  * `task` - Task description
  * `result` - Result ("SUCCESS", "FAILURE", etc.)
  * `metadata` - Optional metadata map

  ## Examples

      Nex.Agent.Memory.append("Fix login bug", "SUCCESS", %{tool: "bash", command: "git commit -m 'fix'"})
  """
  @spec append(String.t(), String.t(), map()) :: :ok | {:error, term()}
  def append(task, result, metadata \\ %{}) do
    init()

    today = Date.utc_today() |> Date.to_string()
    date_dir = Path.join(@memory_dir, today)
    File.mkdir_p!(date_dir)

    timestamp = Time.utc_now() |> Time.to_string() |> String.slice(0..7)
    entry_id = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)

    entry = format_entry(timestamp, entry_id, task, result, metadata)

    file_path = Path.join(date_dir, "log.md")

    case File.open(file_path, [:append, :utf8]) do
      {:ok, file} ->
        IO.write(file, entry)
        File.close(file)
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get all entries for today.
  """
  @spec today() :: list(map())
  def today do
    today = Date.utc_today() |> Date.to_string()
    read_date(today)
  end

  @doc """
  Get entries for a specific date.

  ## Examples

      entries = Nex.Agent.Memory.get("2026-02-27")
  """
  @spec get(String.t()) :: list(map())
  def get(date) when is_binary(date), do: read_date(date)

  @doc """
  Get entries for a date range.
  """
  @spec get_range(String.t(), String.t()) :: list(map())
  def get_range(from_date, to_date) do
    from = Date.from_iso8601!(from_date)
    to = Date.from_iso8601!(to_date)

    Date.range(from, to)
    |> Enum.flat_map(&get(Date.to_string(&1)))
  end

  @doc """
  Search memories using BM25.
  """
  @spec search(String.t(), keyword()) :: list(map())
  def search(query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)

    # Read all memory files and search
    all_entries = read_all_entries()

    # Score and rank
    all_entries
    |> Enum.map(&score_entry(&1, query))
    |> Enum.filter(&(&1.score > 0))
    |> Enum.sort_by(& &1.score, :desc)
    |> Enum.take(limit)
  end

  @doc """
  Reindex all memories (for BM25).
  """
  @spec reindex() :: :ok
  def reindex do
    # For now, just re-read and re-score
    # In the future, could build an index file
    :ok
  end

  # Private functions

  defp read_date(date) do
    date_dir = Path.join(@memory_dir, date)
    log_file = Path.join(date_dir, "log.md")

    if File.exists?(log_file) do
      content = File.read!(log_file)
      parse_entries(content)
    else
      []
    end
  end

  defp read_all_entries do
    if File.exists?(@memory_dir) do
      @memory_dir
      |> File.ls!()
      |> Enum.filter(&Regex.match?(~r/^\d{4}-\d{2}-\d{2}$/, &1))
      |> Enum.flat_map(&read_date/1)
    else
      []
    end
  end

  defp parse_entries(content) do
    content
    |> String.split("## ")
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&parse_entry/1)
  end

  defp parse_entry(entry) do
    [header | lines] = String.split(entry, "\n", parts: 2)

    [timestamp, id, task_result] = String.split(header, " - ", parts: 3)
    [task, result] = String.split(task_result, ": ", parts: 2)

    body = if length(lines) > 0, do: hd(lines), else: ""

    %{
      timestamp: String.trim(timestamp),
      id: String.trim(id),
      task: String.trim(task),
      result: String.trim(result),
      body: String.trim(body)
    }
  end

  defp format_entry(timestamp, id, task, result, metadata) do
    meta_str =
      if map_size(metadata) > 0 do
        "\n\n```json\n#{Jason.encode!(metadata)}\n```"
      else
        ""
      end

    "## #{timestamp} - #{id} - #{task}: #{result}#{meta_str}\n"
  end

  # BM25 scoring (simplified)

  defp score_entry(entry, query) do
    # Combine all text fields
    text =
      "#{entry.task} #{entry.body} #{entry.result}"
      |> String.downcase()

    query_terms =
      query
      |> String.downcase()
      |> String.split()

    score =
      Enum.reduce(query_terms, 0, fn term, acc ->
        if String.contains?(text, term) do
          # Simple TF scoring
          count = Regex.scan(~r/#{Regex.escape(term)}/, text) |> length()
          acc + count
        else
          acc
        end
      end)

    %{entry: entry, score: score}
  end
end
