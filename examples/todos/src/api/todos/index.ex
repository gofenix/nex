defmodule Todos.Api.Todos.Index do
  use Nex.Api

  def get(conn, _params) do
    todos = Nex.Store.get(:todos, [])
    json(conn, %{data: todos})
  end

  def post(conn, %{"text" => text}) do
    todo = %{
      id: System.unique_integer([:positive]),
      text: text,
      completed: false
    }

    Nex.Store.update(:todos, [], &[todo | &1])

    json(conn, %{data: todo}, status: 201)
  end
end
