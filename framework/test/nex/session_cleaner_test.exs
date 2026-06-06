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

    test "cleanup removes expired session entries" do
      Nex.Session.ensure_table()

      # Insert an expired session entry directly into ETS
      past = System.system_time(:millisecond) - 1_000_000
      :ets.insert(:nex_session_store, {{"expired_sess", :key}, "value", past})

      # Insert a non-expired session entry
      future = System.system_time(:millisecond) + 1_000_000
      :ets.insert(:nex_session_store, {{"fresh_sess", :key}, "value", future})

      send(Nex.SessionCleaner, :cleanup)
      Process.sleep(100)

      assert :ets.lookup(:nex_session_store, {"expired_sess", :key}) == []
      assert :ets.lookup(:nex_session_store, {"fresh_sess", :key}) != []
    end

    test "handles missing session table gracefully" do
      # Delete the table if it exists, send cleanup, verify no crash
      case :ets.whereis(:nex_session_store) do
        :undefined -> :ok
        tid -> :ets.delete(tid)
      end

      send(Nex.SessionCleaner, :cleanup)
      Process.sleep(50)

      assert Process.alive?(Process.whereis(Nex.SessionCleaner))

      # Re-create table for other tests
      Nex.Session.ensure_table()
    end
  end
end
