defmodule Nex.Handler.WebSocketTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias Nex.Handler.WebSocket

  describe "handle_live_reload/1" do
    test "returns JSON with reload time" do
      conn = conn(:get, "/nex/live-reload")
      result = WebSocket.handle_live_reload(conn)

      assert result.status == 200
      assert hd(get_resp_header(result, "content-type")) =~ "application/json"
      body = Jason.decode!(result.resp_body)
      assert is_map(body)
      assert Map.has_key?(body, "time")
      assert is_integer(body["time"])
    end
  end

  describe "handle_user_websocket/2" do
    test "returns 404 for unknown websocket path" do
      conn = conn(:get, "/ws/nonexistent")
      result = WebSocket.handle_user_websocket(conn, ["ws", "nonexistent"])
      assert is_struct(result, Plug.Conn)
      assert result.status == 404
    end
  end
end
