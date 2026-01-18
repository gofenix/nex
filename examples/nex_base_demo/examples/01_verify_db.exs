# 示例 01: NexBase 数据库验证
# 测试 NexBase 的数据库连接和 Fluent API 功能

require Dotenvy
# 加载 .env 到环境变量
Dotenvy.source!(".env")

# 确保 DATABASE_URL 存在
url = System.get_env("DATABASE_URL")

if is_nil(url) do
  IO.puts "⚠️  请先设置 DATABASE_URL 环境变量"
  IO.puts "   cp .env.example .env"
  System.halt(1)
end

IO.puts "🚀 NexBase 数据库验证"
IO.puts "----------------------------------------"

# 解析连接字符串用于显示
uri = URI.parse(url)
[username, password] = String.split(uri.userinfo, ":")
database = String.trim_leading(uri.path, "/")

IO.puts "--> Config:"
IO.puts "    Host: #{uri.host}"
IO.puts "    Port: #{uri.port}"
IO.puts "    User: #{username}"
IO.puts "    DB:   #{database}"
IO.puts ""

# 1. 验证基础连接
IO.puts "--> Testing Raw Connection..."
try do
  result = NexBase.query!("SELECT version()", [], repo: NexBase.Repo)
  [[version]] = result.rows
  IO.puts "    ✓ Connection successful!"
  IO.puts "    ✓ DB Version: #{version}"
rescue
  e ->
    IO.puts "    ✗ Connection failed: #{inspect e}"
    IO.puts ""
    IO.puts "请检查 .env 中的 DATABASE_URL 配置是否正确"
    System.halt(1)
end

# 2. 验证 NexBase Fluent API
IO.puts "\n--> Testing NexBase Fluent API..."

try do
  IO.puts "\n--> Testing Write & Read (CRUD)..."
  test_table = "nex_base_verification_temp"

  # Drop if exists
  NexBase.query!("DROP TABLE IF EXISTS #{test_table}", [], repo: NexBase.Repo)
  # Create
  NexBase.query!("CREATE TABLE #{test_table} (id SERIAL PRIMARY KEY, name TEXT, score INT)", [], repo: NexBase.Repo)
  IO.puts "    ✓ Created temp table: #{test_table}"

  # Insert
  NexBase.from(test_table)
  |> NexBase.insert(%{name: "Alice", score: 95})
  |> NexBase.run(repo: NexBase.Repo)

  NexBase.from(test_table)
  |> NexBase.insert(%{name: "Bob", score: 80})
  |> NexBase.run(repo: NexBase.Repo)

  IO.puts "    ✓ Inserted test data (Alice, Bob) using NexBase.insert"

  # Query where score > 90
  {:ok, results} = NexBase.from(test_table)
                   |> NexBase.select([:name, :score])
                   |> NexBase.gt(:score, 90)
                   |> NexBase.run(repo: NexBase.Repo)

  IO.puts "    ✓ Querying where score > 90..."
  case results do
    [%{name: "Alice", score: 95}] -> IO.puts "    ✓ Verification Passed! Found Alice."
    _ -> IO.puts "    ✗ Verification Failed! Expected Alice, got: #{inspect results}"
  end

  # --- 高级功能验证 ---
  IO.puts "\n--> Testing Advanced Features..."

  # 1. Update
  IO.puts "    Testing Update..."
  NexBase.from(test_table)
  |> NexBase.eq(:name, "Bob")
  |> NexBase.update(%{score: 88})
  |> NexBase.run(repo: NexBase.Repo)

  {:ok, [bob]} = NexBase.from(test_table) |> NexBase.eq(:name, "Bob") |> NexBase.select([:score]) |> NexBase.run(repo: NexBase.Repo)
  if bob.score == 88, do: IO.puts("    ✓ Update successful (Bob -> 88)"), else: IO.puts("    ✗ Update failed, got #{bob.score}")

  # 2. IN Filter
  IO.puts "    Testing IN Filter..."
  {:ok, in_results} = NexBase.from(test_table)
                      |> NexBase.in_list(:name, ["Alice", "Bob"])
                      |> NexBase.select([:name])
                      |> NexBase.run(repo: NexBase.Repo)
  if length(in_results) == 2, do: IO.puts("    ✓ IN filter successful (found 2)"), else: IO.puts("    ✗ IN filter failed, found #{length(in_results)}")

  # 3. Range (Pagination)
  IO.puts "    Testing Range (Pagination)..."
  {:ok, range_res} = NexBase.from(test_table)
                     |> NexBase.range(0, 0)
                     |> NexBase.order(:name)
                     |> NexBase.select([:name])
                     |> NexBase.run(repo: NexBase.Repo)
  if length(range_res) == 1, do: IO.puts("    ✓ Range successful (got 1 row)"), else: IO.puts("    ✗ Range failed, got #{length(range_res)}")

  # 4. Upsert
  IO.puts "    Testing Upsert..."
  {:ok, [alice]} = NexBase.from(test_table) |> NexBase.eq(:name, "Alice") |> NexBase.select([:id]) |> NexBase.run(repo: NexBase.Repo)

  NexBase.from(test_table)
  |> NexBase.upsert(%{id: alice.id, name: "Alice", score: 100})
  |> NexBase.run(repo: NexBase.Repo)

  {:ok, [alice_new]} = NexBase.from(test_table) |> NexBase.eq(:id, alice.id) |> NexBase.select([:score]) |> NexBase.run(repo: NexBase.Repo)
  if alice_new.score == 100, do: IO.puts("    ✓ Upsert successful (Alice -> 100)"), else: IO.puts("    ✗ Upsert failed, got #{alice_new.score}")

  # 5. Delete
  IO.puts "    Testing Delete..."
  NexBase.from(test_table)
  |> NexBase.eq(:name, "Bob")
  |> NexBase.delete()
  |> NexBase.run(repo: NexBase.Repo)

  {:ok, after_del} = NexBase.from(test_table) |> NexBase.eq(:name, "Bob") |> NexBase.select([:id]) |> NexBase.run(repo: NexBase.Repo)
  if after_del == [], do: IO.puts("    ✓ Delete successful (Bob gone)"), else: IO.puts("    ✗ Delete failed, Bob still here")

  # 6. RPC
  IO.puts "    Testing RPC..."
  NexBase.query!("CREATE OR REPLACE FUNCTION add_nums(a integer, b integer) RETURNS integer AS 'SELECT $1 + $2;' LANGUAGE SQL IMMUTABLE;", [], repo: NexBase.Repo)

  {:ok, rpc_res} = NexBase.rpc("add_nums", %{a: 10, b: 20}, repo: NexBase.Repo)
  [[sum]] = rpc_res.rows
  if sum == 30, do: IO.puts("    ✓ RPC successful (10+20=30)"), else: IO.puts("    ✗ RPC failed, got #{inspect sum}")

  # Cleanup
  NexBase.query!("DROP FUNCTION add_nums(integer, integer)", [], repo: NexBase.Repo)
  NexBase.query!("DROP TABLE #{test_table}", [], repo: NexBase.Repo)
  IO.puts "    ✓ Cleaned up temp table"

  IO.puts "\n✅ 所有验证通过!"
  IO.puts "----------------------------------------"

rescue
  e -> IO.puts "    ✗ Test failed: #{inspect e}"
end
