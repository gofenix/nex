defmodule Nex.Handler.Dispatch do
  @moduledoc false

  alias Nex.Handler.{Api, Errors, Page, WebSocket}

  def route(conn, method, path) do
    cond do
      path == ["nex", "live-reload-ws"] ->
        WebSockAdapter.upgrade(conn, Nex.LiveReloadSocket, %{}, [])

      path == ["nex", "live-reload"] ->
        WebSocket.handle_live_reload(conn)

      match?(["static" | _], path) ->
        serve_static(conn)

      match?(["ws" | _], path) ->
        WebSocket.handle_user_websocket(conn, path)

      match?(["api" | _], path) ->
        Api.handle(conn, method, path)

      true ->
        Page.handle(conn, method, path)
    end
  end

  defp serve_static(conn) do
    static_dir = find_static_dir()

    if static_dir && File.dir?(static_dir) do
      opts =
        Plug.Static.init(
          at: "/static",
          from: static_dir,
          gzip: false
        )

      case Plug.Static.call(conn, opts) do
        %Plug.Conn{halted: true} = conn -> conn
        conn -> Errors.send_error_page(conn, 404, "File Not Found", nil)
      end
    else
      Errors.send_error_page(conn, 404, "File Not Found", nil)
    end
  end

  defp find_static_dir do
    case Application.get_env(:nex_core, :priv_dir) do
      nil ->
        app_module = Nex.Config.app_module()

        otp_app =
          app_module
          |> String.split(".")
          |> hd()
          |> Macro.underscore()
          |> String.to_existing_atom()

        case :code.priv_dir(otp_app) do
          {:error, _} -> Path.join(File.cwd!(), "priv/static")
          priv -> Path.join(to_string(priv), "static")
        end
    end
  rescue
    _ -> Path.join(File.cwd!(), "priv/static")
  end
end
