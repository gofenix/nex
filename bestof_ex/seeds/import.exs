# seeds/import.exs
# Fetch real Elixir project data from GitHub API

Nex.Env.init()
NexBase.init(url: Nex.Env.get(:database_url), start: true)

IO.puts("🚀 Syncing real data from GitHub...")
IO.puts("   Searching for Elixir repos with stars > 1000")
IO.puts("----------------------------------------")

try do
  case BestofEx.Syncer.sync_all() do
    {:ok, count} ->
      IO.puts("----------------------------------------")
      IO.puts("✅ Sync completed! #{count} projects imported from GitHub")

    {:error, reason} ->
      IO.puts("✗ Sync failed: #{inspect(reason)}")
      System.halt(1)
  end
rescue
  e ->
    IO.puts("✗ Error: #{inspect(e)}")
    IO.puts(Exception.format(:error, e, __STACKTRACE__))
    System.halt(1)
end
