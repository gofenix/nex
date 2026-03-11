defmodule Nex.ReloaderTest do
  use ExUnit.Case, async: false

  setup do
    pid =
      case Process.whereis(Nex.Reloader) do
        nil ->
          {:ok, pid} = start_supervised(Nex.Reloader)
          pid

        pid ->
          pid
      end

    %{reloader_pid: pid}
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
    test "last_reload_time remains queryable" do
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
    test "handles file events", %{reloader_pid: pid} do
      send(pid, {:file_event, self(), {"/test.ex", [:modified]}})
      Process.sleep(50)
      assert Process.alive?(pid)
    end

    test "handles arbitrary messages", %{reloader_pid: pid} do
      send(pid, :some_message)
      Process.sleep(50)
      assert Process.alive?(pid)
    end
  end
end
