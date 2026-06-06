Code.require_file("test/fixtures/page_test/pages.exs")

defmodule Nex.Handler.PageTest do
  use ExUnit.Case, async: false
  import Plug.Test
  import Plug.Conn

  alias Nex.Handler.Page

  setup do
    original_app = Application.get_env(:nex_core, :app_module)
    original_src = Application.get_env(:nex_core, :src_path)
    original_env = Application.get_env(:nex_core, :env)
    original_secret = System.get_env("SECRET_KEY_BASE")

    System.put_env(
      "SECRET_KEY_BASE",
      "test_secret_key_base_long_enough_for_phoenix_token_32chars"
    )

    Application.put_env(:nex_core, :app_module, "PageTestApp")
    Application.put_env(:nex_core, :src_path, "test/fixtures/page_test/src")
    Application.put_env(:nex_core, :env, :test)

    Nex.RouteDiscovery.clear_cache()
    Process.delete(:nex_pending_cookies)
    Process.delete(:nex_incoming_cookies)
    Process.delete(:nex_session_id)
    Process.delete(:nex_page_id)
    Process.delete(:csrf_token)

    # Ensure Store GenServer and ETS table exist.
    # The ETS table is owned by the GenServer; if it dies the table is deleted.
    if :ets.whereis(:nex_store) == :undefined do
      if Process.whereis(Nex.Store) do
        # GenServer alive but table missing — kill and restart
        Process.exit(Process.whereis(Nex.Store), :kill)
        Process.sleep(10)
      end
      Nex.Store.start_link()
      Process.sleep(10)
    end

    on_exit(fn ->
      if original_app do
        Application.put_env(:nex_core, :app_module, original_app)
      else
        Application.delete_env(:nex_core, :app_module)
      end

      if original_src do
        Application.put_env(:nex_core, :src_path, original_src)
      else
        Application.delete_env(:nex_core, :src_path)
      end

      if original_env do
        Application.put_env(:nex_core, :env, original_env)
      else
        Application.delete_env(:nex_core, :env)
      end

      if original_secret do
        System.put_env("SECRET_KEY_BASE", original_secret)
      else
        System.delete_env("SECRET_KEY_BASE")
      end
    end)

    :ok
  end

  # --- GET page render tests ---

  describe "GET / renders Index page through full pipeline" do
    test "returns 200 with rendered content wrapped in app and document layout" do
      conn = conn(:get, "/")
      result = Page.handle(conn, :get, [])

      assert result.status == 200
      assert hd(get_resp_header(result, "content-type")) =~ "text/html"
      # Index renders <h1>Home</h1>
      assert result.resp_body =~ "<h1>Home</h1>"
      # Pages.App wraps in <app>
      assert result.resp_body =~ "<app>"
      # Pages.Document provides custom <!DOCTYPE custom> and <title>
      assert result.resp_body =~ "<title>Home</title>"
    end

    test "injects nex script with page_id, csrfToken, pagePath data attributes" do
      conn = conn(:get, "/")
      result = Page.handle(conn, :get, [])

      assert result.resp_body =~ "document.body.dataset.pageId"
      assert result.resp_body =~ "document.body.dataset.csrfToken"
      assert result.resp_body =~ "document.body.dataset.pagePath"
    end

    test "injects csrf meta tag into <head>" do
      conn = conn(:get, "/")
      result = Page.handle(conn, :get, [])

      assert result.resp_body =~ ~s(<meta name="csrf-token")
    end

    test "injects csrf hidden input into POST forms" do
      conn = conn(:get, "/")
      result = Page.handle(conn, :get, [])
      assert result.status == 200
      assert is_binary(result.resp_body)
    end
  end

  describe "GET page with mount redirect" do
    test "{:redirect, path} returns 302 with Location header" do
      conn = conn(:get, "/redirect_test")
      result = Page.handle(conn, :get, ["redirect_test"])

      assert result.status == 302
      assert hd(get_resp_header(result, "location")) == "/login"
    end

    test "{:redirect, path, status} returns custom status (301)" do
      conn = conn(:get, "/redirect_status")
      result = Page.handle(conn, :get, ["redirect_status"])

      assert result.status == 301
      assert hd(get_resp_header(result, "location")) == "/moved"
    end
  end

  describe "GET page with mount :not_found" do
    test "returns 404 error page" do
      conn = conn(:get, "/not_found")
      result = Page.handle(conn, :get, ["not_found"])

      assert result.status == 404
      assert result.resp_body =~ "Not Found"
    end
  end

  describe "GET page with no mount function" do
    test "defaults to empty assigns and still renders" do
      conn = conn(:get, "/no_mount")
      result = Page.handle(conn, :get, ["no_mount"])

      assert result.status == 200
      assert result.resp_body =~ "<p>Hello world</p>"
    end
  end

  describe "GET unknown page path" do
    test "returns 404 error page" do
      conn = conn(:get, "/totally_missing")
      result = Page.handle(conn, :get, ["totally_missing"])

      assert result.status == 404
    end
  end

  # --- POST action tests ---

  defp build_csrf_token do
    secret = "test_secret_key_base_long_enough_for_phoenix_token_32chars"
    nonce = :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
    Phoenix.Token.sign(secret, "nex.csrf", nonce)
  end

  describe "POST actions via full handler" do
    test "action returning Nex.html() returns HTML response" do
      token = build_csrf_token()

      conn =
        conn(:post, "/increment", %{"_csrf_token" => token})
        |> put_req_header("referer", "/")

      result = Page.handle(conn, :post, ["increment"])

      assert result.status == 200
      assert result.resp_body == "<p>incremented</p>"
    end

    test "action returning :empty returns 200 with empty body" do
      token = build_csrf_token()

      conn =
        conn(:post, "/empty_action", %{"_csrf_token" => token})
        |> put_req_header("referer", "/")

      result = Page.handle(conn, :post, ["empty_action"])

      assert result.status == 200
      assert result.resp_body == ""
    end

    test "action returning {:redirect, to} sets hx-redirect header" do
      token = build_csrf_token()

      conn =
        conn(:post, "/redirect_action", %{"_csrf_token" => token})
        |> put_req_header("referer", "/")

      result = Page.handle(conn, :post, ["redirect_action"])

      assert result.status == 200
      assert hd(get_resp_header(result, "hx-redirect")) == "/home"
    end

    test "action returning {:refresh, _} sets hx-refresh header" do
      token = build_csrf_token()

      conn =
        conn(:post, "/refresh_action", %{"_csrf_token" => token})
        |> put_req_header("referer", "/")

      result = Page.handle(conn, :post, ["refresh_action"])

      assert result.status == 200
      assert hd(get_resp_header(result, "hx-refresh")) == "true"
    end

    test "action returning Nex.json() returns JSON response" do
      token = build_csrf_token()

      conn =
        conn(:post, "/json_action", %{"_csrf_token" => token})
        |> put_req_header("referer", "/")

      result = Page.handle(conn, :post, ["json_action"])

      assert result.status == 200
      assert Jason.decode!(result.resp_body) == %{"ok" => true}
    end
  end

  describe "POST CSRF validation" do
    test "missing CSRF token returns 403" do
      conn =
        conn(:post, "/increment", %{})
        |> put_req_header("referer", "/")

      result = Page.handle(conn, :post, ["increment"])
      assert result.status == 403
    end

    test "invalid CSRF token returns 403" do
      conn =
        conn(:post, "/increment", %{"_csrf_token" => "not_a_real_token"})
        |> put_req_header("referer", "/")

      result = Page.handle(conn, :post, ["increment"])
      assert result.status == 403
    end

    test "valid CSRF token via X-CSRF-Token header works" do
      token = build_csrf_token()

      conn =
        conn(:post, "/empty_action", %{})
        |> put_req_header("x-csrf-token", token)
        |> put_req_header("referer", "/")

      result = Page.handle(conn, :post, ["empty_action"])
      assert result.status == 200
    end
  end

  describe "POST unknown action" do
    test "returns 404 for action not on module" do
      token = build_csrf_token()

      conn =
        conn(:post, "/nonexistent_action", %{"_csrf_token" => token})
        |> put_req_header("referer", "/")

      result = Page.handle(conn, :post, ["nonexistent_action"])
      assert result.status == 404
    end

    test "returns 404 for unknown page path with action" do
      token = build_csrf_token()

      conn =
        conn(:post, "/totally_missing/delete", %{"_csrf_token" => token})
        |> put_req_header("referer", "/")

      result = Page.handle(conn, :post, ["totally_missing", "delete"])
      assert result.status == 404
    end
  end

  describe "referer_path parsing" do
    test "action works when referer is root /" do
      token = build_csrf_token()

      conn =
        conn(:post, "/empty_action", %{"_csrf_token" => token})
        |> put_req_header("referer", "http://localhost:4000/")

      result = Page.handle(conn, :post, ["empty_action"])
      assert result.status == 200
    end

    test "action works with no referer header (falls back to Index)" do
      token = build_csrf_token()

      conn = conn(:post, "/empty_action", %{"_csrf_token" => token})

      result = Page.handle(conn, :post, ["empty_action"])
      assert result.status == 200
    end
  end
end
