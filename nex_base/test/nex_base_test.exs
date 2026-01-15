defmodule NexBaseTest do
  use ExUnit.Case
  alias NexBase.Query

  # 由于我们没有真实的数据库连接，我们将重点测试 Query Builder 生成的结构是否正确
  # 我们可以通过 mock run 函数或检查内部私有函数来验证 Ecto Query 的生成，
  # 但更简单的是验证 NexBase.Query 结构体本身，以及确保 build_ecto_query 不会崩溃。

  # 注意：由于 build_ecto_query 是私有的，且 run 需要数据库连接，
  # 我们在这里主要测试 NexBase 的公共 API 是否正确构建了 NexBase.Query 结构体。
  # 这种"状态测试"足以验证链式调用的逻辑。

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
  
  # 如果我们想测试 Ecto Query 的生成，我们可以导出一个仅在测试环境可见的函数，
  # 或者在 NexBase 中添加一个 `to_ecto_query` 的辅助函数。
  # 为了演示，我们可以假设 build_ecto_query 能够正常工作。
end
