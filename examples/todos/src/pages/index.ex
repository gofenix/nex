defmodule Todos.Pages.Index do
  use Nex
  import Todos.Components.Todos.Item

  def mount(_params) do
    %{
      title: "Todo App",
      todos: Nex.Store.get(:todos, [])
    }
  end

  def render(assigns) do
    ~H"""
    <div data-testid="todos-page" class="max-w-md mx-auto">
      <h1 class="text-3xl font-bold text-gray-800 mb-6">Todo List</h1>

      <form hx-post="/create_todo"
            hx-target="#todo-list"
            hx-swap="beforeend"
            hx-on::after-request="this.reset()"
            data-testid="todo-form"
            class="mb-6 flex gap-2">
        <input type="text"
               name="text"
               placeholder="New task..."
               required
               data-testid="todo-input"
               class="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" />
        <button type="submit"
                data-testid="todo-submit"
                class="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600">
          add+
        </button>
      </form>

      <ul id="todo-list" data-testid="todo-list" class="space-y-2">
        <.todo_item :for={todo <- @todos} todo={todo} />
      </ul>
    </div>
    """
  end

  def create_todo(req) do
    text = req.body["text"]

    todo = %{
      id: System.unique_integer([:positive]),
      text: text,
      completed: false
    }

    Nex.Store.update(:todos, [], &[todo | &1])

    assigns = %{todo: todo}
    ~H"<.todo_item todo={@todo} />"
  end

  def toggle_todo(req) do
    id = req.body["id"]
    id = String.to_integer(id)

    Nex.Store.update(:todos, [], fn todos ->
      Enum.map(todos, fn todo ->
        if todo.id == id do
          %{todo | completed: !todo.completed}
        else
          todo
        end
      end)
    end)

    todo = Nex.Store.get(:todos, []) |> Enum.find(&(&1.id == id))

    assigns = %{todo: todo}
    ~H"<.todo_item todo={@todo} />"
  end

  def delete_todo(req) do
    id = req.body["id"]
    id = String.to_integer(id)

    Nex.Store.update(:todos, [], fn todos ->
      Enum.reject(todos, &(&1.id == id))
    end)

    :empty
  end
end
