defmodule NexBase.RepoTest do
  use ExUnit.Case, async: true

  setup do
    Application.delete_env(:nex_base, :default_conn)
    Application.delete_env(:nex_base, :repo_config)
    Application.delete_env(:nex_base, :adapter)
    :ok
  end

  describe "NexBase.Repo" do
    test "module loads correctly" do
      assert Code.ensure_loaded?(NexBase.Repo)
    end

    test "child_spec with Conn struct" do
      conn = NexBase.init(url: "sqlite::memory:")
      spec = NexBase.Repo.child_spec(conn)
      assert spec.id == {NexBase.Repo, conn.name}
      assert spec.type == :supervisor
    end

    test "child_spec with options list requires init" do
      assert_raise RuntimeError, fn ->
        NexBase.Repo.child_spec([])
      end
    end

    test "start_link with options list requires init" do
      assert_raise RuntimeError, fn ->
        NexBase.Repo.start_link([])
      end
    end
  end

  describe "NexBase.Repo.Postgres" do
    test "module loads correctly" do
      assert Code.ensure_loaded?(NexBase.Repo.Postgres)
    end

    test "init/2 with config" do
      config = [url: "postgres://localhost/test"]
      {:ok, result} = NexBase.Repo.Postgres.init(:runtime, config)
      assert is_list(result)
    end
  end

  describe "NexBase.Repo.SQLite" do
    test "module loads correctly" do
      assert Code.ensure_loaded?(NexBase.Repo.SQLite)
    end

    test "init/2 with config" do
      config = [url: "sqlite::memory:"]
      {:ok, result} = NexBase.Repo.SQLite.init(:runtime, config)
      assert is_list(result)
    end
  end
end
