defmodule NexBaseTest do
  use ExUnit.Case
  alias NexBase.Query

  # Since we don't have a real database connection, we focus on testing whether the Query Builder generates correct structures.
  # We can verify Ecto Query generation by mocking the run function or checking internal private functions,
  # but a simpler approach is to verify the NexBase.Query struct itself and ensure build_ecto_query doesn't crash.

  # Note: Since build_ecto_query is private and run requires a database connection,
  # we mainly test whether NexBase's public API correctly builds the NexBase.Query struct.
  # This "state testing" is sufficient to validate the logic of chain calls.

  describe "Query Builder" do
    test "from/1 creates initial query" do
      q = NexBase.from("users")
      assert %Query{table: "users"} = q
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
  end

  describe "Adapter Detection" do
    test "init/1 detects postgres from URL" do
      NexBase.init(url: "postgres://localhost/testdb")
      assert NexBase.adapter() == :postgres
    end

    test "init/1 detects postgres from postgresql:// URL" do
      NexBase.init(url: "postgresql://localhost/testdb")
      assert NexBase.adapter() == :postgres
    end

    test "init/1 detects sqlite from URL" do
      NexBase.init(url: "sqlite:///tmp/test.db")
      assert NexBase.adapter() == :sqlite
    end

    test "init/1 detects sqlite in-memory" do
      NexBase.init(url: "sqlite::memory:")
      assert NexBase.adapter() == :sqlite
    end

    test "init/1 defaults to postgres when no URL" do
      NexBase.init([])
      assert NexBase.adapter() == :postgres
    end
  end
end
