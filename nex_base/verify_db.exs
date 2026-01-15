# nex_base/verify_db.exs

# 0. 停止应用以防自动启动导致配置未生效
Application.stop(:nex_base)
Application.stop(:ecto_sql)
Application.stop(:postgrex)

# 1. 解析连接字符串
url = "postgresql://postgres:qcfgoAWdMOtsVLaUzVYscWJxnHMqciRv@crossover.proxy.rlwy.net:12664/railway"
uri = URI.parse(url)
[username, password] = String.split(uri.userinfo, ":")
database = String.trim_leading(uri.path, "/")

# 清理可能干扰的环境变量
System.delete_env("DATABASE_URL")

IO.puts "--> Config:"
IO.puts "    Host: #{uri.host}"
IO.puts "    Port: #{uri.port}"
IO.puts "    User: #{username}"
IO.puts "    DB:   #{database}"

# 2. 直接配置 Application Env
# 注意：Ecto.Adapters.Postgres 需要 SSL 选项来连接 Railway
Application.put_env(:nex_base, NexBase.Repo, [
  username: username,
  password: password,
  hostname: uri.host,
  port: uri.port,
  database: database,
  pool_size: 2,
  ssl: true,
  ssl_opts: [verify: :verify_none]
])

# 3. 确保应用启动
IO.puts "--> Starting NexBase Application..."
{:ok, _} = Application.ensure_all_started(:nex_base)

# 4. 验证基础连接 (Raw SQL)
IO.puts "--> Testing Raw Connection..."
try do
  result = NexBase.query!("SELECT version()", [])
  [[version]] = result.rows
  IO.puts "    ✓ Connection successful!"
  IO.puts "    ✓ DB Version: #{version}"
rescue
  e -> 
    IO.puts "    ✗ Connection failed: #{inspect e}"
    # 如果是 SSL 错误，提示一下
    if inspect(e) =~ "ssl" do
       IO.puts "    (Hint: This might be an SSL requirement issue. Try changing ssl: false to ssl: true)"
    end
    System.halt(1)
end

# 5. 验证 NexBase Fluent API
IO.puts "\n--> Testing NexBase Fluent API..."

