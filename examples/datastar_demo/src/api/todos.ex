defmodule DatastarDemo.Api.Todos do
  use Nex

  def post(req) do
    text = req.body["text"] |> to_string() |> String.trim()
    page_id = req.body["pageId"]

    if is_binary(page_id) and page_id != "" do
      Nex.Store.set_page_id(page_id)
    end

    todo = %{id: System.unique_integer([:positive]), text: text}
    todos = Nex.Store.update(:datastar_todos, [], &(&1 ++ [todo]))
    count = length(todos)
    item = render_todo_item(todo)

    Nex.stream(fn send ->
      send.(Nex.Datastar.patch_elements(item, selector: "#todo-list", mode: "append"))
      send.(Nex.Datastar.patch_signals(%{todoCount: count, newTodo: ""}))
    end)
  end

  defp render_todo_item(todo) do
    text =
      todo.text
      |> Phoenix.HTML.html_escape()
      |> Phoenix.HTML.safe_to_string()

    ~s(<li data-testid="datastar-todo-item" class="rounded-lg bg-base-200 px-4 py-3 text-sm">#{text}</li>)
  end
end
