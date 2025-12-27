defmodule Todos.Api.Todos.Index do
  use Nex.Api

  def get do
    %{data: Nex.Store.get(:todos, [])}
  end

  def post(%{"text" => text}) do
    todo = %{
      id: System.unique_integer([:positive]),
      text: text,
      completed: false
    }

    Nex.Store.update(:todos, [], &[todo | &1])

    {201, %{data: todo}}
  end
end
