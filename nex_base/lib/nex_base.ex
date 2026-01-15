defmodule NexBase do
  @moduledoc """
  The main entry point for NexBase.
  Provides a fluent API for building and executing PostgreSQL queries.
  """

  alias NexBase.Query
  require Ecto.Query

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
  Executes a raw SQL query.
  """
  def query(sql, params \\ []) do
    Ecto.Adapters.SQL.query(NexBase.Repo, sql, params)
  end

  @doc """
  Executes a raw SQL query, raising on error.
  """
  def query!(sql, params \\ []) do
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
  """
  def rpc(function_name, params \\ %{}) do
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
    
    Ecto.Adapters.SQL.query(NexBase.Repo, sql, values)
  end

  # -- Execution --

  @doc """
  Executes the built query.
  """
  def run(%Query{type: :select} = query) do
    ecto_query = build_ecto_query(query)
    {:ok, NexBase.Repo.all(ecto_query)}
  rescue
    e -> {:error, e}
  end

  def run(%Query{type: :insert, table: table, data: data} = _query) do
    # insert_all supports both a list of maps or a single map (if wrapped)
    data_list = if is_list(data), do: data, else: [data]
    
    # insert_all returns {count, nil} unless returning is specified.
    {count, _} = NexBase.Repo.insert_all(table, data_list)
    {:ok, %{count: count}}
  rescue
    e -> {:error, e}
  end

  def run(%Query{type: :update, table: table, data: data, filters: filters} = _query) do
    # For Schema-less update, we use Repo.update_all.
    # We must build a query to filter which rows to update.
    # `from(t in table) |> where(...)`
    
    # Re-use builder logic partially or manually construct:
    base_query = Ecto.Query.from(t in table)
    query_with_filters = Enum.reduce(filters, base_query, fn filter, acc ->
      apply_filter(acc, filter)
    end)
    
    # update_all expects [set: [col: val]]
    updates = [set: Enum.to_list(data)]
    
    {count, _} = NexBase.Repo.update_all(query_with_filters, updates)
    {:ok, %{count: count}}
  rescue
    e -> {:error, e}
  end

  def run(%Query{type: :delete, table: table, filters: filters} = _query) do
    base_query = Ecto.Query.from(t in table)
    query_with_filters = Enum.reduce(filters, base_query, fn filter, acc ->
      apply_filter(acc, filter)
    end)
    
    {count, _} = NexBase.Repo.delete_all(query_with_filters)
    {:ok, %{count: count}}
  rescue
    e -> {:error, e}
  end

  def run(%Query{type: :upsert, table: table, data: data} = _query) do
    # Schema-less upsert via insert_all(..., on_conflict: :replace_all, conflict_target: :id)
    # Ideally conflict_target should be customizable via .on_conflict() modifier (TODO).
    # For now, default to :id or assume simple upsert.
    # Supabase JS upsert usually replaces all.
    
    data_list = if is_list(data), do: data, else: [data]
    
    # WARNING: conflict_target is required for upsert in PG.
    # Without schema, we might need user to specify it?
    # Or we default to :id if it exists?
    # Let's assume user provides it via options or we default to [:id].
    # But Ecto schema-less might need explicit columns.
    
    # For MVP, let's try strict replacement on :id
    opts = [
      on_conflict: :replace_all,
      conflict_target: :id # This is an assumption!
    ]
    
    {count, _} = NexBase.Repo.insert_all(table, data_list, opts)
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
      Ecto.Query.select(q, [t], t)
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
