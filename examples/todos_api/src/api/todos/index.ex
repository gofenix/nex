defmodule TodosApi.Api.Todos.Index do
  use Nex

  @moduledoc """
  RESTful API for todo collection.

  Fully aligned with Next.js API Routes behavior.
  """

  @doc """
  GET /api/todos - List all todos with optional filtering

  ## Query Parameters
  - `completed` - Filter by completion status (optional)
  - `limit` - Limit number of results (optional)

  ## Next.js Equivalent
  ```javascript
  export default function handler(req, res) {
    const { completed, limit } = req.query
    const todos = getTodos({ completed, limit })
    res.json({ data: todos })
  }
  ```
  """
  def get(req) do
    # Query parameters - Next.js style
    completed_filter = req.query["completed"]
    limit = req.query["limit"]

    todos = Nex.Store.get(:todos, [])
    |> filter_by_completed(completed_filter)
    |> limit_results(limit)

    Nex.json(%{
      data: todos,
      count: length(todos)
    })
  end

  @doc """
  POST /api/todos - Create a new todo

  ## Request Body
  - `text` - Todo text (required)
  - `completed` - Initial completion status (optional, default: false)

  ## Next.js Equivalent
  ```javascript
  export default function handler(req, res) {
    const { text, completed } = req.body
    const todo = createTodo({ text, completed })
    res.status(201).json({ data: todo })
  }
  ```
  """
  def post(req) do
    # Request body - Next.js style
    text = req.body["text"]
    completed = req.body["completed"] || false

    cond do
      is_nil(text) or text == "" ->
        Nex.json(%{error: "Text is required"}, status: 400)

      true ->
        todo = %{
          id: System.unique_integer([:positive, :monotonic]),
          text: text,
          completed: completed,
          created_at: DateTime.utc_now() |> DateTime.to_iso8601()
        }

        Nex.Store.update(:todos, [], &[todo | &1])

        # 201 Created - standard for successful resource creation
        Nex.json(%{data: todo}, status: 201)
    end
  end

  # Private helpers

  defp filter_by_completed(todos, nil), do: todos
  defp filter_by_completed(todos, "true"), do: Enum.filter(todos, & &1.completed)
  defp filter_by_completed(todos, "false"), do: Enum.filter(todos, &(not &1.completed))
  defp filter_by_completed(todos, _), do: todos

  defp limit_results(todos, nil), do: todos
  defp limit_results(todos, limit_str) do
    case Integer.parse(limit_str) do
      {limit, _} -> Enum.take(todos, limit)
      :error -> todos
    end
  end
end
