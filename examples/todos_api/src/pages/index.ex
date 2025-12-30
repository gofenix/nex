defmodule TodosApi.Pages.Index do
  use Nex.Page

  def mount(_params) do
    %{
      title: "Todo App (HTMX → Page Function → Req → JSON API → HTML)",
      todos: []
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto">
      <h1 class="text-3xl font-bold text-gray-800 mb-6">Todo App (HTMX → Page Function → Req → JSON API → HTML)</h1>

      <form hx-post="/create_todo"
            hx-target="#todo-list"
            hx-swap="beforeend"
            hx-on::after-request="this.reset()"
            class="mb-6 flex gap-2">
        <input type="text"
               name="text"
               placeholder="New task..."
               required
               class="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" />
        <button type="submit"
                class="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600">
          Add
        </button>
      </form>

      <ul id="todo-list" class="space-y-2">
        {raw(fetch_todos())}
      </ul>
    </div>
    """
  end

  def fetch_todos do
    case Req.get("http://localhost:4000/api/todos", finch: TodosApi.Finch) do
      {:ok, %{status: 200, body: %{"data" => todos}}} ->
        Enum.map(todos, fn todo ->
          ~s(<li id="todo-#{todo["id"]}" class="flex items-center gap-3 p-3 bg-white rounded-lg shadow"><span class="flex-1 text-gray-700">#{todo["text"]}</span><button hx-delete="/delete_todo?id=#{todo["id"]}" hx-target="#todo-#{todo["id"]}" hx-swap="outerHTML" class="text-red-500 hover:text-red-700">Delete</button></li>)
        end)
        |> Enum.join("")
      _ -> ""
    end
  end

  def create_todo(%{"text" => text}) do
    assigns = %{}
    case Req.post("http://localhost:4000/api/todos", json: %{"text" => text}, finch: TodosApi.Finch) do
      {:ok, %{status: 201, body: %{"data" => todo}}} ->
        ~H"""
        <li id={"todo-#{todo["id"]}"} class="flex items-center gap-3 p-3 bg-white rounded-lg shadow">
          <span class="flex-1 text-gray-700">{todo["text"]}</span>
          <button hx-delete={"/delete_todo?id=#{todo["id"]}"}
                  hx-target={"#todo-#{todo["id"]}"}
                  hx-swap="outerHTML"
                  class="text-red-500 hover:text-red-700">
            Delete
          </button>
        </li>
        """
      _ -> ""
    end
  end

  def delete_todo(%{"id" => id}) do
    Req.delete("http://localhost:4000/api/todos?id=#{id}", finch: TodosApi.Finch)
    :empty
  end
end
