defmodule TodosApi.Api.Todos.Index do
  use Nex.Api

  def get(_req) do
    todos = Nex.Store.get(:todos, [])
    Nex.json(%{data: todos})
  end

  def post(req) do
    # Like Next.js req.body
    body = req.body

    cond do
      Map.has_key?(body, "text") ->
        text = body["text"]
        todo = %{id: System.unique_integer([:positive, :monotonic]), text: text, completed: false}
        Nex.Store.update(:todos, [], &[todo | &1])
        Nex.json(%{data: todo}, status: 201)

      Map.has_key?(body, "id") and body["action"] == "toggle" ->
        id = body["id"]
        Nex.Store.update(:todos, [], fn todos ->
          Enum.map(todos, fn t ->
            if t.id == id, do: %{t | completed: not t.completed}, else: t
          end)
        end)
        Nex.status(204)

      true ->
        Nex.json(%{error: "Invalid parameters"}, status: 400)
    end
  end

  def delete(req) do
    # Like Next.js req.query
    id = req.query["id"]
    Nex.Store.update(:todos, [], fn todos ->
      Enum.filter(todos, fn t -> t.id != id end)
    end)
    Nex.status(204)
  end
end
