defmodule Nex.Handler.Api do
  @moduledoc false

  require Logger

  alias Nex.Handler.{Errors, Stream}

  def handle(conn, method, path) do
    api_path =
      case path do
        ["api" | rest] -> rest
        _ -> path
      end

    case Nex.RouteDiscovery.resolve(:api, api_path) do
      {:ok, module, params} ->
        handle_endpoint(conn, method, module, Map.merge(conn.params, params))

      :error ->
        Errors.send_json_error(conn, 404, "Not Found")
    end
  end

  defp handle_endpoint(conn, method, module, params) do
    page_id = Nex.Handler.Page.page_id_from_request(conn)
    Nex.Store.set_page_id(page_id)
    req = Nex.Req.from_plug_conn(conn, params)

    try do
      if function_exported?(module, method, 1) do
        result = apply(module, method, [req])
        send_api_response(conn, result)
      else
        send_api_response(conn, :method_not_allowed)
      end
    rescue
      error in FunctionClauseError ->
        if error.function == method and error.arity == 1 and error.module == module do
          Logger.error("""
          [Nex] API Breaking Change Detected!
          The API signature for #{inspect(module)}.#{method}/1 has changed.
          It now expects a `Nex.Req` struct instead of a map.

          Please update your code:

              def #{method}(req) do
                id = req.query["id"]
                name = req.body["name"]
                Nex.json(%{data: ...})
              end
          """)

          Errors.send_json_error(conn, 500, "Internal Server Error: API signature mismatch")
        else
          reraise error, __STACKTRACE__
        end
    end
  end

  defp send_api_response(conn, %Nex.Response{} = response) do
    Stream.send_response(conn, response)
  end

  defp send_api_response(conn, :method_not_allowed) do
    Errors.send_json_error(conn, 405, "Method Not Allowed")
  end

  defp send_api_response(conn, other) do
    Logger.error("""
    [Nex] API Response Error!
    Your API handler returned an invalid response type.
    It must return a `%Nex.Response{}` struct using one of the helper functions:

    * `Nex.json(data, opts \\\\ [])`
    * `Nex.text(string, opts \\\\ [])`
    * `Nex.html(content, opts \\\\ [])`
    * `Nex.redirect(to, opts \\\\ [])`
    * `Nex.status(code)`

    Received: #{inspect(other)}
    """)

    if Nex.Config.dev?() do
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(
        500,
        Jason.encode!(%{
          error: "Internal Server Error: Invalid Response Type",
          details: %{
            message: "Your API handler returned an invalid response type",
            received_type: other.__struct__ || "unknown",
            hint: "Return a `%Nex.Response{}` struct using helper functions like `Nex.json/2`"
          }
        })
      )
    else
      Errors.send_json_error(conn, 500, "Internal Server Error")
    end
  end
end
