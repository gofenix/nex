defmodule Nex.Handler.ExtraTest do
  use ExUnit.Case, async: false
  import Plug.Test
  import Plug.Conn

  alias Nex.Handler

  setup do
    original_app = Application.get_env(:nex_core, :app_module)
    original_src = Application.get_env(:nex_core, :src_path)

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
    end)

    # Make route discovery resolve to nothing useful by default
    Application.put_env(:nex_core, :app_module, "HandlerExtraTest")
    Application.put_env(:nex_core, :src_path, "test/fixtures/nonexistent")
    Application.delete_env(:nex_core, :plugs)

    Nex.RouteDiscovery.clear_cache()

    Process.delete(:nex_pending_cookies)
    Process.delete(:nex_incoming_cookies)
    Process.delete(:nex_session_id)
    Process.delete(:nex_page_id)

    # Ensure Store + ETS table exist (other tests may have killed the GenServer)
    if :ets.whereis(:nex_store) == :undefined do
      if pid = Process.whereis(Nex.Store), do: Process.exit(pid, :kill)
      Nex.Store.start_link()
      Process.sleep(10)
    end

    # Ensure SECRET_KEY_BASE is set for session/CSRF signing
    unless System.get_env("SECRET_KEY_BASE") do
      System.put_env(
        "SECRET_KEY_BASE",
        "test_secret_key_base_long_enough_for_phoenix_token_32chars"
      )
    end

    :ok
  end

  test "handle/1 returns conn for GET / (404)" do
    conn = conn(:get, "/")
    result = Handler.handle(conn)
    assert is_struct(result, Plug.Conn)
    assert result.status == 404
  end

  test "handle/1 returns conn for POST to missing page" do
    conn =
      conn(:post, "/something", %{"name" => "test"})
      |> put_req_header("content-type", "application/x-www-form-urlencoded")

    result = Handler.handle(conn)
    assert is_struct(result, Plug.Conn)
    assert result.status in [403, 404]
  end

  test "handle/1 returns conn for GET /api/unknown" do
    conn = conn(:get, "/api/unknown")
    result = Handler.handle(conn)
    assert is_struct(result, Plug.Conn)
    assert result.status == 404
    assert Jason.decode!(result.resp_body) == %{"error" => "Not Found"}
  end

  test "handle/1 handles HEAD gracefully" do
    conn = conn(:head, "/")
    result = Handler.handle(conn)
    assert is_struct(result, Plug.Conn)
  end

  test "handle/1 handles OPTIONS gracefully" do
    conn = conn(:options, "/")
    result = Handler.handle(conn)
    assert is_struct(result, Plug.Conn)
    assert result.status == 405
  end

  test "handle/1 rescues exceptions and returns 500 error page" do
    # Use a middleware that raises to trigger the rescue path
    defmodule HandlerExtraTestApp.RaisingMiddleware do
      @behaviour Plug
      @impl true
      def init(opts), do: opts
      @impl true
      def call(_conn, _opts) do
        raise RuntimeError, "boom"
      end
    end

    on_exit(fn ->
      Application.delete_env(:nex_core, :plugs)
      purge(HandlerExtraTestApp.RaisingMiddleware)
    end)

    Application.put_env(:nex_core, :plugs, [HandlerExtraTestApp.RaisingMiddleware])

    conn = conn(:get, "/")
    result = Handler.handle(conn)
    assert is_struct(result, Plug.Conn)
    assert result.status == 500
  end

  test "handle/1 catches throw and returns 500 error page" do
    defmodule HandlerExtraTestApp.ThrowingMiddleware do
      @behaviour Plug
      @impl true
      def init(opts), do: opts
      @impl true
      def call(_conn, _opts) do
        throw(:oops)
      end
    end

    on_exit(fn ->
      Application.delete_env(:nex_core, :plugs)
      purge(HandlerExtraTestApp.ThrowingMiddleware)
    end)

    Application.put_env(:nex_core, :plugs, [HandlerExtraTestApp.ThrowingMiddleware])

    conn = conn(:get, "/")
    result = Handler.handle(conn)
    assert is_struct(result, Plug.Conn)
    assert result.status == 500
  end

  test "handle/1 respects conn.halted from middleware" do
    defmodule HandlerExtraTestApp.HaltingMiddleware do
      @behaviour Plug
      import Plug.Conn
      @impl true
      def init(opts), do: opts
      @impl true
      def call(conn, _opts) do
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(418, "I'm a teapot")
        |> halt()
      end
    end

    on_exit(fn ->
      Application.delete_env(:nex_core, :plugs)
      purge(HandlerExtraTestApp.HaltingMiddleware)
    end)

    Application.put_env(:nex_core, :plugs, [HandlerExtraTestApp.HaltingMiddleware])

    conn = conn(:get, "/anything")
    result = Handler.handle(conn)
    assert is_struct(result, Plug.Conn)
    assert result.status == 418
    assert result.resp_body == "I'm a teapot"
  end

  describe "Regression: bug fixes" do
    test "unknown HTTP method does not create new atoms (atom DoS prevention)" do
      conn = :get |> conn("/test") |> Map.put(:method, "CRAZYMETHOD123")
      result = Handler.handle(conn)
      assert is_struct(result, Plug.Conn)
      # Verify it routes gracefully — doesn't crash
      assert result.status in 200..599
    end
  end

  defp purge(module) do
    :code.delete(module)
    :code.purge(module)
  end
end
