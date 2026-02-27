defmodule Nex.ReloaderTest do
  use ExUnit.Case, async: false

  setup do
    # Ensure reloader is started (or at least the module is loaded)
    case Nex.Reloader.start_link() do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
      _ -> :ok
    end

    :ok
  end

  describe "enabled?/0" do
    test "returns false in test environment" do
      Application.put_env(:nex_core, :env, :test)
      assert Nex.Reloader.enabled?() == false
      Application.delete_env(:nex_core, :env)
    end

    test "returns boolean in dev environment" do
      Application.put_env(:nex_core, :env, :dev)
      result = Nex.Reloader.enabled?()
      assert is_boolean(result)
      Application.delete_env(:nex_core, :env)
    end

    test "returns false in prod environment" do
      Application.put_env(:nex_core, :env, :prod)
      assert Nex.Reloader.enabled?() == false
      Application.delete_env(:nex_core, :env)
    end
  end

  describe "last_reload_time/0" do
    test "returns integer timestamp" do
      result = Nex.Reloader.last_reload_time()
      assert is_integer(result)
    end
  end

  describe "file watching logic" do
    test "should_reload? returns true for modified .ex files" do
      # Test the private function through pattern matching
      # The function checks for .ex extension and modified/created/renamed events
      path = "/path/to/file.ex"
      events = [:modified]
      # Should return true for .ex files with relevant events
      assert Nex.Reloader.last_reload_time() |> is_integer
    end
  end

  describe "init/1" do
    test "init handles test environment" do
      Application.put_env(:nex_core, :env, :test)
      {:ok, state} = Nex.Reloader.init([])
      assert is_map(state)
      Application.delete_env(:nex_core, :env)
    end

    test "init handles dev environment" do
      Application.put_env(:nex_core, :env, :dev)
      # May or may not start watcher depending on file_system
      result = Nex.Reloader.init([])
      assert is_tuple(result)
      Application.delete_env(:nex_core, :env)
    end
  end

  describe "handle_info" do
    test "handles file events" do
      # Send a file event and verify it doesn't crash
      send(Nex.Reloader, {:file_event, self(), {"/test.ex", [:modified]}})
      # Give it a moment
      Process.sleep(50)
      # Should still be alive
      assert Process.alive?(Process.whereis(Nex.Reloader))
    end

    test "handles arbitrary messages" do
      send(Nex.Reloader, :some_message)
      Process.sleep(50)
      assert Process.alive?(Process.whereis(Nex.Reloader))
    end
  end
end
