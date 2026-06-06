defmodule Nex.SessionTest do
  use ExUnit.Case, async: false

  setup do
    Nex.Session.ensure_table()
    Process.delete(:nex_session_id)
    # Provide a secret for session signing. Preserve original SECRET_KEY_BASE across tests.
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

  describe "get/2" do
    test "returns default when no session exists" do
      assert Nex.Session.get(:key, "default") == "default"
      assert Nex.Session.get(:missing) == nil
    end

    test "returns value from session when exists" do
      Process.put(:nex_session_id, "test_session_123")
      Nex.Session.put(:user_id, 42)

      assert Nex.Session.get(:user_id) == 42
    end
  end

  describe "put/2" do
    test "creates session and stores value" do
      Nex.Session.put(:key, "value")

      assert Nex.Session.get(:key) == "value"
    end

    test "stores different types" do
      Nex.Session.put(:int, 42)
      Nex.Session.put(:float, 3.14)
      Nex.Session.put(:map, %{a: 1})
      Nex.Session.put(:list, [1, 2, 3])

      assert Nex.Session.get(:int) == 42
      assert Nex.Session.get(:float) == 3.14
      assert Nex.Session.get(:map) == %{a: 1}
      assert Nex.Session.get(:list) == [1, 2, 3]
    end
  end

  describe "update/3" do
    test "updates value using function" do
      Nex.Session.put(:counter, 10)
      Nex.Session.update(:counter, 0, fn val -> val + 1 end)

      assert Nex.Session.get(:counter) == 11
    end

    test "uses default when key doesn't exist" do
      Nex.Session.update(:new_key, 100, fn val -> val + 1 end)

      assert Nex.Session.get(:new_key) == 101
    end
  end

  describe "delete/1" do
    test "deletes key from session" do
      Nex.Session.put(:key, "value")
      Nex.Session.delete(:key)

      assert Nex.Session.get(:key) == nil
    end
  end

  describe "clear/0" do
    test "clears all session data" do
      Nex.Session.put(:key1, "value1")
      Nex.Session.put(:key2, "value2")
      Nex.Session.clear()

      assert Nex.Session.get(:key1) == nil
      assert Nex.Session.get(:key2) == nil
    end
  end

  describe "session_id/0" do
    test "returns session ID after session is created" do
      Nex.Session.put(:user, "test")
      session_id = Nex.Session.session_id()
      assert is_binary(session_id)
    end
  end

  describe "ensure_table/0" do
    test "creates table if not exists" do
      Nex.Session.ensure_table()
      assert :ets.whereis(:nex_session_store) != :undefined
    end
  end

  describe "load_from_conn/1" do
    test "stores session ID from signed cookie in process dictionary" do
      signed = Phoenix.Token.sign(test_secret(), "nex.session", "loaded_sess_123")

      conn =
        Plug.Test.conn(:get, "/")
        |> Plug.Test.put_req_cookie("_nex_session", signed)
        |> Nex.Session.load_from_conn()

      assert Process.get(:nex_session_id) == "loaded_sess_123"
      assert is_struct(conn, Plug.Conn)
    end

    test "stores nil when no session cookie present" do
      conn = Plug.Test.conn(:get, "/") |> Nex.Session.load_from_conn()
      assert Process.get(:nex_session_id) == nil
      assert is_struct(conn, Plug.Conn)
    end

    test "stores nil for invalid session cookie" do
      _conn =
        Plug.Test.conn(:get, "/")
        |> Plug.Test.put_req_cookie("_nex_session", "not-a-valid-token")
        |> Nex.Session.load_from_conn()

      assert Process.get(:nex_session_id) == nil
    end
  end

  describe "persist_to_conn/1" do
    test "writes signed session cookie to pending cookies and applies it" do
      Process.put(:nex_session_id, "persist_session_abc")
      conn = Plug.Test.conn(:get, "/") |> Nex.Session.persist_to_conn()

      # Cookie goes to pending dict (Nex.Cookie.put), then apply_to_conn writes to conn.
      conn = Nex.Cookie.apply_to_conn(conn)

      assert is_map_key(conn.resp_cookies, "_nex_session")
      assert conn.resp_cookies["_nex_session"].value != ""
      assert conn.resp_cookies["_nex_session"].http_only == true
    end

    test "does not set cookie when no session exists" do
      Process.delete(:nex_session_id)
      conn = Plug.Test.conn(:get, "/") |> Nex.Session.persist_to_conn()
      conn = Nex.Cookie.apply_to_conn(conn)
      assert map_size(conn.resp_cookies) == 0
    end
  end

  describe "clear_process_state/0" do
    test "clears session ID from process dictionary" do
      Process.put(:nex_session_id, "about_to_clear")
      Nex.Session.clear_process_state()
      assert Process.get(:nex_session_id) == nil
    end
  end

  describe "load_from_conn with TTL expiry" do
    test "expired session cookie results in nil session ID" do
      original_ttl = Application.get_env(:nex_core, :session_ttl)
      Application.put_env(:nex_core, :session_ttl, 1)

      on_exit(fn ->
        if original_ttl do
          Application.put_env(:nex_core, :session_ttl, original_ttl)
        else
          Application.delete_env(:nex_core, :session_ttl)
        end
      end)

      signed = Phoenix.Token.sign(test_secret(), "nex.session", "old_session")
      :timer.sleep(1100)

      conn =
        Plug.Test.conn(:get, "/")
        |> Plug.Test.put_req_cookie("_nex_session", signed)
        |> Nex.Session.load_from_conn()

      assert Process.get(:nex_session_id) == nil
      assert is_struct(conn, Plug.Conn)
    end
  end

  defp test_secret, do: System.get_env("SECRET_KEY_BASE")
end
