defmodule TodosApi.Api.Todos.Id do
  @moduledoc """
  RESTful API for individual todo items.

  Demonstrates Next.js-style dynamic route parameters.
  """
  use Nex.Api

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

    case find_todo(id) do
      nil ->
        Nex.json(%{error: "Todo not found"}, status: 404)

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

    case find_todo(id) do
      nil ->
        Nex.json(%{error: "Todo not found"}, status: 404)

      _todo ->
        # Parse ID to integer for comparison
        todo_id = case Integer.parse(id) do
          {int_id, _} -> int_id
          :error -> nil
        end

        if todo_id do
          updated_todo = Nex.Store.update(:todos, [], fn todos ->
            Enum.map(todos, fn t ->
              if t.id == todo_id do
                t
                |> maybe_update_field(:text, text)
                |> maybe_update_field(:completed, completed)
              else
                t
              end
            end)
          end)
          |> Enum.find(fn t -> t.id == todo_id end)

          Nex.json(%{data: updated_todo})
        else
          Nex.json(%{error: "Invalid ID"}, status: 400)
        end
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

    # Parse ID to integer
    todo_id = case Integer.parse(id) do
      {int_id, _} -> int_id
      :error -> nil
    end

    if todo_id do
      Nex.Store.update(:todos, [], fn todos ->
        Enum.filter(todos, fn t -> t.id != todo_id end)
      end)

      # 204 No Content - standard for successful DELETE
      Nex.status(204)
    else
      Nex.json(%{error: "Invalid ID"}, status: 400)
    end
  end

  # Private helpers

  defp find_todo(id) do
    case Integer.parse(id) do
      {int_id, _} ->
        Nex.Store.get(:todos, [])
        |> Enum.find(fn t -> t.id == int_id end)

      :error ->
        nil
    end
  end

  defp maybe_update_field(todo, _field, nil), do: todo
  defp maybe_update_field(todo, field, value), do: Map.put(todo, field, value)
end
