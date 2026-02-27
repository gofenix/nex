defmodule Nex.RouterTest do
  use ExUnit.Case, async: true
  import Plug.Test
  
  alias Nex.Router

  describe "Nex.Router module" do
    test "module loads correctly" do
      assert Code.ensure_loaded?(Nex.Router)
    end

    test "uses Plug.Router" do
      assert function_exported?(Nex.Router, :init, 1)
      assert function_exported?(Nex.Router, :call, 2)
    end

    test "call/2 with GET request" do
      conn = conn(:get, "/")
      result = Router.call(conn, [])
      assert is_struct(result, Plug.Conn)
    end

    test "call/2 with POST request" do
      conn = conn(:post, "/api/test", %{"key" => "value"})
      result = Router.call(conn, [])
      assert is_struct(result, Plug.Conn)
    end

    test "call/2 with unknown path" do
      conn = conn(:get, "/unknown")
      result = Router.call(conn, [])
      assert is_struct(result, Plug.Conn)
    end
  end
end
