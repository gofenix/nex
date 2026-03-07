defmodule Nex.Agent.Memory.Index do
  @moduledoc """
  BM25 inverted index for memory search.

  Maintains an in-memory inverted index over daily logs, MEMORY.md sections,
  and HISTORY.md entries. Supports BM25 scoring with field weights, time decay,
  and trigram fuzzy fallback.
  """

  use GenServer
  require Logger

  @bm25_k1 1.2
  @bm25_b 0.75
  @decay_window_days 90

  defstruct documents: %{},
            inverted_index: %{},
            doc_freq: %{},
            doc_count: 0,
            doc_lengths: %{},
            total_doc_length: 0,
            avg_doc_length: 0.0

  # ── Client API ──

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc "Rebuild index from disk."
  @spec rebuild() :: :ok
  def rebuild do
    GenServer.call(__MODULE__, :rebuild, 30_000)
  end

  @doc "Add a single document incrementally."
  @spec add_document(String.t(), map()) :: :ok
  def add_document(doc_id, doc) do
    GenServer.cast(__MODULE__, {:add_document, doc_id, doc})
  end

  @doc "Search with BM25 scoring. Returns [{score, doc}]."
  @spec search(String.t(), keyword()) :: list(map())
  def search(query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)
    source = Keyword.get(opts, :source, :all)

    GenServer.call(__MODULE__, {:search, query, limit, source}, 100)
  catch
    :exit, {:timeout, _} -> []
    :exit, {:noproc, _} -> []
  end

  # ── GenServer Callbacks ──

  @impl true
  def init(_opts) do
    {:ok, %__MODULE__{}, {:continue, :rebuild}}
  end

  @impl true
  def handle_continue(:rebuild, _state) do
    state = do_rebuild()
    Logger.info("[Memory.Index] Built index: #{state.doc_count} documents")
    {:noreply, state}
  end

  @impl true
  def handle_call(:rebuild, _from, _state) do
    state = do_rebuild()
    Logger.info("[Memory.Index] Rebuilt index: #{state.doc_count} documents")
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:search, query, limit, source}, _from, state) do
    results = do_search(state, query, limit, source)
    {:reply, results, state}
  end

  @impl true
  def handle_cast({:add_document, doc_id, doc}, state) do
    state = index_document(state, doc_id, doc)
    {:noreply, state}
  end

  # ── Index Building ──

  defp do_rebuild do
    docs = load_all_documents()

    Enum.reduce(docs, %__MODULE__{}, fn {doc_id, doc}, state ->
      index_document(state, doc_id, doc)
    end)
  end

  defp load_all_documents do
    daily_docs = load_daily_logs()
    memory_docs = load_memory_sections()
    history_docs = load_history_entries()
    daily_docs ++ memory_docs ++ history_docs
  end

  defp load_daily_logs do
    try do
      Nex.Agent.Memory.read_all_entries()
      |> Enum.with_index()
      |> Enum.map(fn {entry, idx} ->
        date_str = entry[:date_str]
        doc_id = "daily:#{date_str}:#{entry[:id] || idx}"

        doc = %{
          text: "#{entry[:task]} #{entry[:result]} #{entry[:body]}",
          task: entry[:task] || "",
          date: parse_date_string(date_str),
          source: :daily
        }

        {doc_id, doc}
      end)
    rescue
      _ -> []
    end
  end

  defp load_memory_sections do
    try do
      Nex.Agent.Memory.read_memory_sections()
      |> Enum.with_index()
      |> Enum.map(fn {section, idx} ->
        doc_id = "memory:#{idx}"

        doc = %{
          text: section[:content] || "",
          task: section[:header] || "",
          date: nil,
          source: :memory
        }

        {doc_id, doc}
      end)
    rescue
      _ -> []
    end
  end

  defp load_history_entries do
    try do
      Nex.Agent.Memory.read_history()
      |> Enum.with_index()
      |> Enum.map(fn {entry, idx} ->
        doc_id = "history:#{idx}"

        doc = %{
          text: entry[:content] || "",
          task: "",
          date: entry[:date],
          source: :history
        }

        {doc_id, doc}
      end)
    rescue
      _ -> []
    end
  end

  defp parse_date_string(nil), do: nil

  defp parse_date_string(str) when is_binary(str) do
    case Date.from_iso8601(str) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp parse_date_string(_), do: nil

  # ── Indexing ──

  defp index_document(state, doc_id, doc) do
    text = "#{doc[:text]} #{doc[:task]}"
    terms = tokenize(text)
    term_count = length(terms)

    # Build term frequency map for this doc
    term_freqs = Enum.frequencies(terms)

    # Task field bonus: double-count terms from task
    task_terms = tokenize(doc[:task] || "")
    task_freqs = Enum.frequencies(task_terms)

    boosted_freqs =
      Map.merge(term_freqs, task_freqs, fn _k, base, task_count ->
        base + task_count
      end)

    # Update inverted index and doc_freq
    unique_terms = Map.keys(boosted_freqs)

    inverted_index =
      Enum.reduce(unique_terms, state.inverted_index, fn term, idx ->
        Map.update(idx, term, MapSet.new([doc_id]), &MapSet.put(&1, doc_id))
      end)

    doc_freq =
      Enum.reduce(unique_terms, state.doc_freq, fn term, df ->
        Map.update(df, term, 1, &(&1 + 1))
      end)

    documents = Map.put(state.documents, doc_id, Map.put(doc, :term_freqs, boosted_freqs))
    doc_lengths = Map.put(state.doc_lengths, doc_id, term_count)
    doc_count = map_size(documents)
    total_doc_length = state.total_doc_length + term_count
    avg_doc_length = if doc_count > 0, do: total_doc_length / doc_count, else: 0.0

    %{
      state
      | documents: documents,
        inverted_index: inverted_index,
        doc_freq: doc_freq,
        doc_count: doc_count,
        doc_lengths: doc_lengths,
        total_doc_length: total_doc_length,
        avg_doc_length: avg_doc_length
    }
  end

  # ── Search ──

  defp do_search(state, query, limit, source) do
    if state.doc_count == 0 do
      []
    else
      query_terms = tokenize(query)

      # Filter by source
      doc_ids =
        case source do
          :all ->
            Map.keys(state.documents)

          source_filter ->
            state.documents
            |> Enum.filter(fn {_id, doc} -> doc[:source] == source_filter end)
            |> Enum.map(&elem(&1, 0))
        end

      doc_ids
      |> Enum.map(fn doc_id ->
        doc = state.documents[doc_id]
        score = bm25_score(state, doc_id, doc, query_terms)
        score = apply_time_decay(score, doc[:date])

        %{
          score: score,
          text: String.slice(doc[:text] || "", 0..500),
          task: doc[:task],
          date: if(doc[:date], do: Date.to_string(doc[:date]), else: nil),
          source: doc[:source]
        }
      end)
      |> Enum.filter(&(&1.score > 0))
      |> Enum.sort_by(& &1.score, :desc)
      |> Enum.take(limit)
    end
  end

  defp bm25_score(state, doc_id, doc, query_terms) do
    term_freqs = doc[:term_freqs] || %{}
    doc_len = Map.get(state.doc_lengths, doc_id, 0)
    avgdl = state.avg_doc_length
    n = state.doc_count

    Enum.reduce(query_terms, 0.0, fn term, acc ->
      tf = Map.get(term_freqs, term, 0)

      if tf > 0 do
        # Exact match BM25
        df = Map.get(state.doc_freq, term, 0)
        idf = :math.log((n - df + 0.5) / (df + 0.5) + 1)
        norm_tf = (tf * (@bm25_k1 + 1)) / (tf + @bm25_k1 * (1 - @bm25_b + @bm25_b * doc_len / max(avgdl, 1)))
        acc + idf * norm_tf
      else
        # Trigram fuzzy fallback
        acc + trigram_fallback_score(state, term, doc)
      end
    end)
  end

  defp trigram_fallback_score(_state, query_term, doc) do
    if String.length(query_term) < 3 do
      0.0
    else
      query_trigrams = trigrams(query_term)
      doc_terms = Map.keys(doc[:term_freqs] || %{})

      # Only check terms in this document, not the entire vocabulary
      Enum.reduce(doc_terms, 0.0, fn idx_term, best ->
        if String.length(idx_term) >= 3 do
          sim = jaccard_similarity(query_trigrams, trigrams(idx_term))
          if sim > 0.3 and sim > best, do: sim * 0.5, else: best
        else
          best
        end
      end)
    end
  end

  defp apply_time_decay(score, nil), do: score

  defp apply_time_decay(score, date) do
    days_old = Date.diff(Date.utc_today(), date)
    decay = 0.5 + 0.5 * max(0, 1 - days_old / @decay_window_days)
    score * decay
  end

  # ── Text Processing ──

  defp tokenize(text) when is_binary(text) do
    text
    |> String.downcase()
    |> String.split(~r/[^a-z0-9\p{Han}\-_]+/u, trim: true)
    |> Enum.reject(&(String.length(&1) < 2))
  end

  defp tokenize(_), do: []

  defp trigrams(str) when is_binary(str) do
    str
    |> String.graphemes()
    |> Enum.chunk_every(3, 1, :discard)
    |> Enum.map(&Enum.join/1)
    |> MapSet.new()
  end

  defp jaccard_similarity(set_a, set_b) do
    intersection = MapSet.intersection(set_a, set_b) |> MapSet.size()
    union = MapSet.union(set_a, set_b) |> MapSet.size()
    if union == 0, do: 0.0, else: intersection / union
  end
end