try do
  # 尝试查询 public schema 下的表
  # 注意：Ecto 会将 "schema.table" 视为带点的表名，而不是 schema 限定。
  # 暂时跳过 information_schema 查询，直接测试 CRUD。
  # IO.puts "    Querying information_schema.tables..."
  # {:ok, tables} = NexBase.from("information_schema.tables")
  #                 |> NexBase.select([:table_name])
  #                 |> NexBase.eq(:table_schema, "public")
  #                 |> NexBase.limit(5)
  #                 |> NexBase.run()
  # 
  # IO.puts "    ✓ Query successful. Tables found: #{length(tables)}"
  # Enum.each(tables, fn t -> IO.puts("      - #{inspect t}") end)

  # 如果没有表，创建一个临时表测试写入和读取
  IO.puts "\n--> Testing Write & Read (CRUD)..."
  test_table = "nex_base_verification_temp"
  
  # Drop if exists
  NexBase.query!("DROP TABLE IF EXISTS #{test_table}", [])
  # Create
  NexBase.query!("CREATE TABLE #{test_table} (id SERIAL PRIMARY KEY, name TEXT, score INT)", [])
  IO.puts "    ✓ Created temp table: #{test_table}"
  
  # Insert (Use NexBase.insert DSL)
  # Note: Ecto schema-less insert_all doesn't support autogenerating IDs unless we use returning, 
  # or unless database handles it (SERIAL does).
  
  NexBase.from(test_table)
  |> NexBase.insert(%{name: "Alice", score: 95})
  |> NexBase.run()
  
  NexBase.from(test_table)
  |> NexBase.insert(%{name: "Bob", score: 80})
  |> NexBase.run()
  
  IO.puts "    ✓ Inserted test data (Alice, Bob) using NexBase.insert"

  # Use NexBase API to query back
  {:ok, results} = NexBase.from(test_table)
                   |> NexBase.select([:name, :score])
                   |> NexBase.gt(:score, 90)
                   |> NexBase.run()

  IO.puts "    ✓ Querying where score > 90..."
  case results do
    [%{name: "Alice", score: 95}] -> IO.puts "    ✓ Verification Passed! Found Alice."
    _ -> IO.puts "    ✗ Verification Failed! Expected Alice, got: #{inspect results}"
  end

  # --- 新功能验证 (NexBase v0.2.0) ---
  IO.puts "\n--> Testing Advanced Features (v0.2.0)..."

  # 1. Update
  IO.puts "    Testing Update..."
  NexBase.from(test_table)
  |> NexBase.eq(:name, "Bob")
  |> NexBase.update(%{score: 88})
  |> NexBase.run()
  
  {:ok, [bob]} = NexBase.from(test_table) |> NexBase.eq(:name, "Bob") |> NexBase.select([:score]) |> NexBase.run()
  if bob.score == 88, do: IO.puts("    ✓ Update successful (Bob -> 88)"), else: IO.puts("    ✗ Update failed, got #{bob.score}")

  # 2. IN Filter
  IO.puts "    Testing IN Filter..."
  {:ok, in_results} = NexBase.from(test_table)
                      |> NexBase.in_list(:name, ["Alice", "Bob"])
                      |> NexBase.select([:name])
                      |> NexBase.run()
  if length(in_results) == 2, do: IO.puts("    ✓ IN filter successful (found 2)"), else: IO.puts("    ✗ IN filter failed, found #{length(in_results)}")

  # 3. Range (Limit/Offset)
  IO.puts "    Testing Range (Pagination)..."
  {:ok, range_res} = NexBase.from(test_table)
                     |> NexBase.range(0, 0) # Should return 1 row (index 0 to 0)
                     |> NexBase.order(:name)
                     |> NexBase.select([:name])
                     |> NexBase.run()
  if length(range_res) == 1, do: IO.puts("    ✓ Range successful (got 1 row)"), else: IO.puts("    ✗ Range failed, got #{length(range_res)}")

  # 4. Upsert (using id as conflict target)
  IO.puts "    Testing Upsert..."
  # First get Alice's ID
  {:ok, [alice]} = NexBase.from(test_table) |> NexBase.eq(:name, "Alice") |> NexBase.select([:id]) |> NexBase.run()
  
  # Upsert Alice with new score
  # Ecto schema-less upsert needs explicit :conflict_target if it's not the primary key?
  # Actually Ecto docs say: "If a schema is not given, the :conflict_target option is required".
  # We hardcoded it to :id in NexBase.run for upsert. 
  # But wait, conflict_target expects atoms usually.
  # Let's ensure our implementation passes it correctly.
  
  NexBase.from(test_table)
  |> NexBase.upsert(%{id: alice.id, name: "Alice", score: 100})
  |> NexBase.run()
  
  {:ok, [alice_new]} = NexBase.from(test_table) |> NexBase.eq(:id, alice.id) |> NexBase.select([:score]) |> NexBase.run()
  if alice_new.score == 100, do: IO.puts("    ✓ Upsert successful (Alice -> 100)"), else: IO.puts("    ✗ Upsert failed, got #{alice_new.score}")

  # 5. Delete
  IO.puts "    Testing Delete..."
  NexBase.from(test_table)
  |> NexBase.eq(:name, "Bob")
  |> NexBase.delete()
  |> NexBase.run()
  
  # Need to select fields explicitly, otherwise Ecto complains about selecting all without schema
  {:ok, after_del} = NexBase.from(test_table) |> NexBase.eq(:name, "Bob") |> NexBase.select([:id]) |> NexBase.run()
  if after_del == [], do: IO.puts("    ✓ Delete successful (Bob gone)"), else: IO.puts("    ✗ Delete failed, Bob still here")

  # 6. RPC (Optional - needs a function to exist)
  # 这里我们创建一个简单的加法函数来测试 RPC
  IO.puts "    Testing RPC..."
  NexBase.query!("CREATE OR REPLACE FUNCTION add_nums(a integer, b integer) RETURNS integer AS 'SELECT $1 + $2;' LANGUAGE SQL IMMUTABLE;")
  
  {:ok, rpc_res} = NexBase.rpc("add_nums", %{a: 10, b: 20})
  # rpc_res is Raw result from Ecto.Adapters.SQL.query
  [[sum]] = rpc_res.rows
  if sum == 30, do: IO.puts("    ✓ RPC successful (10+20=30)"), else: IO.puts("    ✗ RPC failed, got #{inspect sum}")
  
  # Cleanup RPC
  NexBase.query!("DROP FUNCTION add_nums(integer, integer)")

  # Cleanup Table
  NexBase.query!("DROP TABLE #{test_table}", [])
  IO.puts "    ✓ Cleaned up temp table"

rescue
  e -> IO.puts "    ✗ Test failed: #{inspect e}"
end
