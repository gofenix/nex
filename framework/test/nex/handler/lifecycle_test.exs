defmodule Nex.Handler.LifecycleTest do
  use ExUnit.Case, async: true
  import Plug.Test

  alias Nex.Handler.Lifecycle

  setup do
    Process.delete(:nex_pending_cookies)
    Process.delete(:nex_incoming_cookies)
    Process.delete(:nex_session_id)
    Process.delete(:nex_page_id)
    Nex.Session.ensure_table()

    original_secret = System.get_env("SECRET_KEY_BASE")
    System.put_env("SECRET_KEY_BASE", "test_secret_key_base_long_enough_for_phoenix_token_32chars")

    on_exit(fn ->
      if original_secret do
        System.put_env("SECRET_KEY_BASE", original_secret)
      else
        System.delete_env("SECRET_KEY_BASE")
      end
    end)

    :ok
  end

  describe "prepare/1" do
    test "loads cookies and session from conn" do
      signed = Phoenix.Token.sign("test_secret_key_base_long_enough_for_phoenix_token_32chars", "nex.session", "sess_abc")

      conn =
        conn(:get, "/")
        |> put_req_cookie("_nex_session", signed)
        |> Lifecycle.prepare()

      assert is_struct(conn, Plug.Conn)
      # Incoming cookies are loaded
      assert Process.get(:nex_incoming_cookies) != nil
      assert Process.get(:nex_session_id) == "sess_abc"
    end

    test "registers a before_send callback that persists session/cookies and clears state" do
      Nex.Cookie.put(:test_cookie, "cookie_value")
      Nex.Session.put(:sess_k, "sess_v")

      conn =
        conn(:get, "/")
        |> Lifecycle.prepare()
        # Trigger the before_send callbacks
        |> Plug.Conn.send_resp(200, "ok")

      # After response sent, process state should be cleared
      assert Process.get(:nex_pending_cookies) == nil
      assert Process.get(:nex_incoming_cookies) == nil
      assert Process.get(:nex_session_id) == nil
      assert Process.get(:nex_page_id) == nil

      # Cookie should be in the response
      assert map_size(conn.resp_cookies) > 0
    end
  end
end
