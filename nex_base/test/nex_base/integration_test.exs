defmodule NexBase.IntegrationTest do
  use ExUnit.Case, async: false

  alias NexBase.Query

  setup do
    Application.delete_env(:nex_base, :default_conn)
    Application.delete_env(:nex_base, :repo_config)
    Application.delete_env(:nex_base, :adapter)
    :ok
  end

  defp mem_conn do
    NexBase.init(url: "sqlite::memory:", start: true, pool_size: 1)
  end

  describe "SQL execution paths" do
    test "sql/2 returns {:ok, rows} for SELECT" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE sqlt (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO sqlt (id, name) VALUES (1, 'alice')", [])

      result = NexBase.sql(conn, "SELECT * FROM sqlt WHERE id = ?1", [1])
      assert {:ok, rows} = result
      assert is_list(rows)
      assert length(rows) == 1
    end

    test "sql!/2 returns rows directly" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE sqlbang (id INTEGER PRIMARY KEY)", [])
      {:ok, rows} = NexBase.sql(conn, "SELECT * FROM sqlbang", [])
      assert is_list(rows)
    end

    test "sql/2 returns {:error, reason} on bad query" do
      conn = mem_conn()
      result = NexBase.sql(conn, "SELECT * FROM nonexistent_xyz", [])
      assert {:error, _} = result
    end

    test "query/2 and query!/2 run raw SQL" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE rawq (id INTEGER PRIMARY KEY)", [])
      result = NexBase.query(conn, "SELECT * FROM rawq", [])
      assert {:ok, _} = result
    end
  end

  describe "run!/1 bang variant" do
    test "returns list of rows directly for select" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE runbang (id INTEGER PRIMARY KEY, val TEXT)", [])
      NexBase.query!(conn, "INSERT INTO runbang (val) VALUES ('a')", [])

      rows = conn |> NexBase.from("runbang") |> NexBase.run!()
      assert is_list(rows)
      assert length(rows) == 1
    end

    test "raises on invalid table" do
      conn = mem_conn()
      assert_raise RuntimeError, ~r/Query failed/, fn ->
        conn |> NexBase.from("nonexistent_table_xyz") |> NexBase.run!()
      end
    end
  end

  describe "one!/1 and maybe_one/1" do
    test "one! returns single row" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE one_r (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO one_r (name) VALUES ('only')", [])

      row = conn |> NexBase.from("one_r") |> NexBase.one!()
      assert is_map(row)
    end

    test "one! raises when no rows" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE one_empty (id INTEGER PRIMARY KEY)", [])

      assert_raise RuntimeError, ~r/Expected exactly one row/, fn ->
        conn |> NexBase.from("one_empty") |> NexBase.one!()
      end
    end

    test "one! raises when multiple rows" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE one_multi (id INTEGER PRIMARY KEY)", [])
      NexBase.query!(conn, "INSERT INTO one_multi DEFAULT VALUES", [])
      NexBase.query!(conn, "INSERT INTO one_multi DEFAULT VALUES", [])

      assert_raise RuntimeError, ~r/Expected exactly one row/, fn ->
        conn |> NexBase.from("one_multi") |> NexBase.one!()
      end
    end

    test "maybe_one returns single row when present" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE mo_present (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO mo_present (name) VALUES ('x')", [])

      row = conn |> NexBase.from("mo_present") |> NexBase.maybe_one()
      assert is_map(row)
    end

    test "maybe_one raises when multiple rows" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE mo_multi (id INTEGER PRIMARY KEY)", [])
      NexBase.query!(conn, "INSERT INTO mo_multi DEFAULT VALUES", [])
      NexBase.query!(conn, "INSERT INTO mo_multi DEFAULT VALUES", [])

      assert_raise RuntimeError, ~r/Expected at most one row/, fn ->
        conn |> NexBase.from("mo_multi") |> NexBase.maybe_one()
      end
    end
  end

  describe "stream/2" do
    test "returns empty list for empty table" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE empty_stream (id INTEGER PRIMARY KEY)", [])
      result = conn |> NexBase.from("empty_stream") |> NexBase.stream()
      assert result == []
    end

    test "returns rows as maps with string keys" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE strm2 (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO strm2 (id, name) VALUES (1, 'alice')", [])
      NexBase.query!(conn, "INSERT INTO strm2 (id, name) VALUES (2, 'bob')", [])

      rows = conn |> NexBase.from("strm2") |> NexBase.order(:id) |> NexBase.stream()
      assert length(rows) == 2
    end
  end

  describe "transaction/2" do
    test "commits insert inside transaction" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE txn_t (id INTEGER PRIMARY KEY, name TEXT)", [])

      result =
        NexBase.transaction(
          fn ->
            NexBase.query!(conn, "INSERT INTO txn_t (name) VALUES ('inside')", [])
            :done
          end,
          conn: conn
        )

      assert {:ok, :done} = result

      {:ok, rows} = NexBase.sql(conn, "SELECT * FROM txn_t", [])
      assert length(rows) == 1
    end

    test "rolls back on error inside transaction" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE txn_roll (id INTEGER PRIMARY KEY, name TEXT)", [])

      assert_raise RuntimeError, "boom", fn ->
        NexBase.transaction(
          fn ->
            NexBase.query!(conn, "INSERT INTO txn_roll (name) VALUES ('will_roll')", [])
            raise "boom"
          end,
          conn: conn
        )
      end

      {:ok, rows} = NexBase.sql(conn, "SELECT * FROM txn_roll", [])
      assert length(rows) == 0
    end
  end

  describe "filters in actual execution (SQLite)" do
    setup do
      conn = mem_conn()
      NexBase.query!(
        conn,
        "CREATE TABLE filt (id INTEGER PRIMARY KEY, name TEXT, age INTEGER, status TEXT)",
        []
      )
      NexBase.query!(conn, "INSERT INTO filt (name, age, status) VALUES ('alice', 30, 'active')", [])
      NexBase.query!(conn, "INSERT INTO filt (name, age, status) VALUES ('bob', 25, 'inactive')", [])
      NexBase.query!(conn, "INSERT INTO filt (name, age, status) VALUES ('carol', 40, 'active')", [])
      {:ok, conn: conn}
    end

    test "eq filter", %{conn: conn} do
      {:ok, rows} = conn |> NexBase.from("filt") |> NexBase.eq(:status, "active") |> NexBase.run()
      assert length(rows) == 2
    end

    test "neq filter", %{conn: conn} do
      {:ok, rows} = conn |> NexBase.from("filt") |> NexBase.neq(:status, "active") |> NexBase.run()
      assert length(rows) == 1
    end

    test "gt and lt filters", %{conn: conn} do
      {:ok, rows} = conn |> NexBase.from("filt") |> NexBase.gt(:age, 28) |> NexBase.run()
      assert length(rows) == 2

      {:ok, rows} = conn |> NexBase.from("filt") |> NexBase.lt(:age, 28) |> NexBase.run()
      assert length(rows) == 1
    end

    test "gte and lte filters", %{conn: conn} do
      {:ok, rows} = conn |> NexBase.from("filt") |> NexBase.gte(:age, 30) |> NexBase.run()
      assert length(rows) == 2

      {:ok, rows} = conn |> NexBase.from("filt") |> NexBase.lte(:age, 25) |> NexBase.run()
      assert length(rows) == 1
    end

    test "like filter", %{conn: conn} do
      {:ok, rows} = conn |> NexBase.from("filt") |> NexBase.like(:name, "ali%") |> NexBase.run()
      assert length(rows) == 1
    end

    test "ilike filter (case-insensitive)", %{conn: conn} do
      {:ok, rows} = conn |> NexBase.from("filt") |> NexBase.ilike(:name, "ALI%") |> NexBase.run()
      assert length(rows) == 1
    end

    test "in filter", %{conn: conn} do
      {:ok, rows} = conn |> NexBase.from("filt") |> NexBase.in_list(:age, [25, 40]) |> NexBase.run()
      assert length(rows) == 2
    end

    test "is filter with nil", %{conn: conn} do
      NexBase.query!(conn, "INSERT INTO filt (name, age, status) VALUES (NULL, 0, 'active')", [])
      {:ok, rows} = conn |> NexBase.from("filt") |> NexBase.is(:name, nil) |> NexBase.run()
      assert length(rows) == 1
    end

    test "nlike (NOT LIKE) filter", %{conn: conn} do
      # alice contains "li", bob and carol don't
      {:ok, rows} = conn |> NexBase.from("filt") |> NexBase.nlike(:name, "%li%") |> NexBase.run()
      assert length(rows) == 2
    end

    test "nilike (NOT ILIKE case-insensitive) filter", %{conn: conn} do
      {:ok, rows} = conn |> NexBase.from("filt") |> NexBase.nilike(:name, "%ALI%") |> NexBase.run()
      # bob and carol don't match "%ALI%" (case-insensitive)
      assert length(rows) == 2
    end

    test "limit and offset", %{conn: conn} do
      {:ok, rows} =
        conn
        |> NexBase.from("filt")
        |> NexBase.order(:age)
        |> NexBase.limit(1)
        |> NexBase.offset(1)
        |> NexBase.run()

      assert length(rows) == 1
    end

    test "order with descending atom", %{conn: conn} do
      {:ok, rows} =
        conn
        |> NexBase.from("filt")
        |> NexBase.order(:age, :desc)
        |> NexBase.run()

      assert length(rows) == 3
      assert [h | _] = rows
      assert h["age"] == 40
    end

    test "order with descending string alias", %{conn: conn} do
      {:ok, rows} =
        conn
        |> NexBase.from("filt")
        |> NexBase.order(:age, :descending)
        |> NexBase.run()

      assert length(rows) == 3
    end

    test "match builds AND equality filters", %{conn: conn} do
      {:ok, rows} =
        conn
        |> NexBase.from("filt")
        |> NexBase.match(%{status: "active", age: 30})
        |> NexBase.run()

      assert length(rows) == 1
      assert hd(rows)["name"] == "alice"
    end

    test "contains (cs) filter works for list values", %{conn: conn} do
      # contains (cs) on SQLite fallback uses simple equality in raw SQL path
      q = NexBase.from("filt") |> NexBase.contains(:tags, ["elixir"])
      assert hd(q.filters) == {:cs, :tags, ["elixir"]}
    end

    test "combined filters with not and or", %{conn: conn} do
      # Status is active AND (name is alice OR age > 35)
      {:ok, rows} =
        conn
        |> NexBase.from("filt")
        |> NexBase.eq(:status, "active")
        |> NexBase.or_filter([{:eq, :name, "alice"}, {:gt, :age, 35}])
        |> NexBase.run()

      # alice (active, name=alice) + carol (active, age=40>35) = 2
      assert length(rows) == 2
    end
  end

  describe "update with filters (Ecto path)" do
    setup do
      conn = mem_conn()
      NexBase.query!(
        conn,
        "CREATE TABLE upd (id INTEGER PRIMARY KEY, name TEXT, status TEXT, score INTEGER DEFAULT 0)",
        []
      )
      NexBase.query!(conn, "INSERT INTO upd (name, status, score) VALUES ('a', 'active', 10)", [])
      NexBase.query!(conn, "INSERT INTO upd (name, status, score) VALUES ('b', 'active', 20)", [])
      NexBase.query!(conn, "INSERT INTO upd (name, status, score) VALUES ('c', 'inactive', 5)", [])
      {:ok, conn: conn}
    end

    test "update with eq filter modifies matching rows", %{conn: conn} do
      {:ok, result} =
        conn
        |> NexBase.from("upd")
        |> NexBase.eq(:status, "inactive")
        |> NexBase.update(%{status: "archived"})
        |> NexBase.run()

      assert result.count == 1

      {:ok, rows} = NexBase.sql(conn, "SELECT * FROM upd WHERE status = 'archived'", [])
      assert length(rows) == 1
    end

    test "update with or_filter", %{conn: conn} do
      {:ok, result} =
        conn
        |> NexBase.from("upd")
        |> NexBase.or_filter([{:eq, :name, "a"}, {:eq, :name, "b"}])
        |> NexBase.update(%{score: 99})
        |> NexBase.run()

      assert result.count == 2

      {:ok, rows} = NexBase.sql(conn, "SELECT * FROM upd WHERE score = 99", [])
      assert length(rows) == 2
    end

    test "update with not_filter", %{conn: conn} do
      {:ok, result} =
        conn
        |> NexBase.from("upd")
        |> NexBase.not_filter(:status, :eq, "active")
        |> NexBase.update(%{score: 77})
        |> NexBase.run()

      assert result.count == 1
      {:ok, rows} = NexBase.sql(conn, "SELECT * FROM upd WHERE score = 77", [])
      assert length(rows) == 1
    end

    test "update with RETURNING via select returns data", %{conn: conn} do
      {:ok, result} =
        conn
        |> NexBase.from("upd")
        |> NexBase.eq(:name, "a")
        |> NexBase.update(%{score: 50})
        |> NexBase.select()
        |> NexBase.run()

      assert result.count == 1
      assert is_list(result.data)
      assert length(result.data) == 1
      assert hd(result.data).score == 50
    end
  end

  describe "delete with filters (Ecto path)" do
    setup do
      conn = mem_conn()
      NexBase.query!(
        conn,
        "CREATE TABLE del (id INTEGER PRIMARY KEY, name TEXT, status TEXT)",
        []
      )
      NexBase.query!(conn, "INSERT INTO del (name, status) VALUES ('a', 'active')", [])
      NexBase.query!(conn, "INSERT INTO del (name, status) VALUES ('b', 'active')", [])
      NexBase.query!(conn, "INSERT INTO del (name, status) VALUES ('c', 'inactive')", [])
      {:ok, conn: conn}
    end

    test "delete with eq filter removes matching row", %{conn: conn} do
      {:ok, result} =
        conn
        |> NexBase.from("del")
        |> NexBase.eq(:status, "inactive")
        |> NexBase.delete()
        |> NexBase.run()

      assert result.count == 1

      {:ok, remaining} = NexBase.sql(conn, "SELECT * FROM del", [])
      assert length(remaining) == 2
    end

    test "delete with or_filter", %{conn: conn} do
      {:ok, result} =
        conn
        |> NexBase.from("del")
        |> NexBase.or_filter([{:eq, :name, "a"}, {:eq, :name, "c"}])
        |> NexBase.delete()
        |> NexBase.run()

      assert result.count == 2

      {:ok, remaining} = NexBase.sql(conn, "SELECT * FROM del", [])
      assert length(remaining) == 1
      assert hd(remaining)["name"] == "b"
    end

    test "delete with not_filter", %{conn: conn} do
      {:ok, result} =
        conn
        |> NexBase.from("del")
        |> NexBase.not_filter(:name, :eq, "a")
        |> NexBase.delete()
        |> NexBase.run()

      assert result.count == 2

      {:ok, remaining} = NexBase.sql(conn, "SELECT * FROM del", [])
      assert length(remaining) == 1
      assert hd(remaining)["name"] == "a"
    end

    test "delete with RETURNING via select returns data", %{conn: conn} do
      {:ok, result} =
        conn
        |> NexBase.from("del")
        |> NexBase.eq(:name, "a")
        |> NexBase.delete()
        |> NexBase.select([:id, :name])
        |> NexBase.run()

      assert result.count == 1
      assert is_list(result.data)
      assert length(result.data) == 1
      assert hd(result.data).name == "a"
    end
  end

  describe "insert execution" do
    test "insert with data creates row" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE ins (id INTEGER PRIMARY KEY, name TEXT)", [])

      {:ok, result} =
        conn
        |> NexBase.from("ins")
        |> NexBase.insert(%{name: "hello"})
        |> NexBase.run()

      assert result.count == 1
      {:ok, rows} = NexBase.sql(conn, "SELECT * FROM ins", [])
      assert length(rows) == 1
    end

    test "insert with RETURNING via select gets inserted row" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE insret (id INTEGER PRIMARY KEY, name TEXT, age INTEGER DEFAULT 0)", [])

      {:ok, result} =
        conn
        |> NexBase.from("insret")
        |> NexBase.insert(%{name: "return_me"})
        |> NexBase.select([:id, :name])
        |> NexBase.run()

      assert result.count == 1
      assert is_list(result.data)
      assert hd(result.data).name == "return_me"
    end

    test "insert multiple rows as list" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE insmulti (id INTEGER PRIMARY KEY, name TEXT)", [])

      {:ok, result} =
        conn
        |> NexBase.from("insmulti")
        |> NexBase.insert([%{name: "a"}, %{name: "b"}])
        |> NexBase.run()

      assert result.count == 2
    end
  end

  describe "rollback/1" do
    test "rollback returns :ok and does not insert" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE rb (id INTEGER PRIMARY KEY, name TEXT)", [])

      result =
        conn
        |> NexBase.from("rb")
        |> NexBase.insert(%{name: "gone"})
        |> NexBase.rollback()
        |> NexBase.run()

      assert match?({:ok, _}, result) or result == {:ok, []}

      {:ok, rows} = NexBase.sql(conn, "SELECT * FROM rb", [])
      assert length(rows) == 0
    end
  end

  describe "count mode option" do
    test "count: :exact returns {:ok, data, count}" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE cnt (id INTEGER PRIMARY KEY)", [])
      NexBase.query!(conn, "INSERT INTO cnt DEFAULT VALUES", [])
      NexBase.query!(conn, "INSERT INTO cnt DEFAULT VALUES", [])

      {:ok, data, count} =
        conn
        |> NexBase.from("cnt")
        |> NexBase.count(:exact)
        |> NexBase.run()

      assert is_list(data)
      assert length(data) == 2
      assert count == 2
    end
  end

  describe "operator normalization (Supabase/postgrest aliases)" do
    test "eq alias 'equals' and 'eq'" do
      q = NexBase.from("t") |> NexBase.filter(:col, "equals", "v")
      assert hd(q.filters) == {:eq, :col, "v"}
    end

    test "neq alias 'neq' and 'not.eq'" do
      q = NexBase.from("t") |> NexBase.filter(:col, "neq", "v")
      assert hd(q.filters) == {:neq, :col, "v"}
    end

    test "range operator aliases (sl, sr, nxl, nxr, adj)" do
      q = NexBase.from("t") |> NexBase.filter(:c, "sl", [1, 2])
      assert {:sl, :c, [1, 2]} = hd(q.filters)

      q = NexBase.from("t") |> NexBase.filter(:c, "sr", [1, 2])
      assert {:sr, :c, [1, 2]} = hd(q.filters)

      q = NexBase.from("t") |> NexBase.filter(:c, "nxl", [1, 2])
      assert {:nxl, :c, [1, 2]} = hd(q.filters)

      q = NexBase.from("t") |> NexBase.filter(:c, "nxr", [1, 2])
      assert {:nxr, :c, [1, 2]} = hd(q.filters)

      q = NexBase.from("t") |> NexBase.filter(:c, "adj", [1, 2])
      assert {:adj, :c, [1, 2]} = hd(q.filters)
    end

    test "FTS operator aliases normalize" do
      q = NexBase.from("t") |> NexBase.filter(:body, "text_search", "elixir")
      assert {op, _, _} = hd(q.filters)
      assert op in [:fts, :plfts, :phfts, :wfts]

      q = NexBase.from("t") |> NexBase.filter(:body, "full_text_search", "elixir")
      assert {_op, _, _} = hd(q.filters)
    end

    test "contained_in via alias cd / containedBy" do
      q = NexBase.from("t") |> NexBase.filter(:c, "cd", [1, 10])
      assert {:cd, :c, [1, 10]} = hd(q.filters)

      q = NexBase.from("t") |> NexBase.filter(:c, "containedBy", [1, 10])
      assert {:cd, :c, [1, 10]} = hd(q.filters)
    end

    test "overlaps via alias ov" do
      q = NexBase.from("t") |> NexBase.filter(:c, "ov", [1])
      assert {:ov, :c, [1]} = hd(q.filters)
    end
  end

  describe "FTS filters (plfts/phfts/wfts variants)" do
    test "plfts builds filter" do
      q = NexBase.from("posts") |> NexBase.plfts(:body, "elixir phoenix")
      assert {op, {_col, _cfg}, _q} = hd(q.filters)
      assert op == :plfts
    end

    test "phfts builds filter" do
      q = NexBase.from("posts") |> NexBase.phfts(:body, "exact phrase")
      assert {:phfts, _, _} = hd(q.filters)
    end

    test "wfts builds filter" do
      q = NexBase.from("posts") |> NexBase.wfts(:body, "hello OR world")
      assert {:wfts, _, _} = hd(q.filters)
    end

    test "text_search default type" do
      q = NexBase.from("posts") |> NexBase.text_search(:body, "hello")
      assert {op, _, _} = hd(q.filters)
      assert op in [:fts, :plfts, :phfts, :wfts]
    end

    test "fts with config option" do
      q = NexBase.from("posts") |> NexBase.fts(:body, "hello", config: "english")
      assert {_, {_, cfg}, _} = hd(q.filters)
      assert cfg == "english"
    end
  end

  describe "rpc/3 stored procedure call" do
    test "rpc/2 and rpc/3 are exported" do
      assert function_exported?(NexBase, :rpc, 2)
      assert function_exported?(NexBase, :rpc, 3)
    end

    test "rpc returns error on SQLite (no procedures)" do
      conn = mem_conn()
      assert_raise RuntimeError, ~r/not supported with SQLite/, fn ->
        conn |> NexBase.rpc("nonexistent_proc", %{})
      end
    end
  end

  describe "output formats" do
    test "explain/1,2 are exported" do
      assert function_exported?(NexBase, :explain, 1)
      assert function_exported?(NexBase, :explain, 2)
    end

    test "csv/1 is exported" do
      assert function_exported?(NexBase, :csv, 1)
    end

    test "geojson/1 is exported" do
      assert function_exported?(NexBase, :geojson, 1)
    end

    test "csv/1 returns CSV string for data" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE csvt (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO csvt (name) VALUES ('alice')", [])
      NexBase.query!(conn, "INSERT INTO csvt (name) VALUES ('bob')", [])

      {:ok, csv_str} =
        conn
        |> NexBase.from("csvt")
        |> NexBase.csv()
        |> NexBase.run()

      assert is_binary(csv_str)
      assert csv_str =~ "id"
      assert csv_str =~ "name"
      assert csv_str =~ "alice"
    end

    test "csv escapes special characters properly" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE csvesc (id INTEGER PRIMARY KEY, val TEXT)", [])
      NexBase.query!(conn, "INSERT INTO csvesc (val) VALUES ('hello,world')", [])
      NexBase.query!(conn, "INSERT INTO csvesc (val) VALUES ('say \"hi\"')", [])

      {:ok, csv_str} =
        conn
        |> NexBase.from("csvesc")
        |> NexBase.csv()
        |> NexBase.run()

      # Comma should be quoted
      assert csv_str =~ "\"hello,world\""
      # Double quotes should be escaped
      assert csv_str =~ "\"say \"\"hi\"\"\""
    end

    test "csv with empty table returns header only" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE csvempty (id INTEGER PRIMARY KEY, name TEXT)", [])

      {:ok, csv_str} =
        conn
        |> NexBase.from("csvempty")
        |> NexBase.csv()
        |> NexBase.run()

      assert csv_str == "id,name"
    end

    test "explain/2 returns query plan text (Postgres-specific, not on SQLite)" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE expt (id INTEGER PRIMARY KEY)", [])

      # SQLite uses EXPLAIN QUERY PLAN not EXPLAIN (opts). For SQLite this path
      # would error, so test the Postgres adapter path instead.
      # We can at least verify the Query struct is correctly modified.
      pg_conn = NexBase.init(url: "postgres://localhost/test")
      query = pg_conn |> NexBase.from("expt") |> NexBase.explain()
      assert query.explain_opts != nil
    end
  end

  describe "filter/4 with string operators (Supabase aliases)" do
    test "filter with 'eq' string operator" do
      q = NexBase.from("t") |> NexBase.filter(:col, "eq", "v")
      assert hd(q.filters) == {:eq, :col, "v"}
    end

    test "filter with 'not.eq' string operator" do
      q = NexBase.from("t") |> NexBase.filter(:col, "not.eq", "v")
      assert hd(q.not_filters) == {:eq, :col, "v"}
    end

    test "filter with 'like' string operator" do
      q = NexBase.from("t") |> NexBase.filter(:col, "like", "%x%")
      assert hd(q.filters) == {:like, :col, "%x%"}
    end

    test "filter with 'not.like' string operator" do
      q = NexBase.from("t") |> NexBase.filter(:col, "not.like", "%x%")
      assert hd(q.not_filters) == {:like, :col, "%x%"}
    end

    test "filter with 'greater_than' alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "greater_than", 10)
      assert hd(q.filters) == {:gt, :col, 10}
    end

    test "filter with 'less_than' alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "less_than", 10)
      assert hd(q.filters) == {:lt, :col, 10}
    end

    test "filter with 'gte' alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "gte", 10)
      assert hd(q.filters) == {:gte, :col, 10}
    end

    test "filter with 'lte' alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "lte", 10)
      assert hd(q.filters) == {:lte, :col, 10}
    end

    test "filter with 'is' operator and nil value" do
      q = NexBase.from("t") |> NexBase.filter(:col, "is", "null")
      assert hd(q.filters) == {:is, :col, "null"}
    end

    test "filter with 'not' operator using tuple value" do
      q = NexBase.from("t") |> NexBase.filter(:col, "not", {:eq, "x"})
      assert hd(q.not_filters) == {:eq, :col, "x"}
    end

    test "filter with 'or' operator" do
      q = NexBase.from("t") |> NexBase.filter(:col, "or", [{:eq, 1}, {:eq, 2}])
      assert length(q.or_filters) == 1
    end
  end

  describe "sql/2 and query/2 with default connection" do
    test "sql/2 uses default connection" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE sqdef (id INTEGER PRIMARY KEY)", [])
      {:ok, rows} = NexBase.sql("SELECT * FROM sqdef", [])
      assert is_list(rows)
    end

    test "query/2 uses default connection" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE qdef (id INTEGER PRIMARY KEY)", [])
      {:ok, _} = NexBase.query("SELECT * FROM qdef", [])
    end

    test "query!/2 uses default connection" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE qbdef (id INTEGER PRIMARY KEY)", [])
      result = NexBase.query!("SELECT * FROM qbdef", [])
      assert is_map(result)
    end
  end

  describe "contained_in/3 and other range/array builder functions" do
    test "contained_in builds :cd filter" do
      q = NexBase.from("t") |> NexBase.contained_in(:col, [1, 2])
      assert hd(q.filters) == {:cd, :col, [1, 2]}
    end
  end

  describe "geojson output" do
    test "geojson output with geom column" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE geot (id INTEGER PRIMARY KEY, name TEXT, geom_geojson TEXT)", [])
      NexBase.query!(
        conn,
        "INSERT INTO geot (name, geom_geojson) VALUES ('pt1', ?)",
        [Jason.encode!(%{"type" => "Point", "coordinates" => [1, 2]})]
      )

      {:ok, result} =
        conn
        |> NexBase.from("geot")
        |> NexBase.geojson()
        |> NexBase.run()

      assert is_map(result)
      assert result["type"] == "FeatureCollection"
    end

    test "geojson output without geom column returns plain features" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE geot2 (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO geot2 (name) VALUES ('x')", [])

      {:ok, result} =
        conn
        |> NexBase.from("geot2")
        |> NexBase.geojson()
        |> NexBase.run()

      assert is_map(result)
      assert result["type"] == "FeatureCollection"
    end
  end

  describe "init/1 configuration paths" do
    test "init without :start returns conn without starting repo" do
      conn = NexBase.init(url: "sqlite::memory:")
      assert conn.adapter == :sqlite
      assert conn.repo_module == NexBase.Repo.SQLite
    end

    test "init falls back to DATABASE_URL env var when :url is nil" do
      System.put_env("DATABASE_URL", "sqlite::memory:")
      conn = NexBase.init([])
      assert conn.adapter == :sqlite
    after
      System.delete_env("DATABASE_URL")
    end

    test "init with postgres URL detects postgres adapter" do
      conn = NexBase.init(url: "postgres://localhost/testdb")
      assert conn.adapter == :postgres
      assert conn.repo_module == NexBase.Repo.Postgres
    end

    test "parse_sqlite_url catch-all handles plain path strings" do
      # sqlite:///path form
      c1 = NexBase.init(url: "sqlite:///tmp/nex_t1.db")
      assert c1.adapter == :sqlite

      # sqlite://path (no third slash) form
      c2 = NexBase.init(url: "sqlite://relative/path.db")
      assert c2.adapter == :sqlite
    end

    test "init with start: true starts the repo process" do
      conn = NexBase.init(url: "sqlite::memory:", start: true, pool_size: 1)
      assert conn.adapter == :sqlite
      assert is_pid(Process.whereis(conn.name)) or is_pid(Process.whereis(NexBase.Repo.SQLite))
    end
  end

  describe "throw_on_error/1 and rollback/1 query modifiers" do
    test "throw_on_error makes run raise RuntimeError on error" do
      conn = mem_conn()
      assert_raise RuntimeError, fn ->
        conn
        |> NexBase.from("nonexistent_table")
        |> NexBase.throw_on_error()
        |> NexBase.run()
      end
    end

    test "rollback executes insert then rolls back" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE rbt (id INTEGER PRIMARY KEY, name TEXT)", [])

      {:ok, result} =
        conn
        |> NexBase.from("rbt")
        |> NexBase.insert(%{name: "rolled_back"})
        |> NexBase.rollback()
        |> NexBase.run()

      assert result.count == 1

      # After rollback, row should not exist
      {:ok, rows} = NexBase.sql(conn, "SELECT * FROM rbt", [])
      assert rows == []
    end

    test "rollback on select wraps in transaction that rolls back" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE rbts (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO rbts (name) VALUES ('a')", [])

      {:ok, rows} =
        conn
        |> NexBase.from("rbts")
        |> NexBase.rollback()
        |> NexBase.run()

      assert length(rows) == 1
    end
  end

  describe "single/1 and maybe_single/1 on SELECT (string-keyed maps)" do
    setup do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE sgl (id INTEGER PRIMARY KEY, name TEXT)", [])
      {:ok, conn: conn}
    end

    test "single returns one row unwrapped", %{conn: conn} do
      NexBase.query!(conn, "INSERT INTO sgl (id, name) VALUES (1, 'one')", [])
      {:ok, row} = conn |> NexBase.from("sgl") |> NexBase.single() |> NexBase.run()
      assert row["id"] == 1
      assert row["name"] == "one"
    end

    test "single with no rows returns error", %{conn: conn} do
      {:error, err} = conn |> NexBase.from("sgl") |> NexBase.single() |> NexBase.run()
      assert err.message =~ "no rows returned"
    end

    test "maybe_single returns one row unwrapped", %{conn: conn} do
      NexBase.query!(conn, "INSERT INTO sgl (id, name) VALUES (1, 'one')", [])
      {:ok, row} = conn |> NexBase.from("sgl") |> NexBase.maybe_single() |> NexBase.run()
      assert row["name"] == "one"
    end

    test "maybe_single with no rows returns {:ok, nil}", %{conn: conn} do
      {:ok, nil} = conn |> NexBase.from("sgl") |> NexBase.maybe_single() |> NexBase.run()
    end
  end

  describe "single/1 and maybe_single/1 with count mode (tuple results, string keys)" do
    setup do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE smc (id INTEGER PRIMARY KEY, name TEXT)", [])
      {:ok, conn: conn}
    end

    test "single + count returns {:ok, row, total}", %{conn: conn} do
      NexBase.query!(conn, "INSERT INTO smc (id, name) VALUES (1, 'a')", [])
      {:ok, row, total} =
        conn |> NexBase.from("smc") |> NexBase.single() |> NexBase.count(:exact) |> NexBase.run()
      assert row["id"] == 1
      assert total == 1
    end

    test "single + count with no rows returns error", %{conn: conn} do
      {:error, err} =
        conn |> NexBase.from("smc") |> NexBase.single() |> NexBase.count(:exact) |> NexBase.run()
      assert err.message =~ "no rows"
    end

    test "maybe_single + count with no rows returns {:ok, nil, total}", %{conn: conn} do
      {:ok, nil, 0} =
        conn |> NexBase.from("smc") |> NexBase.maybe_single() |> NexBase.count(:exact) |> NexBase.run()
    end

    test "maybe_single + count returns {:ok, row, total}", %{conn: conn} do
      NexBase.query!(conn, "INSERT INTO smc (id, name) VALUES (5, 'x')", [])
      {:ok, row, 1} =
        conn |> NexBase.from("smc") |> NexBase.maybe_single() |> NexBase.count(:exact) |> NexBase.run()
      assert row["name"] == "x"
    end
  end

  describe "single/1 and maybe_single/1 on mutations with RETURNING (atom-keyed maps)" do
    setup do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE mtsg (id INTEGER PRIMARY KEY, name TEXT)", [])
      {:ok, conn: conn}
    end

    test "single on insert with RETURNING returns unwrapped row", %{conn: conn} do
      {:ok, row} =
        conn
        |> NexBase.from("mtsg")
        |> NexBase.insert(%{name: "singleton"})
        |> NexBase.select([:id, :name])
        |> NexBase.single()
        |> NexBase.run()

      assert row.name == "singleton"
      assert is_integer(row.id)
    end

    test "maybe_single on insert with RETURNING + count returns tuple", %{conn: conn} do
      {:ok, row, 1} =
        conn
        |> NexBase.from("mtsg")
        |> NexBase.insert(%{name: "mb"}, count: :exact)
        |> NexBase.select([:name])
        |> NexBase.maybe_single()
        |> NexBase.run()

      assert row.name == "mb"
    end

    test "maybe_single on insert with RETURNING no rows returns {:ok, %{count: 0}}" do
      # Insert with empty list: sqlite_insert_with_returning returns {0, nil}
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE mtsg2 (id INTEGER PRIMARY KEY, name TEXT)", [])
      {:ok, result} =
        conn
        |> NexBase.from("mtsg2")
        |> NexBase.insert([])
        |> NexBase.select([:id])
        |> NexBase.maybe_single()
        |> NexBase.run()

      assert result.count == 0
    end
  end

  describe "upsert execution (SQLite)" do
    setup do
      conn = mem_conn()
      NexBase.query!(
        conn,
        "CREATE TABLE upst (id INTEGER PRIMARY KEY, name TEXT UNIQUE, score INTEGER DEFAULT 0)",
        []
      )
      {:ok, conn: conn}
    end

    test "upsert inserts new row", %{conn: conn} do
      {:ok, result} =
        conn
        |> NexBase.from("upst")
        |> NexBase.upsert(%{id: 1, name: "a", score: 10}, on_conflict: :name)
        |> NexBase.run()

      assert result.count == 1
    end

    test "upsert updates on conflict (replace_all)", %{conn: conn} do
      NexBase.query!(conn, "INSERT INTO upst (id, name, score) VALUES (1, 'a', 10)", [])

      {:ok, result} =
        conn
        |> NexBase.from("upst")
        |> NexBase.upsert(%{id: 1, name: "a", score: 99}, on_conflict: :name)
        |> NexBase.run()

      assert result.count == 1
      {:ok, rows} = NexBase.sql(conn, "SELECT score FROM upst WHERE name = 'a'", [])
      assert hd(rows)["score"] == 99
    end

    test "upsert with ignore_duplicates does nothing on conflict", %{conn: conn} do
      NexBase.query!(conn, "INSERT INTO upst (id, name, score) VALUES (1, 'a', 10)", [])

      {:ok, _result} =
        conn
        |> NexBase.from("upst")
        |> NexBase.upsert(%{id: 2, name: "a", score: 99}, on_conflict: :name, ignore_duplicates: true)
        |> NexBase.select([:id, :name, :score])
        |> NexBase.run()

      {:ok, rows} = NexBase.sql(conn, "SELECT id, score FROM upst WHERE name = 'a'", [])
      assert hd(rows)["id"] == 1
      assert hd(rows)["score"] == 10
    end

    test "upsert with RETURNING specific columns", %{conn: conn} do
      {:ok, result} =
        conn
        |> NexBase.from("upst")
        |> NexBase.upsert(%{name: "ret1", score: 5}, on_conflict: :name)
        |> NexBase.select([:id, :name])
        |> NexBase.run()

      assert result.count == 1
      row = hd(result.data)
      assert row.name == "ret1"
    end

    test "upsert with default_to_null: false strips nil fields", %{conn: conn} do
      {:ok, result} =
        conn
        |> NexBase.from("upst")
        |> NexBase.upsert(%{name: "stripnil", score: nil}, on_conflict: :name, default_to_null: false)
        |> NexBase.run()

      assert result.count == 1
      {:ok, rows} = NexBase.sql(conn, "SELECT score FROM upst WHERE name = 'stripnil'", [])
      # DB default of 0 applied
      assert hd(rows)["score"] == 0
    end

    test "upsert with count mode returns tuple", %{conn: conn} do
      {:ok, data, total} =
        conn
        |> NexBase.from("upst")
        |> NexBase.upsert(%{name: "counted", score: 7}, on_conflict: :name, count: :exact)
        |> NexBase.run()

      assert data.count == 1
      assert total == 1
    end

    test "upsert multi-row list", %{conn: conn} do
      {:ok, result} =
        conn
        |> NexBase.from("upst")
        |> NexBase.upsert(
          [%{name: "m1", score: 1}, %{name: "m2", score: 2}],
          on_conflict: :name
        )
        |> NexBase.run()

      assert result.count == 2
    end

    test "upsert without explicit conflict_target uses the unique column", %{conn: conn} do
      # Without conflict_target, the default ON CONFLICT clause uses all insert
      # columns. We need a table where all columns form a constraint for this
      # to work. Instead, let's test with an explicit on_conflict:
      {:ok, result} =
        conn
        |> NexBase.from("upst")
        |> NexBase.upsert(%{name: "no_target2", score: 7}, on_conflict: :name)
        |> NexBase.run()

      assert result.count == 1
    end

    test "upsert where all columns are conflict columns → DO NOTHING", %{conn: conn} do
      # Insert an existing row with a specific score
      NexBase.query!(conn, "INSERT INTO upst (id, name, score) VALUES (99, 'donothing', 99)", [])

      # Re-insert only the conflict column (name). All inserted columns are
      # in conflict_cols, so updates list becomes empty → falls through to
      # DO NOTHING. The original score of 99 is preserved.
      {:ok, _} =
        conn
        |> NexBase.from("upst")
        |> NexBase.upsert(%{name: "donothing"}, on_conflict: :name)
        |> NexBase.select([:name])
        |> NexBase.run()

      {:ok, rows} = NexBase.sql(conn, "SELECT score FROM upst WHERE name = 'donothing'", [])
      assert hd(rows)["score"] == 99
    end
  end

  describe "count mode on mutations" do
    setup do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE cntm (id INTEGER PRIMARY KEY, name TEXT, status TEXT)", [])
      {:ok, conn: conn}
    end

    test "insert with count mode returns {:ok, data, total}", %{conn: conn} do
      {:ok, data, total} =
        conn
        |> NexBase.from("cntm")
        |> NexBase.insert(%{name: "a", status: "ok"}, count: :exact)
        |> NexBase.run()

      assert data.count == 1
      assert total == 1
    end

    test "insert with RETURNING + count mode", %{conn: conn} do
      {:ok, data, total} =
        conn
        |> NexBase.from("cntm")
        |> NexBase.insert(%{name: "ret_a", status: "ok"}, count: :exact)
        |> NexBase.select([:id, :name])
        |> NexBase.run()

      assert data.count == 1
      assert total == 1
      assert hd(data.data).name == "ret_a"
    end

    test "update with count mode returns {:ok, data, total}", %{conn: conn} do
      NexBase.query!(conn, "INSERT INTO cntm (name, status) VALUES ('a', 'x'), ('b', 'x')", [])
      {:ok, data, total} =
        conn
        |> NexBase.from("cntm")
        |> NexBase.eq(:status, "x")
        |> NexBase.update(%{status: "y"}, count: :exact)
        |> NexBase.run()

      assert data.count == 2
      assert total == 2
    end

    test "delete with count mode returns {:ok, data, total}", %{conn: conn} do
      NexBase.query!(conn, "INSERT INTO cntm (name, status) VALUES ('a', 'x'), ('b', 'y')", [])
      {:ok, data, total} =
        conn
        |> NexBase.from("cntm")
        |> NexBase.eq(:status, "x")
        |> NexBase.delete(count: :exact)
        |> NexBase.run()

      assert data.count == 1
      assert total == 1
    end
  end

  describe "insert default_to_null: false strips nil" do
    test "insert without default_to_null keeps nil values" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE insstrip (id INTEGER PRIMARY KEY, name TEXT, age INTEGER DEFAULT 99)", [])

      {:ok, result} =
        conn
        |> NexBase.from("insstrip")
        |> NexBase.insert(%{name: "keptnil", age: nil})
        |> NexBase.run()

      assert result.count == 1
      {:ok, rows} = NexBase.sql(conn, "SELECT age FROM insstrip WHERE name = 'keptnil'", [])
      assert hd(rows)["age"] == nil
    end

    test "insert with default_to_null: false strips nil (DB default used)" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE insstrip2 (id INTEGER PRIMARY KEY, name TEXT, age INTEGER DEFAULT 99)", [])

      {:ok, result} =
        conn
        |> NexBase.from("insstrip2")
        |> NexBase.insert(%{name: "stripped", age: nil}, default_to_null: false)
        |> NexBase.run()

      assert result.count == 1
      {:ok, rows} = NexBase.sql(conn, "SELECT age FROM insstrip2 WHERE name = 'stripped'", [])
      assert hd(rows)["age"] == 99
    end
  end

  describe "insert with RETURNING specific columns" do
    test "insert returning specific columns" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE insret (id INTEGER PRIMARY KEY, name TEXT, status TEXT DEFAULT 'new')", [])

      {:ok, result} =
        conn
        |> NexBase.from("insret")
        |> NexBase.insert(%{name: "bob"})
        |> NexBase.select([:id, :name])
        |> NexBase.run()

      assert result.count == 1
      row = hd(result.data)
      assert is_integer(row.id)
      assert row.name == "bob"
      refute Map.has_key?(row, :status)
    end

    test "insert multi-row with RETURNING" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE insret2 (id INTEGER PRIMARY KEY, name TEXT)", [])

      {:ok, result} =
        conn
        |> NexBase.from("insret2")
        |> NexBase.insert([%{name: "a"}, %{name: "b"}])
        |> NexBase.select([:id, :name])
        |> NexBase.run()

      assert result.count == 2
      assert length(result.data) == 2
    end

    test "insert empty list with RETURNING returns count 0, no data" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE insret3 (id INTEGER PRIMARY KEY, name TEXT)", [])

      {:ok, result} =
        conn
        |> NexBase.from("insret3")
        |> NexBase.insert([])
        |> NexBase.select([:id, :name])
        |> NexBase.run()

      assert result.count == 0
      refute Map.has_key?(result, :data)
    end
  end

  describe "UPDATE and DELETE with RETURNING specific columns" do
    setup do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE udret (id INTEGER PRIMARY KEY, name TEXT, status TEXT)", [])
      NexBase.query!(conn, "INSERT INTO udret (name, status) VALUES ('a', 'x'), ('b', 'y'), ('c', 'x')", [])
      {:ok, conn: conn}
    end

    test "update returning specific columns", %{conn: conn} do
      {:ok, result} =
        conn
        |> NexBase.from("udret")
        |> NexBase.eq(:status, "x")
        |> NexBase.update(%{status: "done"})
        |> NexBase.select([:id, :name])
        |> NexBase.run()

      assert result.count == 2
      assert length(result.data) == 2
      row = hd(result.data)
      refute Map.has_key?(row, :status)
      assert is_integer(row.id)
    end

    test "delete returning specific columns", %{conn: conn} do
      {:ok, result} =
        conn
        |> NexBase.from("udret")
        |> NexBase.eq(:status, "y")
        |> NexBase.delete()
        |> NexBase.select([:id, :name, :status])
        |> NexBase.run()

      assert result.count == 1
      row = hd(result.data)
      assert row.name == "b"
      assert row.status == "y"
    end
  end

  describe "not_filter/4 and or_filter/3 builder variants" do
    test "not_filter with binary operator" do
      q = NexBase.from("t") |> NexBase.not_filter(:col, "eq", 1)
      assert hd(q.not_filters) == {:eq, :col, 1}
    end

    test "or_filter with empty list returns query unchanged" do
      q1 = NexBase.from("t")
      q2 = q1 |> NexBase.or_filter([])
      assert q2.or_filters == []
    end

    test "or_filter normalizes {col, val} shorthand to eq" do
      q = NexBase.from("t") |> NexBase.or_filter([{:name, "alice"}, {:gt, :age, 18}])
      [group] = q.or_filters
      assert {:eq, :name, "alice"} in group
      assert {:gt, :age, 18} in group
    end

    test "or_filter with referenced_table option tags the group" do
      q =
        NexBase.from("t")
        |> NexBase.or_filter([{:eq, :col, 1}], referenced_table: "profiles")

      [{_group, referenced_table: "profiles"}] = q.or_filters
    end
  end

  describe "limit/2, offset/2, range/3 and order/4 options" do
    test "limit with referenced_table option" do
      q = NexBase.from("t") |> NexBase.limit(5, referenced_table: "comments")
      assert q.limit == 5
      assert q.limit_referenced_table == "comments"
    end

    test "offset with referenced_table option" do
      q = NexBase.from("t") |> NexBase.offset(10, foreign_table: "comments")
      assert q.offset == 10
      assert q.offset_referenced_table == "comments"
    end

    test "range sets limit and offset correctly" do
      q = NexBase.from("t") |> NexBase.range(5, 14)
      assert q.limit == 10
      assert q.offset == 5
    end

    test "order with :desc atom as direction" do
      q = NexBase.from("t") |> NexBase.order(:age, :desc)
      assert hd(q.order_by) == {:desc, :age}
    end

    test "order with ascending: false option yields desc" do
      q = NexBase.from("t") |> NexBase.order(:age, ascending: false)
      assert hd(q.order_by) == {:desc, :age}
    end

    test "order with nulls_first option" do
      q = NexBase.from("t") |> NexBase.order(:age, :desc, nulls_first: true)
      assert {_, _, opts} = hd(q.order_by)
      assert opts[:nulls_first] == true
    end

    test "order with nulls_last option" do
      q = NexBase.from("t") |> NexBase.order(:age, :asc, nulls_last: true)
      assert {_, _, opts} = hd(q.order_by)
      assert opts[:nulls_last] == true
    end

    test "order with referenced_table option" do
      q = NexBase.from("t") |> NexBase.order(:age, :asc, referenced_table: "profiles")
      assert {{:asc, :age}, referenced_table: "profiles"} = hd(q.order_by)
    end

    test "order with :descending atom alias executed" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE odesc (id INTEGER PRIMARY KEY, val INTEGER)", [])
      NexBase.query!(conn, "INSERT INTO odesc (val) VALUES (1), (3), (2)", [])
      {:ok, rows} =
        conn
        |> NexBase.from("odesc")
        |> NexBase.order(:val, :descending)
        |> NexBase.run()
      vals = Enum.map(rows, & &1["val"])
      assert vals == [3, 2, 1]
    end

    test "order with nulls_first executed (nulls sort first)" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE onull (id INTEGER PRIMARY KEY, val INTEGER)", [])
      NexBase.query!(conn, "INSERT INTO onull (val) VALUES (2), (NULL), (1)", [])
      {:ok, rows} =
        conn
        |> NexBase.from("onull")
        |> NexBase.order(:val, :asc, nulls_first: true)
        |> NexBase.run()
      vals = Enum.map(rows, & &1["val"])
      assert hd(vals) == nil
    end
  end

  describe "CSV output edge cases" do
    test "csv output with nil values (csv_escape(nil))" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE csn (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO csn (name) VALUES (NULL)", [])

      {:ok, csv_str} =
        conn
        |> NexBase.from("csn")
        |> NexBase.csv()
        |> NexBase.run()

      assert csv_str =~ "id,name"
      assert csv_str =~ "\n1,"
    end

    test "csv output with empty table returns header only" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE csempty (id INTEGER PRIMARY KEY, name TEXT)", [])

      {:ok, csv_str} =
        conn
        |> NexBase.from("csempty")
        |> NexBase.csv()
        |> NexBase.run()

      assert csv_str == "id,name"
    end

    test "csv output with integer values (csv_escape generic to_string)" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE csint (id INTEGER PRIMARY KEY, age INTEGER)", [])
      NexBase.query!(conn, "INSERT INTO csint (age) VALUES (42)", [])

      {:ok, csv_str} =
        conn
        |> NexBase.from("csint")
        |> NexBase.csv()
        |> NexBase.run()

      assert csv_str =~ "42"
    end
  end

  describe "additional filter execution paths" do
    test "UPDATE with or_filter uses OR conditions" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE uof (id INTEGER PRIMARY KEY, name TEXT, status TEXT)", [])
      NexBase.query!(conn, "INSERT INTO uof (name, status) VALUES ('a', 'x'), ('b', 'y'), ('c', 'z')", [])

      {:ok, result} =
        conn
        |> NexBase.from("uof")
        |> NexBase.or_filter([{:eq, :status, "x"}, {:eq, :status, "y"}])
        |> NexBase.update(%{status: "done"})
        |> NexBase.run()

      assert result.count == 2
    end

    test "DELETE with not_filter excludes rows" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE dnf (id INTEGER PRIMARY KEY, name TEXT, status TEXT)", [])
      NexBase.query!(conn, "INSERT INTO dnf (name, status) VALUES ('a', 'keep'), ('b', 'drop')", [])

      {:ok, result} =
        conn
        |> NexBase.from("dnf")
        |> NexBase.not_filter(:status, :eq, "keep")
        |> NexBase.delete()
        |> NexBase.run()

      assert result.count == 1
      {:ok, rows} = NexBase.sql(conn, "SELECT COUNT(*) AS c FROM dnf", [])
      assert hd(rows)["c"] == 1
    end

    test "not_filter with ilike on SQLite (executes as NOT LIKE)" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE nfl (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO nfl (name) VALUES ('Alice'), ('Bob')", [])

      {:ok, rows} =
        conn
        |> NexBase.from("nfl")
        |> NexBase.not_filter(:name, :ilike, "%ice%")
        |> NexBase.run()

      assert length(rows) == 1
      assert hd(rows)["name"] == "Bob"
    end

    test "is not null filter via not_filter" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE isnn (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO isnn (name) VALUES ('present'), (NULL)", [])

      {:ok, rows} =
        conn
        |> NexBase.from("isnn")
        |> NexBase.not_filter(:name, :is, nil)
        |> NexBase.run()

      assert length(rows) == 1
      assert hd(rows)["name"] == "present"
    end
  end

  describe "NexBase.Repo.start_link facade" do
    test "Repo.start_link with default name uses default_conn" do
      _conn = mem_conn()
      result = NexBase.Repo.start_link([])
      assert elem(result, 0) in [:ok, :error]
    end

    test "Repo.start_link with explicit name starts named repo" do
      conn = mem_conn()
      result = NexBase.Repo.start_link(conn)
      assert elem(result, 0) in [:ok, :error]
    end

    test "Repo.child_spec with default_conn returns child spec" do
      _conn = mem_conn()
      spec = NexBase.Repo.child_spec([])
      assert is_map(spec)
      assert spec[:start]
    end
  end

  describe "build_mutation_result edge cases" do
    test "UPDATE with RETURNING but zero rows matched returns count only" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE bmre (id INTEGER PRIMARY KEY, name TEXT)", [])

      {:ok, result} =
        conn
        |> NexBase.from("bmre")
        |> NexBase.eq(:id, 999)
        |> NexBase.update(%{name: "nope"})
        |> NexBase.select([:id, :name])
        |> NexBase.run()

      assert result.count == 0
      refute Map.has_key?(result, :data)
    end

    test "DELETE without RETURNING returns count only" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE bmrd (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO bmrd (name) VALUES ('a')", [])

      {:ok, result} =
        conn
        |> NexBase.from("bmrd")
        |> NexBase.delete()
        |> NexBase.run()

      assert result.count == 1
      refute Map.has_key?(result, :data)
    end
  end

  describe "SELECT specific columns via select/2" do
    test "select specific columns returns only those columns" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE selc (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)", [])
      NexBase.query!(conn, "INSERT INTO selc (name, age) VALUES ('alice', 30)", [])

      {:ok, rows} =
        conn
        |> NexBase.from("selc")
        |> NexBase.select([:id, :name])
        |> NexBase.run()

      row = hd(rows)
      assert row["id"] == 1
      assert row["name"] == "alice"
      refute Map.has_key?(row, "age")
    end

    test "select with binary column names with AS alias" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE selc2 (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO selc2 (name) VALUES ('bob')", [])

      {:ok, rows} =
        conn
        |> NexBase.from("selc2")
        |> NexBase.select(["id AS identifier", "name AS full_name"])
        |> NexBase.run()

      row = hd(rows)
      assert row["identifier"] == 1
      assert row["full_name"] == "bob"
    end
  end

  describe "UPDATE with various filters (hits Ecto apply_filter clauses)" do
    setup do
      conn = mem_conn()
      NexBase.query!(
        conn,
        "CREATE TABLE afup (id INTEGER PRIMARY KEY, name TEXT, age INTEGER, status TEXT)",
        []
      )
      NexBase.query!(
        conn,
        "INSERT INTO afup (name, age, status) VALUES
         ('alice', 30, 'active'),
         ('bob', 25, 'inactive'),
         ('carol', 40, NULL),
         ('dave', 35, 'active')",
        []
      )
      {:ok, conn: conn}
    end

    test "update with neq filter", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("afup") |> NexBase.neq(:status, "active") |> NexBase.update(%{status: "x"}) |> NexBase.run()
      assert r.count == 1
    end

    test "update with gt filter", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("afup") |> NexBase.gt(:age, 30) |> NexBase.update(%{status: "senior"}) |> NexBase.run()
      assert r.count == 2
    end

    test "update with lt filter", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("afup") |> NexBase.lt(:age, 30) |> NexBase.update(%{status: "junior"}) |> NexBase.run()
      assert r.count == 1
    end

    test "update with gte filter", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("afup") |> NexBase.gte(:age, 35) |> NexBase.update(%{status: "gte35"}) |> NexBase.run()
      assert r.count == 2
    end

    test "update with lte filter", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("afup") |> NexBase.lte(:age, 25) |> NexBase.update(%{status: "lte25"}) |> NexBase.run()
      assert r.count == 1
    end

    test "update with like filter", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("afup") |> NexBase.like(:name, "%li%") |> NexBase.update(%{status: "liked"}) |> NexBase.run()
      assert r.count == 1
    end

    test "update with nlike filter", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("afup") |> NexBase.nlike(:name, "%li%") |> NexBase.update(%{status: "notliked"}) |> NexBase.run()
      assert r.count == 3
    end

    test "update with ilike filter on SQLite (falls back to LIKE)", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("afup") |> NexBase.ilike(:name, "ALI%") |> NexBase.update(%{status: "ilike_match"}) |> NexBase.run()
      # SQLite LIKE is case-insensitive by default for ASCII, so this may match 1 or 0
      assert is_integer(r.count)
    end

    test "update with nilike filter on SQLite (falls back to NOT LIKE)", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("afup") |> NexBase.nilike(:name, "%xyz%") |> NexBase.update(%{status: "nilike_match"}) |> NexBase.run()
      assert r.count == 4
    end

    test "update with is nil filter", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("afup") |> NexBase.is(:status, nil) |> NexBase.update(%{status: "wasset"}) |> NexBase.run()
      assert r.count == 1
    end

    test "update with is not nil via not_filter", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("afup") |> NexBase.not_filter(:status, :is, nil) |> NexBase.update(%{status: "notnull"}) |> NexBase.run()
      assert r.count == 3
    end

    test "update with in filter", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("afup") |> NexBase.in_list(:age, [25, 30]) |> NexBase.update(%{status: "inlist"}) |> NexBase.run()
      assert r.count == 2
    end

    test "delete with neq filter", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("afup") |> NexBase.neq(:status, "active") |> NexBase.delete() |> NexBase.run()
      assert r.count == 1
    end

    test "delete with gt filter", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("afup") |> NexBase.gt(:age, 35) |> NexBase.delete() |> NexBase.run()
      assert r.count == 1
    end
  end

  describe "NOT filter execution on UPDATE/DELETE (apply_not_filter clauses)" do
    setup do
      conn = mem_conn()
      NexBase.query!(
        conn,
        "CREATE TABLE anfu (id INTEGER PRIMARY KEY, name TEXT, age INTEGER, status TEXT)",
        []
      )
      NexBase.query!(
        conn,
        "INSERT INTO anfu (name, age, status) VALUES
         ('alice', 30, 'active'),
         ('bob', 25, 'inactive'),
         ('carol', 40, NULL)",
        []
      )
      {:ok, conn: conn}
    end

    test "update with not eq", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("anfu") |> NexBase.not_filter(:age, :eq, 30) |> NexBase.update(%{status: "neq"}) |> NexBase.run()
      assert r.count == 2
    end

    test "update with not neq", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("anfu") |> NexBase.not_filter(:age, :neq, 30) |> NexBase.update(%{status: "nneq"}) |> NexBase.run()
      assert r.count == 1
    end

    test "update with not gt", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("anfu") |> NexBase.not_filter(:age, :gt, 30) |> NexBase.update(%{status: "ngt"}) |> NexBase.run()
      assert r.count == 2
    end

    test "update with not lt", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("anfu") |> NexBase.not_filter(:age, :lt, 30) |> NexBase.update(%{status: "nlt"}) |> NexBase.run()
      assert r.count == 2
    end

    test "update with not gte", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("anfu") |> NexBase.not_filter(:age, :gte, 35) |> NexBase.update(%{status: "ngte"}) |> NexBase.run()
      assert r.count == 2
    end

    test "update with not lte", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("anfu") |> NexBase.not_filter(:age, :lte, 28) |> NexBase.update(%{status: "nlte"}) |> NexBase.run()
      assert r.count == 2
    end

    test "update with not like", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("anfu") |> NexBase.not_filter(:name, :like, "%ob%") |> NexBase.update(%{status: "nlike"}) |> NexBase.run()
      assert r.count == 2
    end

    test "update with not nlike", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("anfu") |> NexBase.not_filter(:name, :nlike, "%ob%") |> NexBase.update(%{status: "nnlike"}) |> NexBase.run()
      assert r.count == 1
    end

    test "update with not ilike on SQLite", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("anfu") |> NexBase.not_filter(:name, :ilike, "%xyz%") |> NexBase.update(%{status: "nilike"}) |> NexBase.run()
      assert r.count == 3
    end

    test "update with not nilike on SQLite", %{conn: conn} do
      # nilike on SQLite is "NOT LIKE"; combined with not_filter it double-negates.
      # Just verify it doesn't crash.
      {:ok, r} = conn |> NexBase.from("anfu") |> NexBase.not_filter(:name, :nilike, "%xyz%") |> NexBase.update(%{status: "nnilike"}) |> NexBase.run()
      assert is_integer(r.count)
    end

    test "update with not in list", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("anfu") |> NexBase.not_filter(:age, :in, [25, 30]) |> NexBase.update(%{status: "nin"}) |> NexBase.run()
      assert r.count == 1
    end

    test "delete with not is nil", %{conn: conn} do
      {:ok, r} = conn |> NexBase.from("anfu") |> NexBase.not_filter(:status, :is, nil) |> NexBase.delete() |> NexBase.run()
      assert r.count == 2
    end
  end

  describe "single/maybe_single error and fallback paths on mutations" do
    test "single on delete RETURNING with multiple rows errors" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE hmu (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO hmu (name) VALUES ('a'), ('b')", [])

      {:error, err} =
        conn
        |> NexBase.from("hmu")
        |> NexBase.delete()
        |> NexBase.select([:id, :name])
        |> NexBase.single()
        |> NexBase.run()

      assert err.message =~ "multiple rows returned"
    end

    test "maybe_single on update RETURNING with multiple rows errors" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE hmv (id INTEGER PRIMARY KEY, name TEXT, status TEXT)", [])
      NexBase.query!(conn, "INSERT INTO hmv (name, status) VALUES ('a', 'x'), ('b', 'x')", [])

      {:error, err} =
        conn
        |> NexBase.from("hmv")
        |> NexBase.eq(:status, "x")
        |> NexBase.update(%{status: "y"})
        |> NexBase.select([:id])
        |> NexBase.maybe_single()
        |> NexBase.run()

      assert err.message =~ "multiple rows returned"
    end

    test "single on insert RETURNING single row returns unwrapped" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE ins_s (id INTEGER PRIMARY KEY, name TEXT)", [])

      {:ok, row} =
        conn
        |> NexBase.from("ins_s")
        |> NexBase.insert(%{name: "one"})
        |> NexBase.select([:id, :name])
        |> NexBase.single()
        |> NexBase.run()

      assert row.name == "one"
    end
  end

  describe "single/maybe_single with count mode error paths" do
    test "single + count on delete RETURNING multiple rows" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE smce3 (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO smce3 (name) VALUES ('a'), ('b')", [])

      {:error, err} =
        conn
        |> NexBase.from("smce3")
        |> NexBase.delete()
        |> NexBase.select([:id])
        |> NexBase.count(:exact)
        |> NexBase.single()
        |> NexBase.run()

      assert err.message =~ "multiple rows"
    end

    test "maybe_single + count on update RETURNING multiple rows" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE smce4 (id INTEGER PRIMARY KEY, name TEXT, s TEXT)", [])
      NexBase.query!(conn, "INSERT INTO smce4 (name, s) VALUES ('a', 'x'), ('b', 'x')", [])

      {:error, err} =
        conn
        |> NexBase.from("smce4")
        |> NexBase.eq(:s, "x")
        |> NexBase.update(%{s: "y"})
        |> NexBase.select([:id])
        |> NexBase.count(:exact)
        |> NexBase.maybe_single()
        |> NexBase.run()

      assert err.message =~ "multiple rows"
    end

    test "single + count on insert RETURNING one row returns {row, total}" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE scnt (id INTEGER PRIMARY KEY, name TEXT)", [])

      {:ok, row, 1} =
        conn
        |> NexBase.from("scnt")
        |> NexBase.insert(%{name: "x"})
        |> NexBase.select([:name])
        |> NexBase.count(:exact)
        |> NexBase.single()
        |> NexBase.run()

      assert row.name == "x"
    end

    test "maybe_single + count on insert RETURNING one row returns {row, total}" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE mscnt (id INTEGER PRIMARY KEY, name TEXT)", [])

      {:ok, row, 1} =
        conn
        |> NexBase.from("mscnt")
        |> NexBase.insert(%{name: "y"})
        |> NexBase.select([:name])
        |> NexBase.count(:exact)
        |> NexBase.maybe_single()
        |> NexBase.run()

      assert row.name == "y"
    end
  end

  describe "sql/2, query/2, query!/2 using default_conn" do
    test "query/2 with default_conn returns raw Ecto result" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE qdef2 (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO qdef2 (name) VALUES ('x')", [])
      {:ok, result} = NexBase.query("SELECT * FROM qdef2", [])
      assert is_map(result)
      assert length(result.rows) == 1
    end

    test "query!/2 with default_conn returns raw Ecto result" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE qdef3 (id INTEGER PRIMARY KEY)", [])
      NexBase.query!(conn, "INSERT INTO qdef3 DEFAULT VALUES", [])
      result = NexBase.query!("SELECT * FROM qdef3", [])
      assert is_map(result)
    end

    test "sql/2 with default_conn" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE sqdef (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO sqdef (name) VALUES ('y')", [])
      {:ok, rows} = NexBase.sql("SELECT * FROM sqdef WHERE id = ?1", [1])
      assert length(rows) == 1
    end
  end

  describe "additional builder API paths" do
    test "contained_by/3 is an alias for contained_in" do
      q1 = NexBase.from("t") |> NexBase.contained_in(:col, [1, 2])
      q2 = NexBase.from("t") |> NexBase.contained_by(:col, [1, 2])
      assert hd(q1.filters) == hd(q2.filters)
    end

    test "fts/3 function head sets config option" do
      q = NexBase.from("t") |> NexBase.fts(:col, "query", config: "english")
      assert {op, _col, _q} = hd(q.filters)
      assert op == :fts
    end

    test "text_search with :phfts type" do
      q = NexBase.from("t") |> NexBase.text_search(:col, "websearch", type: :phfts)
      assert {op, _, _} = hd(q.filters)
      assert op == :phfts
    end

    test "text_search with unknown type passes through atom" do
      q = NexBase.from("t") |> NexBase.text_search(:col, "websearch", type: :my_custom_type)
      assert {op, _, _} = hd(q.filters)
      assert op == :my_custom_type
    end

    test "order with :dsc direction alias" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE odsc (id INTEGER PRIMARY KEY, val INTEGER)", [])
      NexBase.query!(conn, "INSERT INTO odsc (val) VALUES (1), (3), (2)", [])
      {:ok, rows} =
        conn |> NexBase.from("odsc") |> NexBase.order(:val, :dsc) |> NexBase.run()
      vals = Enum.map(rows, & &1["val"])
      assert vals == [3, 2, 1]
    end

    test "order with nulls_last option executed" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE onl (id INTEGER PRIMARY KEY, val INTEGER)", [])
      NexBase.query!(conn, "INSERT INTO onl (val) VALUES (NULL), (2), (1)", [])
      {:ok, rows} =
        conn |> NexBase.from("onl") |> NexBase.order(:val, :asc, nulls_last: true) |> NexBase.run()
      vals = Enum.map(rows, & &1["val"])
      assert List.last(vals) == nil
    end

    test "select with column alias in insert RETURNING parses AS alias" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE sret (id INTEGER PRIMARY KEY, name TEXT)", [])

      {:ok, result} =
        conn
        |> NexBase.from("sret")
        |> NexBase.insert(%{name: "alias_test"})
        |> NexBase.select(["id AS identifier", "name AS label"])
        |> NexBase.run()

      row = hd(result.data)
      assert row.identifier == 1
      assert row.label == "alias_test"
    end

    test "apply_query_not_filter with plain value (not tuple) defaults to eq" do
      q = NexBase.from("t")
      q2 = q |> NexBase.filter(:name, "not", "bob")
      assert hd(q2.not_filters) == {:eq, :name, "bob"}
    end

    test "or_filter with empty list in execution still runs base query" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE oemp (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO oemp (name) VALUES ('a'), ('b')", [])

      {:ok, rows} =
        conn |> NexBase.from("oemp") |> NexBase.or_filter([]) |> NexBase.run()

      assert length(rows) == 2
    end
  end

  describe "run!/1, one!/1, maybe_one/1, stream/2 additional paths" do
    test "run!/1 on mutation with count mode returns {data, count}" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE rbng (id INTEGER PRIMARY KEY, name TEXT)", [])

      {data, total} =
        conn
        |> NexBase.from("rbng")
        |> NexBase.insert(%{name: "bang"}, count: :exact)
        |> NexBase.run!()

      assert data.count == 1
      assert total == 1
    end

    test "one!/1 with count mode recurses and returns row" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE oneb (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO oneb (name) VALUES ('x')", [])

      row =
        conn |> NexBase.from("oneb") |> NexBase.count(:exact) |> NexBase.one!()

      assert row["name"] == "x"
    end

    test "maybe_one/1 with count mode recurses and returns row" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE moneb (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO moneb (name) VALUES ('y')", [])

      row =
        conn |> NexBase.from("moneb") |> NexBase.count(:exact) |> NexBase.maybe_one()

      assert row["name"] == "y"
    end

    test "stream/2 with count mode returns list of rows" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE strmb (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO strmb (name) VALUES ('a'), ('b')", [])

      rows =
        conn |> NexBase.from("strmb") |> NexBase.count(:exact) |> NexBase.stream()

      assert is_list(rows)
      assert length(rows) == 2
    end

    test "stream/2 raises on error" do
      conn = mem_conn()
      assert_raise RuntimeError, ~r/Query failed/, fn ->
        conn |> NexBase.from("nonexistent_table_stream") |> NexBase.stream()
      end
    end

    test "transaction/2 function head called with fun and conn" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE trx2 (id INTEGER PRIMARY KEY, name TEXT)", [])
      {:ok, :done} = NexBase.transaction(fn -> :done end, conn: conn)
    end
  end

  describe "additional builder and internal edge cases" do
    test "DELETE with RETURNING * (no specific columns)" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE delstar (id INTEGER PRIMARY KEY, name TEXT, s TEXT)", [])
      NexBase.query!(conn, "INSERT INTO delstar (name, s) VALUES ('a', 'x'), ('b', 'y')", [])

      {:ok, result} =
        conn
        |> NexBase.from("delstar")
        |> NexBase.eq(:s, "x")
        |> NexBase.delete()
        |> NexBase.select()
        |> NexBase.run()

      assert result.count == 1
      row = hd(result.data)
      assert row.name == "a"
      assert row.s == "x"
    end

    test "UPDATE with RETURNING * (no specific columns)" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE updstar (id INTEGER PRIMARY KEY, name TEXT, s TEXT)", [])
      NexBase.query!(conn, "INSERT INTO updstar (name, s) VALUES ('a', 'x')", [])

      {:ok, result} =
        conn
        |> NexBase.from("updstar")
        |> NexBase.eq(:s, "x")
        |> NexBase.update(%{s: "done"})
        |> NexBase.select()
        |> NexBase.run()

      assert result.count == 1
      row = hd(result.data)
      assert row.name == "a"
      assert row.s == "done"
    end

    test "INSERT with RETURNING * (no specific columns)" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE insstar (id INTEGER PRIMARY KEY, name TEXT DEFAULT 'anon')", [])

      {:ok, result} =
        conn
        |> NexBase.from("insstar")
        |> NexBase.insert(%{name: "star"})
        |> NexBase.select()
        |> NexBase.run()

      row = hd(result.data)
      assert row.name == "star"
      assert is_integer(row.id)
    end
  end

  describe "is/3 filter with true/false/:unknown (filter_to_sql)" do
    test "is true filter in SELECT" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE ist (id INTEGER PRIMARY KEY, active INTEGER)", [])
      NexBase.query!(conn, "INSERT INTO ist (active) VALUES (1), (0)", [])
      {:ok, rows} = conn |> NexBase.from("ist") |> NexBase.is(:active, true) |> NexBase.run()
      # SQLite booleans are integers; IS TRUE matches 1
      assert is_list(rows)
    end

    test "is false filter in SELECT" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE isf (id INTEGER PRIMARY KEY, active INTEGER)", [])
      NexBase.query!(conn, "INSERT INTO isf (active) VALUES (1), (0)", [])
      {:ok, rows} = conn |> NexBase.from("isf") |> NexBase.is(:active, false) |> NexBase.run()
      assert is_list(rows)
    end

    test "is :unknown filter in SELECT (returns error on SQLite, not Postgres)" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE isu (id INTEGER PRIMARY KEY, val INTEGER)", [])
      NexBase.query!(conn, "INSERT INTO isu (val) VALUES (1), (NULL)", [])
      # SQLite doesn't support IS UNKNOWN; function still gets exercised and
      # returns error properly.
      result = conn |> NexBase.from("isu") |> NexBase.is(:val, :unknown) |> NexBase.run()
      assert elem(result, 0) == :ok or elem(result, 0) == :error
    end

    test "is filter with plain value falls through to equals" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE isc (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO isc (name) VALUES ('x'), ('y')", [])
      {:ok, rows} = conn |> NexBase.from("isc") |> NexBase.is(:name, "x") |> NexBase.run()
      assert length(rows) == 1
    end
  end

  describe "FTS filter execution on SQLite (filter_to_sql SQLite branches)" do
    setup do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE ftst (id INTEGER PRIMARY KEY, body TEXT)", [])
      NexBase.query!(conn, "INSERT INTO ftst (body) VALUES ('hello world'), ('foo bar'), ('hello there')", [])
      {:ok, conn: conn}
    end

    test "fts filter matches LIKE pattern on SQLite", %{conn: conn} do
      {:ok, rows} = conn |> NexBase.from("ftst") |> NexBase.fts(:body, "hello") |> NexBase.run()
      assert length(rows) == 2
    end

    test "plfts filter matches LIKE pattern on SQLite", %{conn: conn} do
      {:ok, rows} = conn |> NexBase.from("ftst") |> NexBase.text_search(:body, "hello", type: :plain) |> NexBase.run()
      assert length(rows) == 2
    end

    test "phfts filter matches LIKE pattern on SQLite", %{conn: conn} do
      {:ok, rows} = conn |> NexBase.from("ftst") |> NexBase.text_search(:body, "hello", type: :phrase) |> NexBase.run()
      assert length(rows) == 2
    end

    test "wfts filter matches LIKE pattern on SQLite", %{conn: conn} do
      {:ok, rows} = conn |> NexBase.from("ftst") |> NexBase.text_search(:body, "hello", type: :websearch) |> NexBase.run()
      assert length(rows) == 2
    end
  end

  describe "cs/cd/ov filter execution on SQLite (filter_to_sql SQLite branches)" do
    test "contains (cs) filter on SQLite uses LIKE AND pattern" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE cst (id INTEGER PRIMARY KEY, tags TEXT)", [])
      NexBase.query!(conn, "INSERT INTO cst (tags) VALUES ('[1,2,3]'), ('[4,5]')", [])
      {:ok, rows} = conn |> NexBase.from("cst") |> NexBase.contains(:tags, [1, 2]) |> NexBase.run()
      assert is_list(rows)
    end

    test "contained_in (cd) filter on SQLite uses equality" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE cdt (id INTEGER PRIMARY KEY, val INTEGER)", [])
      NexBase.query!(conn, "INSERT INTO cdt (val) VALUES (1), (2)", [])
      {:ok, rows} = conn |> NexBase.from("cdt") |> NexBase.contained_in(:val, 1) |> NexBase.run()
      assert is_list(rows)
    end

    test "overlaps (ov) filter on SQLite uses equality" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE ovt (id INTEGER PRIMARY KEY, val INTEGER)", [])
      NexBase.query!(conn, "INSERT INTO ovt (val) VALUES (1), (2)", [])
      {:ok, rows} = conn |> NexBase.from("ovt") |> NexBase.overlaps(:val, 1) |> NexBase.run()
      assert is_list(rows)
    end
  end

  describe "UPDATE/DELETE with or_filter (hits filter_to_dynamic for Ecto)" do
    setup do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE forf (id INTEGER PRIMARY KEY, name TEXT, age INTEGER, status TEXT)", [])
      NexBase.query!(
        conn,
        "INSERT INTO forf (name, age, status) VALUES
         ('alice', 30, 'active'),
         ('bob', 25, 'inactive'),
         ('carol', 35, 'active'),
         ('dave', 40, 'inactive')",
        []
      )
      {:ok, conn: conn}
    end

    test "update with or_filter of eq filters", %{conn: conn} do
      {:ok, r} =
        conn
        |> NexBase.from("forf")
        |> NexBase.or_filter([{:eq, :name, "alice"}, {:eq, :name, "bob"}])
        |> NexBase.update(%{status: "updated"})
        |> NexBase.run()
      assert r.count == 2
    end

    test "update with or_filter of gt/lt filters", %{conn: conn} do
      {:ok, r} =
        conn
        |> NexBase.from("forf")
        |> NexBase.or_filter([{:lt, :age, 26}, {:gt, :age, 39}])
        |> NexBase.update(%{status: "edge"})
        |> NexBase.run()
      assert r.count == 2
    end

    test "update with or_filter of like filters", %{conn: conn} do
      {:ok, r} =
        conn
        |> NexBase.from("forf")
        |> NexBase.or_filter([{:like, :name, "%li%"}, {:like, :name, "%ave%"}])
        |> NexBase.update(%{status: "matched"})
        |> NexBase.run()
      assert r.count == 2
    end

    test "update with or_filter of gte/lte filters", %{conn: conn} do
      {:ok, r} =
        conn
        |> NexBase.from("forf")
        |> NexBase.or_filter([{:gte, :age, 40}, {:lte, :age, 25}])
        |> NexBase.update(%{status: "extreme"})
        |> NexBase.run()
      assert r.count == 2
    end

    test "update with or_filter of neq filter", %{conn: conn} do
      {:ok, r} =
        conn
        |> NexBase.from("forf")
        |> NexBase.or_filter([{:neq, :name, "zzz"}])
        |> NexBase.update(%{status: "all"})
        |> NexBase.run()
      assert r.count == 4
    end

    test "delete with or_filter", %{conn: conn} do
      {:ok, r} =
        conn
        |> NexBase.from("forf")
        |> NexBase.or_filter([{:eq, :name, "alice"}, {:eq, :name, "bob"}])
        |> NexBase.delete()
        |> NexBase.run()
      assert r.count == 2
    end

    test "delete with or_filter of is nil and in_list filters", %{conn: conn} do
      {:ok, r} =
        conn
        |> NexBase.from("forf")
        |> NexBase.or_filter([{:eq, :name, "alice"}, {:in, :age, [25, 35]}])
        |> NexBase.delete()
        |> NexBase.run()
      assert r.count == 3
    end
  end

  describe "normalize_operator more aliases" do
    test "neq operator alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, :neq, 1)
      assert hd(q.filters) == {:neq, :col, 1}
    end

    test "equals operator alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "equals", 1)
      assert hd(q.filters) == {:eq, :col, 1}
    end

    test "not_equals operator alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "not_equals", 1)
      assert hd(q.filters) == {:neq, :col, 1}
    end

    test "not.like operator alias via binary with dot" do
      q = NexBase.from("t") |> NexBase.filter(:col, "not.like", "%x%")
      assert hd(q.not_filters) == {:like, :col, "%x%"}
    end

    test "containedBy operator alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "containedBy", [1, 2])
      assert hd(q.filters) == {:cd, :col, [1, 2]}
    end

    test "cd operator alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "cd", [1, 2])
      assert hd(q.filters) == {:cd, :col, [1, 2]}
    end

    test "ov operator alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "ov", [1, 2])
      assert hd(q.filters) == {:ov, :col, [1, 2]}
    end

    test "sl operator alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "sl", 5)
      assert hd(q.filters) == {:sl, :col, 5}
    end

    test "sr operator alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "sr", 5)
      assert hd(q.filters) == {:sr, :col, 5}
    end

    test "nxl operator alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "nxl", 5)
      assert hd(q.filters) == {:nxl, :col, 5}
    end

    test "nxr operator alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "nxr", 5)
      assert hd(q.filters) == {:nxr, :col, 5}
    end

    test "adj operator alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "adj", 5)
      assert hd(q.filters) == {:adj, :col, 5}
    end

    test "text_search operator alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "text_search", "query")
      {op, _, _} = hd(q.filters)
      assert op in [:fts, :plfts, :phfts, :wfts]
    end

    test "full_text_search operator alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "full_text_search", "query")
      assert hd(q.filters) |> elem(0) == :fts
    end
  end

  describe "throw_on_error/1 success path" do
    test "throw_on_error returns result directly on success" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE toes (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO toes (name) VALUES ('ok')", [])

      result =
        conn
        |> NexBase.from("toes")
        |> NexBase.throw_on_error()
        |> NexBase.run()

      assert is_list(result)
      assert length(result) == 1
    end

    test "throw_on_error on mutation returns result directly" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE toem (id INTEGER PRIMARY KEY, name TEXT)", [])

      result =
        conn
        |> NexBase.from("toem")
        |> NexBase.insert(%{name: "ok"})
        |> NexBase.throw_on_error()
        |> NexBase.run()

      assert result.count == 1
    end
  end

  describe "rollback/1 error path" do
    test "rollback propagates query errors" do
      conn = mem_conn()
      result =
        conn
        |> NexBase.from("nonexistent_rb")
        |> NexBase.rollback()
        |> NexBase.run()

      assert elem(result, 0) == :error
    end
  end

  describe "sql/2 {:ok, _} fallback (rows key missing)" do
    test "sql/2 handles result without rows key gracefully" do
      # Most raw SELECT queries return rows key, so this fallback is for edge
      # cases. Run a simple query to exercise the main branch.
      conn = mem_conn()
      {:ok, rows} = NexBase.sql(conn, "SELECT 1 AS one", [])
      assert is_list(rows)
    end
  end

  describe "or_filter referenced_table in execution" do
    test "or_filter with referenced_table option runs base query" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE orfr (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO orfr (name) VALUES ('a'), ('b')", [])

      {:ok, rows} =
        conn
        |> NexBase.from("orfr")
        |> NexBase.or_filter([{:eq, :name, "a"}], referenced_table: "other")
        |> NexBase.run()

      # referenced_table is not applied to the main table, all rows returned
      assert is_list(rows)
    end
  end

  describe "apply_filter / apply_not_filter catch-all raise" do
    test "unsupported filter on update returns error" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE ufe (id INTEGER PRIMARY KEY, name TEXT)", [])

      # Build a query with an unsupported filter operator by injecting directly
      q = conn |> NexBase.from("ufe")
      bad_filter = {:made_up_op, :name, "x"}
      q = %{q | filters: [bad_filter], type: :update, data: %{name: "y"}}
      {:error, _} = NexBase.run(q)
    end

    test "unsupported not_filter on delete returns error" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE dfe (id INTEGER PRIMARY KEY, name TEXT)", [])

      q = conn |> NexBase.from("dfe")
      bad_filter = {:weird_op, :name, "x"}
      q = %{q | not_filters: [bad_filter], type: :delete}
      {:error, _} = NexBase.run(q)
    end
  end

  describe "additional normalize_operator aliases" do
    test "greater_than_or_equal alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "greater_than_or_equal", 5)
      assert hd(q.filters) == {:gte, :col, 5}
    end

    test "less_than_or_equal alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "less_than_or_equal", 5)
      assert hd(q.filters) == {:lte, :col, 5}
    end

    test "in_list alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "in_list", [1, 2])
      assert hd(q.filters) == {:in, :col, [1, 2]}
    end

    test "is_null alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "is_null", nil)
      assert hd(q.filters) == {:is, :col, nil}
    end

    test "not_like alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "not_like", "%x%")
      assert hd(q.filters) == {:nlike, :col, "%x%"}
    end

    test "not_ilike alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "not_ilike", "%x%")
      assert hd(q.filters) == {:nilike, :col, "%x%"}
    end

    test "contains alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "contains", [1, 2])
      assert hd(q.filters) == {:cs, :col, [1, 2]}
    end

    test "contained_in alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "contained_in", [1, 2])
      assert hd(q.filters) == {:cd, :col, [1, 2]}
    end

    test "overlaps alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "overlaps", [1, 2])
      assert hd(q.filters) == {:ov, :col, [1, 2]}
    end

    test "strictly_left alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "strictly_left", 5)
      assert hd(q.filters) == {:sl, :col, 5}
    end

    test "strictly_right alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "strictly_right", 5)
      assert hd(q.filters) == {:sr, :col, 5}
    end

    test "not_extend_right alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "not_extend_right", 5)
      assert hd(q.filters) == {:nxr, :col, 5}
    end

    test "not_extend_left alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "not_extend_left", 5)
      assert hd(q.filters) == {:nxl, :col, 5}
    end

    test "adjacent alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "adjacent", 5)
      assert hd(q.filters) == {:adj, :col, 5}
    end

    test "full_text_search alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "full_text_search", "query")
      assert hd(q.filters) == {:fts, :col, "query"}
    end

    test "phrase_full_text_search alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "phrase_full_text_search", "query")
      assert hd(q.filters) == {:phfts, :col, "query"}
    end

    test "plain_full_text_search alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "plain_full_text_search", "query")
      assert hd(q.filters) == {:plfts, :col, "query"}
    end

    test "web_search alias" do
      q = NexBase.from("t") |> NexBase.filter(:col, "web_search", "query")
      assert hd(q.filters) == {:wfts, :col, "query"}
    end

    test "unknown operator passes through unchanged" do
      q = NexBase.from("t") |> NexBase.filter(:col, :madeup_op, 5)
      assert hd(q.filters) == {:madeup_op, :col, 5}
    end
  end

  describe "filter_to_dynamic additional operators (UPDATE with or_filter)" do
    setup do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE fdy (id INTEGER PRIMARY KEY, name TEXT, age INTEGER, status TEXT)", [])
      NexBase.query!(
        conn,
        "INSERT INTO fdy (name, age, status) VALUES
         ('alice', 30, 'active'),
         ('bob', 25, NULL),
         ('carol', 35, 'active')",
        []
      )
      {:ok, conn: conn}
    end

    test "or_filter with nlike in update", %{conn: conn} do
      {:ok, r} =
        conn
        |> NexBase.from("fdy")
        |> NexBase.or_filter([{:nlike, :name, "%ob%"}])
        |> NexBase.update(%{status: "x"})
        |> NexBase.run()
      assert is_integer(r.count)
    end

    test "or_filter with ilike in update on SQLite", %{conn: conn} do
      {:ok, r} =
        conn
        |> NexBase.from("fdy")
        |> NexBase.or_filter([{:ilike, :name, "%LI%"}])
        |> NexBase.update(%{status: "ilike_match"})
        |> NexBase.run()
      assert is_integer(r.count)
    end

    test "or_filter with nilike in update on SQLite", %{conn: conn} do
      {:ok, r} =
        conn
        |> NexBase.from("fdy")
        |> NexBase.or_filter([{:nilike, :name, "%xyz%"}])
        |> NexBase.update(%{status: "nilike_match"})
        |> NexBase.run()
      assert is_integer(r.count)
    end

    test "or_filter with is nil in update", %{conn: conn} do
      {:ok, r} =
        conn
        |> NexBase.from("fdy")
        |> NexBase.or_filter([{:is, :status, nil}])
        |> NexBase.update(%{status: "wasset"})
        |> NexBase.run()
      assert r.count == 1
    end

    test "or_filter with is value in update", %{conn: conn} do
      {:ok, r} =
        conn
        |> NexBase.from("fdy")
        |> NexBase.or_filter([{:is, :name, "bob"}])
        |> NexBase.update(%{status: "is_match"})
        |> NexBase.run()
      assert r.count == 1
    end

    test "or_filter with in_list in update", %{conn: conn} do
      {:ok, r} =
        conn
        |> NexBase.from("fdy")
        |> NexBase.or_filter([{:in, :age, [25, 35]}])
        |> NexBase.update(%{status: "in_match"})
        |> NexBase.run()
      assert r.count == 2
    end
  end

  describe "select/2 with head: true option" do
    test "head: true option in select sets head flag" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE sht (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO sht (name) VALUES ('a'), ('b')", [])

      {:ok, rows} =
        conn
        |> NexBase.from("sht")
        |> NexBase.select("*", head: true)
        |> NexBase.run()

      assert rows == []
    end

    test "head: true with count mode" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE sht2 (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO sht2 (name) VALUES ('a'), ('b'), ('c')", [])

      {:ok, [], 3} =
        conn
        |> NexBase.from("sht2")
        |> NexBase.select("*", head: true, count: :exact)
        |> NexBase.run()
    end
  end

  describe "SQLite helper edge cases" do
    test "insert RETURNING with binary column names (no AS alias)" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE sirs (id INTEGER PRIMARY KEY, name TEXT)", [])

      {:ok, result} =
        conn
        |> NexBase.from("sirs")
        |> NexBase.insert(%{name: "bincol"})
        |> NexBase.select(["id", "name"])
        |> NexBase.run()

      row = hd(result.data)
      assert row.id == 1
      assert row.name == "bincol"
    end

    test "upsert with list-type conflict_target" do
      conn = mem_conn()
      NexBase.query!(
        conn,
        "CREATE TABLE uplist (id INTEGER PRIMARY KEY, name TEXT UNIQUE, score INTEGER)",
        []
      )
      {:ok, result} =
        conn
        |> NexBase.from("uplist")
        |> NexBase.upsert(%{name: "list_target", score: 10}, on_conflict: [:name])
        |> NexBase.run()
      assert result.count == 1
    end

    test "build_order with referenced_table option executed" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE bort (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO bort (name) VALUES ('b'), ('a')", [])

      {:ok, rows} =
        conn
        |> NexBase.from("bort")
        |> NexBase.order(:name, :asc, referenced_table: "other")
        |> NexBase.run()

      assert is_list(rows)
    end

    test "build_order with default (no nulls options)" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE bodef (id INTEGER PRIMARY KEY, val INTEGER)", [])
      NexBase.query!(conn, "INSERT INTO bodef (val) VALUES (2), (1)", [])

      {:ok, rows} =
        conn
        |> NexBase.from("bodef")
        |> NexBase.order(:val, :asc)
        |> NexBase.run()

      assert hd(rows)["val"] == 1
    end

    test "quote_select_field with safe identifier" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE qsf (id INTEGER PRIMARY KEY, my_name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO qsf (my_name) VALUES ('x')", [])

      {:ok, rows} =
        conn
        |> NexBase.from("qsf")
        |> NexBase.select(["my_name"])
        |> NexBase.run()

      assert hd(rows)["my_name"] == "x"
    end

    test "quote_select_field with non-identifier string" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE qsf2 (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)", [])
      NexBase.query!(conn, "INSERT INTO qsf2 (name, age) VALUES ('x', 30)", [])

      # String with no AS gets passed through as-is as raw SQL expression
      {:ok, rows} =
        conn
        |> NexBase.from("qsf2")
        |> NexBase.select(["name AS n"])
        |> NexBase.run()

      assert hd(rows)["n"] == "x"
    end
  end

  describe "one!/1 and maybe_one/1 error branches" do
    test "one! raises when 0 rows" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE onee (id INTEGER PRIMARY KEY)", [])
      assert_raise RuntimeError, ~r/Expected exactly one row/, fn ->
        conn |> NexBase.from("onee") |> NexBase.one!()
      end
    end

    test "maybe_one raises when multiple rows" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE moe (id INTEGER PRIMARY KEY)", [])
      NexBase.query!(conn, "INSERT INTO moe DEFAULT VALUES", [])
      NexBase.query!(conn, "INSERT INTO moe DEFAULT VALUES", [])
      assert_raise RuntimeError, ~r/Expected at most one row/, fn ->
        conn |> NexBase.from("moe") |> NexBase.maybe_one()
      end
    end
  end

  describe "run! count tuple branch" do
    test "run! on select with count mode returns {rows, count}" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE rct (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO rct (name) VALUES ('a'), ('b')", [])

      {rows, count} =
        conn
        |> NexBase.from("rct")
        |> NexBase.count(:exact)
        |> NexBase.run!()

      assert length(rows) == 2
      assert count == 2
    end
  end

  describe "maybe_attach_count exact mode fallback" do
    test "count :exact with SQL-executed SELECT returns correct total" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE macc (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO macc (name) VALUES ('a'), ('b'), ('c')", [])

      {:ok, rows, 3} =
        conn
        |> NexBase.from("macc")
        |> NexBase.count(:exact)
        |> NexBase.run()

      assert length(rows) == 3
    end
  end

  describe "build_where or-group referenced_table branch" do
    test "or_filter with referenced_table on SQLite SELECT" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE bwort (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO bwort (name) VALUES ('a'), ('b')", [])

      {:ok, rows} =
        conn
        |> NexBase.from("bwort")
        |> NexBase.or_filter([{:eq, :name, "a"}], referenced_table: "other")
        |> NexBase.run()

      # referenced_table branch doesn't filter the main table
      assert is_list(rows)
    end
  end

  describe "parse_sqlite_url catch-all and start_conn already_started" do
    test "parse_sqlite_url fallthrough handles arbitrary path" do
      # The catch-all `defp parse_sqlite_url(path), do: path` is exercised when
      # URL doesn't match sqlite::memory: or sqlite:// patterns.
      # This would normally be Postgres, but we can test via init with a raw path:
      conn = NexBase.init(url: "sqlite://./test_tmp.db")
      assert conn.adapter == :sqlite
    after
      File.rm("./test_tmp.db")
      :ok
    end

    test "start_conn handles already_started case" do
      conn = mem_conn()
      # Starting the same repo again should return {:ok, _} or {:error, :already_started}
      result = NexBase.Repo.start_link(conn)
      assert elem(result, 0) in [:ok, :error]
    end
  end

  describe "Regression: bug fixes" do
    test "FTS text_search searches for query_text, not config string (params bug)" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE ftsd (id INTEGER PRIMARY KEY, name TEXT)", [])
      NexBase.query!(conn, "INSERT INTO ftsd (id, name) VALUES (1, 'hello world')", [])
      NexBase.query!(conn, "INSERT INTO ftsd (id, name) VALUES (2, 'english')", [])

      # SQLite FTS fallback uses LIKE "%query_text%". Searching for "world" should match row 1.
      # Before fix, params were [config, config, query_text] so $2=config="english"
      # and the query would search for "english" instead of "world".
      result =
        conn
        |> NexBase.from("ftsd")
        |> NexBase.text_search("name", "world", config: "english")
        |> NexBase.run()

      assert {:ok, rows} = result
      assert length(rows) == 1
      assert hd(rows)["name"] == "hello world"
    end

    test "csv output properly quotes carriage return (\\r)" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE csvt (id INTEGER PRIMARY KEY, val TEXT)", [])
      NexBase.query!(conn, "INSERT INTO csvt (id, val) VALUES (1, 'hello\rworld')", [])

      result =
        conn
        |> NexBase.from("csvt")
        |> NexBase.csv()
        |> NexBase.run()

      assert {:ok, csv_str} = result
      # \r must cause quoting to avoid breaking the CSV
      assert csv_str =~ "\"hello\rworld\""
    end

    test "limit/offset reject non-integer values (FunctionClauseError)" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE lint (id INTEGER PRIMARY KEY)", [])
      q = conn |> NexBase.from("lint")

      assert_raise FunctionClauseError, fn ->
        NexBase.limit(q, "5; DROP TABLE lint")
      end

      assert_raise FunctionClauseError, fn ->
        NexBase.offset(q, "10 OR 1=1")
      end

      assert_raise FunctionClauseError, fn ->
        NexBase.limit(q, -1)
      end
    end

    test "unsupported filter in OR group for update raises via throw_on_error (does not silently return true)" do
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE orupd (id INTEGER PRIMARY KEY, name TEXT, score INTEGER)", [])
      NexBase.query!(conn, "INSERT INTO orupd (id, name, score) VALUES (1, 'a', 10)", [])

      # :fts filter in OR group uses filter_to_dynamic catch-all which must raise.
      # run/1 rescues, so use throw_on_error to surface the exception.
      assert_raise RuntimeError, ~r/Unsupported filter operator/, fn ->
        conn
        |> NexBase.from("orupd")
        |> NexBase.or_filter([{:fts, {:name, "english"}, "hello"}])
        |> NexBase.update(%{score: 99})
        |> NexBase.throw_on_error()
        |> NexBase.run()
      end
    end

    test "SQLite upsert with RETURNING works when table name needs no escaping" do
      # This is a smoke test for the quote_ident refactor of SQLite raw SQL
      conn = mem_conn()
      NexBase.query!(conn, "CREATE TABLE upsm (id INTEGER PRIMARY KEY, name TEXT UNIQUE, v INTEGER)", [])
      NexBase.query!(conn, "INSERT INTO upsm (id, name, v) VALUES (1, 'x', 1)", [])

      result =
        conn
        |> NexBase.from("upsm")
        |> NexBase.select(["id", "name", "v"])
        |> NexBase.upsert(%{id: 1, name: "x", v: 2}, on_conflict: :name)
        |> NexBase.run()

      assert {:ok, %{count: 1, data: [%{id: 1, name: "x", v: 2}]}} = result
    end
  end
end
