# 示例 01: NexBase 数据库验证
# 快速验证数据库连接和 NexBase 功能

# Set script mode to prevent Application from starting Repo
System.put_env("SCRIPT_MODE", "true")

# Load .env file manually
env_file = ".env"
if File.exists?(env_file) do
  File.read!(env_file)
  |> String.split("\n")
  |> Enum.each(fn line ->
    line = String.trim(line)
    unless String.starts_with?(line, "#") or line == "" do
      case String.split(line, "=", parts: 2) do
        [key, value] ->
          key = String.trim(key)
          value = String.trim(value)
          System.put_env(key, value)
        _ -> :ok
      end
    end
  end)
else
  IO.puts("⚠️  .env file not found")
  System.halt(1)
end

url = System.get_env("DATABASE_URL")

if is_nil(url) or url == "" do
  IO.puts("⚠️  DATABASE_URL not set")
  System.halt(1)
end

# Ensure dependencies are started (but NOT the application)
Application.ensure_all_started(:postgrex)
Application.ensure_all_started(:ecto_sql)

# Start Repo manually with explicit config
repo_config = [
  url: url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
]

case NexBaseDemo.Repo.start_link(repo_config) do
  {:ok, _pid} -> :ok
  {:error, {:already_started, _pid}} -> :ok
end

IO.puts("🚀 NexBase Database Verification")
IO.puts("----------------------------------------")

try do
  # Initialize client (Supabase-style)
  client = NexBase.client(repo: NexBaseDemo.Repo)

  # 1. Test connection
  result = client |> NexBase.query("SELECT version()", []) |> elem(1)
  [[version]] = result.rows
  IO.puts("✓ Connection successful")
  IO.puts("✓ PostgreSQL: #{String.slice(version, 0..30)}...")

  # 2. Test CRUD
  IO.puts("\n✓ Testing CRUD Operations...")
  table = "verify_temp"

  client |> NexBase.query("DROP TABLE IF EXISTS #{table}", [])
  client |> NexBase.query("CREATE TABLE #{table} (id SERIAL PRIMARY KEY, name TEXT, score INT)", [])

  # Insert
  client |> NexBase.from(table) |> NexBase.insert(%{name: "Alice", score: 95}) |> NexBase.run()
  client |> NexBase.from(table) |> NexBase.insert(%{name: "Bob", score: 80}) |> NexBase.run()

  # Read
  {:ok, results} = client |> NexBase.from(table) |> NexBase.gt(:score, 90) |> NexBase.run()
  IO.puts("  - Insert & Select: #{length(results)} record(s) with score > 90")

  # Update
  client |> NexBase.from(table) |> NexBase.eq(:name, "Bob") |> NexBase.update(%{score: 88}) |> NexBase.run()
  {:ok, [bob]} = client |> NexBase.from(table) |> NexBase.eq(:name, "Bob") |> NexBase.select([:score]) |> NexBase.run()
  IO.puts("  - Update: Bob's score = #{bob.score}")

  # Delete
  client |> NexBase.from(table) |> NexBase.eq(:name, "Bob") |> NexBase.delete() |> NexBase.run()
  {:ok, remaining} = client |> NexBase.from(table) |> NexBase.run()
  IO.puts("  - Delete: #{length(remaining)} record(s) remaining")

  # Cleanup
  NexBase.query!("DROP TABLE #{table}", [], repo: NexBaseDemo.Repo)

  IO.puts("\n✅ All tests passed!")
  IO.puts("----------------------------------------")

rescue
  e ->
    IO.puts("✗ Error: #{inspect(e)}")
    System.halt(1)
end
