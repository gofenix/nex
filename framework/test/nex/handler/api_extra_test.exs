Code.require_file("test/fixtures/page_test/pages.exs")

defmodule Nex.Handler.ApiExtraTest do
  use ExUnit.Case, async: false
  import Plug.Test
  import Plug.Conn

  alias Nex.Handler.Api

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

    # Ensure Store ETS table exists
    if :ets.whereis(:nex_store) == :undefined do
      if Process.whereis(Nex.Store), do: Process.exit(Process.whereis(Nex.Store), :kill)
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

  test "GET /api/health returns JSON via resolved module" do
    conn = conn(:get, "/api/health")
    result = Api.handle(conn, :get, ["api", "health"])

    assert result.status == 200
    assert Jason.decode!(result.resp_body) == %{"status" => "ok"}
    assert hd(get_resp_header(result, "content-type")) =~ "application/json"
  end

  test "POST /api/health returns 201 JSON" do
    conn = conn(:post, "/api/health")
    result = Api.handle(conn, :post, ["api", "health"])

    assert result.status == 201
    assert Jason.decode!(result.resp_body) == %{"created" => true}
  end

  test "returns 404 JSON for unknown API path" do
    conn = conn(:get, "/api/notfound")
    result = Api.handle(conn, :get, ["api", "notfound"])

    assert result.status == 404
    assert Jason.decode!(result.resp_body) == %{"error" => "Not Found"}
  end

  test "returns 405 Method Not Allowed for unsupported method" do
    conn = conn(:delete, "/api/health")
    result = Api.handle(conn, :delete, ["api", "health"])

    assert result.status == 405
    assert Jason.decode!(result.resp_body) == %{"error" => "Method Not Allowed"}
  end

  test "path without 'api' prefix works (already stripped by Dispatch)" do
    # Simulating what Dispatch does: strips "api" segment before calling Api.handle
    conn = conn(:get, "/health")
    result = Api.handle(conn, :get, ["health"])

    assert result.status == 200
    assert Jason.decode!(result.resp_body) == %{"status" => "ok"}
  end
end
