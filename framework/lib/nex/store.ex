defmodule Nex.Store do
  @moduledoc """
  Page-scoped state management for Nex applications.

  Provides simple key-value storage isolated by page view,
  similar to React/Vue state - refresh the page and state is gone.

  ## Usage

      # In a Page module
      def mount(conn, _params) do
        # First page load: empty state
        %{title: "Todos", todos: Nex.Store.get(conn, :todos, [])}
      end

      def create_todo(conn, %{"text" => text}) do
        todo = %{id: unique_id(), text: text, completed: false}
        Nex.Store.update(conn, :todos, [], &[todo | &1])
        render_fragment(conn, ~H"<.todo_item todo={todo} />")
      end

  State is tied to a `_page_id` that is generated on first page render.
  HTMX requests carry this `_page_id` to maintain state within the same page view.
  Refreshing the page generates a new `_page_id`, effectively clearing state.
  """

  use GenServer

  @table :nex_store

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Generate a new page ID"
  def generate_page_id do
    :crypto.strong_rand_bytes(12) |> Base.url_encode64()
  end

  @doc "Get value from page store"
  def get(conn, key, default \\ nil) do
    page_id = get_page_id(conn)

    case :ets.lookup(@table, {page_id, key}) do
      [{_, value}] -> value
      [] -> default
    end
  end

  @doc "Put value into page store"
  def put(conn, key, value) do
    page_id = get_page_id(conn)
    :ets.insert(@table, {{page_id, key}, value})
    value
  end

  @doc "Update value in page store"
  def update(conn, key, default, fun) do
    current = get(conn, key, default)
    new_value = fun.(current)
    put(conn, key, new_value)
  end

  @doc "Delete value from page store"
  def delete(conn, key) do
    page_id = get_page_id(conn)
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

  ## Private

  defp get_page_id(conn) do
    # Try to get page_id from:
    # 1. Request params (_page_id from HTMX)
    # 2. conn.private (set by Handler on page render)
    conn.params["_page_id"] || conn.private[:nex_page_id] || "unknown"
  end
end
