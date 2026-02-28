defmodule Nex.Store do
  @moduledoc """
  Page-scoped state management for Nex applications.

  Provides simple key-value storage isolated by page view,
  similar to React/Vue state - refresh the page and state is gone.

  ## Usage

      # In a Page module
      def mount(_params) do
        %{title: "Todos", todos: Nex.Store.get(:todos, [])}
      end

      def create_todo(%{"text" => text}) do
        todo = %{id: unique_id(), text: text, completed: false}
        Nex.Store.update(:todos, [], &[todo | &1])
        # ...
      end

  State is tied to a `_page_id` that is generated on first page render.
  HTMX requests carry this `_page_id` to maintain state within the same page view.
  Refreshing the page generates a new `_page_id`, effectively clearing state.

  ## TTL & Cleanup

  Each page's state has a TTL (default 1 hour). After TTL expires, state is
  automatically cleaned up to prevent memory leaks.
  """

  use GenServer
  require Logger

  @table :nex_store
  @page_id_key :nex_page_id
  @default_ttl :timer.hours(1)
  @cleanup_interval :timer.minutes(5)

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Generate a new page ID"
  def generate_page_id do
    :crypto.strong_rand_bytes(12) |> Base.url_encode64()
  end

  @doc "Set current page ID in process dictionary (called by Nex.Handler)"
  def set_page_id(page_id) do
    Process.put(@page_id_key, page_id)
    # Touch the page to update its last access time
    touch_page(page_id)
  end

  @doc "Get current page ID from process dictionary"
  def get_page_id do
    Process.get(@page_id_key, "unknown")
  end

  @doc "Clear page_id from process dictionary (called by Nex.Handler after request)"
  def clear_process_dictionary do
    Process.delete(@page_id_key)
  end

  @doc "Get value from page store"
  def get(key, default \\ nil) do
    page_id = get_page_id()

    case :ets.lookup(@table, {page_id, key}) do
      [{_, value, _expires_at}] -> value
      [] -> default
    end
  end

  @doc "Put value into page store"
  def put(key, value) do
    page_id = get_page_id()
    expires_at = System.system_time(:millisecond) + @default_ttl
    :ets.insert(@table, {{page_id, key}, value, expires_at})
    value
  end

  @doc "Update value in page store"
  def update(key, default, fun) do
    current = get(key, default)
    new_value = fun.(current)
    put(key, new_value)
  end

  @doc "Delete value from page store"
  def delete(key) do
    page_id = get_page_id()
    :ets.delete(@table, {page_id, key})
    :ok
  end

  @doc "Delete all state for a page"
  def clear_page(page_id) do
    :ets.match_delete(@table, {{page_id, :_}, :_, :_})
    :ok
  end

  ## Server Callbacks

  @impl true
  def init(_opts) do
    # Use read_concurrency for better read performance since we have many readers
    table = :ets.new(@table, [
      :named_table,
      :public,
      :set,
      read_concurrency: true,
      write_concurrency: true
    ])
    schedule_cleanup()
    {:ok, %{table: table}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_expired()
    schedule_cleanup()
    {:noreply, state}
  end

  ## Private

  defp touch_page(page_id) do
    # Update expiry for all keys of this page
    # Optimized: use :ets.match to only scan matching records instead of full table
    expires_at = System.system_time(:millisecond) + @default_ttl

    # Match pattern: {{page_id, '$1'}, '$2', '_'}
    # Returns list of [key, value] pairs
    :ets.match(@table, {{page_id, :"$1"}, :"$2", :_})
    |> Enum.each(fn [key, value] ->
      :ets.insert(@table, {{page_id, key}, value, expires_at})
    end)
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end

  defp cleanup_expired do
    now = System.system_time(:millisecond)

    # Find and delete expired entries
    expired =
      :ets.foldl(
        fn
          {key, _value, expires_at}, acc when expires_at < now ->
            [key | acc]
          _, acc ->
            acc
        end,
        [],
        @table
      )

    Enum.each(expired, &:ets.delete(@table, &1))

    if length(expired) > 0 do
      Logger.debug("[Nex.Store] Cleaned up #{length(expired)} expired entries")
    end
  end
end
