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

  describe "Supabase-like additional filters" do
    test "not_filter adds negated filter" do
      q = NexBase.from("users") |> NexBase.not_filter(:status, :eq, "banned")
      assert length(q.not_filters) == 1
      assert hd(q.not_filters) == {:eq, :status, "banned"}
    end

    test "not_filter supports different operators" do
      q = NexBase.from("users") |> NexBase.not_filter(:age, :gt, 100)
      assert hd(q.not_filters) == {:gt, :age, 100}
    end

    test "or_filter adds OR group" do
      q =
        NexBase.from("users")
        |> NexBase.or_filter([{:eq, :status, "active"}, {:gt, :age, 65}])

      assert length(q.or_filters) == 1
      assert hd(q.or_filters) == [{:eq, :status, "active"}, {:gt, :age, 65}]
    end

    test "multiple or_filter calls accumulate" do
      q =
        NexBase.from("users")
        |> NexBase.or_filter([{:eq, :status, "vip"}])
        |> NexBase.or_filter([{:eq, :role, "admin"}])

      assert length(q.or_filters) == 2
    end

    test "match builds AND equality filters from map" do
      q = NexBase.from("users") |> NexBase.match(%{status: "active", role: "admin"})
      assert length(q.filters) == 2
      assert {:eq, :status, "active"} in q.filters
      assert {:eq, :role, "admin"} in q.filters
    end

    test "filter dispatches to :not operator" do
      q = NexBase.from("users") |> NexBase.filter(:role, :not, {:eq, "banned"})
      assert length(q.not_filters) == 1
    end

    test "filter dispatches to :or operator" do
      q = NexBase.from("users") |> NexBase.filter(:unused, :or, [{:eq, :a, 1}, {:eq, :b, 2}])
      assert length(q.or_filters) == 1
    end

    test "filter normalizes operator aliases" do
      q = NexBase.from("users") |> NexBase.filter(:age, :greater_than, 18)
      assert hd(q.filters) == {:gt, :age, 18}

      q2 = NexBase.from("users") |> NexBase.filter(:name, :equals, "Alice")
      assert hd(q2.filters) == {:eq, :name, "Alice"}

      q3 = NexBase.from("users") |> NexBase.filter(:tags, :contains, ["elixir"])
      assert hd(q3.filters) == {:cs, :tags, ["elixir"]}
    end

    test "contains filter" do
      q = NexBase.from("posts") |> NexBase.contains(:tags, ["elixir", "phoenix"])
      assert hd(q.filters) == {:cs, :tags, ["elixir", "phoenix"]}
    end

    test "contained_in filter" do
      q = NexBase.from("events") |> NexBase.contained_in(:time_range, [1, 10])
      assert hd(q.filters) == {:cd, :time_range, [1, 10]}
    end

    test "overlaps filter" do
      q = NexBase.from("events") |> NexBase.overlaps(:dates, [~D[2026-01-01]])
      assert hd(q.filters) == {:ov, :dates, [~D[2026-01-01]]}
    end

    test "range filters" do
      q = NexBase.from("events") |> NexBase.range_lt(:period, [10, 20])
      assert hd(q.filters) == {:sl, :period, [10, 20]}

      q = NexBase.from("events") |> NexBase.range_gt(:period, [10, 20])
      assert hd(q.filters) == {:sr, :period, [10, 20]}

      q = NexBase.from("events") |> NexBase.range_gte(:period, [10, 20])
      assert hd(q.filters) == {:nxl, :period, [10, 20]}

      q = NexBase.from("events") |> NexBase.range_lte(:period, [10, 20])
      assert hd(q.filters) == {:nxr, :period, [10, 20]}

      q = NexBase.from("events") |> NexBase.range_adjacent(:period, [10, 20])
      assert hd(q.filters) == {:adj, :period, [10, 20]}
    end

    test "text_search / fts filter" do
      q = NexBase.from("posts") |> NexBase.text_search(:body, "elixir phoenix")
      assert {op, {_col, _cfg}, _query} = hd(q.filters)
      # Default type :plain maps to :plfts (plainto_tsquery) — matches Supabase semantics
      assert op in [:plfts, :fts, :phfts, :wfts]

      q2 = NexBase.from("posts") |> NexBase.fts(:body, "elixir phoenix", "simple")
      assert {op2, {_col2, cfg2}, _q2} = hd(q2.filters)
      assert cfg2 == "simple"
    end

    test "plfts / phfts / wfts filters" do
      q = NexBase.from("posts") |> NexBase.plfts(:body, "search query")
      assert {op, _, _} = hd(q.filters)
      assert op == :plfts

      q = NexBase.from("posts") |> NexBase.phfts(:body, "search query")
      assert {op, _, _} = hd(q.filters)
      assert op == :phfts

      q = NexBase.from("posts") |> NexBase.wfts(:body, "search query")
      assert {op, _, _} = hd(q.filters)
      assert op == :wfts
    end
  end

  describe "count / ordering / execution helpers" do
    test "count sets count mode" do
      q = NexBase.from("users") |> NexBase.count(:exact)
      assert q.count == :exact

      q = NexBase.from("users") |> NexBase.count(:planned)
      assert q.count == :planned

      q = NexBase.from("users") |> NexBase.count(:estimated)
      assert q.count == :estimated

      q = NexBase.from("users") |> NexBase.count()
      assert q.count == :exact
    end

    test "order with options (nulls_first)" do
      q = NexBase.from("users") |> NexBase.order(:name, :asc, nulls_first: true)
      assert hd(q.order_by) == {:asc, :name, [nulls_first: true]}
    end

    test "order with options (nulls_last)" do
      q = NexBase.from("users") |> NexBase.order(:name, :desc, nulls_last: true)
      assert hd(q.order_by) == {:desc, :name, [nulls_last: true]}
    end

    test "mixed old and new order formats" do
      q =
        NexBase.from("users")
        |> NexBase.order(:name, :asc)
        |> NexBase.order(:age, :desc, nulls_last: true)

      assert length(q.order_by) == 2
      assert elem(hd(q.order_by), 0) == :asc
    end

    test "Query struct backward compatible defaults" do
      q = NexBase.from("users")
      assert q.or_filters == []
      assert q.not_filters == []
      assert q.count == nil
    end

    test "run! returns data directly (bang variant)" do
      conn = NexBase.init(url: "sqlite::memory:", start: true, pool_size: 1)
      NexBase.query!(conn, "CREATE TABLE helpers_test (id INTEGER PRIMARY KEY, name TEXT)", [])
      result = conn |> NexBase.from("helpers_test") |> NexBase.run!()
      assert is_list(result)
    end

    test "maybe_one returns nil for empty result" do
      conn = NexBase.init(url: "sqlite::memory:", start: true, pool_size: 1)
      NexBase.query!(conn, "CREATE TABLE empty_test (id INTEGER PRIMARY KEY)", [])
      assert conn |> NexBase.from("empty_test") |> NexBase.maybe_one() == nil
    end

    test "one! raises when no rows" do
      conn = NexBase.init(url: "sqlite::memory:", start: true, pool_size: 1)
      NexBase.query!(conn, "CREATE TABLE one_test (id INTEGER PRIMARY KEY)", [])

      assert_raise RuntimeError, ~r/Expected exactly one row/, fn ->
        conn |> NexBase.from("one_test") |> NexBase.one!()
      end
    end

    test "stream returns rows as list" do
      conn = NexBase.init(url: "sqlite::memory:", start: true, pool_size: 1)
      NexBase.query!(conn, "CREATE TABLE stream_test (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO stream_test (id, name) VALUES (1, 'a')", [])
      result = conn |> NexBase.from("stream_test") |> NexBase.stream()
      assert is_list(result)
      assert length(result) == 1
    end
  end

  describe "transaction" do
    test "transaction exists and returns tuple" do
      assert function_exported?(NexBase, :transaction, 1)
      assert function_exported?(NexBase, :transaction, 2)
    end
  end

  # -- Supabase API parity tests --

  describe "Supabase parity: select with aliases" do
    test "select default is * (no columns)" do
      q = NexBase.from("users") |> NexBase.select()
      assert q.select == []
    end

    test "select string parses comma-separated columns" do
      q = NexBase.from("users") |> NexBase.select("id, name, email")
      assert q.select == ["id", "name", "email"]
    end

    test "select string with alias syntax col:alias" do
      q = NexBase.from("users") |> NexBase.select("id, display_name:name")
      assert q.select == ["id", "name AS display_name"]
    end

    test "select list still works" do
      q = NexBase.from("users") |> NexBase.select([:id, :name])
      assert q.select == [:id, :name]
    end

    test "select after insert enables RETURNING" do
      q = NexBase.from("users") |> NexBase.insert(%{name: "A"}) |> NexBase.select()
      assert q.returning == true
    end

    test "select after update enables RETURNING" do
      q = NexBase.from("users") |> NexBase.update(%{name: "B"}) |> NexBase.select()
      assert q.returning == true
    end

    test "select after delete enables RETURNING" do
      q = NexBase.from("users") |> NexBase.delete() |> NexBase.select()
      assert q.returning == true
    end

    test "select after upsert enables RETURNING" do
      q = NexBase.from("users") |> NexBase.upsert(%{id: 1}) |> NexBase.select()
      assert q.returning == true
    end
  end

  describe "Supabase parity: order/limit/range with referencedTable" do
    test "order with opts map ascending: false" do
      q = NexBase.from("users") |> NexBase.order(:name, ascending: false)
      assert q.order_by == [{:desc, :name}]
    end

    test "order with opts map and nullsFirst" do
      q = NexBase.from("users") |> NexBase.order(:name, nulls_first: true)
      assert match?([{:asc, :name, _}], q.order_by)
      opts = elem(hd(q.order_by), 2)
      assert opts[:nulls_first] == true
    end

    test "order with referenced_table option" do
      q = NexBase.from("users") |> NexBase.order(:title, ascending: false, referenced_table: "posts")
      assert {_entry, [referenced_table: "posts"]} = hd(q.order_by)
    end

    test "order with deprecated foreign_table option" do
      q = NexBase.from("users") |> NexBase.order(:title, foreign_table: "posts")
      assert {_entry, [referenced_table: "posts"]} = hd(q.order_by)
    end

    test "limit with referenced_table option" do
      q = NexBase.from("users") |> NexBase.limit(10, referenced_table: "posts")
      assert q.limit == 10
      assert q.limit_referenced_table == "posts"
    end

    test "offset with referenced_table option" do
      q = NexBase.from("users") |> NexBase.offset(5, referenced_table: "posts")
      assert q.offset == 5
      assert q.offset_referenced_table == "posts"
    end

    test "range with referenced_table sets both ref tables" do
      q = NexBase.from("users") |> NexBase.range(2, 6, referenced_table: "posts")
      assert q.limit == 5
      assert q.offset == 2
      assert q.limit_referenced_table == "posts"
      assert q.offset_referenced_table == "posts"
    end
  end

  describe "Supabase parity: or_filter with referencedTable" do
    test "or_filter with referenced_table option" do
      q =
        NexBase.from("users")
        |> NexBase.or_filter([{:eq, :status, "active"}, {:eq, :role, "admin"}], referenced_table: "posts")

      assert length(q.or_filters) == 1
      {group, referenced_table: "posts"} = hd(q.or_filters)
      assert group == [{:eq, :status, "active"}, {:eq, :role, "admin"}]
    end
  end

  describe "Supabase parity: single / maybeSingle" do
    test "single sets single flag and limit 1" do
      q = NexBase.from("users") |> NexBase.single()
      assert q.single == true
      assert q.limit == 1
    end

    test "maybe_single sets maybe_single flag and limit 1" do
      q = NexBase.from("users") |> NexBase.maybe_single()
      assert q.maybe_single == true
      assert q.limit == 1
    end

    test "single() unwraps a single row at run time" do
      conn = NexBase.init(url: "sqlite::memory:", start: true, pool_size: 1)
      NexBase.query!(conn, "CREATE TABLE single_test (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO single_test (id, name) VALUES (1, 'alice')", [])
      result = conn |> NexBase.from("single_test") |> NexBase.single() |> NexBase.run()
      assert {:ok, %{"id" => 1, "name" => "alice"}} = result
    end

    test "single() returns error when 0 rows" do
      conn = NexBase.init(url: "sqlite::memory:", start: true, pool_size: 1)
      NexBase.query!(conn, "CREATE TABLE empty_single (id INTEGER PRIMARY KEY)", [])
      result = conn |> NexBase.from("empty_single") |> NexBase.single() |> NexBase.run()
      assert {:error, _} = result
    end

    test "maybe_single() returns nil when 0 rows" do
      conn = NexBase.init(url: "sqlite::memory:", start: true, pool_size: 1)
      NexBase.query!(conn, "CREATE TABLE empty_ms (id INTEGER PRIMARY KEY)", [])
      result = conn |> NexBase.from("empty_ms") |> NexBase.maybe_single() |> NexBase.run()
      assert {:ok, nil} = result
    end

    test "maybe_single() unwraps a single row" do
      conn = NexBase.init(url: "sqlite::memory:", start: true, pool_size: 1)
      NexBase.query!(conn, "CREATE TABLE ms_test (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO ms_test (id, name) VALUES (1, 'bob')", [])
      result = conn |> NexBase.from("ms_test") |> NexBase.maybe_single() |> NexBase.run()
      assert {:ok, %{"id" => 1, "name" => "bob"}} = result
    end
  end

  describe "Supabase parity: extended filters (nlike, nilike, is_null, not_in, like_*_of, ilike_*_of)" do
    test "nlike adds NOT LIKE filter" do
      q = NexBase.from("users") |> NexBase.nlike(:name, "%admin%")
      assert {:nlike, :name, "%admin%"} in q.filters
    end

    test "nilike adds NOT ILIKE filter" do
      q = NexBase.from("users") |> NexBase.nilike(:email, "%@spam%")
      assert {:nilike, :email, "%@spam%"} in q.filters
    end

    test "is_null adds IS NULL filter" do
      q = NexBase.from("users") |> NexBase.is_null(:deleted_at)
      assert {:is, :deleted_at, nil} in q.filters
    end

    test "is_not_null adds NOT IS NULL filter (via not_filters)" do
      q = NexBase.from("users") |> NexBase.is_not_null(:email)
      assert {:is, :email, nil} in q.not_filters
    end

    test "not_in_list adds NOT IN filter (via not_filters)" do
      q = NexBase.from("users") |> NexBase.not_in_list(:role, ["admin", "mod"])
      assert {:in, :role, ["admin", "mod"]} in q.not_filters
    end

    test "like_all_of adds multiple LIKE filters" do
      q = NexBase.from("users") |> NexBase.like_all_of(:name, ["a%", "%z"])
      assert length(q.filters) == 2
      assert {:like, :name, "a%"} in q.filters
      assert {:like, :name, "%z"} in q.filters
    end

    test "like_any_of adds or-group of LIKE filters" do
      q = NexBase.from("users") |> NexBase.like_any_of(:name, ["a%", "%z"])
      assert length(q.or_filters) == 1
      [group] = q.or_filters
      assert {:like, :name, "a%"} in group
      assert {:like, :name, "%z"} in group
    end

    test "ilike_all_of adds multiple ILIKE filters" do
      q = NexBase.from("users") |> NexBase.ilike_all_of(:email, ["A%", "%Z"])
      assert length(q.filters) == 2
      assert {:ilike, :email, "A%"} in q.filters
      assert {:ilike, :email, "%Z"} in q.filters
    end

    test "ilike_any_of adds or-group of ILIKE filters" do
      q = NexBase.from("users") |> NexBase.ilike_any_of(:email, ["A%", "%Z"])
      assert length(q.or_filters) == 1
      [group] = q.or_filters
      assert {:ilike, :email, "A%"} in group
      assert {:ilike, :email, "%Z"} in group
    end
  end

  describe "Supabase parity: text_search opts form" do
    test "text_search with opts list uses config and defaults to plain" do
      q = NexBase.from("docs") |> NexBase.text_search(:body, "hello", config: "english")
      # Default type :plain maps to :plfts (plainto_tsquery)
      assert [{op, {:body, "english"}, "hello"}] = q.filters
      assert op in [:plfts, :fts]
    end

    test "text_search with type: :phrase uses phfts (phraseto_tsquery)" do
      q = NexBase.from("docs") |> NexBase.text_search(:body, "hello world", type: :phrase)
      assert [{:phfts, {:body, "english"}, "hello world"}] = q.filters
    end

    test "text_search with type: :websearch uses wfts" do
      q = NexBase.from("docs") |> NexBase.text_search(:body, "hello OR world", type: :websearch)
      assert [{:wfts, {:body, "english"}, "hello OR world"}] = q.filters
    end

    test "text_search with string config (backward compat)" do
      q = NexBase.from("docs") |> NexBase.text_search(:body, "hello", "simple")
      assert [{:fts, {:body, "simple"}, "hello"}] = q.filters
    end

    test "fts, plfts, phfts, wfts accept opts list" do
      q1 = NexBase.from("d") |> NexBase.fts(:b, "q", config: "simple")
      assert [{:fts, {:b, "simple"}, "q"}] = q1.filters

      q2 = NexBase.from("d") |> NexBase.plfts(:b, "q", config: "simple")
      assert [{:plfts, {:b, "simple"}, "q"}] = q2.filters

      q3 = NexBase.from("d") |> NexBase.phfts(:b, "q", config: "simple")
      assert [{:phfts, {:b, "simple"}, "q"}] = q3.filters

      q4 = NexBase.from("d") |> NexBase.wfts(:b, "q", config: "simple")
      assert [{:wfts, {:b, "simple"}, "q"}] = q4.filters
    end
  end

  describe "Supabase parity: explain / csv / rollback" do
    test "explain sets explain_opts with defaults" do
      q = NexBase.from("users") |> NexBase.explain()
      assert q.explain_opts == [analyze: false, verbose: false, settings: false, buffers: false, wal: false, format: :text]
    end

    test "explain with all options" do
      q = NexBase.from("users") |> NexBase.explain(analyze: true, format: :json, wal: true)
      assert q.explain_opts[:analyze] == true
      assert q.explain_opts[:format] == :json
      assert q.explain_opts[:wal] == true
    end

    test "csv sets csv flag" do
      q = NexBase.from("users") |> NexBase.csv()
      assert q.csv == true
    end

    test "geojson sets geojson flag" do
      q = NexBase.from("users") |> NexBase.geojson()
      assert q.geojson == true
    end

    test "throw_on_error sets flag" do
      q = NexBase.from("users") |> NexBase.throw_on_error()
      assert q.throw_on_error == true
    end

    test "rollback sets rollback flag" do
      q = NexBase.from("users") |> NexBase.rollback()
      assert q.rollback == true
    end
  end

  describe "Supabase parity: schema / max_affected" do
    test "schema/2 sets schema on query" do
      q = NexBase.from("users") |> NexBase.schema("private")
      assert q.schema == "private"
    end

    test "schema/1 returns a conn-scoped builder" do
      conn = NexBase.init(url: "sqlite::memory:", start: true, pool_size: 1)
      scoped = conn |> NexBase.schema("private")
      assert is_function(scoped, 1)
      q = scoped.("users")
      assert q.schema == "private"
    end

    test "max_affected sets max_affected" do
      q = NexBase.from("users") |> NexBase.max_affected(100)
      assert q.max_affected == 100
    end
  end

  describe "Supabase parity: insert / update / delete / upsert options" do
    test "insert with count option sets count" do
      q = NexBase.from("users") |> NexBase.insert(%{name: "A"}, count: :exact)
      assert q.count == :exact
    end

    test "insert with default_to_null: false sets flag" do
      q = NexBase.from("users") |> NexBase.insert([%{name: "A"}], default_to_null: false)
      assert q.default_to_null == false
    end

    test "update with count option sets count" do
      q = NexBase.from("users") |> NexBase.update(%{name: "B"}, count: :exact)
      assert q.count == :exact
    end

    test "delete with count option sets count" do
      q = NexBase.from("users") |> NexBase.delete(count: :exact)
      assert q.count == :exact
    end

    test "upsert sets ignore_duplicates and on_conflict" do
      q =
        NexBase.from("users")
        |> NexBase.upsert(%{id: 1, name: "A"}, on_conflict: :id, ignore_duplicates: true)

      assert q.upsert_opts[:on_conflict] == :id
      assert q.upsert_opts[:ignore_duplicates] == true
    end

    test "upsert with default_to_null: false sets flag" do
      q =
        NexBase.from("users")
        |> NexBase.upsert([%{id: 1}], default_to_null: false)

      assert q.default_to_null == false
    end

    test "upsert with count option" do
      q = NexBase.from("users") |> NexBase.upsert(%{id: 1}, count: :estimated)
      assert q.count == :estimated
    end
  end

  describe "Supabase parity: insert + select returns rows" do
    test "insert with .select() returns the inserted row" do
      conn = NexBase.init(url: "sqlite::memory:", start: true, pool_size: 1)
      NexBase.query!(conn, "CREATE TABLE ins_ret (id INTEGER PRIMARY KEY, name TEXT)", [])

      result =
        conn
        |> NexBase.from("ins_ret")
        |> NexBase.insert(%{id: 1, name: "Alice"})
        |> NexBase.select()
        |> NexBase.run()

      assert {:ok, res} = result
      assert %{count: 1, data: [%{id: 1, name: "Alice"}]} = res
    end
  end

  describe "Supabase parity: head / count on select" do
    test "select with head: true sets head flag" do
      q = NexBase.from("users") |> NexBase.select("*", head: true)
      assert q.head == true
    end

    test "select with count option sets count" do
      q = NexBase.from("users") |> NexBase.select("*", count: :exact)
      assert q.count == :exact
    end
  end
end
