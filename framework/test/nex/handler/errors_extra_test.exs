defmodule Nex.Handler.ErrorsExtraTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias Nex.Handler.Errors

  describe "send_json_error/3" do
    test "returns JSON error with given status and message" do
      conn = conn(:get, "/whatever") |> Errors.send_json_error(418, "I'm a teapot")

      assert conn.status == 418
      assert hd(get_resp_header(conn, "content-type")) =~ "application/json"
      assert Jason.decode!(conn.resp_body) == %{"error" => "I'm a teapot"}
    end
  end

  describe "send_error_page/4 JSON variant" do
    test "API path returns JSON error" do
      conn = conn(:get, "/api/users") |> Errors.send_error_page(404, "Not Found", nil)

      assert conn.status == 404
      assert hd(get_resp_header(conn, "content-type")) =~ "application/json"
      assert Jason.decode!(conn.resp_body) == %{"error" => "Not Found"}
    end

    test "Accept: application/json returns JSON error" do
      conn =
        conn(:get, "/page")
        |> put_req_header("accept", "application/json")
        |> Errors.send_error_page(403, "Forbidden", nil)

      assert conn.status == 403
      assert hd(get_resp_header(conn, "content-type")) =~ "application/json"
    end
  end

  describe "send_error_page/4 HTMX variant" do
    test "HX-Request returns inline HTML error" do
      conn =
        conn(:get, "/page")
        |> put_req_header("hx-request", "true")
        |> Errors.send_error_page(400, "Bad Request", nil)

      assert conn.status == 400
      assert hd(get_resp_header(conn, "content-type")) =~ "text/html"
      assert conn.resp_body =~ "Error 400"
      assert conn.resp_body =~ "Bad Request"
      assert conn.resp_body =~ "bg-red-100"
    end
  end

  describe "send_error_page/4 fallback HTML variant" do
    test "plain request returns default HTML error page" do
      conn = conn(:get, "/missing") |> Errors.send_error_page(404, "Not Found", nil)

      assert conn.status == 404
      assert hd(get_resp_header(conn, "content-type")) =~ "text/html"
      assert conn.resp_body =~ "<!DOCTYPE html>"
      assert conn.resp_body =~ "Not Found"
    end

    test "dev mode includes exception details when error is provided" do
      original_env = Application.get_env(:nex_core, :env)
      Application.put_env(:nex_core, :env, :dev)

      on_exit(fn ->
        if original_env do
          Application.put_env(:nex_core, :env, original_env)
        else
          Application.delete_env(:nex_core, :env)
        end
      end)

      conn =
        conn(:get, "/boom")
        |> Errors.send_error_page(500, "Internal Server Error", RuntimeError.exception("boom"))

      assert conn.status == 500
      assert conn.resp_body =~ "RuntimeError"
      assert conn.resp_body =~ "boom"
      assert conn.resp_body =~ "Exception"
      assert conn.resp_body =~ "Request"
    end

    test "non-dev mode does not include stacktrace details" do
      original_env = Application.get_env(:nex_core, :env)
      Application.put_env(:nex_core, :env, :prod)

      on_exit(fn ->
        if original_env do
          Application.put_env(:nex_core, :env, original_env)
        else
          Application.delete_env(:nex_core, :env)
        end
      end)

      conn =
        conn(:get, "/boom")
        |> Errors.send_error_page(500, "Internal Server Error", RuntimeError.exception("boom"))

      assert conn.status == 500
      refute conn.resp_body =~ "RuntimeError"
      refute conn.resp_body =~ "Stacktrace"
    end

    test "escapes HTML in error messages to prevent XSS" do
      conn =
        conn(:get, "/x")
        |> Errors.send_error_page(400, "<script>alert(1)</script>", nil)

      refute conn.resp_body =~ "<script>alert(1)</script>"
      # Should be escaped
      assert conn.resp_body =~ "&lt;script&gt;"
    end
  end
end
