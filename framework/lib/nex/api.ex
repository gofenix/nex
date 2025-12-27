defmodule Nex.Api do
  @moduledoc """
  API module for JSON endpoints.
  
  ## Usage
  
      # src/api/todos/index.ex
      defmodule MyApp.Api.Todos.Index do
        use Nex.Api
        
        def get(conn, _params) do
          todos = fetch_todos()
          json(conn, %{data: todos})
        end
        
        def post(conn, params) do
          case create_todo(params) do
            {:ok, todo} -> json(conn, %{data: todo}, status: 201)
            {:error, err} -> error(conn, err, 422)
          end
        end
      end
  """

  defmacro __using__(_opts) do
    quote do
      import Nex.Api.Helpers
    end
  end
end

defmodule Nex.Api.Helpers do
  @moduledoc false
  import Plug.Conn

  @doc "Return JSON response"
  def json(conn, data, opts \\ []) do
    status = Keyword.get(opts, :status, 200)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end

  @doc "Return empty response"
  def empty(conn, status \\ 204) do
    send_resp(conn, status, "")
  end

  @doc "Return error response"
  def error(conn, message, status \\ 400) do
    json(conn, %{error: message}, status: status)
  end
end
