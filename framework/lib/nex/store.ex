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
  """

  use GenServer

  @table :nex_store
  @page_id_key :nex_page_id

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Generate a new page ID"
  def generate_page_id do
    :crypto.strong_rand_bytes(12) |> Base.url_encode64()
  end

  @doc "Set current page ID in process dictionary (called by framework)"
  def set_page_id(page_id) do
    Process.put(@page_id_key, page_id)
  end

  @doc "Get current page ID from process dictionary"
  def get_page_id do
    Process.get(@page_id_key, "unknown")
  end

  @doc "Get value from page store"
  def get(key, default \\ nil) do
    page_id = get_page_id()

    case :ets.lookup(@table, {page_id, key}) do
      [{_, value}] -> value
      [] -> default
    end
  end

  @doc "Put value into page store"
  def put(key, value) do
    page_id = get_page_id()
    :ets.insert(@table, {{page_id, key}, value})
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
    :ets.match_delete(@table, {{page_id, :_}, :_})
    :ok
  end

  ## Server Callbacks

  @impl true
  def init(_opts) do
    table = :ets.new(@table, [:named_table, :public, :set])
    {:ok, %{table: table}}
  end
end
