defmodule TodosApi.Api.Todos.Id do
  use Nex

  @moduledoc """
  RESTful API for individual todo items.

  Demonstrates Next.js-style dynamic route parameters.
  """

  @doc """
  GET /api/todos/[id] - Get a single todo by ID

  ## Next.js Equivalent
  ```javascript
  export default function handler(req, res) {
    const { id } = req.query  // Path parameter
    const todo = findTodo(id)
    res.json({ data: todo })
  }
  ```
  """
  def get(req) do
    # Path parameter from [id] - Next.js style
    id = req.query["id"]

    case TodosApi.TodosStore.find(id) do
      nil ->
        Nex.json(%{error: "Todo not found"}, status: 404)

      :error ->
        Nex.json(%{error: "Invalid ID"}, status: 400)

      todo ->
        Nex.json(%{data: todo})
    end
  end

  @doc """
  PUT /api/todos/[id] - Update a todo

  ## Next.js Equivalent
  ```javascript
  export default function handler(req, res) {
    const { id } = req.query
    const { text, completed } = req.body
    // Update logic
    res.json({ data: updatedTodo })
  }
  ```
  """
  def put(req) do
    id = req.query["id"]

    # Request body - Next.js style
    text = req.body["text"]
    completed = req.body["completed"]

    case TodosApi.TodosStore.find(id) do
      nil ->
        Nex.json(%{error: "Todo not found"}, status: 404)

      :error ->
        Nex.json(%{error: "Invalid ID"}, status: 400)

      _todo ->
        updated_todo =
          TodosApi.TodosStore.update(id, %{
            text: text,
            completed: completed
          })

        Nex.json(%{data: updated_todo})
    end
  end

  @doc """
  DELETE /api/todos/[id] - Delete a todo

  ## Next.js Equivalent
  ```javascript
  export default function handler(req, res) {
    const { id } = req.query
    // Delete logic
    res.status(204).end()
  }
  ```
  """
  def delete(req) do
    id = req.query["id"]

    case TodosApi.TodosStore.delete(id) do
      :ok ->
        Nex.status(204)

      :error ->
        Nex.json(%{error: "Invalid ID"}, status: 400)
    end
  end
end
