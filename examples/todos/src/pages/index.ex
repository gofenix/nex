defmodule Todos.Pages.Index do
  use Nex.Page

  # In-memory todo storage (for demo purposes)
  @todos_agent :todos_agent

  def mount(_conn, _params) do
    ensure_agent_started()

    %{
      title: "Todo App",
      todos: get_todos()
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto">
      <h1 class="text-3xl font-bold text-gray-800 mb-6">Todo List</h1>

      <form hx-post="/create_todo"
            hx-target="#todo-list"
            hx-swap="beforeend"
            hx-on::after-request="this.reset()"
            class="mb-6 flex gap-2">
        <input type="text"
               name="text"
               placeholder="新任务..."
               required
               class="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" />
        <button type="submit"
                class="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600">
          添加
        </button>
      </form>

      <ul id="todo-list" class="space-y-2">
        <.todo_item :for={todo <- @todos} todo={todo} />
      </ul>
    </div>
    """
  end

  def create_todo(conn, %{"text" => text}) do
    ensure_agent_started()

    todo = %{
      id: System.unique_integer([:positive]),
      text: text,
      completed: false
    }

    Agent.update(@todos_agent, fn todos -> [todo | todos] end)

    assigns = %{todo: todo}
    render_fragment(conn, ~H"<.todo_item todo={@todo} />")
  end

  def toggle_todo(conn, %{"id" => id}) do
    ensure_agent_started()
    id = String.to_integer(id)

    Agent.update(@todos_agent, fn todos ->
      Enum.map(todos, fn todo ->
        if todo.id == id do
          %{todo | completed: !todo.completed}
        else
          todo
        end
      end)
    end)

    todo = Agent.get(@todos_agent, fn todos ->
      Enum.find(todos, &(&1.id == id))
    end)

    assigns = %{todo: todo}
    render_fragment(conn, ~H"<.todo_item todo={@todo} />")
  end

  def delete_todo(conn, %{"id" => id}) do
    ensure_agent_started()
    id = String.to_integer(id)

    Agent.update(@todos_agent, fn todos ->
      Enum.reject(todos, &(&1.id == id))
    end)

    empty(conn)
  end

  # Private component
  defp todo_item(assigns) do
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
        删除
      </button>
    </li>
    """
  end

  # Helper functions
  defp ensure_agent_started do
    case Process.whereis(@todos_agent) do
      nil -> Agent.start_link(fn -> [] end, name: @todos_agent)
      _pid -> :ok
    end
  end

  defp get_todos do
    Agent.get(@todos_agent, & &1)
  rescue
    _ -> []
  end
end
