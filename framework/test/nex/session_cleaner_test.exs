defmodule Nex.SessionCleanerTest do
  use ExUnit.Case, async: false

  setup do
    # Ensure session cleaner is running
    case Nex.SessionCleaner.start_link() do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    :ok
  end

  describe "Nex.SessionCleaner" do
    test "starts and runs" do
      pid = Process.whereis(Nex.SessionCleaner)
      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "handles cleanup message" do
      # Send a cleanup message - it should handle it without crashing
      send(Nex.SessionCleaner, :cleanup)

      # Give it a moment to process
      Process.sleep(100)

      # Should still be alive
      assert Process.alive?(Process.whereis(Nex.SessionCleaner))
    end

    test "handles arbitrary info messages" do
      # Should not crash on random messages
      send(Nex.SessionCleaner, :some_unknown_message)
      Process.sleep(50)

      assert Process.alive?(Process.whereis(Nex.SessionCleaner))
    end

    test "handles tuple info messages" do
      send(Nex.SessionCleaner, {:some, :tuple})
      Process.sleep(50)

      assert Process.alive?(Process.whereis(Nex.SessionCleaner))
    end

    test "handles pid info messages" do
      send(Nex.SessionCleaner, self())
      Process.sleep(50)

      assert Process.alive?(Process.whereis(Nex.SessionCleaner))
    end

    test "module is loaded with GenServer behavior" do
      assert Code.ensure_loaded?(Nex.SessionCleaner)
      assert function_exported?(Nex.SessionCleaner, :start_link, 1)
      assert function_exported?(Nex.SessionCleaner, :init, 1)
      assert function_exported?(Nex.SessionCleaner, :handle_info, 2)
    end
  end
end
