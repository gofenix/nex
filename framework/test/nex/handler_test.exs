defmodule Nex.HandlerTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias Nex.Handler

  setup do
    Process.delete(:nex_pending_cookies)
    Process.delete(:nex_incoming_cookies)
    :ok
  end

  describe "Nex.Handler module" do
    test "module loads correctly" do
      assert Code.ensure_loaded?(Nex.Handler)
    end

    test "exports handle/1 function" do
      assert function_exported?(Nex.Handler, :handle, 1)
    end
  end

  describe "handle/1 with different paths" do
    test "GET / returns conn" do
      conn = conn(:get, "/")
      result = Handler.handle(conn)
      assert is_struct(result, Plug.Conn)
    end

    test "POST / returns conn" do
      conn =
        conn(:post, "/", %{"name" => "test"})
        |> put_req_header("content-type", "application/x-www-form-urlencoded")

      result = Handler.handle(conn)
      assert is_struct(result, Plug.Conn)
    end

    test "GET /unknown/path returns conn" do
      conn = conn(:get, "/unknown/path")
      result = Handler.handle(conn)
      assert is_struct(result, Plug.Conn)
    end

    test "GET /api/test returns conn" do
      conn = conn(:get, "/api/test")
      result = Handler.handle(conn)
      assert is_struct(result, Plug.Conn)
    end

    test "GET /static/style.css returns conn" do
      conn = conn(:get, "/static/style.css")
      result = Handler.handle(conn)
      assert is_struct(result, Plug.Conn)
    end

    test "GET /ws/chat returns conn" do
      conn = conn(:get, "/ws/chat")
      result = Handler.handle(conn)
      assert is_struct(result, Plug.Conn)
    end

    test "GET /nex/live-reload returns conn" do
      conn = conn(:get, "/nex/live-reload")
      result = Handler.handle(conn)
      assert is_struct(result, Plug.Conn)
    end

    test "DELETE request returns conn" do
      conn = conn(:delete, "/item/1")
      result = Handler.handle(conn)
      assert is_struct(result, Plug.Conn)
    end

    test "PUT request returns conn" do
      conn = conn(:put, "/item/1")
      result = Handler.handle(conn)
      assert is_struct(result, Plug.Conn)
    end

    test "PATCH request returns conn" do
      conn = conn(:patch, "/item/1")
      result = Handler.handle(conn)
      assert is_struct(result, Plug.Conn)
    end
  end
end
