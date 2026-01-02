defmodule Todos.Components.Todos.Item do
  use Nex

  @doc """
  Render a single todo item.

  ## Usage

      alias Todos.Components.Todos.Item

      # In HEEx template
      <Item.todo_item todo={todo} />

      # Or with alias
      alias Todos.Components.Todos.Item, as: TodoItem
      <TodoItem.todo_item todo={todo} />
  """
  def todo_item(assigns) do
    ~H"""
    <li id={"todo-#{@todo.id}"}
        class={"flex items-center gap-3 p-3 bg-white rounded-lg shadow #{if @todo.completed, do: "opacity-60"}"}>
      <input type="checkbox"
             checked={@todo.completed}
             hx-post="/toggle_todo"
             hx-vals={Jason.encode!(%{id: @todo.id})}
             hx-target={"#todo-#{@todo.id}"}
             hx-swap="outerHTML"
             class="w-5 h-5 text-blue-500" />
      <span class={"flex-1 #{if @todo.completed, do: "line-through text-gray-400", else: "text-gray-700"}"}>
        {@todo.text}
      </span>
      <button hx-post="/delete_todo"
              hx-vals={Jason.encode!(%{id: @todo.id})}
              hx-target={"#todo-#{@todo.id}"}
              hx-swap="outerHTML"
              class="text-red-500 hover:text-red-700">
        Delete
      </button>
    </li>
    """
  end
end
