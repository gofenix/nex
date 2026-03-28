defmodule Nex.Handler.WebSocket do
  @moduledoc false

  import Plug.Conn

  alias Nex.Handler.Errors

  def handle_live_reload(conn) do
    last_reload = Nex.Reloader.last_reload_time()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{time: last_reload}))
  end

  def handle_user_websocket(conn, path) do
    conn = Plug.Conn.fetch_query_params(conn)
    ws_path = tl(path)

    case Nex.RouteDiscovery.resolve(:api, ws_path) do
      {:ok, module, path_params} ->
        if function_exported?(module, :handle_message, 2) do
          query = Map.merge(conn.query_params, path_params)

          initial_state =
            module.initial_state(%{
              cookies: Nex.Cookie.all(),
              params: path_params,
              path: conn.request_path,
              query: query
            })

          WebSockAdapter.upgrade(conn, Nex.WebSocket.Adapter, {module, initial_state}, [])
        else
          Errors.send_error_page(conn, 404, "Not Found", nil)
        end

      :error ->
        Errors.send_error_page(conn, 404, "Not Found", nil)
    end
  end
end
