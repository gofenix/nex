defmodule TodosApi.Api.Todos.Index do
  use Nex.Api

  def get do
    todos = Nex.Store.get(:todos, [])
    %{data: todos}
  end

  def post(%{"text" => text}) do
    todo = %{id: System.unique_integer([:positive, :monotonic]), text: text, completed: false}
    Nex.Store.update(:todos, [], &[todo | &1])
    {201, %{data: todo}}
  end

  def post(%{"id" => id, "action" => "toggle"}) do
    Nex.Store.update(:todos, [], fn todos ->
      Enum.map(todos, fn t ->
        if t.id == id, do: %{t | completed: not t.completed}, else: t
      end)
    end)
    :empty
  end

  def delete(%{"id" => id}) do
    Nex.Store.update(:todos, [], fn todos ->
      Enum.filter(todos, fn t -> t.id != id end)
    end)
    :empty
  end
end
