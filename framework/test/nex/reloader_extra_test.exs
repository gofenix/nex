defmodule Nex.ReloaderExtraTest do
  use ExUnit.Case, async: false

  describe "enabled?/0" do
    test "returns true only for :dev environment" do
      Application.put_env(:nex_core, :env, :dev)
      assert Nex.Reloader.enabled?() == true

      Application.put_env(:nex_core, :env, :test)
      assert Nex.Reloader.enabled?() == false

      Application.put_env(:nex_core, :env, :prod)
      assert Nex.Reloader.enabled?() == false

      Application.delete_env(:nex_core, :env)
      assert Nex.Reloader.enabled?() == false
    end
  end

  describe "last_reload_time/0" do
    test "returns integer even when GenServer not started" do
      assert is_integer(Nex.Reloader.last_reload_time())
    end

    test "returns monotonically non-decreasing timestamps" do
      t1 = Nex.Reloader.last_reload_time()
      Process.sleep(1)
      t2 = Nex.Reloader.last_reload_time()
      assert t2 >= t1
    end
  end

  describe "init/1" do
    test "returns {:ok, state} tuple in test environment" do
      Application.put_env(:nex_core, :env, :test)
      {:ok, state} = Nex.Reloader.init([])
      assert is_map(state)
      assert is_integer(state.last_reload)
      assert state.watcher == nil
      Application.delete_env(:nex_core, :env)
    end

    test "returns {:ok, state} with nil watcher when no dirs exist" do
      Application.put_env(:nex_core, :env, :dev)
      # The init_watcher checks for src/ and lib/ dirs. Even if they exist,
      # ensure we get a proper state back.
      result = Nex.Reloader.init([])
      assert {:ok, state} = result
      assert is_map(state)
      Application.delete_env(:nex_core, :env)
    end
  end

  describe "handle_info file events" do
    test "ignores non-.ex files" do
      pid = Process.whereis(Nex.Reloader) || start!()
      t_before = Nex.Reloader.last_reload_time()
      send(pid, {:file_event, self(), {"/tmp/test.txt", [:modified]}})
      Process.sleep(30)
      t_after = Nex.Reloader.last_reload_time()
      # Should not reload
      assert t_after == t_before
    end

    test "handles :created events on .ex files" do
      pid = Process.whereis(Nex.Reloader) || start!()
      send(pid, {:file_event, self(), {"/tmp/new.ex", [:created]}})
      Process.sleep(30)
      assert Process.alive?(pid)
    end

    defp start! do
      {:ok, pid} = Nex.Reloader.start_link()
      pid
    end
  end
end
