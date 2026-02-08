defmodule NexBaseTest do
  use ExUnit.Case
  alias NexBase.{Query, Conn}

  setup do
    # Reset default conn between tests so each test has clean state
    Application.delete_env(:nex_base, :default_conn)
    Application.delete_env(:nex_base, :repo_config)
    Application.delete_env(:nex_base, :adapter)
    :ok
  end

  describe "Query Builder" do
    test "from/1 creates initial query without conn" do
      q = NexBase.from("users")
      assert %Query{table: "users", conn: nil} = q
    end

    test "from/2 creates query with conn" do
      conn = NexBase.init(url: "postgres://localhost/testdb")
      q = conn |> NexBase.from("users")
      assert %Query{table: "users", conn: ^conn} = q
    end

    test "select/2 adds columns" do
      q = NexBase.from("users") |> NexBase.select([:id, :name])
      assert q.select == [:id, :name]
    end

    test "filters work correctly" do
      q = NexBase.from("products")
          |> NexBase.eq(:category, "electronics")
          |> NexBase.gt(:price, 100)
          |> NexBase.like(:name, "%phone%")

      assert length(q.filters) == 3
      assert Enum.at(q.filters, 0) == {:eq, :category, "electronics"}
      assert Enum.at(q.filters, 1) == {:gt, :price, 100}
      assert Enum.at(q.filters, 2) == {:like, :name, "%phone%"}
    end

    test "pagination works correctly" do
      q = NexBase.from("posts")
          |> NexBase.limit(10)
          |> NexBase.offset(20)

      assert q.limit == 10
      assert q.offset == 20
    end

    test "sorting works correctly" do
      q = NexBase.from("posts")
          |> NexBase.order(:created_at, :desc)
          |> NexBase.order(:id) # default asc

      assert length(q.order_by) == 2
      assert Enum.at(q.order_by, 0) == {:desc, :created_at}
      assert Enum.at(q.order_by, 1) == {:asc, :id}
    end

    test "conn flows through chain" do
      conn = NexBase.init(url: "postgres://localhost/testdb")
      q = conn
          |> NexBase.from("users")
          |> NexBase.eq(:active, true)
          |> NexBase.order(:name, :asc)
          |> NexBase.limit(10)

      assert q.conn == conn
      assert q.table == "users"
      assert length(q.filters) == 1
    end
  end

  describe "Adapter Detection" do
    test "init/1 returns Conn struct" do
      conn = NexBase.init(url: "postgres://localhost/testdb")
      assert %Conn{} = conn
    end

    test "init/1 detects postgres from URL" do
      conn = NexBase.init(url: "postgres://localhost/testdb")
      assert conn.adapter == :postgres
      assert conn.repo_module == NexBase.Repo.Postgres
    end

    test "init/1 detects postgres from postgresql:// URL" do
      conn = NexBase.init(url: "postgresql://localhost/testdb")
      assert conn.adapter == :postgres
    end

    test "init/1 detects sqlite from URL" do
      conn = NexBase.init(url: "sqlite:///tmp/test.db")
      assert conn.adapter == :sqlite
      assert conn.repo_module == NexBase.Repo.SQLite
    end

    test "init/1 detects sqlite in-memory" do
      conn = NexBase.init(url: "sqlite::memory:")
      assert conn.adapter == :sqlite
    end

    test "init/1 defaults to postgres when no URL" do
      conn = NexBase.init([])
      assert conn.adapter == :postgres
    end

    test "init/1 generates unique names" do
      conn1 = NexBase.init(url: "postgres://localhost/db1")
      conn2 = NexBase.init(url: "postgres://localhost/db2")
      assert conn1.name != conn2.name
    end

    test "init/1 stores as default conn" do
      conn = NexBase.init(url: "postgres://localhost/testdb")
      assert NexBase.default_conn() == conn
    end
  end

  describe "Multi-connection" do
    test "multiple inits create independent conns" do
      pg = NexBase.init(url: "postgres://localhost/main")
      sqlite = NexBase.init(url: "sqlite::memory:")

      assert pg.adapter == :postgres
      assert sqlite.adapter == :sqlite
      assert pg.name != sqlite.name
    end

    test "conn pipes through from to query" do
      pg = NexBase.init(url: "postgres://localhost/main")
      sqlite = NexBase.init(url: "sqlite::memory:")

      q1 = pg |> NexBase.from("users")
      q2 = sqlite |> NexBase.from("sessions")

      assert q1.conn == pg
      assert q2.conn == sqlite
      assert q1.conn.adapter == :postgres
      assert q2.conn.adapter == :sqlite
    end
  end
end
