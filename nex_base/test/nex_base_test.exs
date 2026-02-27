defmodule NexBaseTest do
  use ExUnit.Case
  alias NexBase.{Query, Conn}

  setup do
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
      q =
        NexBase.from("products")
        |> NexBase.eq(:category, "electronics")
        |> NexBase.gt(:price, 100)
        |> NexBase.like(:name, "%phone%")

      assert length(q.filters) == 3
      assert Enum.at(q.filters, 0) == {:eq, :category, "electronics"}
      assert Enum.at(q.filters, 1) == {:gt, :price, 100}
      assert Enum.at(q.filters, 2) == {:like, :name, "%phone%"}
    end

    test "pagination works correctly" do
      q =
        NexBase.from("posts")
        |> NexBase.limit(10)
        |> NexBase.offset(20)

      assert q.limit == 10
      assert q.offset == 20
    end

    test "sorting works correctly" do
      q =
        NexBase.from("posts")
        |> NexBase.order(:created_at, :Desc)
        |> NexBase.order(:id)

      assert length(q.order_by) == 2
      assert Enum.at(q.order_by, 0) == {:Desc, :created_at}
      assert Enum.at(q.order_by, 1) == {:asc, :id}
    end

    test "conn flows through chain" do
      conn = NexBase.init(url: "postgres://localhost/testdb")

      q =
        conn
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

  describe "nil URL handling" do
    test "init with nil url defaults to postgres" do
      conn = NexBase.init(url: nil)
      assert conn.adapter == :postgres
    end
  end

  describe "SQLite URL Parsing" do
    test "sqlite:///path format" do
      conn = NexBase.init(url: "sqlite:///path/to/db.db")
      assert conn.adapter == :sqlite
    end

    test "sqlite://path format (no leading slash)" do
      conn = NexBase.init(url: "sqlite://relative/path.db")
      assert conn.adapter == :sqlite
    end

    test "plain path defaults to postgres" do
      conn = NexBase.init(url: "local.db")
      assert conn.adapter == :postgres
    end
  end

  describe "init with options" do
    test "pool_size option" do
      conn = NexBase.init(url: "postgres://localhost/test", pool_size: 5)
      assert conn.repo_config[:pool_size] == 5
    end

    test "ssl option adds ssl config" do
      conn = NexBase.init(url: "postgres://localhost/test", ssl: true)
      assert conn.repo_config[:ssl] == [verify: :verify_none]
      assert conn.repo_config[:queue_target] == 10_000
      assert conn.repo_config[:queue_interval] == 20_000
    end

    test "prepare option defaults to unnamed" do
      conn = NexBase.init(url: "postgres://localhost/test")
      assert conn.repo_config[:prepare] == :unnamed
    end

    test "prepare option can be set to named" do
      conn = NexBase.init(url: "postgres://localhost/test", prepare: :named)
      assert conn.repo_config[:prepare] == :named
    end

    test "timeout option" do
      conn = NexBase.init(url: "postgres://localhost/test", timeout: 30_000)
      assert conn.repo_config[:timeout] == 30_000
    end

    test "connect_timeout option" do
      conn = NexBase.init(url: "postgres://localhost/test", connect_timeout: 5000)
      assert conn.repo_config[:connect_timeout] == 5000
    end
  end

  describe "DATABASE_URL env var fallback" do
    test "uses DATABASE_URL when url not provided" do
      System.put_env("DATABASE_URL", "postgres://localhost/envdb")

      try do
        conn = NexBase.init([])
        assert conn.adapter == :postgres
      after
        System.delete_env("DATABASE_URL")
      end
    end
  end

  describe "Query builder functions" do
    test "eq adds equality filter" do
      q = NexBase.from("users") |> NexBase.eq(:status, "active")
      assert q.filters == [{:eq, :status, "active"}]
    end

    test "neq adds not-equal filter" do
      q = NexBase.from("users") |> NexBase.neq(:status, "inactive")
      assert q.filters == [{:neq, :status, "inactive"}]
    end

    test "gt adds greater-than filter" do
      q = NexBase.from("products") |> NexBase.gt(:price, 100)
      assert q.filters == [{:gt, :price, 100}]
    end

    test "gte adds greater-than-or-equal filter" do
      q = NexBase.from("products") |> NexBase.gte(:price, 100)
      assert q.filters == [{:gte, :price, 100}]
    end

    test "lt adds less-than filter" do
      q = NexBase.from("products") |> NexBase.lt(:price, 100)
      assert q.filters == [{:lt, :price, 100}]
    end

    test "lte adds less-than-or-equal filter" do
      q = NexBase.from("products") |> NexBase.lte(:price, 100)
      assert q.filters == [{:lte, :price, 100}]
    end

    test "is adds IS filter" do
      q = NexBase.from("users") |> NexBase.is(:deleted_at, nil)
      assert q.filters == [{:is, :deleted_at, nil}]
    end

    test "is with :null" do
      q = NexBase.from("users") |> NexBase.is(:deleted_at, :null)
      assert q.filters == [{:is, :deleted_at, :null}]
    end

    test "is with boolean" do
      q = NexBase.from("users") |> NexBase.is(:active, true)
      assert q.filters == [{:is, :active, true}]
    end

    test "in_list adds IN filter" do
      q = NexBase.from("users") |> NexBase.in_list(:status, ["active", "pending"])
      assert q.filters == [{:in, :status, ["active", "pending"]}]
    end

    test "filter_in is alias for in_list" do
      q = NexBase.from("users") |> NexBase.filter_in(:id, [1, 2, 3])
      assert q.filters == [{:in, :id, [1, 2, 3]}]
    end

    test "like adds LIKE filter" do
      q = NexBase.from("users") |> NexBase.like(:name, "john%")
      assert q.filters == [{:like, :name, "john%"}]
    end

    test "ilike adds ILIKE filter" do
      q = NexBase.from("users") |> NexBase.ilike(:email, "%@example.com")
      assert q.filters == [{:ilike, :email, "%@example.com"}]
    end

    test "limit sets limit" do
      q = NexBase.from("users") |> NexBase.limit(50)
      assert q.limit == 50
    end

    test "offset sets offset" do
      q = NexBase.from("users") |> NexBase.offset(100)
      assert q.offset == 100
    end

    test "order with default asc" do
      q = NexBase.from("users") |> NexBase.order(:name)
      assert q.order_by == [{:asc, :name}]
    end

    test "order with desc" do
      q = NexBase.from("users") |> NexBase.order(:created_at, :Desc)
      assert q.order_by == [{:Desc, :created_at}]
    end

    test "multiple order calls accumulate" do
      q =
        NexBase.from("users")
        |> NexBase.order(:name, :asc)
        |> NexBase.order(:age, :desc)
        |> NexBase.order(:created_at)

      assert length(q.order_by) == 3
      assert q.order_by == [{:asc, :name}, {:desc, :age}, {:asc, :created_at}]
    end
  end

  describe "Query mutations" do
    test "insert sets type and data" do
      q = NexBase.from("users") |> NexBase.insert(%{name: "John"})
      assert q.type == :insert
      assert q.data == %{name: "John"}
    end

    test "insert with list data" do
      q = NexBase.from("users") |> NexBase.insert([%{name: "John"}, %{name: "Jane"}])
      assert q.type == :insert
      assert is_list(q.data)
    end

    test "update sets type and data" do
      q = NexBase.from("users") |> NexBase.update(%{name: "Jane"})
      assert q.type == :update
      assert q.data == %{name: "Jane"}
    end

    test "delete sets type" do
      q = NexBase.from("users") |> NexBase.delete()
      assert q.type == :delete
    end

    test "upsert sets type and data" do
      q = NexBase.from("users") |> NexBase.upsert(%{id: 1, name: "John"})
      assert q.type == :upsert
      assert q.data == %{id: 1, name: "John"}
    end

    test "upsert with list data" do
      q =
        NexBase.from("users") |> NexBase.upsert([%{id: 1, name: "John"}, %{id: 2, name: "Jane"}])

      assert q.type == :upsert
      assert is_list(q.data)
    end

    test "single sets limit to 1" do
      q = NexBase.from("users") |> NexBase.single()
      assert q.limit == 1
    end

    test "maybe_single sets limit to 1" do
      q = NexBase.from("users") |> NexBase.maybe_single()
      assert q.limit == 1
    end

    test "range sets limit and offset" do
      q = NexBase.from("users") |> NexBase.range(0, 9)
      assert q.limit == 10
      assert q.offset == 0
    end

    test "range with different values" do
      q = NexBase.from("users") |> NexBase.range(10, 19)
      assert q.limit == 10
      assert q.offset == 10
    end
  end

  describe "Conn struct" do
    test "Conn has required fields" do
      conn = NexBase.init(url: "postgres://localhost/test")
      assert conn.name != nil
      assert conn.adapter == :postgres
      assert conn.repo_module == NexBase.Repo.Postgres
      assert conn.repo_config != nil
    end

    test "Conn struct can be pattern matched" do
      %Conn{name: name, adapter: adapter} = NexBase.init(url: "sqlite::memory:")
      assert is_atom(name)
      assert adapter == :sqlite
    end
  end

  describe "Query struct" do
    test "Query has default values" do
      q = NexBase.from("users")
      assert q.table == "users"
      assert q.select == []
      assert q.filters == []
      assert q.limit == nil
      assert q.offset == nil
      assert q.order_by == []
      assert q.type == :select
      assert q.data == nil
      assert q.conn == nil
    end

    test "Query can be modified immutably" do
      q1 = NexBase.from("users")
      q2 = NexBase.eq(q1, :status, "active")

      assert q1.filters == []
      assert q2.filters == [{:eq, :status, "active"}]
    end
  end

  describe "rpc function" do
    test "rpc raises for SQLite" do
      NexBase.init(url: "sqlite::memory:")

      assert_raise RuntimeError, ~r/not supported with SQLite/, fn ->
        NexBase.rpc("my_function", %{param1: "value"})
      end
    end
  end

  describe "sql/query/query! functions exist" do
    test "sql/2 with default conn raises when no default" do
      Application.delete_env(:nex_base, :default_conn)

      assert_raise RuntimeError, ~r/NexBase not initialized/, fn ->
        NexBase.sql("SELECT * FROM users", [])
      end
    end

    test "sql/3 exists with conn" do
      conn = NexBase.init(url: "sqlite::memory:")
      assert function_exported?(NexBase, :sql, 3)
    end

    test "query/2 with default conn raises when no default" do
      Application.delete_env(:nex_base, :default_conn)

      assert_raise RuntimeError, ~r/NexBase not initialized/, fn ->
        NexBase.query("SELECT * FROM users", [])
      end
    end

    test "query!/2 with default conn raises when no default" do
      Application.delete_env(:nex_base, :default_conn)

      assert_raise RuntimeError, ~r/NexBase not initialized/, fn ->
        NexBase.query!("SELECT * FROM users", [])
      end
    end
  end

  describe "run with SQLite" do
    test "run select attempts to execute" do
      conn = NexBase.init(url: "sqlite::memory:")
      result = NexBase.from("users") |> NexBase.run()
      assert is_tuple(result)
    end

    test "run insert attempts to execute" do
      conn = NexBase.init(url: "sqlite::memory:")
      result = conn |> NexBase.from("users") |> NexBase.insert(%{name: "test"}) |> NexBase.run()
      assert is_tuple(result)
    end

    test "run update attempts to execute" do
      conn = NexBase.init(url: "sqlite::memory:")

      result =
        conn
        |> NexBase.from("users")
        |> NexBase.eq(:id, 1)
        |> NexBase.update(%{name: "updated"})
        |> NexBase.run()

      assert is_tuple(result)
    end

    test "run delete attempts to execute" do
      conn = NexBase.init(url: "sqlite::memory:")

      result =
        conn |> NexBase.from("users") |> NexBase.eq(:id, 1) |> NexBase.delete() |> NexBase.run()

      assert is_tuple(result)
    end

    test "run upsert attempts to execute" do
      conn = NexBase.init(url: "sqlite::memory:")

      result =
        conn |> NexBase.from("users") |> NexBase.upsert(%{id: 1, name: "test"}) |> NexBase.run()

      assert is_tuple(result)
    end
  end

  describe "adapter/1 function" do
    test "adapter/1 returns adapter from conn" do
      conn = NexBase.init(url: "postgres://localhost/test")
      assert NexBase.adapter(conn) == :postgres
    end

    test "adapter/0 returns adapter from default conn" do
      NexBase.init(url: "sqlite:///test.db")
      assert NexBase.adapter() == :sqlite
    end
  end

  describe "default_conn/0" do
    test "returns stored default conn" do
      conn = NexBase.init(url: "postgres://localhost/test")
      assert NexBase.default_conn() == conn
    end

    test "raises when no conn configured" do
      Application.delete_env(:nex_base, :default_conn)

      assert_raise RuntimeError, ~r/NexBase not initialized/, fn ->
        NexBase.default_conn()
      end
    end
  end
end
