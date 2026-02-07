defmodule NexBase do
  @moduledoc """
  A fluent PostgreSQL query builder for Elixir, inspired by Supabase.

  ## Quick Start

      # 1. Initialize (once, in application.ex or script)
      NexBase.init(url: "postgres://localhost/mydb")

      # 2. Query
      {:ok, users} = NexBase.from("users")
      |> NexBase.eq(:active, true)
      |> NexBase.order(:name, :asc)
      |> NexBase.run()

      # 3. Insert
      NexBase.from("users")
      |> NexBase.insert(%{name: "Alice", active: true})
      |> NexBase.run()

      # 4. Raw SQL
      {:ok, rows} = NexBase.sql("SELECT * FROM users WHERE id = $1", [1])
  """

  alias NexBase.Query
  require Ecto.Query

  # -- Initialization --

  @doc """
  Initialize NexBase with database configuration.

  Call this once in your application startup. NexBase handles the rest internally.

  ## Options

    - `:url` - Database URL (falls back to DATABASE_URL env var)
    - `:ssl` - Enable SSL for cloud databases (default: false)
    - `:pool_size` - Connection pool size (default: 10)

  ## In an application (supervision tree)

      # application.ex
      def start(_type, _args) do
        NexBase.init(url: System.get_env("DATABASE_URL"), ssl: true)
        children = [{NexBase.Repo, []}]
        Supervisor.start_link(children, strategy: :one_for_one)
      end

  ## In a script (seeds, migrations)

      NexBase.init(url: System.get_env("DATABASE_URL"), ssl: true, start: true)
  """
  def init(opts \\ []) do
    url = opts[:url] || System.get_env("DATABASE_URL")
    pool_size = opts[:pool_size] || 10

    repo_config = [url: url, pool_size: pool_size]

    repo_config =
      if opts[:ssl] do
        repo_config ++ [
          ssl: [verify: :verify_none],
          queue_target: 10_000,
          queue_interval: 20_000
        ]
      else
        repo_config
      end

    Application.put_env(:nex_base, :repo_config, repo_config)

    if opts[:start] do
      Application.ensure_all_started(:postgrex)
      Application.ensure_all_started(:ecto_sql)

      case NexBase.Repo.start_link([]) do
        {:ok, _pid} -> :ok
        {:error, {:already_started, _pid}} -> :ok
        {:error, reason} -> {:error, reason}
      end
    else
      :ok
    end
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
    case Ecto.Adapters.SQL.query(NexBase.Repo, sql, params) do
      {:ok, %{rows: rows, columns: columns}} ->
        {:ok, Enum.map(rows, fn row -> columns |> Enum.zip(row) |> Map.new() end)}
      {:error, _} = err -> err
    end
  end

  @doc """
  Executes a raw SQL query (low-level, returns raw Postgrex result).
  """
  def query(sql, params \\ []) when is_binary(sql) do
    Ecto.Adapters.SQL.query(NexBase.Repo, sql, params)
  end

  @doc """
  Executes a raw SQL query, raising on error.
  """
  def query!(sql, params \\ []) when is_binary(sql) do
    Ecto.Adapters.SQL.query!(NexBase.Repo, sql, params)
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
    repo = NexBase.Repo
    # Build raw SQL: SELECT * FROM func($1, $2)
    # This is complex because params can be positional or named.
    # Postgres functions support named params via `func(param := $1)`.

    # For simplicity MVP, assuming params is a map, we construct `func(key := $val)`

    placeholders = Enum.map(1..map_size(params), fn i -> "$#{i}" end)
    keys = Map.keys(params)
    values = Map.values(params)

    # args_str = "p1 := $1, p2 := $2"
    args_str = Enum.zip(keys, placeholders)
               |> Enum.map(fn {k, p} -> "#{k} := #{p}" end)
               |> Enum.join(", ")

    sql = "SELECT * FROM #{function_name}(#{args_str})"

    Ecto.Adapters.SQL.query(repo, sql, values)
  end

  # -- Execution --

  @doc """
  Executes the built query.

  ## Examples

      {:ok, rows} = NexBase.from("users") |> NexBase.eq(:active, true) |> NexBase.run()
  """
  def run(query)

  def run(%Query{type: :select} = query) do
    repo = NexBase.Repo
    ecto_query = build_ecto_query(query)
    {:ok, repo.all(ecto_query)}
  rescue
    e -> {:error, e}
  end

  def run(%Query{type: :insert, table: table, data: data} = _query) do
    repo = NexBase.Repo
    data_list = if is_list(data), do: data, else: [data]
    {count, _} = repo.insert_all(table, data_list)
    {:ok, %{count: count}}
  rescue
    e -> {:error, e}
  end

  def run(%Query{type: :update, table: table, data: data, filters: filters} = _query) do
    repo = NexBase.Repo
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
    repo = NexBase.Repo
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
    repo = NexBase.Repo
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

  # -- Internal Builder --

  defp build_ecto_query(%Query{table: table, select: select_fields, filters: filters, limit: limit, offset: offset, order_by: order_by}) do
    # Start with the table (string table name support)
    q = Ecto.Query.from(t in table)

    # 1. Apply Selects
    q = if select_fields == [] or select_fields == ["*"] do
      # Use fragment to select all fields without schema
      Ecto.Query.select(q, [t], fragment("row_to_json(?)", t))
    else
      # map(t, ^fields)
      Ecto.Query.select(q, [t], map(t, ^select_fields))
    end

    # 2. Apply Filters
    q = Enum.reduce(filters, q, fn filter, acc ->
      apply_filter(acc, filter)
    end)

    # 3. Apply Order
    q = Enum.reduce(order_by, q, fn {dir, col}, acc ->
        # dir must be :asc or :desc
        Ecto.Query.order_by(acc, [t], [{^dir, field(t, ^col)}])
    end)

    # 4. Apply Limit/Offset
    q = if limit, do: Ecto.Query.limit(q, ^limit), else: q
    q = if offset, do: Ecto.Query.offset(q, ^offset), else: q

    q
  end

  # Helper to apply a single filter
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
    Ecto.Query.where(query, [t], ilike(field(t, ^col), ^pattern))
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
      # Supabase .is('col', true) -> col IS TRUE
      Ecto.Query.where(query, [t], field(t, ^col) == ^val)
    end
  end
  defp apply_filter(query, {:in, col, values}) do
    Ecto.Query.where(query, [t], field(t, ^col) in ^values)
  end
end
