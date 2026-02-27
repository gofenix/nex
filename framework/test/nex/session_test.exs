defmodule Nex.SessionTest do
  use ExUnit.Case, async: false

  setup do
    Nex.Session.ensure_table()
    Process.delete(:nex_session_id)
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
end
