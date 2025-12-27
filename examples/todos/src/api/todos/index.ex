defmodule Todos.Api.Todos.Index do
  use Nex.Api

  @todos_agent :todos_agent

  def get(conn, _params) do
    ensure_agent_started()
    todos = Agent.get(@todos_agent, & &1)
    json(conn, %{data: todos})
  end

  def post(conn, %{"text" => text}) do
    ensure_agent_started()

    todo = %{
      id: System.unique_integer([:positive]),
      text: text,
      completed: false
    }

    Agent.update(@todos_agent, fn todos -> [todo | todos] end)

    json(conn, %{data: todo}, status: 201)
  end

  defp ensure_agent_started do
    case Process.whereis(@todos_agent) do
      nil -> Agent.start_link(fn -> [] end, name: @todos_agent)
      _pid -> :ok
    end
  end
end
