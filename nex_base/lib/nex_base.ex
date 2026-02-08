defmodule NexBase do
  @moduledoc """
  A fluent database query builder for Elixir, inspired by Supabase.

  Supports PostgreSQL and SQLite — the adapter is auto-detected from the URL scheme.

  ## Quick Start

      # PostgreSQL
      NexBase.init(url: "postgres://localhost/mydb")

      # SQLite
      NexBase.init(url: "sqlite:///path/to/mydb.db")

      # Query (same API for both databases)
      {:ok, users} = NexBase.from("users")
      |> NexBase.eq(:active, true)
      |> NexBase.order(:name, :asc)
      |> NexBase.run()

      # Insert
      NexBase.from("users")
      |> NexBase.insert(%{name: "Alice", active: true})
      |> NexBase.run()

      # Raw SQL
      {:ok, rows} = NexBase.sql("SELECT * FROM users WHERE id = $1", [1])
  """

  alias NexBase.Query
  require Ecto.Query

  # -- Initialization --

  @doc """
  Initialize NexBase with database configuration.

  Call this once in your application startup. NexBase handles the rest internally.
  The adapter is auto-detected from the URL scheme:

  - `postgres://` or `postgresql://` → PostgreSQL
  - `sqlite://` → SQLite

  ## Options

    - `:url` - Database URL (falls back to DATABASE_URL env var)
    - `:ssl` - Enable SSL for cloud databases (default: false, ignored for SQLite)
    - `:pool_size` - Connection pool size (default: 10)
    - `:start` - Start the Repo immediately (for scripts, default: false)

  ## Examples

      # PostgreSQL (in application.ex)
      NexBase.init(url: "postgres://localhost/mydb", ssl: true)
      children = [{NexBase.Repo, []}]

      # SQLite (in application.ex)
      NexBase.init(url: "sqlite:///path/to/mydb.db")
      children = [{NexBase.Repo, []}]

      # In a script (seeds, migrations)
      NexBase.init(url: System.get_env("DATABASE_URL"), start: true)
  """
  def init(opts \\ []) do
    url = opts[:url] || System.get_env("DATABASE_URL")
    adapter = detect_adapter(url)
    pool_size = opts[:pool_size] || 10

    Application.put_env(:nex_base, :adapter, adapter)

    repo_config = build_repo_config(adapter, url, pool_size, opts)
    Application.put_env(:nex_base, :repo_config, repo_config)

    if opts[:start] do
      start_repo(adapter)
    else
      :ok
    end
  end

  defp detect_adapter(nil), do: :postgres
  defp detect_adapter(url) when is_binary(url) do
    cond do
      String.starts_with?(url, "sqlite") -> :sqlite
      true -> :postgres
    end
  end

  defp build_repo_config(:postgres, url, pool_size, opts) do
    config = [url: url, pool_size: pool_size]

    if opts[:ssl] do
      config ++ [
        ssl: [verify: :verify_none],
        queue_target: 10_000,
        queue_interval: 20_000
      ]
    else
      config
    end
  end

  defp build_repo_config(:sqlite, url, pool_size, _opts) do
    database = parse_sqlite_url(url)
    [database: database, pool_size: pool_size]
  end

  defp parse_sqlite_url("sqlite::memory:"), do: ":memory:"
  defp parse_sqlite_url("sqlite:///" <> path), do: "/" <> path
  defp parse_sqlite_url("sqlite://" <> path), do: path
  defp parse_sqlite_url(path), do: path

  defp start_repo(:postgres) do
    Application.ensure_all_started(:postgrex)
    Application.ensure_all_started(:ecto_sql)
    do_start_repo()
  end

  defp start_repo(:sqlite) do
    Application.ensure_all_started(:exqlite)
    Application.ensure_all_started(:ecto_sql)
    do_start_repo()
  end

  defp do_start_repo do
    case NexBase.Repo.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Returns the currently active adapter (`:postgres` or `:sqlite`)."
  def adapter do
    Application.get_env(:nex_base, :adapter, :postgres)
  end

  # -- Query Building --

  @doc """
  Starts a query builder for the given table.
  """
  def from(table_name) when is_binary(table_name) do
    %Query{table: table_name}
  end

  @doc """
  Selects specific columns.
  Default is all columns (`*`) if not specified.
  """
  def select(%Query{} = query, columns) when is_list(columns) do
    %{query | select: columns}
  end

  @doc """
  Adds an equality filter.
  """
  def eq(%Query{} = query, column, value) do
    filter = {:eq, column, value}
    %{query | filters: query.filters ++ [filter]}
  end

  @doc """
  Adds a not-equal filter.
  """
  def neq(%Query{} = query, column, value) do
    filter = {:neq, column, value}
    %{query | filters: query.filters ++ [filter]}
  end

  @doc """
  Adds a greater-than filter.
  """
  def gt(%Query{} = query, column, value) do
    filter = {:gt, column, value}
    %{query | filters: query.filters ++ [filter]}
  end

  @doc """
  Adds a less-than filter.
  """
  def lt(%Query{} = query, column, value) do
    filter = {:lt, column, value}
    %{query | filters: query.filters ++ [filter]}
  end

  @doc """
  Adds a greater-than-or-equal filter.
  """
  def gte(%Query{} = query, column, value) do
    filter = {:gte, column, value}
    %{query | filters: query.filters ++ [filter]}
  end

  @doc """
  Adds a less-than-or-equal filter.
  """
  def lte(%Query{} = query, column, value) do
    filter = {:lte, column, value}
    %{query | filters: query.filters ++ [filter]}
  end

  @doc """
  Adds an IS filter (e.g. for NULL).
  """
  def is(%Query{} = query, column, value) do
    filter = {:is, column, value}
    %{query | filters: query.filters ++ [filter]}
  end

  @doc """
  Adds an IN filter.
  Note: Named `in_list` to avoid conflict with Kernel.in operator.
  """
  def in_list(%Query{} = query, column, values) when is_list(values) do
    filter = {:in, column, values}
    %{query | filters: query.filters ++ [filter]}
  end

  @doc """
  Adds a like filter.
  """
  def like(%Query{} = query, column, pattern) do
    filter = {:like, column, pattern}
    %{query | filters: query.filters ++ [filter]}
  end

  @doc """
  Adds an ilike filter.
  """
  def ilike(%Query{} = query, column, pattern) do
    filter = {:ilike, column, pattern}
    %{query | filters: query.filters ++ [filter]}
  end

  @doc """
  Sets the limit.
  """
  def limit(%Query{} = query, limit) do
    %{query | limit: limit}
  end

  @doc """
  Sets the offset.
  """
  def offset(%Query{} = query, offset) do
    %{query | offset: offset}
  end

  @doc """
  Sets order by.
  """
  def order(%Query{} = query, column, direction \\ :asc) do
     # We append to allow multiple order by clauses if needed
    %{query | order_by: query.order_by ++ [{direction, column}]}
  end

  @doc """
  Executes a raw SQL query and returns results as a list of maps.

  ## Examples

      {:ok, rows} = NexBase.sql("SELECT * FROM users WHERE active = $1", [true])
      {:ok, rows} = NexBase.sql(client, "SELECT * FROM users", [])
  """
  def sql(sql, params \\ []) when is_binary(sql) do
    repo = repo()
    sql = normalize_placeholders(sql)
    case Ecto.Adapters.SQL.query(repo, sql, params) do
      {:ok, %{rows: rows, columns: columns}} ->
        {:ok, Enum.map(rows, fn row -> columns |> Enum.zip(row) |> Map.new() end)}
      {:error, _} = err -> err
    end
  end

  @doc """
  Executes a raw SQL query (low-level, returns raw driver result).
  """
  def query(sql, params \\ []) when is_binary(sql) do
    Ecto.Adapters.SQL.query(repo(), normalize_placeholders(sql), params)
  end

  @doc """
  Executes a raw SQL query, raising on error.
  """
  def query!(sql, params \\ []) when is_binary(sql) do
    Ecto.Adapters.SQL.query!(repo(), normalize_placeholders(sql), params)
  end

  @doc """
  Adds data for insertion.
  """
  def insert(%Query{} = query, data) when is_map(data) or is_list(data) do
    %{query | type: :insert, data: data}
  end

  @doc """
  Adds data for update.
  """
  def update(%Query{} = query, data) when is_map(data) do
    %{query | type: :update, data: data}
  end

  @doc """
  Sets query to delete.
  """
  def delete(%Query{} = query) do
    %{query | type: :delete}
  end

  @doc """
  Adds data for upsert.
  """
  def upsert(%Query{} = query, data) when is_map(data) or is_list(data) do
    %{query | type: :upsert, data: data}
  end

  @doc """
  Sets limits the range of rows to return.
  """
  def range(%Query{} = query, from, to) do
    # Supabase .range(0, 9) means limit 10 offset 0
    # to is inclusive index
    limit = to - from + 1
    offset = from
    %{query | limit: limit, offset: offset}
  end

  @doc """
  Sets query to return a single result.
  """
  def single(%Query{} = query) do
    %{query | limit: 1}
  end

  @doc """
  Sets query to return a single result or nil.
  """
  def maybe_single(%Query{} = query) do
    %{query | limit: 1}
  end

  @doc """
  Executes a stored procedure (RPC).

  ## Examples

      {:ok, result} = NexBase.rpc("my_function", %{param1: "value"})
  """
  def rpc(function_name, params \\ %{}) do
    if adapter() == :sqlite do
      raise "NexBase.rpc/2 is not supported with SQLite (stored procedures are a PostgreSQL feature)"
    end

    placeholders = Enum.map(1..map_size(params), fn i -> "$#{i}" end)
    keys = Map.keys(params)
    values = Map.values(params)

    args_str = Enum.zip(keys, placeholders)
               |> Enum.map(fn {k, p} -> "#{k} := #{p}" end)
               |> Enum.join(", ")

    sql = "SELECT * FROM #{function_name}(#{args_str})"

    Ecto.Adapters.SQL.query(repo(), sql, values)
  end

  # -- Execution --

  @doc """
  Executes the built query.

  ## Examples

      {:ok, rows} = NexBase.from("users") |> NexBase.eq(:active, true) |> NexBase.run()
  """
  def run(query)

  def run(%Query{type: :select} = query) do
    run_select(query)
  rescue
    e -> {:error, e}
  end

  def run(%Query{type: :insert, table: table, data: data} = _query) do
    repo = repo()
    data_list = if is_list(data), do: data, else: [data]
    {count, _} = repo.insert_all(table, data_list)
    {:ok, %{count: count}}
  rescue
    e -> {:error, e}
  end

  def run(%Query{type: :update, table: table, data: data, filters: filters} = _query) do
    repo = repo()
    base_query = Ecto.Query.from(t in table)
    query_with_filters = Enum.reduce(filters, base_query, fn filter, acc ->
      apply_filter(acc, filter)
    end)
    updates = [set: Enum.to_list(data)]
    {count, _} = repo.update_all(query_with_filters, updates)
    {:ok, %{count: count}}
  rescue
    e -> {:error, e}
  end

  def run(%Query{type: :delete, table: table, filters: filters} = _query) do
    repo = repo()
    base_query = Ecto.Query.from(t in table)
    query_with_filters = Enum.reduce(filters, base_query, fn filter, acc ->
      apply_filter(acc, filter)
    end)
    {count, _} = repo.delete_all(query_with_filters)
    {:ok, %{count: count}}
  rescue
    e -> {:error, e}
  end

  def run(%Query{type: :upsert, table: table, data: data} = _query) do
    repo = repo()
    data_list = if is_list(data), do: data, else: [data]
    upsert_opts = [
      on_conflict: :replace_all,
      conflict_target: :id
    ]
    {count, _} = repo.insert_all(table, data_list, upsert_opts)
    {:ok, %{count: count}}
  rescue
    e -> {:error, e}
  end

  # -- Internal Helpers --

  defp repo, do: NexBase.Repo.repo()

  # SELECT queries use raw SQL to avoid row_to_json (Postgres-only)
  # and schemaless query issues (SQLite). This is portable across both adapters.
  defp run_select(%Query{table: table, select: select_fields, filters: filters, limit: limit, offset: offset, order_by: order_by}) do
    columns = if select_fields == [] or select_fields == ["*"], do: "*", else: Enum.map_join(select_fields, ", ", &to_string/1)

    {where_clause, params} = build_where(filters)
    order_clause = build_order(order_by)
    limit_clause = if limit, do: " LIMIT #{limit}", else: ""
    offset_clause = if offset, do: " OFFSET #{offset}", else: ""

    sql = "SELECT #{columns} FROM #{table}#{where_clause}#{order_clause}#{limit_clause}#{offset_clause}"
    sql = normalize_placeholders(sql)

    case Ecto.Adapters.SQL.query(repo(), sql, params) do
      {:ok, %{rows: rows, columns: cols}} ->
        {:ok, Enum.map(rows, fn row -> cols |> Enum.zip(row) |> Map.new() end)}
      {:error, _} = err -> err
    end
  end

  defp build_where([]), do: {"", []}
  defp build_where(filters) do
    {clauses, params, _idx} =
      Enum.reduce(filters, {[], [], 1}, fn filter, {clauses, params, idx} ->
        {clause, new_params, next_idx} = filter_to_sql(filter, idx)
        {clauses ++ [clause], params ++ new_params, next_idx}
      end)

    {" WHERE " <> Enum.join(clauses, " AND "), params}
  end

  defp filter_to_sql({:eq, col, val}, idx),   do: {"#{col} = $#{idx}", [val], idx + 1}
  defp filter_to_sql({:neq, col, val}, idx),  do: {"#{col} != $#{idx}", [val], idx + 1}
  defp filter_to_sql({:gt, col, val}, idx),   do: {"#{col} > $#{idx}", [val], idx + 1}
  defp filter_to_sql({:lt, col, val}, idx),   do: {"#{col} < $#{idx}", [val], idx + 1}
  defp filter_to_sql({:gte, col, val}, idx),  do: {"#{col} >= $#{idx}", [val], idx + 1}
  defp filter_to_sql({:lte, col, val}, idx),  do: {"#{col} <= $#{idx}", [val], idx + 1}
  defp filter_to_sql({:like, col, val}, idx),  do: {"#{col} LIKE $#{idx}", [val], idx + 1}
  defp filter_to_sql({:ilike, col, val}, idx) do
    if adapter() == :sqlite do
      # SQLite LIKE is case-insensitive for ASCII by default
      {"#{col} LIKE $#{idx}", [val], idx + 1}
    else
      {"#{col} ILIKE $#{idx}", [val], idx + 1}
    end
  end
  defp filter_to_sql({:is, col, val}, idx) do
    if is_nil(val) or val == :null do
      {"#{col} IS NULL", [], idx}
    else
      {"#{col} = $#{idx}", [val], idx + 1}
    end
  end
  defp filter_to_sql({:in, col, values}, idx) do
    placeholders = Enum.map_join(0..(length(values) - 1), ", ", fn i -> "$#{idx + i}" end)
    {"#{col} IN (#{placeholders})", values, idx + length(values)}
  end

  defp build_order([]), do: ""
  defp build_order(order_by) do
    clauses = Enum.map(order_by, fn {dir, col} ->
      direction = if dir == :desc, do: "DESC", else: "ASC"
      "#{col} #{direction}"
    end)
    " ORDER BY " <> Enum.join(clauses, ", ")
  end

  # Convert $1, $2 placeholders to ? for SQLite
  defp normalize_placeholders(sql) do
    if adapter() == :sqlite do
      Regex.replace(~r/\$\d+/, sql, "?")
    else
      sql
    end
  end

  # Ecto-based filter application (used by update/delete which go through Ecto.Query)
  defp apply_filter(query, {:eq, col, val}) do
    Ecto.Query.where(query, [t], field(t, ^col) == ^val)
  end
  defp apply_filter(query, {:neq, col, val}) do
    Ecto.Query.where(query, [t], field(t, ^col) != ^val)
  end
  defp apply_filter(query, {:gt, col, val}) do
    Ecto.Query.where(query, [t], field(t, ^col) > ^val)
  end
  defp apply_filter(query, {:lt, col, val}) do
    Ecto.Query.where(query, [t], field(t, ^col) < ^val)
  end
  defp apply_filter(query, {:like, col, pattern}) do
    Ecto.Query.where(query, [t], like(field(t, ^col), ^pattern))
  end
  defp apply_filter(query, {:ilike, col, pattern}) do
    if adapter() == :sqlite do
      Ecto.Query.where(query, [t], like(field(t, ^col), ^pattern))
    else
      Ecto.Query.where(query, [t], ilike(field(t, ^col), ^pattern))
    end
  end
  defp apply_filter(query, {:gte, col, val}) do
    Ecto.Query.where(query, [t], field(t, ^col) >= ^val)
  end
  defp apply_filter(query, {:lte, col, val}) do
    Ecto.Query.where(query, [t], field(t, ^col) <= ^val)
  end
  defp apply_filter(query, {:is, col, val}) do
    if is_nil(val) or val == :null do
      Ecto.Query.where(query, [t], is_nil(field(t, ^col)))
    else
      Ecto.Query.where(query, [t], field(t, ^col) == ^val)
    end
  end
  defp apply_filter(query, {:in, col, values}) do
    Ecto.Query.where(query, [t], field(t, ^col) in ^values)
  end
end
