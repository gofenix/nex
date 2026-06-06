defmodule Nex.CookieTest do
  use ExUnit.Case, async: true
  alias Nex.Cookie

  setup do
    Process.delete(:nex_pending_cookies)
    Process.delete(:nex_incoming_cookies)
    :ok
  end

  describe "put/3" do
    test "stores cookie in process dictionary" do
      Cookie.put(:session_id, "abc123")

      pending = Process.get(:nex_pending_cookies)
      assert is_list(pending)
      assert length(pending) == 1

      [cookie] = pending
      assert cookie.name == "session_id"
      assert cookie.value == "abc123"
    end

    test "returns the value" do
      assert Cookie.put(:token, "xyz") == "xyz"
    end

    test "accepts options" do
      Cookie.put(:session, "value", max_age: 3600, http_only: true, secure: true)

      [cookie] = Process.get(:nex_pending_cookies)
      assert cookie.max_age == 3600
      assert cookie.http_only == true
      assert cookie.secure == true
    end

    test "appends to existing pending cookies" do
      Cookie.put(:first, "1")
      Cookie.put(:second, "2")

      pending = Process.get(:nex_pending_cookies)
      assert length(pending) == 2
    end

    test "put with path option" do
      Cookie.put(:path_test, "value", path: "/")
      pending = Process.get(:nex_pending_cookies)
      assert length(pending) == 1
    end

    test "put with domain option" do
      Cookie.put(:domain_test, "value", domain: "example.com")
      pending = Process.get(:nex_pending_cookies)
      assert length(pending) == 1
    end
  end

  describe "delete/2" do
    test "marks cookie for deletion" do
      Cookie.delete(:session_id)

      [cookie] = Process.get(:nex_pending_cookies)
      assert cookie.name == "session_id"
      assert cookie.delete == true
      assert cookie.max_age == 0
    end

    test "returns :ok" do
      assert Cookie.delete(:token) == :ok
    end
  end

  describe "get/2" do
    test "returns default for missing cookie" do
      assert Cookie.get(:nonexistent) == nil
      assert Cookie.get(:nonexistent, "default") == "default"
    end

    test "returns cookie value when present" do
      Process.put(:nex_incoming_cookies, %{"session" => "value"})

      assert Cookie.get(:session) == "value"
    end

    test "get with default for missing key" do
      Process.put(:nex_incoming_cookies, %{})
      assert Cookie.get(:missing, "default_value") == "default_value"
    end
  end

  describe "all/0" do
    test "returns all cookies" do
      Process.put(:nex_incoming_cookies, %{"a" => "1", "b" => "2"})

      assert Cookie.all() == %{"a" => "1", "b" => "2"}
    end

    test "returns empty map when no cookies" do
      assert Cookie.all() == %{}
    end
  end

  describe "clear_process_state/0" do
    test "clears pending and incoming cookies from process" do
      Process.put(:nex_pending_cookies, [%{name: "test"}])
      Process.put(:nex_incoming_cookies, %{"test" => "value"})

      Cookie.clear_process_state()

      assert Process.get(:nex_pending_cookies) == nil
      assert Process.get(:nex_incoming_cookies) == nil
    end
  end

  describe "load_from_conn/1" do
    test "stores incoming cookies from conn into process dictionary" do
      conn =
        Plug.Test.conn(:get, "/")
        |> Plug.Test.put_req_cookie("user_id", "42")
        |> Plug.Test.put_req_cookie("theme", "dark")
        |> Cookie.load_from_conn()

      assert Process.get(:nex_incoming_cookies) == %{"user_id" => "42", "theme" => "dark"}
      assert is_struct(conn, Plug.Conn)
    end

    test "handles conns with no cookies" do
      conn = Plug.Test.conn(:get, "/") |> Cookie.load_from_conn()
      assert Process.get(:nex_incoming_cookies) == %{}
      assert is_struct(conn, Plug.Conn)
    end
  end

  describe "apply_to_conn/1" do
    test "applies pending put cookies to the response" do
      Cookie.put(:session, "abc123", max_age: 3600)
      Cookie.put(:theme, "light")

      conn = Plug.Test.conn(:get, "/") |> Cookie.apply_to_conn()

      assert map_size(conn.resp_cookies) == 2
      assert conn.resp_cookies["session"].value == "abc123"
      assert conn.resp_cookies["session"].max_age == 3600
      assert conn.resp_cookies["theme"].value == "light"
    end

    test "applies pending delete cookies with max_age=0" do
      Cookie.delete(:session)

      conn = Plug.Test.conn(:get, "/") |> Cookie.apply_to_conn()

      assert conn.resp_cookies["session"].value == ""
      assert conn.resp_cookies["session"].max_age == 0
    end

    test "returns conn unchanged when no pending cookies" do
      conn = Plug.Test.conn(:get, "/")
      result = Cookie.apply_to_conn(conn)
      assert map_size(result.resp_cookies) == 0
    end

    test "includes domain option when provided" do
      Cookie.put(:c, "v", domain: "example.com")

      conn = Plug.Test.conn(:get, "/") |> Cookie.apply_to_conn()
      assert conn.resp_cookies["c"].domain == "example.com"
    end
  end
end
