defmodule Nex.Api do
  @moduledoc """
  API module for JSON endpoints.

  ## Usage

      defmodule MyApp.Api.Todos.Index do
        use Nex.Api

        # GET /api/todos - no params needed
        def get do
          %{data: fetch_todos()}
        end

        # POST /api/todos - with params
        def post(%{"text" => text}) do
          todo = create_todo(text)
          {201, %{data: todo}}
        end

        # Error response
        def post(%{"text" => ""}) do
          {:error, 400, "text is required"}
        end
      end

  ## Return values

  - `data` - Returns 200 with JSON body
  - `{status, data}` - Returns custom status with JSON body
  - `{:error, status, message}` - Returns error response
  - `:empty` - Returns 204 No Content
  """

  defmacro __using__(_opts) do
    quote do
    end
  end
end
