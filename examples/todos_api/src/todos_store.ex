defmodule TodosApi.TodosStore do
  @moduledoc false

  @key {__MODULE__, :todos}

  def list do
    :persistent_term.get(@key, [])
  end

  def create(attrs) do
    todo = %{
      id: System.unique_integer([:positive, :monotonic]),
      text: Map.fetch!(attrs, :text),
      completed: Map.get(attrs, :completed, false),
      created_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    persist([todo | list()])
    todo
  end

  def find(id) do
    with {:ok, todo_id} <- normalize_id(id) do
      Enum.find(list(), &(&1.id == todo_id))
    end
  end

  def update(id, attrs) do
    with {:ok, todo_id} <- normalize_id(id) do
      todos =
        Enum.map(list(), fn todo ->
          if todo.id == todo_id do
            todo
            |> maybe_update_field(:text, Map.get(attrs, :text))
            |> maybe_update_field(:completed, Map.get(attrs, :completed))
          else
            todo
          end
        end)

      persist(todos)
      Enum.find(todos, &(&1.id == todo_id))
    end
  end

  def delete(id) do
    with {:ok, todo_id} <- normalize_id(id) do
      persist(Enum.reject(list(), &(&1.id == todo_id)))
      :ok
    end
  end

  defp normalize_id(id) when is_integer(id), do: {:ok, id}

  defp normalize_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {todo_id, _} -> {:ok, todo_id}
      :error -> :error
    end
  end

  defp normalize_id(_id), do: :error

  defp maybe_update_field(todo, _field, nil), do: todo
  defp maybe_update_field(todo, field, value), do: Map.put(todo, field, value)

  defp persist(todos) do
    :persistent_term.put(@key, todos)
  end
end
