defmodule Nex.Handler.StreamTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias Nex.Handler.Stream
  alias Nex.Response

  describe "send_response/2 for regular (non-SSE)" do
    test "sends a text response" do
      conn = conn(:get, "/")
      resp = %Response{status: 200, body: "hello", content_type: "text/plain"}

      result = Stream.send_response(conn, resp)

      assert result.status == 200
      assert result.resp_body == "hello"
      assert get_resp_header(result, "content-type") == ["text/plain; charset=utf-8"]
    end

    test "sends a JSON response and encodes non-binary body" do
      conn = conn(:get, "/")
      resp = %Response{status: 201, body: %{ok: true}, content_type: "application/json"}

      result = Stream.send_response(conn, resp)

      assert result.status == 201
      assert Jason.decode!(result.resp_body) == %{"ok" => true}
    end

    test "handles nil body as empty string" do
      conn = conn(:get, "/")
      resp = %Response{status: 204, body: nil, content_type: nil}

      result = Stream.send_response(conn, resp)

      assert result.status == 204
      assert result.resp_body == ""
    end

    test "applies custom headers" do
      conn = conn(:get, "/")

      resp = %Response{
        status: 200,
        body: "ok",
        content_type: "text/plain",
        headers: %{"x-custom" => "value"}
      }

      result = Stream.send_response(conn, resp)

      assert get_resp_header(result, "x-custom") == ["value"]
    end
  end

  describe "handle_regular_response/2" do
    test "sets content-type and sends body" do
      conn = conn(:get, "/")
      resp = %Response{status: 200, body: "body", content_type: "text/html"}

      result = Stream.handle_regular_response(conn, resp)
      assert result.status == 200
      assert result.resp_body == "body"
      assert hd(get_resp_header(result, "content-type")) =~ "text/html"
    end
  end

  describe "handle_sse_response/2" do
    test "streams SSE formatted chunks" do
      conn = conn(:get, "/")

      resp = %Response{
        status: 200,
        content_type: "text/event-stream",
        body: fn send_fn ->
          send_fn.("hello")
          send_fn.(%{event: "update", data: %{id: 1}})
          send_fn.(%{user: "alice"})
        end
      }

      result = Stream.handle_sse_response(conn, resp)

      assert result.status == 200
      assert get_resp_header(result, "content-type") == ["text/event-stream; charset=utf-8"]
      assert get_resp_header(result, "cache-control") == ["no-cache, no-transform"]
      assert get_resp_header(result, "connection") == ["keep-alive"]
    end

    test "handles SSE with custom headers" do
      conn = conn(:get, "/")

      resp = %Response{
        status: 200,
        content_type: "text/event-stream",
        headers: %{"x-stream-id" => "s1"},
        body: fn _send_fn -> :ok end
      }

      result = Stream.send_response(conn, resp)
      assert get_resp_header(result, "x-stream-id") == ["s1"]
    end

    test "catches errors inside the streaming callback" do
      conn = conn(:get, "/")

      resp = %Response{
        status: 200,
        content_type: "text/event-stream",
        body: fn _send_fn -> raise "boom" end
      }

      # Should not raise - errors are logged and swallowed
      result = Stream.handle_sse_response(conn, resp)
      assert result.status == 200
    end
  end
end
