defmodule NexBase do
  @moduledoc """
  A fluent database query builder for Elixir, inspired by Supabase.

  Supports PostgreSQL and SQLite — the adapter is auto-detected from the URL scheme.
  Supports multiple simultaneous database connections.

  ## Quick Start

      # Single connection (simplest)
      NexBase.init(url: "postgres://localhost/mydb")
      NexBase.from("users") |> NexBase.run()

      # Multiple connections
      main = NexBase.init(url: "postgres://localhost/main")
      cache = NexBase.init(url: "sqlite::memory:")

      main |> NexBase.from("users") |> NexBase.run()
      cache |> NexBase.from("sessions") |> NexBase.run()

      # Raw SQL
      main |> NexBase.sql("SELECT * FROM users WHERE id = $1", [1])
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
      children = [{NexBase.Repo, []}]

      # Multiple connections
      main = NexBase.init(url: "postgres://localhost/main")
      analytics = NexBase.init(url: "postgres://analytics/db")
      children = [{NexBase.Repo, main}, {NexBase.Repo, analytics}]

      # In a script
      conn = NexBase.init(url: "sqlite::memory:", start: true)
      conn |> NexBase.from("users") |> NexBase.run()
  """
  def init(opts \\ []) do
    url = opts[:url] || System.get_env("DATABASE_URL")
    adapter = detect_adapter(url)
    pool_size = opts[:pool_size] || 10
    repo_module = repo_module_for(adapter)
    repo_config = build_repo_config(adapter, url, pool_size, opts)

    # First connection uses the module name (Ecto default).
    # Subsequent connections get unique names for multi-db support.
    is_first = Application.get_env(:nex_base, :default_conn) == nil
    name = if is_first, do: repo_module, else: :"nex_base_#{:erlang.unique_integer([:positive, :monotonic])}"

    conn = %Conn{
      name: name,
      adapter: adapter,
      repo_module: repo_module,
      repo_config: repo_config
    }

    # Always store config under legacy key (for Repo init/2 fallback)
    Application.put_env(:nex_base, :repo_config, repo_config)
    # Store config keyed by name for multi-conn Repo init/2 lookup
    Application.put_env(:nex_base, name, repo_config)
    # Store as default for backward compatibility (first init wins)
    if is_first do
      Application.put_env(:nex_base, :default_conn, conn)
    end
    # Also store adapter for legacy adapter/0 calls
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
    config = [url: url, pool_size: pool_size]

    config = if opts[:ssl] do
      config ++ [
        ssl: [verify: :verify_none],
        queue_target: 10_000,
        queue_interval: 20_000
      ]
    else
      config
    end

    # Pass through extra Postgrex options (e.g. prepare: :unnamed for pgBouncer)
    extra_keys = [:prepare, :queue_target, :queue_interval, :timeout, :connect_timeout]
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
  Starts a query builder for the given table.

  Can be called with or without a connection:

      # Uses default connection
      NexBase.from("users")

      # Uses specific connection (pipe-friendly)
      conn |> NexBase.from("users")
  """
  def from(%Conn{} = conn, table_name) when is_binary(table_name) do
    %Query{table: table_name, conn: conn}
  end

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
      {:ok, rows} = conn |> NexBase.sql("SELECT * FROM users", [])
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

  @doc """
  Executes a raw SQL query (low-level, returns raw driver result).
  """
  def query(%Conn{} = conn, sql_str, params) when is_binary(sql_str) and is_list(params) do
    repo_mod = resolve_repo(conn)
    Ecto.Adapters.SQL.query(repo_mod, normalize_placeholders(sql_str, conn.adapter), params)
  end

  def query(sql_str, params \\ []) when is_binary(sql_str) do
    query(default_conn(), sql_str, params)
  end

  @doc """
  Executes a raw SQL query, raising on error.
  """
  def query!(%Conn{} = conn, sql_str, params) when is_binary(sql_str) and is_list(params) do
    repo_mod = resolve_repo(conn)
    Ecto.Adapters.SQL.query!(repo_mod, normalize_placeholders(sql_str, conn.adapter), params)
  end

  def query!(sql_str, params \\ []) when is_binary(sql_str) do
    query!(default_conn(), sql_str, params)
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
    conn = default_conn()
    if conn.adapter == :sqlite do
      raise "NexBase.rpc/2 is not supported with SQLite (stored procedures are a PostgreSQL feature)"
    end

    repo_mod = resolve_repo(conn)

    placeholders = Enum.map(1..map_size(params), fn i -> "$#{i}" end)
    keys = Map.keys(params)
    values = Map.values(params)

    args_str = Enum.zip(keys, placeholders)
               |> Enum.map(fn {k, p} -> "#{k} := #{p}" end)
               |> Enum.join(", ")

    sql_str = "SELECT * FROM #{function_name}(#{args_str})"

    Ecto.Adapters.SQL.query(repo_mod, sql_str, values)
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

  def run(%Query{type: :insert, table: table, data: data, conn: conn} = _query) do
    conn = conn || default_conn()
    repo_mod = resolve_repo(conn)
    data_list = if is_list(data), do: data, else: [data]
    {count, _} = repo_mod.insert_all(table, data_list)
    {:ok, %{count: count}}
  rescue
    e -> {:error, e}
  end

  def run(%Query{type: :update, table: table, data: data, filters: filters, conn: conn} = _query) do
    conn = conn || default_conn()
    repo_mod = resolve_repo(conn)
    base_query = Ecto.Query.from(t in table)
    query_with_filters = Enum.reduce(filters, base_query, fn filter, acc ->
      apply_filter(acc, filter, conn.adapter)
    end)
    updates = [set: Enum.to_list(data)]
    {count, _} = repo_mod.update_all(query_with_filters, updates)
    {:ok, %{count: count}}
  rescue
    e -> {:error, e}
  end

  def run(%Query{type: :delete, table: table, filters: filters, conn: conn} = _query) do
    conn = conn || default_conn()
    repo_mod = resolve_repo(conn)
    base_query = Ecto.Query.from(t in table)
    query_with_filters = Enum.reduce(filters, base_query, fn filter, acc ->
      apply_filter(acc, filter, conn.adapter)
    end)
    {count, _} = repo_mod.delete_all(query_with_filters)
    {:ok, %{count: count}}
  rescue
    e -> {:error, e}
  end

  def run(%Query{type: :upsert, table: table, data: data, conn: conn} = _query) do
    conn = conn || default_conn()
    repo_mod = resolve_repo(conn)
    data_list = if is_list(data), do: data, else: [data]
    upsert_opts = [
      on_conflict: :replace_all,
      conflict_target: :id
    ]
    {count, _} = repo_mod.insert_all(table, data_list, upsert_opts)
    {:ok, %{count: count}}
  rescue
    e -> {:error, e}
  end

  # -- Internal Helpers --

  defp resolve_repo(%Conn{repo_module: repo_mod, name: name}) do
    # For multi-conn (custom name), set dynamic repo so Ecto routes to the right process
    if name != repo_mod do
      repo_mod.put_dynamic_repo(name)
    end
    repo_mod
  end

  defp run_select(%Query{table: table, select: select_fields, filters: filters, limit: limit, offset: offset, order_by: order_by, conn: conn}) do
    conn = conn || default_conn()
    repo_mod = resolve_repo(conn)

    columns = if select_fields == [] or select_fields == ["*"], do: "*", else: Enum.map_join(select_fields, ", ", &to_string/1)

    {where_clause, params} = build_where(filters, conn.adapter)
    order_clause = build_order(order_by)
    limit_clause = if limit, do: " LIMIT #{limit}", else: ""
    offset_clause = if offset, do: " OFFSET #{offset}", else: ""

    sql_str = "SELECT #{columns} FROM #{table}#{where_clause}#{order_clause}#{limit_clause}#{offset_clause}"
    sql_str = normalize_placeholders(sql_str, conn.adapter)

    case Ecto.Adapters.SQL.query(repo_mod, sql_str, params) do
      {:ok, %{rows: rows, columns: cols}} ->
        {:ok, Enum.map(rows, fn row -> cols |> Enum.zip(row) |> Map.new() end)}
      {:error, _} = err -> err
    end
  end

  defp build_where([], _adapter), do: {"", []}
  defp build_where(filters, adapter) do
    {clauses, params, _idx} =
      Enum.reduce(filters, {[], [], 1}, fn filter, {clauses, params, idx} ->
        {clause, new_params, next_idx} = filter_to_sql(filter, idx, adapter)
        {clauses ++ [clause], params ++ new_params, next_idx}
      end)

    {" WHERE " <> Enum.join(clauses, " AND "), params}
  end

  defp filter_to_sql({:eq, col, val}, idx, _),   do: {"#{col} = $#{idx}", [val], idx + 1}
  defp filter_to_sql({:neq, col, val}, idx, _),  do: {"#{col} != $#{idx}", [val], idx + 1}
  defp filter_to_sql({:gt, col, val}, idx, _),   do: {"#{col} > $#{idx}", [val], idx + 1}
  defp filter_to_sql({:lt, col, val}, idx, _),   do: {"#{col} < $#{idx}", [val], idx + 1}
  defp filter_to_sql({:gte, col, val}, idx, _),  do: {"#{col} >= $#{idx}", [val], idx + 1}
  defp filter_to_sql({:lte, col, val}, idx, _),  do: {"#{col} <= $#{idx}", [val], idx + 1}
  defp filter_to_sql({:like, col, val}, idx, _),  do: {"#{col} LIKE $#{idx}", [val], idx + 1}
  defp filter_to_sql({:ilike, col, val}, idx, :sqlite), do: {"#{col} LIKE $#{idx}", [val], idx + 1}
  defp filter_to_sql({:ilike, col, val}, idx, _), do: {"#{col} ILIKE $#{idx}", [val], idx + 1}
  defp filter_to_sql({:is, col, val}, idx, _) do
    if is_nil(val) or val == :null do
      {"#{col} IS NULL", [], idx}
    else
      {"#{col} = $#{idx}", [val], idx + 1}
    end
  end
  defp filter_to_sql({:in, col, values}, idx, _) do
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

  defp normalize_placeholders(sql, :sqlite), do: Regex.replace(~r/\$\d+/, sql, "?")
  defp normalize_placeholders(sql, _), do: sql

  # Ecto-based filter application (used by update/delete which go through Ecto.Query)
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
  defp apply_filter(query, {:ilike, col, pattern}, :sqlite) do
    Ecto.Query.where(query, [t], like(field(t, ^col), ^pattern))
  end
  defp apply_filter(query, {:ilike, col, pattern}, _) do
    Ecto.Query.where(query, [t], ilike(field(t, ^col), ^pattern))
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
end
