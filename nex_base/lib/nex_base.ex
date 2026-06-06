defmodule NexBase do
  @moduledoc """
  A fluent database query builder for Elixir, modeled after the Supabase JS SDK
  (postgrest-js). Supports PostgreSQL and SQLite with automatic adapter detection
  and multiple simultaneous database connections.

  ## Quick Start

      # Single connection (simplest)
      NexBase.init(url: "postgres://localhost/mydb")
      NexBase.from("users") |> NexBase.select("*") |> NexBase.run()

      # Multiple connections
      main = NexBase.init(url: "postgres://localhost/main")
      cache = NexBase.init(url: "sqlite::memory:")

      main |> NexBase.from("users") |> NexBase.run()
      cache |> NexBase.from("sessions") |> NexBase.run()

  ## Supabase API parity

  All PostgrestFilterBuilder, PostgrestTransformBuilder, and
  PostgrestQueryBuilder methods are implemented with equivalent semantics.
  """

  alias NexBase.{Query, Conn}
  require Ecto.Query

  # -- Initialization --

  @doc """
  Initialize a database connection. Returns a `%NexBase.Conn{}` struct.

  The adapter is auto-detected from the URL scheme:
  - `postgres://` or `postgresql://` → PostgreSQL
  - `sqlite://` → SQLite

  ## Options

    - `:url` - Database URL (falls back to DATABASE_URL env var)
    - `:ssl` - Enable SSL for cloud databases (default: false, ignored for SQLite)
    - `:pool_size` - Connection pool size (default: 10)
    - `:start` - Start the Repo immediately (for scripts, default: false)

  ## Examples

      # Single connection (in application.ex)
      NexBase.init(url: "postgres://localhost/mydb", ssl: true)

      # In a script
      conn = NexBase.init(url: "sqlite::memory:", start: true, pool_size: 1)
      conn |> NexBase.from("users") |> NexBase.run()
  """
  def init(opts \\ []) do
    url = opts[:url] || System.get_env("DATABASE_URL")
    adapter = detect_adapter(url)
    pool_size = opts[:pool_size] || 10
    repo_module = repo_module_for(adapter)
    repo_config = build_repo_config(adapter, url, pool_size, opts)

    is_first = Application.get_env(:nex_base, :default_conn) == nil
    name = if is_first, do: repo_module, else: :"nex_base_#{:erlang.unique_integer([:positive, :monotonic])}"

    conn = %Conn{
      name: name,
      adapter: adapter,
      repo_module: repo_module,
      repo_config: repo_config
    }

    Application.put_env(:nex_base, :repo_config, repo_config)
    Application.put_env(:nex_base, name, repo_config)
    if is_first do
      Application.put_env(:nex_base, :default_conn, conn)
    end
    Application.put_env(:nex_base, :adapter, adapter)

    if opts[:start] do
      start_conn(conn)
    end

    conn
  end

  defp detect_adapter(nil), do: :postgres
  defp detect_adapter(url) when is_binary(url) do
    cond do
      String.starts_with?(url, "sqlite") -> :sqlite
      true -> :postgres
    end
  end

  defp build_repo_config(:postgres, url, pool_size, opts) do
    config = [
      url: url,
      pool_size: pool_size,
      prepare: Keyword.get(opts, :prepare, :unnamed)
    ]

    config = if opts[:ssl] do
      config ++ [
        ssl: [verify: :verify_none],
        queue_target: 10_000,
        queue_interval: 20_000
      ]
    else
      config
    end

    extra_keys = [:queue_target, :queue_interval, :timeout, :connect_timeout]
    extra = Keyword.take(opts, extra_keys)
    Keyword.merge(config, extra)
  end

  defp build_repo_config(:sqlite, url, pool_size, _opts) do
    database = parse_sqlite_url(url)
    [database: database, pool_size: pool_size]
  end

  defp parse_sqlite_url("sqlite::memory:"), do: ":memory:"
  defp parse_sqlite_url("sqlite:///" <> path), do: "/" <> path
  defp parse_sqlite_url("sqlite://" <> path), do: path
  defp parse_sqlite_url(path), do: path

  defp repo_module_for(:postgres), do: NexBase.Repo.Postgres
  defp repo_module_for(:sqlite), do: NexBase.Repo.SQLite

  defp start_conn(%Conn{adapter: adapter, repo_module: repo_module, name: name}) do
    case adapter do
      :postgres -> Application.ensure_all_started(:postgrex)
      :sqlite -> Application.ensure_all_started(:exqlite)
    end
    Application.ensure_all_started(:ecto_sql)

    start_opts = if name == repo_module, do: [], else: [name: name]
    case repo_module.start_link(start_opts) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Returns the default connection, or raises if none configured."
  def default_conn do
    Application.get_env(:nex_base, :default_conn) ||
      raise "NexBase not initialized. Call NexBase.init/1 first."
  end

  @doc "Returns the adapter for a connection (`:postgres` or `:sqlite`)."
  def adapter(%Conn{adapter: adapter}), do: adapter
  def adapter, do: default_conn().adapter

  # -- Query Building --

  @doc """
  Starts a query builder for the given table. Supabase `.from(table)` equivalent.
  """
  def from(%Conn{} = conn, table_name) when is_binary(table_name) do
    %Query{table: table_name, conn: conn}
  end

  def from(table_name) when is_binary(table_name) do
    %Query{table: table_name}
  end

  @doc """
  Selects specific columns. Supabase `.select(columns)` equivalent.

  Accepts either a list of columns (atoms or strings) or a Supabase-style
  comma-separated column string, which supports column aliases via `alias:column`
  syntax. Calling `.select()` on insert/update/upsert/delete queries enables
  `RETURNING`, so the affected rows are returned (Supabase `return=representation`).

  ## Examples

      # List of atoms
      NexBase.from("users") |> NexBase.select([:id, :name])

      # String with aliases
      NexBase.from("users") |> NexBase.select("id,display_name:name,profile(*)")

      # Enable RETURNING after insert
      NexBase.from("users") |> NexBase.insert(%{name: "Alice"}) |> NexBase.select() |> NexBase.run()
  """
  def select(query, columns \\ "*")

  def select(%Query{type: type} = query, columns) when type in [:insert, :update, :delete, :upsert] do
    %{query | select: normalize_select(columns), returning: true}
  end

  def select(%Query{} = query, columns) do
    %{query | select: normalize_select(columns)}
  end

  @doc """
  Like `select/2` but accepts options `head:` and `count:`.
  Supabase `.select("col", { head: true, count: "exact" })` equivalent.
  """
  def select(%Query{} = query, columns, opts) when is_list(opts) do
    base = select(query, columns)
    base = if opts[:head], do: %{base | head: true}, else: base
    if opts[:count], do: count(base, opts[:count]), else: base
  end

  defp normalize_select("*"), do: []
  defp normalize_select(columns) when is_list(columns), do: columns
  defp normalize_select(columns) when is_binary(columns) do
    columns
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.flat_map(&parse_select_col/1)
  end

  defp parse_select_col(col) do
    # Handle "alias:column" → column AS alias
    case String.split(col, ":", parts: 2) do
      [alias_name, col_name] when alias_name != "" and col_name != "" ->
        # Strip foreign-table parens like posts(*)
        col_name_clean = String.replace(col_name, ~r/\(.*\)$/, "")
        if String.contains?(col_name, "(") do
          # Foreign table select: just select the raw column name for now
          [col_name_clean]
        else
          ["#{col_name_clean} AS #{alias_name}"]
        end
      [col] ->
        [col]
    end
  end

  # -- Basic Filters --

  @doc "Supabase `.eq(column, value)` equivalent."
  def eq(%Query{} = query, column, value) do
    append_filter(query, {:eq, column, value})
  end

  @doc "Supabase `.neq(column, value)` equivalent."
  def neq(%Query{} = query, column, value) do
    append_filter(query, {:neq, column, value})
  end

  @doc "Supabase `.gt(column, value)` equivalent."
  def gt(%Query{} = query, column, value) do
    append_filter(query, {:gt, column, value})
  end

  @doc "Supabase `.lt(column, value)` equivalent."
  def lt(%Query{} = query, column, value) do
    append_filter(query, {:lt, column, value})
  end

  @doc "Supabase `.gte(column, value)` equivalent."
  def gte(%Query{} = query, column, value) do
    append_filter(query, {:gte, column, value})
  end

  @doc "Supabase `.lte(column, value)` equivalent."
  def lte(%Query{} = query, column, value) do
    append_filter(query, {:lte, column, value})
  end

  @doc """
  Supabase `.is(column, value)` equivalent. Use for NULL checks and boolean columns.

  ## Examples

      NexBase.from("users") |> NexBase.is(:deleted_at, nil)
      NexBase.from("users") |> NexBase.is(:active, true)
  """
  def is(%Query{} = query, column, value) do
    append_filter(query, {:is, column, value})
  end

  @doc "Shorthand for `is(column, nil)`."
  def is_null(%Query{} = query, column) do
    append_filter(query, {:is, column, nil})
  end

  @doc "Shorthand for `not_filter(column, :is, nil)`."
  def is_not_null(%Query{} = query, column) do
    append_not_filter(query, {:is, column, nil})
  end

  @doc """
  Supabase `.in(column, values)` equivalent. Named `in_list` to avoid the
  reserved `in/2` operator. Use `filter_in/3` for a friendlier alias.
  """
  def in_list(%Query{} = query, column, values) when is_list(values) do
    append_filter(query, {:in, column, values})
  end

  @doc "Alias for `in_list/3`."
  def filter_in(%Query{} = query, column, values) when is_list(values) do
    in_list(query, column, values)
  end

  @doc "Supabase `.not(column, :in, values)` convenience. Equivalent to `not_filter(column, :in, values)`."
  def not_in_list(%Query{} = query, column, values) when is_list(values) do
    append_not_filter(query, {:in, column, values})
  end

  @doc "Supabase `.like(column, pattern)` equivalent."
  def like(%Query{} = query, column, pattern) do
    append_filter(query, {:like, column, pattern})
  end

  @doc "Supabase `.not(column, :like, pattern)` convenience."
  def nlike(%Query{} = query, column, pattern) do
    append_filter(query, {:nlike, column, pattern})
  end

  @doc "Supabase `.ilike(column, pattern)` equivalent."
  def ilike(%Query{} = query, column, pattern) do
    append_filter(query, {:ilike, column, pattern})
  end

  @doc "Supabase `.not(column, :ilike, pattern)` convenience."
  def nilike(%Query{} = query, column, pattern) do
    append_filter(query, {:nilike, column, pattern})
  end

  @doc """
  Supabase `.likeAllOf(column, patterns)` equivalent. Matches if the column matches
  ALL of the given LIKE patterns (ANDed together).
  """
  def like_all_of(%Query{} = query, column, patterns) when is_list(patterns) do
    filters = Enum.map(patterns, &{:like, column, &1})
    %{query | filters: query.filters ++ filters}
  end

  @doc """
  Supabase `.likeAnyOf(column, patterns)` equivalent. Matches if the column matches
  ANY of the given LIKE patterns (ORed together).
  """
  def like_any_of(%Query{} = query, column, patterns) when is_list(patterns) do
    group = Enum.map(patterns, &{:like, column, &1})
    %{query | or_filters: query.or_filters ++ [group]}
  end

  @doc """
  Supabase `.ilikeAllOf(column, patterns)` equivalent. Case-insensitive.
  """
  def ilike_all_of(%Query{} = query, column, patterns) when is_list(patterns) do
    filters = Enum.map(patterns, &{:ilike, column, &1})
    %{query | filters: query.filters ++ filters}
  end

  @doc """
  Supabase `.ilikeAnyOf(column, patterns)` equivalent. Case-insensitive.
  """
  def ilike_any_of(%Query{} = query, column, patterns) when is_list(patterns) do
    group = Enum.map(patterns, &{:ilike, column, &1})
    %{query | or_filters: query.or_filters ++ [group]}
  end

  defp append_filter(%Query{} = query, filter) do
    %{query | filters: query.filters ++ [filter]}
  end

  defp append_not_filter(%Query{} = query, filter) do
    %{query | not_filters: query.not_filters ++ [filter]}
  end

  # -- Pagination / Ordering --

  @doc """
  Supabase `.limit(count, opts)` equivalent.

  ## Options
    - `:referenced_table` / `:foreign_table` — apply to a referenced/embedded table
  """
  def limit(%Query{} = query, count, opts \\ []) when is_integer(count) and count >= 0 do
    ref_table = opts[:referenced_table] || opts[:foreign_table]
    %{query | limit: count, limit_referenced_table: ref_table}
  end

  @doc """
  Supabase `.offset(value, opts)` equivalent.
  """
  def offset(%Query{} = query, offset, opts \\ []) when is_integer(offset) and offset >= 0 do
    ref_table = opts[:referenced_table] || opts[:foreign_table]
    %{query | offset: offset, offset_referenced_table: ref_table}
  end

  @doc """
  Supabase `.order(column, opts)` equivalent.

  ## Options
    - `:ascending` — boolean, default `true`
    - `:nulls_first` — if `true`, NULLs sort first; if `false`, NULLs sort last
    - `:nulls_last` — alias for `nulls_first: false`
    - `:referenced_table` / `:foreign_table` — apply to a referenced/embedded table

  Backward-compatible: `order(query, col, :asc)` or `order(query, col, :desc, nulls_first: true)`
  are still supported.
  """
  def order(query, column, direction_or_opts \\ :asc)

  def order(%Query{} = query, column, direction) when is_atom(direction) and not is_list(direction) do
    order(query, column, direction, [])
  end

  def order(%Query{} = query, column, opts) when is_list(opts) do
    dir = if opts[:ascending] == false, do: :desc, else: :asc
    order(query, column, dir, opts)
  end

  def order(%Query{} = query, column, direction, opts) when is_list(opts) do
    ref_table = opts[:referenced_table] || opts[:foreign_table]

    entry =
      case {direction, opts} do
        {dir, []} -> {dir, column}
        {dir, o} ->
          stripped = Enum.reject(o, fn {k, _} -> k in [:referenced_table, :foreign_table, :ascending] end)
          if stripped == [], do: {dir, column}, else: {dir, column, stripped}
      end

    entry_with_ref = if ref_table, do: {entry, referenced_table: ref_table}, else: entry
    %{query | order_by: query.order_by ++ [entry_with_ref]}
  end

  # -- Generic filter dispatch --

  @doc """
  Adds a generic filter clause. Supabase `filter(column, operator, value)` equivalent.

  `operator` can be either an atom (`:eq`, `:gt`, ...) or a string, including the
  `"not.eq"` form supported by Supabase.

  ## Examples

      NexBase.from("users") |> NexBase.filter(:status, :eq, "active")
      NexBase.from("users") |> NexBase.filter("status", "not.eq", "banned")
  """
  def filter(%Query{} = query, column, operator, value) when is_atom(operator) do
    case operator do
      :or -> or_filter(query, value)
      :not -> apply_query_not_filter(query, column, value)
      op ->
        normalized = normalize_operator(op)
        append_filter(query, {normalized, column, value})
    end
  end

  def filter(%Query{} = query, column, "not." <> op_str, value) do
    op = String.to_existing_atom(op_str)
    normalized = normalize_operator(op)
    append_not_filter(query, {normalized, column, value})
  end

  def filter(%Query{} = query, column, operator, value) when is_binary(operator) do
    op = String.to_existing_atom(operator)
    filter(query, column, op, value)
  end

  @doc """
  Adds a negated filter. Supabase `.not(column, operator, value)` equivalent.

  Named `not_filter/4` in Elixir because `not` is a reserved keyword.
  """
  def not_filter(%Query{} = query, column, operator, value) when is_atom(operator) do
    normalized = normalize_operator(operator)
    append_not_filter(query, {normalized, column, value})
  end

  def not_filter(%Query{} = query, column, operator, value) when is_binary(operator) do
    not_filter(query, column, String.to_existing_atom(operator), value)
  end

  defp apply_query_not_filter(%Query{} = query, column, {op, value}) when is_atom(op) do
    normalized = normalize_operator(op)
    append_not_filter(query, {normalized, column, value})
  end

  defp apply_query_not_filter(%Query{} = query, column, value) do
    not_filter(query, column, :eq, value)
  end

  @doc """
  Adds an OR filter group. Supabase `.or(filters, opts)` equivalent.

  Accepts a list of filter tuples `{operator, column, value}`. All filters inside
  are joined with OR and combined with the query's AND filters.

  ## Options
    - `:referenced_table` / `:foreign_table` — filter on a referenced/embedded table
  """
  def or_filter(%Query{} = query, filters, opts \\ []) when is_list(filters) do
    if Enum.empty?(filters) do
      query
    else
      normalized =
        Enum.map(filters, fn
          {op, col, val} -> {normalize_operator(op), col, val}
          {col, val} -> {:eq, col, val}
        end)

      ref_table = opts[:referenced_table] || opts[:foreign_table]
      entry = if ref_table, do: {normalized, referenced_table: ref_table}, else: normalized
      %{query | or_filters: query.or_filters ++ [entry]}
    end
  end

  # -- Full Text Search --

  @doc """
  Supabase `.textSearch(column, query, opts)` equivalent.

  ## Options
    - `:config` — text search config (default: `"english"`)
    - `:type` — `:plain` (default), `:phrase`, or `:websearch`
  """
  def text_search(query, column, query_text, opts \\ [])

  def text_search(%Query{} = query, column, query_text, opts) when is_list(opts) do
    config = opts[:config] || "english"
    type = opts[:type] || :plain

    op = case type do
      :plain -> :plfts
      :phrase -> :phfts
      :phfts -> :phfts
      :websearch -> :wfts
      other when is_atom(other) -> other
    end

    append_filter(query, {op, {column, config}, query_text})
  end

  # For backward compat: text_search(query, col, query_text, "english") — 4th arg as string config
  def text_search(%Query{} = query, column, query_text, config) when is_binary(config) do
    append_filter(query, {:fts, {column, config}, query_text})
  end

  @doc """
  Supabase `.fts(column, query, opts)` — plainto_tsquery full text search.
  """
  def fts(%Query{} = query, column, query_text, opts \\ []) do
    config = if is_list(opts), do: opts[:config] || "english", else: opts
    append_filter(query, {:fts, {column, config}, query_text})
  end

  @doc """
  Supabase `.plfts(column, query, opts)` — plainto_tsquery full text search.
  """
  def plfts(%Query{} = query, column, query_text, opts \\ []) do
    config = if is_list(opts), do: opts[:config] || "english", else: opts
    append_filter(query, {:plfts, {column, config}, query_text})
  end

  @doc """
  Supabase `.phfts(column, query, opts)` — phraseto_tsquery full text search.
  """
  def phfts(%Query{} = query, column, query_text, opts \\ []) do
    config = if is_list(opts), do: opts[:config] || "english", else: opts
    append_filter(query, {:phfts, {column, config}, query_text})
  end

  @doc """
  Supabase `.wfts(column, query, opts)` — websearch_to_tsquery full text search.
  """
  def wfts(%Query{} = query, column, query_text, opts \\ []) do
    config = if is_list(opts), do: opts[:config] || "english", else: opts
    append_filter(query, {:wfts, {column, config}, query_text})
  end

  # -- Array / Range operators --

  @doc "Supabase `.contains(column, value)` equivalent."
  def contains(%Query{} = query, column, values) do
    append_filter(query, {:cs, column, values})
  end

  @doc """
  Supabase `.containedBy(column, value)` equivalent. Named `contained_in/3` in
  Elixir for natural-language phrasing.
  """
  def contained_in(%Query{} = query, column, values) do
    append_filter(query, {:cd, column, values})
  end

  @doc "Alias for `contained_in/3`."
  def contained_by(%Query{} = query, column, values) do
    contained_in(query, column, values)
  end

  @doc "Supabase `.overlaps(column, value)` equivalent."
  def overlaps(%Query{} = query, column, values) do
    append_filter(query, {:ov, column, values})
  end

  @doc "Supabase `.rangeLt(column, range)` — strictly left of."
  def range_lt(%Query{} = query, column, value) do
    append_filter(query, {:sl, column, value})
  end

  @doc "Supabase `.rangeGte(column, range)` — does not extend to the right of."
  def range_gte(%Query{} = query, column, value) do
    append_filter(query, {:nxl, column, value})
  end

  @doc "Supabase `.rangeGt(column, range)` — strictly right of."
  def range_gt(%Query{} = query, column, value) do
    append_filter(query, {:sr, column, value})
  end

  @doc "Supabase `.rangeLte(column, range)` — does not extend to the left of."
  def range_lte(%Query{} = query, column, value) do
    append_filter(query, {:nxr, column, value})
  end

  @doc "Supabase `.rangeAdjacent(column, range)` — ranges are adjacent."
  def range_adjacent(%Query{} = query, column, value) do
    append_filter(query, {:adj, column, value})
  end

  @doc "Supabase `.match(map)` equivalent — multiple eq filters ANDed together."
  def match(%Query{} = query, conditions) when is_map(conditions) do
    new_filters = Enum.map(conditions, fn {col, val} -> {:eq, col, val} end)
    %{query | filters: query.filters ++ new_filters}
  end

  # -- Count / Single Results --

  @doc """
  Supabase `.count(mode)` equivalent. Accepts `:exact`, `:planned`, or `:estimated`.

  When `run/1` executes with a count set, it returns `{:ok, data, count}`.
  """
  def count(%Query{} = query, mode \\ :exact)
      when mode in [:exact, :planned, :estimated] do
    %{query | count: mode}
  end

  @doc """
  Supabase `.single()` equivalent. Returns the query as a single unwrapped object
  when `.run()/.run!()` executes. Raises if 0 rows or >1 rows are returned.
  """
  def single(%Query{} = query) do
    %{query | single: true, limit: 1}
  end

  @doc """
  Supabase `.maybeSingle()` equivalent. Returns the query as a single unwrapped
  object or `nil` when `.run()/.run!()` executes. Raises only if >1 rows are returned.
  """
  def maybe_single(%Query{} = query) do
    %{query | maybe_single: true, limit: 1}
  end

  @doc """
  Supabase `.range(from, to, opts)` equivalent. `from` and `to` are 0-based inclusive.
  """
  def range(%Query{} = query, from, to, opts \\ []) do
    limit = max(0, to - from + 1)
    from = max(0, from)
    ref_table = opts[:referenced_table] || opts[:foreign_table]
    %{query |
      limit: limit, offset: from,
      limit_referenced_table: ref_table || query.limit_referenced_table,
      offset_referenced_table: ref_table || query.offset_referenced_table
    }
  end

  # -- Explain / CSV / Rollback --

  @doc """
  Supabase `.explain(opts)` equivalent.

  Causes the query to return its EXPLAIN plan instead of rows.

  ## Options
    - `:analyze` — execute the query and show actual timing
    - `:verbose` — include query identifier and output columns
    - `:settings` — include configuration parameters affecting the plan
    - `:buffers` — include buffer usage information
    - `:wal` — include WAL record generation info
    - `:format` — `:text` (default) or `:json`
  """
  def explain(%Query{} = query, opts \\ []) do
    defaults = [analyze: false, verbose: false, settings: false, buffers: false, wal: false, format: :text]
    merged = Keyword.merge(defaults, opts)
    %{query | explain_opts: merged}
  end

  @doc """
  Supabase `.csv()` equivalent. Returns query results as a CSV string.
  """
  def csv(%Query{} = query) do
    %{query | csv: true}
  end

  @doc """
  Supabase `.geojson()` equivalent.

  Returns results as a GeoJSON FeatureCollection. Each row becomes a Feature;
  columns named `geometry`/`geom` are treated as the Feature geometry. Remaining
  columns become Feature properties.

  Requires PostgreSQL with PostGIS for true spatial output; the Ecto adapter
  converts rows to GeoJSON maps at the client level.
  """
  def geojson(%Query{} = query) do
    %{query | geojson: true}
  end

  @doc """
  Supabase `.throwOnError()` equivalent. Causes `run/1` to raise instead of
  returning `{:error, reason}`.
  """
  def throw_on_error(%Query{} = query) do
    %{query | throw_on_error: true}
  end

  @doc """
  Supabase `.rollback()` equivalent. Executes the query inside a transaction and
  rolls it back (data is not persisted, but query results are returned).
  """
  def rollback(%Query{} = query) do
    %{query | rollback: true}
  end

  @doc """
  Switch the schema for this query. Supabase `PostgrestClient.schema(name)` equivalent.

  When called on a `%Query{}`, all subsequent SQL references the given schema.
  When called on a `%Conn{}`, returns a new connection tagged with that schema
  (useful for `schema("private") |> from("users")` style).
  """
  def schema(%Query{} = query, name) when is_binary(name) do
    %{query | schema: name}
  end

  def schema(%Conn{} = conn, name) when is_binary(name) do
    fn table_name ->
      conn
      |> from(table_name)
      |> schema(name)
    end
  end

  @doc """
  Set the maximum number of rows that can be affected by an update or delete.
  Supabase `.maxAffected(n)` equivalent (PostgREST 13+).
  """
  def max_affected(%Query{} = query, n) when is_integer(n) and n >= 0 do
    %{query | max_affected: n}
  end

  # -- Raw SQL --

  @doc """
  Executes a raw SQL query and returns results as a list of maps. Parameterize with
  `$1`, `$2`, ... — placeholders are automatically adapted for SQLite.
  """
  def sql(%Conn{} = conn, sql_str, params) when is_binary(sql_str) and is_list(params) do
    repo_mod = resolve_repo(conn)
    sql_str = normalize_placeholders(sql_str, conn.adapter)
    case Ecto.Adapters.SQL.query(repo_mod, sql_str, params) do
      {:ok, %{rows: rows, columns: columns}} when is_list(rows) ->
        {:ok, Enum.map(rows, fn row -> columns |> Enum.zip(row) |> Map.new() end)}
      {:ok, _} ->
        {:ok, []}
      {:error, _} = err -> err
    end
  end

  def sql(sql_str, params \\ []) when is_binary(sql_str) do
    sql(default_conn(), sql_str, params)
  end

  @doc "Executes a raw SQL query and returns the raw driver result."
  def query(%Conn{} = conn, sql_str, params) when is_binary(sql_str) and is_list(params) do
    repo_mod = resolve_repo(conn)
    Ecto.Adapters.SQL.query(repo_mod, normalize_placeholders(sql_str, conn.adapter), params)
  end

  def query(sql_str, params \\ []) when is_binary(sql_str) do
    query(default_conn(), sql_str, params)
  end

  @doc "Executes a raw SQL query, raising on error."
  def query!(%Conn{} = conn, sql_str, params) when is_binary(sql_str) and is_list(params) do
    repo_mod = resolve_repo(conn)
    Ecto.Adapters.SQL.query!(repo_mod, normalize_placeholders(sql_str, conn.adapter), params)
  end

  def query!(sql_str, params \\ []) when is_binary(sql_str) do
    query!(default_conn(), sql_str, params)
  end

  # -- CRUD --

  @doc """
  Supabase `.insert(values, opts)` equivalent.

  ## Options
    - `:count` — count mode (`:exact`, `:planned`, `:estimated`)
    - `:default_to_null` — when `false`, missing fields use column defaults
      instead of `NULL` (PostgREST `missing=default`); default is `true`
  """
  def insert(%Query{} = query, data, opts \\ [])
      when is_map(data) or is_list(data) do
    count = opts[:count]
    default_to_null = Keyword.get(opts, :default_to_null, true)
    q = %{query | type: :insert, data: data, default_to_null: default_to_null}
    if count, do: count(q, count), else: q
  end

  @doc """
  Supabase `.update(values, opts)` equivalent.

  ## Options
    - `:count` — count mode
  """
  def update(%Query{} = query, data, opts \\ []) when is_map(data) do
    q = %{query | type: :update, data: data}
    if opts[:count], do: count(q, opts[:count]), else: q
  end

  @doc """
  Supabase `.delete(opts)` equivalent.

  ## Options
    - `:count` — count mode
  """
  def delete(%Query{} = query, opts \\ []) do
    q = %{query | type: :delete}
    if opts[:count], do: count(q, opts[:count]), else: q
  end

  @doc """
  Supabase `.upsert(values, opts)` equivalent.

  ## Options
    - `:on_conflict` — column or list of columns defining the unique constraint
    - `:ignore_duplicates` — if `true`, ignore duplicates instead of merging
      (Supabase `resolution=ignore-duplicates`)
    - `:default_to_null` — default `true`
    - `:count` — count mode
  """
  def upsert(%Query{} = query, data, opts \\ [])
      when is_map(data) or is_list(data) do
    default_to_null = Keyword.get(opts, :default_to_null, true)
    upsert_opts = [
      on_conflict: opts[:on_conflict],
      ignore_duplicates: Keyword.get(opts, :ignore_duplicates, false),
      default_to_null: default_to_null
    ]
    q = %{query | type: :upsert, data: data, upsert_opts: upsert_opts, default_to_null: default_to_null}
    if opts[:count], do: count(q, opts[:count]), else: q
  end

  # -- RPC --

  @doc """
  Supabase `.rpc(function_name, args, opts)` equivalent. Executes a stored
  procedure / function (PostgreSQL only).

  ## Options
    - `:head` — return count only (no body). Supabase `head: true`.
    - `:get` — call via GET instead of POST (read-only mode)
    - `:count` — count mode for set-returning functions
    - `:conn` — use a specific connection (otherwise uses default)
  """
  def rpc(function_name, params \\ %{}, opts \\ []) do
    conn = opts[:conn] || default_conn()
    if conn.adapter == :sqlite do
      raise "NexBase.rpc is not supported with SQLite (stored procedures are a PostgreSQL feature)"
    end

    repo_mod = resolve_repo(conn)
    head = !!opts[:head]
    count_mode = opts[:count]

    keys = Map.keys(params)
    values = Map.values(params)
    placeholders = Enum.map(1..map_size(params), fn i -> "$#{i}" end)

    # Quote function name and argument names to prevent SQL injection.
    quoted_fn = quote_ident(function_name)

    args_str =
      Enum.zip(keys, placeholders)
      |> Enum.map(fn {k, p} -> "#{quote_ident(k)} := #{p}" end)
      |> Enum.join(", ")

    sql_str = "SELECT * FROM #{quoted_fn}(#{args_str})"

    result = Ecto.Adapters.SQL.query(repo_mod, sql_str, values)

    case result do
      {:ok, %{rows: rows, columns: columns}} ->
        data =
          if head do
            nil
          else
            Enum.map(rows, fn row -> columns |> Enum.zip(row) |> Map.new() end)
          end

        if count_mode do
          {:ok, data, length(rows)}
        else
          {:ok, data}
        end
      {:error, _} = err -> err
    end
  end

  # -- Transaction --

  @doc """
  Supabase `.rpc` / transaction flow equivalent. Runs `fun` in a transaction;
  `fun` receives the connection as argument.

  ## Options
    - `:conn` — connection to use (default: default connection)
    - `:timeout` — transaction timeout in ms (default: 60_000)
  """
  def transaction(fun, opts \\ []) when is_function(fun, 0) do
    conn = Keyword.get(opts, :conn) || default_conn()
    repo_mod = resolve_repo(conn)
    timeout = Keyword.get(opts, :timeout, 60_000)
    repo_mod.transaction(fun, timeout: timeout)
  end

  # -- Execution helpers --

  @doc """
  Bang variant of `run/1`. Raises on error instead of returning `{:error, reason}`.
  """
  def run!(%Query{} = query) do
    case run(query) do
      {:ok, result} -> result
      {:ok, result, count} -> {result, count}
      {:error, error} -> raise "Query failed: #{inspect(error)}"
    end
  end

  @doc """
  Supabase `.single()` enforcement: returns exactly one row; raises if 0 or >1.
  """
  def one!(%Query{} = query) do
    query = if query.type in [:insert, :update, :delete, :upsert], do: %{query | type: :select}, else: query
    case run(%{query | limit: 2}) do
      {:ok, [row]} -> row
      {:ok, [_row, _]} -> raise "Expected exactly one row, got more"
      {:ok, []} -> raise "Expected exactly one row, got none"
      {:ok, _data, _count} -> one!(%{query | type: :select, count: nil})
      {:error, error} -> raise "Query failed: #{inspect(error)}"
    end
  end

  @doc """
  Supabase `.maybeSingle()`: returns one row or `nil`. Raises only if >1 rows.
  """
  def maybe_one(%Query{} = query) do
    query = if query.type in [:insert, :update, :delete, :upsert], do: %{query | type: :select}, else: query
    case run(%{query | limit: 2}) do
      {:ok, [row]} -> row
      {:ok, []} -> nil
      {:ok, [_, _ | _]} -> raise "Expected at most one row, got more"
      {:ok, _data, _count} -> maybe_one(%{query | type: :select, count: nil})
      {:error, error} -> raise "Query failed: #{inspect(error)}"
    end
  end

  @doc """
  Returns rows as a list (executes the query eagerly and returns them).
  """
  def stream(%Query{} = query, _opts \\ []) do
    conn = query.conn || default_conn()
    _repo_mod = resolve_repo(conn)
    query = Map.put(query, :type, :select)

    case run(query) do
      {:ok, rows} -> rows
      {:ok, rows, _count} -> rows
      {:error, error} -> raise "Query failed: #{inspect(error)}"
    end
  end

  # -- Execution (run) --

  @doc """
  Executes the built query.

  Returns:
    - `{:ok, data}` for normal select (list of maps, or single unwrapped map when
      `.single()`/`.maybe_single()` is set)
    - `{:ok, data, count}` when `.count(mode)` is set
    - `{:error, exception}` on failure
  """
  def run(query)

  def run(%Query{throw_on_error: true} = query) do
    case run(%{query | throw_on_error: false}) do
      {:ok, result} -> result
      {:ok, result, count} -> {result, count}
      {:error, error} -> raise "Query failed: #{inspect(error)}"
    end
  end

  def run(%Query{rollback: true} = query) do
    # Run inside a transaction and capture the result before rolling back.
    # We store it via the process dictionary so the rollback doesn't discard it.
    conn = query.conn || default_conn()
    repo_mod = resolve_repo(conn)
    key = {:nexbase_rollback_result, make_ref()}

    result =
      repo_mod.transaction(fn ->
        inner = run(%{query | rollback: false})
        Process.put(key, inner)
        repo_mod.rollback(:nexbase_rollback)
      end)

    case result do
      {:error, :nexbase_rollback} -> Process.delete(key) || {:ok, []}
      {:error, reason} -> {:error, reason}
    end
  end

  def run(%Query{type: :select} = query) do
    run_select(query)
  rescue
    e -> {:error, e}
  end

  def run(%Query{type: :insert, table: table, data: data, conn: conn,
                 select: select, returning: returning, count: count_mode,
                 default_to_null: default_to_null, filters: filters,
                 single: single, maybe_single: maybe_single} = _query) do
    conn = conn || default_conn()
    repo_mod = resolve_repo(conn)
    data_list = if is_list(data), do: data, else: [data]

    data_list =
      if default_to_null do
        data_list
      else
        # Remove nil fields so DB defaults apply
        Enum.map(data_list, fn row ->
          Enum.reject(row, fn {_k, v} -> is_nil(v) end) |> Map.new()
        end)
      end

    opts = build_returning_opts(returning, select)

    {count, rows} =
      if returning and conn.adapter == :sqlite do
        sqlite_insert_with_returning(repo_mod, table, data_list, select)
      else
        repo_mod.insert_all(table, data_list, opts)
      end

    build_mutation_result(count, rows, count_mode, filters)
    |> handle_single_maybe_single(single, maybe_single)
  rescue
    e -> {:error, e}
  end

  def run(%Query{type: :update, table: table, data: data, filters: filters, conn: conn,
                 select: select, returning: returning, count: count_mode,
                 or_filters: or_filters, not_filters: not_filters,
                 max_affected: max_affected, single: single, maybe_single: maybe_single} = _query) do
    conn = conn || default_conn()
    repo_mod = resolve_repo(conn)
    base_query = Ecto.Query.from(t in table)
    query_with_filters = Enum.reduce(filters, base_query, fn filter, acc ->
      apply_filter(acc, filter, conn.adapter)
    end)
    query_with_filters = Enum.reduce(not_filters, query_with_filters, fn filter, acc ->
      apply_not_filter(acc, filter, conn.adapter)
    end)
    query_with_filters = Enum.reduce(or_filters, query_with_filters, fn group, acc ->
      apply_or_filter_group(acc, group, conn.adapter)
    end)

    {count, rows} =
      cond do
        returning and conn.adapter == :sqlite ->
          {where_sql, params} = build_where_for_sqlite(filters, or_filters, not_filters)
          sqlite_update_with_returning(repo_mod, table, data, where_sql, params, select, max_affected)

        max_affected != nil and conn.adapter == :postgres ->
          # PostgreSQL doesn't support LIMIT on UPDATE/DELETE. Use raw SQL with a subquery.
          {where_sql, params} = build_where(filters, or_filters, not_filters, :postgres)
          postgres_update_with_limit(repo_mod, table, data, where_sql, params, select, max_affected, returning)

        true ->
          updates = [set: Enum.to_list(data)] ++ if returning, do: [returning: normalize_select_for_returning(select)], else: []
          repo_mod.update_all(query_with_filters, updates)
      end

    build_mutation_result(count, rows, count_mode, filters)
    |> handle_single_maybe_single(single, maybe_single)
  rescue
    e -> {:error, e}
  end

  def run(%Query{type: :delete, table: table, filters: filters, conn: conn,
                 select: select, returning: returning, count: count_mode,
                 or_filters: or_filters, not_filters: not_filters,
                 max_affected: max_affected, single: single, maybe_single: maybe_single} = _query) do
    conn = conn || default_conn()
    repo_mod = resolve_repo(conn)
    base_query = Ecto.Query.from(t in table)
    query_with_filters = Enum.reduce(filters, base_query, fn filter, acc ->
      apply_filter(acc, filter, conn.adapter)
    end)
    query_with_filters = Enum.reduce(not_filters, query_with_filters, fn filter, acc ->
      apply_not_filter(acc, filter, conn.adapter)
    end)
    query_with_filters = Enum.reduce(or_filters, query_with_filters, fn group, acc ->
      apply_or_filter_group(acc, group, conn.adapter)
    end)

    {count, rows} =
      cond do
        returning and conn.adapter == :sqlite ->
          {where_sql, params} = build_where_for_sqlite(filters, or_filters, not_filters)
          sqlite_delete_with_returning(repo_mod, table, where_sql, params, select, max_affected)

        max_affected != nil and conn.adapter == :postgres ->
          {where_sql, params} = build_where(filters, or_filters, not_filters, :postgres)
          postgres_delete_with_limit(repo_mod, table, where_sql, params, select, max_affected, returning)

        true ->
          opts = if returning, do: [returning: normalize_select_for_returning(select)], else: []
          repo_mod.delete_all(query_with_filters, opts)
      end

    build_mutation_result(count, rows, count_mode, filters)
    |> handle_single_maybe_single(single, maybe_single)
  rescue
    e -> {:error, e}
  end

  def run(%Query{type: :upsert, table: table, data: data, conn: conn,
                 select: select, returning: returning, count: count_mode,
                 upsert_opts: upsert_opts, filters: filters,
                 single: single, maybe_single: maybe_single} = _query) do
    conn = conn || default_conn()
    repo_mod = resolve_repo(conn)
    data_list = if is_list(data), do: data, else: [data]

    on_conflict = if upsert_opts[:ignore_duplicates], do: :nothing, else: :replace_all

    default_to_null = Keyword.get(upsert_opts, :default_to_null, true)
    data_list =
      if default_to_null do
        data_list
      else
        Enum.map(data_list, fn row ->
          Enum.reject(row, fn {_k, v} -> is_nil(v) end) |> Map.new()
        end)
      end

    opts =
      if upsert_opts[:on_conflict] do
        [
          on_conflict: on_conflict,
          conflict_target: upsert_opts[:on_conflict]
        ] ++ build_returning_opts(returning, select)
      else
        [on_conflict: on_conflict] ++ build_returning_opts(returning, select)
      end

    {count, rows} =
      if conn.adapter == :sqlite do
        # SQLite ecto adapter does not support schema-less insert_all with
        # :replace_all on_conflict. Always use raw SQL with RETURNING.
        sqlite_upsert_with_returning(repo_mod, table, data_list, on_conflict, upsert_opts[:on_conflict], select)
      else
        repo_mod.insert_all(table, data_list, opts)
      end

    build_mutation_result(count, rows, count_mode, filters)
    |> handle_single_maybe_single(single, maybe_single)
  rescue
    e -> {:error, e}
  end

  # SQLite ecto adapter does not support schema-less insert_all/update_all/delete_all
  # with the `:returning` option. We fall back to raw SQL with RETURNING clause
  # (SQLite 3.35+ supports RETURNING natively).

  defp sqlite_insert_with_returning(repo_mod, table, data_list, select) do
    if Enum.empty?(data_list) do
      {0, nil}
    else
      # Union of all column keys across all rows (matches Supabase behavior).
      column_keys =
        data_list
        |> Enum.flat_map(&Map.keys/1)
        |> Enum.uniq()
      columns = Enum.map(column_keys, &to_string/1)
      returning_cols = sqlite_returning_cols(select)
      returning_column_names =
        if select == [] do
          sqlite_table_columns(repo_mod, table)
        else
          Enum.map(select, fn
            col when is_atom(col) -> col
            col when is_binary(col) ->
              case String.split(col, " AS ", parts: 2) do
                [_c, alias_name] -> String.to_atom(String.trim(alias_name))
                [c] -> String.to_atom(String.trim(c))
              end
          end)
        end

      placeholders_per_row =
        Enum.map(columns, fn _ -> "?" end) |> Enum.join(", ")

      values_sql =
        Enum.map(data_list, fn _row -> "(#{placeholders_per_row})" end) |> Enum.join(", ")

      params =
        Enum.flat_map(data_list, fn row ->
          Enum.map(column_keys, fn k -> Map.get(row, k) end)
        end)

      sql = """
      INSERT INTO #{quote_ident(table)} (#{Enum.map(columns, &quote_ident/1) |> Enum.join(", ")})
      VALUES #{values_sql}
      RETURNING #{returning_cols}
      """

      result = Ecto.Adapters.SQL.query!(repo_mod, sql, params)
      rows = sqlite_rows_to_maps(result, returning_column_names)
      {length(rows), rows}
    end
  end

  defp sqlite_update_with_returning(repo_mod, table, data, where_sql, params, select, max_affected) do
    set_clause =
      data
      |> Enum.to_list()
      |> Enum.map(fn {k, _v} -> "#{quote_ident(k)} = ?" end)
      |> Enum.join(", ")

    data_values = data |> Enum.to_list() |> Enum.map(&elem(&1, 1))
    returning_cols = sqlite_returning_cols(select)
    returning_column_names =
      if select == [] do
        sqlite_table_columns(repo_mod, table)
      else
        Enum.map(select, &sqlite_select_col_name/1)
      end
    limit_sql = if max_affected, do: " LIMIT #{max_affected}", else: ""

    sql = """
    UPDATE #{quote_ident(table)} SET #{set_clause}
    #{where_sql}
    #{limit_sql}
    RETURNING #{returning_cols}
    """

    result = Ecto.Adapters.SQL.query!(repo_mod, sql, data_values ++ params)
    rows = sqlite_rows_to_maps(result, returning_column_names)
    {length(rows), rows}
  end

  defp sqlite_delete_with_returning(repo_mod, table, where_sql, params, select, max_affected) do
    returning_cols = sqlite_returning_cols(select)
    returning_column_names =
      if select == [] do
        sqlite_table_columns(repo_mod, table)
      else
        Enum.map(select, &sqlite_select_col_name/1)
      end
    limit_sql = if max_affected, do: " LIMIT #{max_affected}", else: ""

    sql = """
    DELETE FROM #{quote_ident(table)}
    #{where_sql}
    #{limit_sql}
    RETURNING #{returning_cols}
    """

    result = Ecto.Adapters.SQL.query!(repo_mod, sql, params)
    rows = sqlite_rows_to_maps(result, returning_column_names)
    {length(rows), rows}
  end

  defp sqlite_upsert_with_returning(repo_mod, table, data_list, on_conflict, conflict_target, select) do
    if Enum.empty?(data_list) do
      {0, nil}
    else
      # Union of all column keys across all rows (matches Supabase behavior).
      column_keys =
        data_list
        |> Enum.flat_map(&Map.keys/1)
        |> Enum.uniq()
      columns = Enum.map(column_keys, &to_string/1)
      col_refs = Enum.map(columns, &quote_ident/1) |> Enum.join(", ")
      placeholders_per_row = Enum.map(columns, fn _ -> "?" end) |> Enum.join(", ")
      values_sql = Enum.map(data_list, fn _ -> "(#{placeholders_per_row})" end) |> Enum.join(", ")

      params =
        Enum.flat_map(data_list, fn row ->
          Enum.map(column_keys, fn k -> Map.get(row, k) end)
        end)

      conflict_cols =
        case conflict_target do
          nil -> columns  # No explicit target — assume all columns or let DB infer
          col when is_atom(col) or is_binary(col) -> [to_string(col)]
          cols when is_list(cols) -> Enum.map(cols, &to_string/1)
          _ -> columns
        end

      conflict_ref = Enum.map(conflict_cols, &quote_ident/1) |> Enum.join(", ")

      on_conflict_sql =
        case on_conflict do
          :nothing -> "ON CONFLICT (#{conflict_ref}) DO NOTHING"
          _ ->
            updates =
              columns
              |> Enum.reject(&(&1 in conflict_cols))
              |> Enum.map(fn c -> "#{quote_ident(c)} = excluded.#{quote_ident(c)}" end)
              |> Enum.join(", ")
            if updates == "" do
              "ON CONFLICT (#{conflict_ref}) DO NOTHING"
            else
              "ON CONFLICT (#{conflict_ref}) DO UPDATE SET #{updates}"
            end
        end

      returning_cols = sqlite_returning_cols(select)
      returning_column_names =
        if select == [] do
          sqlite_table_columns(repo_mod, table)
        else
          Enum.map(select, &sqlite_select_col_name/1)
        end

      sql = """
      INSERT INTO #{quote_ident(table)} (#{col_refs})
      VALUES #{values_sql}
      #{on_conflict_sql}
      RETURNING #{returning_cols}
      """

      result = Ecto.Adapters.SQL.query!(repo_mod, sql, params)
      rows = sqlite_rows_to_maps(result, returning_column_names)
      {length(rows), rows}
    end
  end

  defp sqlite_returning_cols([]), do: "*"
  defp sqlite_returning_cols(select) do
    Enum.map(select, fn
      col when is_atom(col) -> ~s("#{col}")
      col when is_binary(col) ->
        case String.split(col, " AS ", parts: 2) do
          [c, alias_name] -> ~s("#{String.trim(c)}" AS "#{String.trim(alias_name)}")
          [c] -> ~s("#{String.trim(c)}")
        end
    end) |> Enum.join(", ")
  end

  defp sqlite_select_col_name(col) when is_atom(col), do: col
  defp sqlite_select_col_name(col) when is_binary(col) do
    case String.split(col, " AS ", parts: 2) do
      [_c, alias_name] -> String.to_atom(String.trim(alias_name))
      [c] -> String.to_atom(String.trim(c))
    end
  end

  defp sqlite_table_columns(repo_mod, table) do
    case Ecto.Adapters.SQL.query(repo_mod, "PRAGMA table_info(#{quote_ident(table)})", []) do
      {:ok, %{rows: rows}} ->
        Enum.map(rows, fn [_cid, name, _type, _notnull, _dflt, _pk] -> String.to_atom(name) end)
      _ ->
        []
    end
  end

  defp sqlite_rows_to_maps(result, fallback_cols) do
    cols =
      case result.columns do
        [] -> fallback_cols
        cs -> Enum.map(cs, &String.to_atom/1)
      end
    Enum.map(result.rows, fn row ->
      Enum.zip(cols, row) |> Map.new()
    end)
  end

  # PostgreSQL UPDATE/DELETE with row limit via ctid subquery (since Postgres doesn't
  # support LIMIT on UPDATE/DELETE directly). Uses the table's system ctid column.
  defp postgres_update_with_limit(repo_mod, table, data, where_sql, params, select, limit, returning) do
    set_clause =
      data
      |> Enum.to_list()
      |> Enum.with_index(1)
      |> Enum.map(fn {{k, _v}, i} -> "#{quote_ident(k)} = $#{i}" end)
      |> Enum.join(", ")

    data_values = data |> Enum.to_list() |> Enum.map(&elem(&1, 1))
    params_offset = length(data_values)

    # Build WHERE ... LIMIT n via ctid self-join
    table_ident = quote_ident(table)
    returning_cols = if select == [], do: "*", else: Enum.map_join(select, ", ", &quote_select_field/1)
    returning_sql = if returning, do: " RETURNING #{returning_cols}", else: ""
    _returning_column_names =
      if select == [] do
        ["*"]  # Postgres populates columns properly
      else
        Enum.map(select, &sqlite_select_col_name/1)
      end

    # Re-number placeholders in where_sql: the $1..$N in where_sql need to shift past the SET params
    shifted_where_sql = shift_placeholders(where_sql, params_offset)
    all_params = data_values ++ params

    sql = """
    UPDATE #{table_ident} SET #{set_clause}
    WHERE ctid IN (
      SELECT ctid FROM #{table_ident}
      #{shifted_where_sql != "" && "WHERE " || ""}#{shifted_where_sql}
      LIMIT #{limit}
    )
    #{returning_sql}
    """

    result = Ecto.Adapters.SQL.query!(repo_mod, sql, all_params)
    rows =
      if returning_sql != "" do
        Enum.map(result.rows, fn row ->
          cols = Enum.map(result.columns, &String.to_atom/1)
          Enum.zip(cols, row) |> Map.new()
        end)
      else
        nil
      end
    {length(rows || []), rows}
  end

  defp postgres_delete_with_limit(repo_mod, table, where_sql, params, select, limit, returning) do
    table_ident = quote_ident(table)
    returning_cols = if select == [], do: "*", else: Enum.map_join(select, ", ", &quote_select_field/1)
    returning_sql = if returning, do: " RETURNING #{returning_cols}", else: ""

    sql = """
    DELETE FROM #{table_ident}
    WHERE ctid IN (
      SELECT ctid FROM #{table_ident}
      #{where_sql != "" && "WHERE " || ""}#{where_sql}
      LIMIT #{limit}
    )
    #{returning_sql}
    """

    result = Ecto.Adapters.SQL.query!(repo_mod, sql, params)
    rows =
      if returning_sql != "" do
        Enum.map(result.rows, fn row ->
          cols = Enum.map(result.columns, &String.to_atom/1)
          Enum.zip(cols, row) |> Map.new()
        end)
      else
        nil
      end
    {length(rows || []), rows}
  end

  # Shift $N placeholders in a SQL string by `offset` (e.g. $1 → $4 if offset=3).
  defp shift_placeholders(sql, 0), do: sql
  defp shift_placeholders(sql, offset) do
    Regex.replace(~r/\$(\d+)/, sql, fn _, n ->
      "$#{String.to_integer(n) + offset}"
    end)
  end

  # Convert "$1", "$2" placeholders to "?" for SQLite raw queries
  defp sqlite_placeholders(sql), do: Regex.replace(~r/\$\d+/, sql, "?")

  defp build_where_for_sqlite(filters, or_filters, not_filters) do
    {sql, params} = build_where(filters, or_filters, not_filters, :sqlite)
    {sqlite_placeholders(sql), params}
  end

  defp build_returning_opts(false, _select), do: []
  defp build_returning_opts(true, select) do
    fields = normalize_select_for_returning(select)
    [returning: fields]
  end

  defp normalize_select_for_returning([]), do: true
  defp normalize_select_for_returning(select) do
    Enum.map(select, fn
      col when is_atom(col) -> col
      col when is_binary(col) ->
        # strip " AS alias" part if present
        col |> String.split(" AS ", parts: 2) |> hd() |> String.trim() |> String.to_atom()
    end)
  end

  defp build_mutation_result(count, rows, nil, _filters) do
    case rows do
      nil -> {:ok, %{count: count}}
      [] -> {:ok, %{count: count}}
      rows when is_list(rows) ->
        row_maps = Enum.map(rows, &normalize_row/1)
        {:ok, %{count: count, data: row_maps}}
    end
  end

  defp build_mutation_result(count, rows, mode, _filters) when mode in [:exact, :planned, :estimated] do
    case rows do
      nil -> {:ok, %{count: count}, count}
      [] -> {:ok, %{count: count}, count}
      rows when is_list(rows) ->
        row_maps = Enum.map(rows, &normalize_row/1)
        {:ok, %{count: count, data: row_maps}, count}
    end
  end

  defp normalize_row(%_{} = struct_row), do: Map.from_struct(struct_row)
  defp normalize_row(row) when is_map(row), do: row

  # -- Internal Helpers --

  defp resolve_repo(%Conn{repo_module: repo_mod, name: name}) do
    if name != repo_mod do
      repo_mod.put_dynamic_repo(name)
    end
    repo_mod
  end

  defp run_select(%Query{
         table: table,
         schema: schema,
         select: select_fields,
         filters: filters,
         or_filters: or_filters,
         not_filters: not_filters,
         limit: limit,
         offset: offset,
         order_by: order_by,
         count: count_mode,
         conn: conn,
         single: single,
         maybe_single: maybe_single,
         explain_opts: explain_opts,
         csv: csv,
         geojson: geojson,
         head: head
       }) do
    conn = conn || default_conn()
    repo_mod = resolve_repo(conn)

    columns_sql =
      cond do
        head -> "NULL"
        explain_opts -> "1"
        true ->
          if select_fields == [] or select_fields == ["*"] or select_fields == nil do
            "*"
          else
            Enum.map_join(select_fields, ", ", &quote_select_field/1)
          end
      end

    table_sql = if schema, do: "#{quote_ident(schema)}.#{quote_ident(table)}", else: quote_ident(table)

    {where_clause, params} = build_where(filters, or_filters, not_filters, conn.adapter)
    order_clause = build_order(order_by)
    limit_clause = if limit && not head, do: " LIMIT #{limit}", else: ""
    offset_clause = if offset && not head, do: " OFFSET #{offset}", else: ""

    sql_prefix =
      cond do
        explain_opts ->
          format = Keyword.get(explain_opts, :format, :text)
          opts = [
            if(explain_opts[:analyze], do: "ANALYZE"),
            if(explain_opts[:verbose], do: "VERBOSE"),
            if(explain_opts[:settings], do: "SETTINGS"),
            if(explain_opts[:buffers], do: "BUFFERS"),
            if(explain_opts[:wal], do: "WAL"),
            if(format == :json, do: "FORMAT JSON")
          ] |> Enum.reject(&is_nil/1)

          "EXPLAIN (#{Enum.join(opts, ", ")}) "
        true -> ""
      end

    sql_str = "#{sql_prefix}SELECT #{columns_sql} FROM #{table_sql}#{where_clause}#{order_clause}#{limit_clause}#{offset_clause}"
    sql_str = normalize_placeholders(sql_str, conn.adapter)

    case Ecto.Adapters.SQL.query(repo_mod, sql_str, params) do
      {:ok, %{rows: rows, columns: cols}} ->
        cond do
          csv ->
            csv_str = rows_to_csv(cols, rows)
            {:ok, csv_str}
          geojson ->
            {:ok, rows_to_geojson(cols, rows)}
          explain_opts && Keyword.get(explain_opts, :format) == :json ->
            {:ok, hd(hd(rows))}
          explain_opts ->
            text = rows |> Enum.map(fn [line] -> line end) |> Enum.join("\n")
            {:ok, text}
          head ->
            result = {:ok, []}
            maybe_attach_count(result, table, filters, or_filters, not_filters, count_mode, schema, conn, repo_mod)
          true ->
            data = Enum.map(rows, fn row -> cols |> Enum.zip(row) |> Map.new() end)
            result = {:ok, data}
            maybe_attach_count(result, table, filters, or_filters, not_filters, count_mode, schema, conn, repo_mod)
            |> handle_single_maybe_single(single, maybe_single)
        end

      {:error, _} = err ->
        err
    end
  end

  defp rows_to_csv(cols, rows) do
    header = Enum.map_join(cols, ",", &csv_escape/1)
    body =
      rows
      |> Enum.map(fn row ->
        row |> Enum.map(&csv_escape/1) |> Enum.join(",")
      end)
      |> Enum.join("\n")

    if body == "", do: header, else: header <> "\n" <> body
  end

  defp csv_escape(nil), do: ""
  defp csv_escape(val) when is_binary(val) do
    if String.contains?(val, [",", "\"", "\n", "\r"]) do
      "\"" <> String.replace(val, "\"", "\"\"") <> "\""
    else
      val
    end
  end
  defp csv_escape(val), do: to_string(val)

  defp rows_to_geojson(cols, rows) do
    col_atoms = Enum.map(cols, &String.to_atom/1)
    geom_idx = Enum.find_index(col_atoms, &(&1 in [:geometry, :geom, :geom_geojson]))
    geom_key = if geom_idx, do: Enum.at(col_atoms, geom_idx), else: nil

    features =
      Enum.map(rows, fn row ->
        geom = if geom_idx, do: Enum.at(row, geom_idx), else: nil
        geom = if is_binary(geom), do: Jason.decode!(geom), else: geom

        props =
          col_atoms
          |> Enum.zip(row)
          |> Enum.reject(fn {k, _v} -> k == geom_key end)
          |> Enum.into(%{})

        %{
          "type" => "Feature",
          "geometry" => geom,
          "properties" => props
        }
      end)

    %{
      "type" => "FeatureCollection",
      "features" => features
    }
  end

  defp handle_single_maybe_single({:ok, %{count: c, data: rows}}, true, _maybe) do
    case rows do
      [row] -> {:ok, row}
      [] -> {:error, %RuntimeError{message: "JSON object requested, no rows returned"}}
      [_ | _] -> {:error, %RuntimeError{message: "JSON object requested, multiple rows returned"}}
      _other -> {:ok, %{count: c, data: rows}}
    end
  end

  defp handle_single_maybe_single({:ok, %{count: c, data: rows}}, _s, true) do
    case rows do
      [row] -> {:ok, row}
      [] -> {:ok, nil}
      [_, _ | _] -> {:error, %RuntimeError{message: "JSON object requested, multiple rows returned"}}
      _other -> {:ok, %{count: c, data: rows}}
    end
  end

  defp handle_single_maybe_single({:ok, %{count: c, data: rows}, total}, true, _) do
    case rows do
      [row] -> {:ok, row, total}
      [] -> {:error, %RuntimeError{message: "JSON object requested, no rows returned"}}
      [_ | _] -> {:error, %RuntimeError{message: "JSON object requested, multiple rows returned"}}
      _other -> {:ok, %{count: c, data: rows}, total}
    end
  end

  defp handle_single_maybe_single({:ok, %{count: c, data: rows}, total}, _s, true) do
    case rows do
      [row] -> {:ok, row, total}
      [] -> {:ok, nil, total}
      [_, _ | _] -> {:error, %RuntimeError{message: "JSON object requested, multiple rows returned"}}
      _other -> {:ok, %{count: c, data: rows}, total}
    end
  end

  defp handle_single_maybe_single({:ok, data}, true, _maybe) do
    case data do
      [row] -> {:ok, row}
      [] -> {:error, %RuntimeError{message: "JSON object requested, no rows returned"}}
      [_ | _] -> {:error, %RuntimeError{message: "JSON object requested, multiple rows returned"}}
      _other -> {:ok, data}
    end
  end

  defp handle_single_maybe_single({:ok, data}, _s, true) do
    case data do
      [row] -> {:ok, row}
      [] -> {:ok, nil}
      [_, _ | _] -> {:error, %RuntimeError{message: "JSON object requested, multiple rows returned"}}
      _other -> {:ok, data}
    end
  end

  defp handle_single_maybe_single({:ok, data, count}, true, _) do
    case data do
      [row] -> {:ok, row, count}
      [] -> {:error, %RuntimeError{message: "JSON object requested, no rows returned"}}
      [_ | _] -> {:error, %RuntimeError{message: "JSON object requested, multiple rows returned"}}
      _other -> {:ok, data, count}
    end
  end

  defp handle_single_maybe_single({:ok, data, count}, _s, true) do
    case data do
      [row] -> {:ok, row, count}
      [] -> {:ok, nil, count}
      [_, _ | _] -> {:error, %RuntimeError{message: "JSON object requested, multiple rows returned"}}
      _other -> {:ok, data, count}
    end
  end

  defp handle_single_maybe_single(result, _, _), do: result

  defp maybe_attach_count({:ok, data}, _table, _filters, _or_filters, _not_filters, nil, _schema, _conn, _repo_mod) do
    {:ok, data}
  end

  defp maybe_attach_count({:ok, data}, table, filters, or_filters, not_filters, mode, schema, conn, repo_mod) do
    {where_clause, params} = build_where(filters, or_filters, not_filters, conn.adapter)
    table_sql = if schema, do: "#{quote_ident(schema)}.#{quote_ident(table)}", else: quote_ident(table)

    count_sql =
      case mode do
        :exact -> "SELECT COUNT(*) FROM #{table_sql}#{where_clause}"
        :planned -> "SELECT reltuples::bigint FROM pg_class WHERE relname = $1"
        :estimated -> "EXPLAIN SELECT * FROM #{table_sql}#{where_clause}"
      end

    count_sql = normalize_placeholders(count_sql, conn.adapter)

    count_params = if mode == :planned, do: [table], else: params

    total =
      case Ecto.Adapters.SQL.query(repo_mod, count_sql, count_params) do
        {:ok, %{rows: [[count]]}} when is_integer(count) or is_number(count) -> trunc(count)
        {:ok, %{rows: [[count_str]]}} when is_binary(count_str) ->
          case Integer.parse(count_str) do
            {n, _} -> n
            _ -> length(data)
          end
        {:ok, %{rows: rows}} when is_list(rows) and mode == :estimated ->
          extract_estimated_rows(rows)
        _ -> length(data)
      end

    {:ok, data, total}
  end

  defp extract_estimated_rows(rows) do
    rows
    |> Enum.map(fn [line] -> to_string(line) end)
    |> Enum.find_value(0, fn line ->
      case Regex.run(~r/rows=(\d+)/, line) do
        [_, n] -> String.to_integer(n)
        _ -> nil
      end
    end)
  end

  # -- WHERE --

  defp build_where([], [], [], _adapter), do: {"", []}

  defp build_where(filters, or_filters, not_filters, adapter) do
    {and_clauses, params, idx} =
      Enum.reduce(filters, {[], [], 1}, fn filter, {clauses, params, idx} ->
        {clause, new_params, next_idx} = filter_to_sql(filter, idx, adapter)
        {clauses ++ [clause], params ++ new_params, next_idx}
      end)

    {not_clauses, params, idx} =
      Enum.reduce(not_filters, {and_clauses, params, idx}, fn filter, {clauses, params, idx} ->
        {clause, new_params, next_idx} = filter_to_sql(filter, idx, adapter)
        {clauses ++ ["NOT (#{clause})"], params ++ new_params, next_idx}
      end)

    {or_groups, params, _idx} =
      Enum.reduce(or_filters, {not_clauses, params, idx}, fn
        {group, referenced_table: _ref_table}, {clauses, params, idx} ->
          # PostgREST supports ${referencedTable}.or but in raw SQL we just filter the main table
          {group_clauses, group_params, next_idx} =
            Enum.reduce(group, {[], params, idx}, fn filter, {gcs, ps, i} ->
              {clause, new_ps, ni} = filter_to_sql(filter, i, adapter)
              {gcs ++ [clause], ps ++ new_ps, ni}
            end)
          or_sql = "(#{Enum.join(group_clauses, " OR ")})"
          {clauses ++ [or_sql], group_params, next_idx}
        group, {clauses, params, idx} ->
          {group_clauses, group_params, next_idx} =
            Enum.reduce(group, {[], params, idx}, fn filter, {gcs, ps, i} ->
              {clause, new_ps, ni} = filter_to_sql(filter, i, adapter)
              {gcs ++ [clause], ps ++ new_ps, ni}
            end)
          or_sql = "(#{Enum.join(group_clauses, " OR ")})"
          {clauses ++ [or_sql], group_params, next_idx}
      end)

    {" WHERE " <> Enum.join(or_groups, " AND "), params}
  end

  # -- filter_to_sql --

  defp filter_to_sql({:eq, col, val}, idx, _),   do: {"#{quote_ident(col)} = $#{idx}", [val], idx + 1}
  defp filter_to_sql({:neq, col, val}, idx, _),  do: {"#{quote_ident(col)} != $#{idx}", [val], idx + 1}
  defp filter_to_sql({:gt, col, val}, idx, _),   do: {"#{quote_ident(col)} > $#{idx}", [val], idx + 1}
  defp filter_to_sql({:lt, col, val}, idx, _),   do: {"#{quote_ident(col)} < $#{idx}", [val], idx + 1}
  defp filter_to_sql({:gte, col, val}, idx, _),  do: {"#{quote_ident(col)} >= $#{idx}", [val], idx + 1}
  defp filter_to_sql({:lte, col, val}, idx, _),  do: {"#{quote_ident(col)} <= $#{idx}", [val], idx + 1}
  defp filter_to_sql({:like, col, val}, idx, _),  do: {"#{quote_ident(col)} LIKE $#{idx}", [val], idx + 1}
  defp filter_to_sql({:nlike, col, val}, idx, _), do: {"#{quote_ident(col)} NOT LIKE $#{idx}", [val], idx + 1}
  defp filter_to_sql({:ilike, col, val}, idx, :sqlite), do: {"#{quote_ident(col)} LIKE $#{idx}", [val], idx + 1}
  defp filter_to_sql({:ilike, col, val}, idx, _), do: {"#{quote_ident(col)} ILIKE $#{idx}", [val], idx + 1}
  defp filter_to_sql({:nilike, col, val}, idx, :sqlite), do: {"#{quote_ident(col)} NOT LIKE $#{idx}", [val], idx + 1}
  defp filter_to_sql({:nilike, col, val}, idx, _), do: {"#{quote_ident(col)} NOT ILIKE $#{idx}", [val], idx + 1}
  defp filter_to_sql({:is, col, val}, idx, _) do
    cond do
      is_nil(val) or val == :null -> {"#{quote_ident(col)} IS NULL", [], idx}
      val == true -> {"#{quote_ident(col)} IS TRUE", [], idx}
      val == false -> {"#{quote_ident(col)} IS FALSE", [], idx}
      val == :unknown -> {"#{quote_ident(col)} IS UNKNOWN", [], idx}
      true -> {"#{quote_ident(col)} = $#{idx}", [val], idx + 1}
    end
  end
  defp filter_to_sql({:in, col, values}, idx, _) do
    placeholders = Enum.map_join(0..(length(values) - 1), ", ", fn i -> "$#{idx + i}" end)
    {"#{quote_ident(col)} IN (#{placeholders})", values, idx + length(values)}
  end

  # Full text search — parameterize the config value to avoid SQL injection.
  defp filter_to_sql({:fts, {col, _config}, query_text}, idx, :sqlite) do
    {"#{quote_ident(col)} LIKE $#{idx}", ["%#{query_text}%"], idx + 1}
  end
  defp filter_to_sql({:fts, {col, config}, query_text}, idx, _) do
    {"to_tsvector($#{idx}::regconfig, #{quote_ident(col)}) @@ plainto_tsquery($#{idx}::regconfig, $#{idx + 1})",
      [config, query_text], idx + 2}
  end
  defp filter_to_sql({:plfts, {col, _config}, query_text}, idx, :sqlite) do
    {"#{quote_ident(col)} LIKE $#{idx}", ["%#{query_text}%"], idx + 1}
  end
  defp filter_to_sql({:plfts, {col, config}, query_text}, idx, _) do
    {"to_tsvector($#{idx}::regconfig, #{quote_ident(col)}) @@ plainto_tsquery($#{idx}::regconfig, $#{idx + 1})",
      [config, query_text], idx + 2}
  end
  defp filter_to_sql({:phfts, {col, _config}, query_text}, idx, :sqlite) do
    {"#{quote_ident(col)} LIKE $#{idx}", ["%#{query_text}%"], idx + 1}
  end
  defp filter_to_sql({:phfts, {col, config}, query_text}, idx, _) do
    {"to_tsvector($#{idx}::regconfig, #{quote_ident(col)}) @@ phraseto_tsquery($#{idx}::regconfig, $#{idx + 1})",
      [config, query_text], idx + 2}
  end
  defp filter_to_sql({:wfts, {col, _config}, query_text}, idx, :sqlite) do
    {"#{quote_ident(col)} LIKE $#{idx}", ["%#{query_text}%"], idx + 1}
  end
  defp filter_to_sql({:wfts, {col, config}, query_text}, idx, _) do
    {"to_tsvector($#{idx}::regconfig, #{quote_ident(col)}) @@ websearch_to_tsquery($#{idx}::regconfig, $#{idx + 1})",
      [config, query_text], idx + 2}
  end

  # Range / array operators
  defp filter_to_sql({:cs, col, values}, idx, :sqlite) do
    {placeholders, params, next_idx} =
      Enum.reduce(values, {[], [], idx}, fn v, {phs, ps, i} ->
        {phs ++ ["#{quote_ident(col)} LIKE $#{i}"], ps ++ ["%#{inspect(v)}%"], i + 1}
      end)
    {"(" <> Enum.join(placeholders, " AND ") <> ")", params, next_idx}
  end
  defp filter_to_sql({:cs, col, values}, idx, _) do
    {"#{quote_ident(col)} @> $#{idx}", [values], idx + 1}
  end
  defp filter_to_sql({:cd, col, values}, idx, :sqlite) do
    {"#{quote_ident(col)} = $#{idx}", [values], idx + 1}
  end
  defp filter_to_sql({:cd, col, values}, idx, _) do
    {"#{quote_ident(col)} <@ $#{idx}", [values], idx + 1}
  end
  defp filter_to_sql({:ov, col, values}, idx, :sqlite) do
    {"#{quote_ident(col)} = $#{idx}", [values], idx + 1}
  end
  defp filter_to_sql({:ov, col, values}, idx, _) do
    {"#{quote_ident(col)} && $#{idx}", [values], idx + 1}
  end
  defp filter_to_sql({:sl, col, value}, idx, _) do
    {"#{quote_ident(col)} << $#{idx}", [value], idx + 1}
  end
  defp filter_to_sql({:sr, col, value}, idx, _) do
    {"#{quote_ident(col)} >> $#{idx}", [value], idx + 1}
  end
  defp filter_to_sql({:nxr, col, value}, idx, _) do
    {"#{quote_ident(col)} &> $#{idx}", [value], idx + 1}
  end
  defp filter_to_sql({:nxl, col, value}, idx, _) do
    {"#{quote_ident(col)} &< $#{idx}", [value], idx + 1}
  end
  defp filter_to_sql({:adj, col, value}, idx, _) do
    {"#{quote_ident(col)} -|- $#{idx}", [value], idx + 1}
  end

  # Fallback
  defp filter_to_sql({op, col, val}, idx, _) do
    {"#{quote_ident(col)} #{Atom.to_string(op)} $#{idx}", [val], idx + 1}
  end

  # -- ORDER --

  defp normalize_direction(dir) do
    case Atom.to_string(dir) |> String.downcase() do
      "desc" -> "DESC"
      "descending" -> "DESC"
      "dsc" -> "DESC"
      _ -> "ASC"
    end
  end

  defp build_order([]), do: ""
  defp build_order(order_by) do
    clauses =
      Enum.map(order_by, fn entry ->
        {actual, _ref_opts} = case entry do
          {clause, referenced_table: _rt} -> {clause, true}
          clause -> {clause, false}
        end

        case actual do
          {dir, col} ->
            direction = normalize_direction(dir)
            "#{quote_ident(col)} #{direction}"

          {dir, col, opts} ->
            direction = normalize_direction(dir)
            base = "#{quote_ident(col)} #{direction}"

            cond do
              Keyword.has_key?(opts, :nulls_first) ->
                if opts[:nulls_first], do: "#{base} NULLS FIRST", else: "#{base} NULLS LAST"
              opts[:nulls_last] -> "#{base} NULLS LAST"
              true -> base
            end
        end
      end)

    " ORDER BY " <> Enum.join(clauses, ", ")
  end

  defp normalize_placeholders(sql, :sqlite), do: Regex.replace(~r/\$\d+/, sql, "?")
  defp normalize_placeholders(sql, _), do: sql

  # Quote SQL identifiers safely (table names, column names, schema names).
  # Follows PostgreSQL/SQLite double-quote rules: quote ", escape embedded " as "".
  defp quote_ident(ident) when is_atom(ident), do: quote_ident(Atom.to_string(ident))
  defp quote_ident(ident) when is_binary(ident) do
    escaped = String.replace(ident, "\"", "\"\"")
    "\"#{escaped}\""
  end

  # Quote a single select field, which may be in "column AS alias" form or a raw atom.
  defp quote_select_field(field) when is_atom(field), do: quote_ident(field)
  defp quote_select_field(field) when is_binary(field) do
    case String.split(field, " AS ", parts: 2) do
      [col, alias_name] ->
        "#{quote_ident(String.trim(col))} AS #{quote_ident(String.trim(alias_name))}"
      [_] ->
        # Could be a raw expression like "count(*)" — if it contains special chars, pass through.
        # Otherwise quote as identifier.
        if String.match?(field, ~r/^[A-Za-z_][A-Za-z0-9_\.]*$/) do
          quote_ident(field)
        else
          field
        end
    end
  end

  # -- Operator normalization (aliases) --

  defp normalize_operator(op) do
    case op do
      :equals -> :eq
      :not_equals -> :neq
      :greater_than -> :gt
      :greater_than_or_equal -> :gte
      :less_than -> :lt
      :less_than_or_equal -> :lte
      :in_list -> :in
      :is_null -> :is
      :not_like -> :nlike
      :not_ilike -> :nilike
      :contains -> :cs
      :contained_in -> :cd
      :containedBy -> :cd
      :overlaps -> :ov
      :strictly_left -> :sl
      :strictly_right -> :sr
      :not_extend_right -> :nxr
      :not_extend_left -> :nxl
      :adjacent -> :adj
      :text_search -> :fts
      :full_text_search -> :fts
      :phrase_full_text_search -> :phfts
      :plain_full_text_search -> :plfts
      :web_search -> :wfts
      other -> other
    end
  end

  # -- Ecto filter application (for update/delete) --

  defp apply_filter(query, {:eq, col, val}, _) do
    Ecto.Query.where(query, [t], field(t, ^col) == ^val)
  end
  defp apply_filter(query, {:neq, col, val}, _) do
    Ecto.Query.where(query, [t], field(t, ^col) != ^val)
  end
  defp apply_filter(query, {:gt, col, val}, _) do
    Ecto.Query.where(query, [t], field(t, ^col) > ^val)
  end
  defp apply_filter(query, {:lt, col, val}, _) do
    Ecto.Query.where(query, [t], field(t, ^col) < ^val)
  end
  defp apply_filter(query, {:like, col, pattern}, _) do
    Ecto.Query.where(query, [t], like(field(t, ^col), ^pattern))
  end
  defp apply_filter(query, {:nlike, col, pattern}, _) do
    Ecto.Query.where(query, [t], not like(field(t, ^col), ^pattern))
  end
  defp apply_filter(query, {:ilike, col, pattern}, :sqlite) do
    Ecto.Query.where(query, [t], like(field(t, ^col), ^pattern))
  end
  defp apply_filter(query, {:ilike, col, pattern}, _) do
    Ecto.Query.where(query, [t], ilike(field(t, ^col), ^pattern))
  end
  defp apply_filter(query, {:nilike, col, pattern}, :sqlite) do
    Ecto.Query.where(query, [t], not like(field(t, ^col), ^pattern))
  end
  defp apply_filter(query, {:nilike, col, pattern}, _) do
    Ecto.Query.where(query, [t], not ilike(field(t, ^col), ^pattern))
  end
  defp apply_filter(query, {:gte, col, val}, _) do
    Ecto.Query.where(query, [t], field(t, ^col) >= ^val)
  end
  defp apply_filter(query, {:lte, col, val}, _) do
    Ecto.Query.where(query, [t], field(t, ^col) <= ^val)
  end
  defp apply_filter(query, {:is, col, val}, _) do
    if is_nil(val) or val == :null do
      Ecto.Query.where(query, [t], is_nil(field(t, ^col)))
    else
      Ecto.Query.where(query, [t], field(t, ^col) == ^val)
    end
  end
  defp apply_filter(query, {:in, col, values}, _) do
    Ecto.Query.where(query, [t], field(t, ^col) in ^values)
  end

  defp apply_filter(query, {:cs, col, values}, _) do
    # PostgreSQL @> operator (contains)
    Ecto.Query.where(query, [t], fragment("? @> ?", field(t, ^col), type(^values, {:array, :any})))
  end
  defp apply_filter(query, {:cd, col, values}, _) do
    # PostgreSQL <@ operator (contained by)
    Ecto.Query.where(query, [t], fragment("? <@ ?", field(t, ^col), type(^values, {:array, :any})))
  end
  defp apply_filter(query, {:ov, col, values}, _) do
    Ecto.Query.where(query, [t], fragment("? && ?", field(t, ^col), type(^values, {:array, :any})))
  end
  defp apply_filter(query, {:sl, col, value}, _) do
    Ecto.Query.where(query, [t], fragment("? << ?", field(t, ^col), ^value))
  end
  defp apply_filter(query, {:sr, col, value}, _) do
    Ecto.Query.where(query, [t], fragment("? >> ?", field(t, ^col), ^value))
  end
  defp apply_filter(query, {:nxr, col, value}, _) do
    Ecto.Query.where(query, [t], fragment("? &> ?", field(t, ^col), ^value))
  end
  defp apply_filter(query, {:nxl, col, value}, _) do
    Ecto.Query.where(query, [t], fragment("? &< ?", field(t, ^col), ^value))
  end
  defp apply_filter(query, {:adj, col, value}, _) do
    Ecto.Query.where(query, [t], fragment("? -|- ?", field(t, ^col), ^value))
  end
  defp apply_filter(query, {:fts, {col, config}, query_text}, _) do
    Ecto.Query.where(
      query,
      [t],
      fragment("to_tsvector(?, ?) @@ plainto_tsquery(?, ?)", ^config, field(t, ^col), ^config, ^query_text)
    )
  end
  defp apply_filter(query, {:plfts, {col, config}, query_text}, _) do
    Ecto.Query.where(
      query,
      [t],
      fragment("to_tsvector(?, ?) @@ plainto_tsquery(?, ?)", ^config, field(t, ^col), ^config, ^query_text)
    )
  end
  defp apply_filter(query, {:phfts, {col, config}, query_text}, _) do
    Ecto.Query.where(
      query,
      [t],
      fragment("to_tsvector(?, ?) @@ phraseto_tsquery(?, ?)", ^config, field(t, ^col), ^config, ^query_text)
    )
  end
  defp apply_filter(query, {:wfts, {col, config}, query_text}, _) do
    Ecto.Query.where(
      query,
      [t],
      fragment("to_tsvector(?, ?) @@ websearch_to_tsquery(?, ?)", ^config, field(t, ^col), ^config, ^query_text)
    )
  end
  # Catch-all: UNSUPPORTED filter operator for Ecto update/delete.
  # Raising here rather than silently dropping the filter prevents accidental mass updates/deletes.
  defp apply_filter(_query, filter, _adapter) do
    raise "Unsupported filter operator for Ecto-based update/delete: #{inspect(filter)}. " <>
          "Supported operators are: eq, neq, gt, lt, gte, lte, like, nlike, ilike, nilike, is, in, " <>
          "and array/range operators (cs, cd, ov, sl, sr, nxr, nxl, adj), plus fts/plfts/phfts/wfts."
  end

  # -- Negated filters for update/delete via Ecto --

  defp apply_not_filter(query, {:eq, col, val}, _) do
    Ecto.Query.where(query, [t], field(t, ^col) != ^val)
  end
  defp apply_not_filter(query, {:neq, col, val}, _) do
    Ecto.Query.where(query, [t], field(t, ^col) == ^val)
  end
  defp apply_not_filter(query, {:gt, col, val}, _) do
    Ecto.Query.where(query, [t], field(t, ^col) <= ^val)
  end
  defp apply_not_filter(query, {:lt, col, val}, _) do
    Ecto.Query.where(query, [t], field(t, ^col) >= ^val)
  end
  defp apply_not_filter(query, {:gte, col, val}, _) do
    Ecto.Query.where(query, [t], field(t, ^col) < ^val)
  end
  defp apply_not_filter(query, {:lte, col, val}, _) do
    Ecto.Query.where(query, [t], field(t, ^col) > ^val)
  end
  defp apply_not_filter(query, {:like, col, pattern}, _) do
    Ecto.Query.where(query, [t], not like(field(t, ^col), ^pattern))
  end
  defp apply_not_filter(query, {:nlike, col, pattern}, _) do
    Ecto.Query.where(query, [t], like(field(t, ^col), ^pattern))
  end
  defp apply_not_filter(query, {:ilike, col, pattern}, :sqlite) do
    Ecto.Query.where(query, [t], not like(field(t, ^col), ^pattern))
  end
  defp apply_not_filter(query, {:ilike, col, pattern}, _) do
    Ecto.Query.where(query, [t], not ilike(field(t, ^col), ^pattern))
  end
  defp apply_not_filter(query, {:nilike, col, pattern}, :sqlite) do
    Ecto.Query.where(query, [t], like(field(t, ^col), ^pattern))
  end
  defp apply_not_filter(query, {:nilike, col, pattern}, _) do
    Ecto.Query.where(query, [t], ilike(field(t, ^col), ^pattern))
  end
  defp apply_not_filter(query, {:is, col, nil}, _) do
    Ecto.Query.where(query, [t], not is_nil(field(t, ^col)))
  end
  defp apply_not_filter(query, {:is, col, val}, _) do
    Ecto.Query.where(query, [t], field(t, ^col) != ^val)
  end
  defp apply_not_filter(query, {:in, col, values}, _) do
    Ecto.Query.where(query, [t], field(t, ^col) not in ^values)
  end
  # Catch-all: UNSUPPORTED NOT filter operator for Ecto update/delete.
  defp apply_not_filter(_query, filter, _adapter) do
    raise "Unsupported NOT filter operator for Ecto-based update/delete: #{inspect(filter)}"
  end

  # -- OR filter groups for update/delete via Ecto --

  defp apply_or_filter_group(query, {group, referenced_table: _ref}, adapter) do
    apply_or_filter_group(query, group, adapter)
  end
  defp apply_or_filter_group(query, group, adapter) when is_list(group) and group != [] do
    # Build a dynamic OR from the filter group
    dynamic =
      Enum.reduce(group, nil, fn
        filter, nil ->
          filter_to_dynamic(filter, adapter)
        filter, acc ->
          Ecto.Query.dynamic([t], ^acc or ^filter_to_dynamic(filter, adapter))
      end)
    Ecto.Query.where(query, [_t], ^dynamic)
  end
  defp apply_or_filter_group(query, [], _adapter), do: query

  defp filter_to_dynamic({:eq, col, val}, _),  do: Ecto.Query.dynamic([t], field(t, ^col) == ^val)
  defp filter_to_dynamic({:neq, col, val}, _), do: Ecto.Query.dynamic([t], field(t, ^col) != ^val)
  defp filter_to_dynamic({:gt, col, val}, _),  do: Ecto.Query.dynamic([t], field(t, ^col) > ^val)
  defp filter_to_dynamic({:lt, col, val}, _),  do: Ecto.Query.dynamic([t], field(t, ^col) < ^val)
  defp filter_to_dynamic({:gte, col, val}, _), do: Ecto.Query.dynamic([t], field(t, ^col) >= ^val)
  defp filter_to_dynamic({:lte, col, val}, _), do: Ecto.Query.dynamic([t], field(t, ^col) <= ^val)
  defp filter_to_dynamic({:like, col, pattern}, _), do: Ecto.Query.dynamic([t], like(field(t, ^col), ^pattern))
  defp filter_to_dynamic({:nlike, col, pattern}, _), do: Ecto.Query.dynamic([t], not like(field(t, ^col), ^pattern))
  defp filter_to_dynamic({:ilike, col, pattern}, :sqlite), do: Ecto.Query.dynamic([t], like(field(t, ^col), ^pattern))
  defp filter_to_dynamic({:ilike, col, pattern}, _), do: Ecto.Query.dynamic([t], ilike(field(t, ^col), ^pattern))
  defp filter_to_dynamic({:nilike, col, pattern}, :sqlite), do: Ecto.Query.dynamic([t], not like(field(t, ^col), ^pattern))
  defp filter_to_dynamic({:nilike, col, pattern}, _), do: Ecto.Query.dynamic([t], not ilike(field(t, ^col), ^pattern))
  defp filter_to_dynamic({:is, col, nil}, _), do: Ecto.Query.dynamic([t], is_nil(field(t, ^col)))
  defp filter_to_dynamic({:is, col, val}, _), do: Ecto.Query.dynamic([t], field(t, ^col) == ^val)
  defp filter_to_dynamic({:in, col, values}, _), do: Ecto.Query.dynamic([t], field(t, ^col) in ^values)
  # Catch-all: UNSUPPORTED filter operator for Ecto-based update/delete OR groups.
  # Raise rather than silently returning true (which would disable the filter).
  defp filter_to_dynamic(filter, _) do
    raise "Unsupported filter operator for Ecto-based update/delete OR groups: #{inspect(filter)}"
  end
end
