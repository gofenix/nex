defmodule NexBase.Repo.SQLiteTest do
  use ExUnit.Case, async: false

  alias NexBase.Repo.SQLite

  setup do
    Application.delete_env(:nex_base, :default_conn)
    Application.delete_env(:nex_base, :repo_config)
    Application.delete_env(:nex_base, :adapter)
    :ok
  end

  describe "NexBase.Repo.SQLite" do
    test "init/2 with config merges correctly" do
      config = [database: ":memory:"]
      {:ok, result} = SQLite.init(:runtime, config)
      assert is_list(result)
      assert Keyword.get(result, :database) == ":memory:"
    end

    test "start_link with name option" do
      unique_name = :"test_sqlite_#{:rand.uniform(99999)}"
      Application.put_env(:nex_base, unique_name, database: ":memory:")

      {:ok, pid} = SQLite.start_link(name: unique_name)
      assert is_pid(pid)
      Process.exit(pid, :shutdown)
    end

    @tag :skip
    test "can execute raw SQL after starting" do
      unique_name = :"test_sqlite2_#{:rand.uniform(99999)}"
      Application.put_env(:nex_base, unique_name, database: ":memory:")

      {:ok, _pid} = SQLite.start_link(name: unique_name)

      # Create table
      result =
        Ecto.Adapters.SQL.query(
          unique_name,
          "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)",
          []
        )

      assert {:ok, _} = result

      # Insert
      result =
        Ecto.Adapters.SQL.query(unique_name, "INSERT INTO users (name) VALUES ('Alice')", [])

      assert {:ok, _} = result

      # Select
      result = Ecto.Adapters.SQL.query(unique_name, "SELECT * FROM users", [])
      assert {:ok, %{rows: [[1, "Alice"]]}} = result
    end
  end
end
