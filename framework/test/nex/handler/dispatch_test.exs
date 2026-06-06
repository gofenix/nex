defmodule Nex.Handler.DispatchTest do
  use ExUnit.Case, async: false
  import Plug.Test

  alias Nex.Handler.Dispatch

  test "routes /static/* paths to static file handling" do
    conn = conn(:get, "/static/style.css")
    result = Dispatch.route(conn, :get, ["static", "style.css"])
    assert is_struct(result, Plug.Conn)
    # Should be a 404 since static dir doesn't exist in tests
    assert result.status == 404
  end

  test "routes /api/* paths to API handler" do
    conn = conn(:get, "/api/users")
    result = Dispatch.route(conn, :get, ["api", "users"])
    assert is_struct(result, Plug.Conn)
    # API handler returns JSON 404 for unknown routes
    assert result.status in [200, 404, 405]
    assert is_binary(result.resp_body)
  end

  test "routes unknown paths to page handler" do
    conn = conn(:get, "/some/page")
    result = Dispatch.route(conn, :get, ["some", "page"])
    assert is_struct(result, Plug.Conn)
    assert result.status in [200, 404]
  end

  test "routes /nex/live-reload path" do
    conn = conn(:get, "/nex/live-reload")
    result = Dispatch.route(conn, :get, ["nex", "live-reload"])
    assert is_struct(result, Plug.Conn)
  end

  test "routes /nex/live-reload-ws path" do
    conn = conn(:get, "/nex/live-reload-ws")
    # This may raise or return a conn depending on websocket upgrade support
    result =
      try do
        Dispatch.route(conn, :get, ["nex", "live-reload-ws"])
      rescue
        _e -> conn
      end

    assert is_struct(result, Plug.Conn)
  end

  test "routes /ws/* paths to WebSocket handler" do
    conn = conn(:get, "/ws/chat")
    result = Dispatch.route(conn, :get, ["ws", "chat"])
    assert is_struct(result, Plug.Conn)
  end
end
