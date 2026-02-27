defmodule Nex.FlashTest do
  use ExUnit.Case, async: true

  setup do
    # Set a test session ID for the process
    Process.put(:nex_session_id, "test_session_123")
    :ok
  end

  describe "put/2" do
    test "stores flash message in session" do
      assert :ok = Nex.Flash.put(:info, "Test message")
      # Verify the flash was stored in session
      assert Nex.Session.get(:__nex_flash__, %{}) |> Map.get(:info) == "Test message"
    end

    test "stores multiple flash messages" do
      Nex.Flash.put(:info, "Info message")
      Nex.Flash.put(:success, "Success message")
      Nex.Flash.put(:error, "Error message")

      flash = Nex.Session.get(:__nex_flash__, %{})
      assert flash.info == "Info message"
      assert flash.success == "Success message"
      assert flash.error == "Error message"
    end

    test "overwrites existing flash message of same type" do
      Nex.Flash.put(:info, "First message")
      Nex.Flash.put(:info, "Second message")

      assert Nex.Flash.get(:info) == "Second message"
    end

    test "accepts various atom types" do
      assert :ok = Nex.Flash.put(:info, "message")
      assert :ok = Nex.Flash.put(:success, "message")
      assert :ok = Nex.Flash.put(:warning, "message")
      assert :ok = Nex.Flash.put(:error, "message")
      assert :ok = Nex.Flash.put(:custom, "message")
    end
  end

  describe "get/1" do
    test "retrieves flash message without clearing" do
      Nex.Flash.put(:info, "Test message")

      assert Nex.Flash.get(:info) == "Test message"
      # Should still be there after get
      assert Nex.Flash.peek_all() |> Map.get(:info) == "Test message"
    end

    test "returns nil for non-existent flash type" do
      assert Nex.Flash.get(:nonexistent) == nil
    end
  end

  describe "pop_all/0" do
    test "returns all flash messages and clears them" do
      Nex.Flash.put(:info, "Info message")
      Nex.Flash.put(:success, "Success message")

      flash = Nex.Flash.pop_all()

      assert flash.info == "Info message"
      assert flash.success == "Success message"
      # Should be cleared now
      assert Nex.Flash.peek_all() == %{}
    end

    test "returns empty map when no flash messages" do
      assert Nex.Flash.pop_all() == %{}
    end
  end

  describe "peek_all/0" do
    test "returns all flash messages without clearing" do
      Nex.Flash.put(:info, "Info message")
      Nex.Flash.put(:warning, "Warning message")

      flash = Nex.Flash.peek_all()

      assert flash.info == "Info message"
      assert flash.warning == "Warning message"
      # Should NOT be cleared
      assert Nex.Flash.peek_all() |> Map.has_key?(:info)
    end
  end

  describe "clear/0" do
    test "clears all flash messages" do
      Nex.Flash.put(:info, "Test")
      Nex.Flash.put(:error, "Error")

      assert :ok = Nex.Flash.clear()

      assert Nex.Flash.peek_all() == %{}
    end

    test "clearing empty flash is idempotent" do
      assert :ok = Nex.Flash.clear()
      assert :ok = Nex.Flash.clear()
    end
  end
end
