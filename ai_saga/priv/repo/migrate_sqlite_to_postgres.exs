_ = """
SQLite to PostgreSQL Migration Script
This script migrates all data from SQLite to PostgreSQL
Usage: mix run priv/repo/migrate_sqlite_to_postgres.exs
Prerequisites:
1. .env must have DATABASE_URL pointing to PostgreSQL
2. SQLite database must exist at data/ai_saga.db
3. PostgreSQL tables must already be created (run 001_create_schema_postgres.exs first)
"""

IO.puts("Starting SQLite to PostgreSQL migration...")

# Initialize environment
Nex.Env.init()

# Connect to PostgreSQL
pg_conn = NexBase.init(
  url: Nex.Env.get(:database_url),
  start: true
)

IO.puts("PostgreSQL connection established")

# Connect to SQLite (using absolute path from project root)
sqlite_path = Path.join(File.cwd!(), "data/ai_saga.db")
sqlite_url = "sqlite:///#{sqlite_path}"
IO.puts("SQLite path: #{sqlite_path}")
sqlite_conn = NexBase.init(
  url: sqlite_url,
  start: true
)

IO.puts("SQLite connection established")

# Helper to get data
get_data = fn conn, table ->
  case NexBase.from(conn, table) |> NexBase.run() do
    {:ok, records} -> records
    _ -> []
  end
end

# Migrate paradigms
IO.puts("\nMigrating paradigms...")
NexBase.query!(pg_conn, "DELETE FROM paradigms", [])

paradigms = get_data.(sqlite_conn, "paradigms")
IO.puts("Found #{length(paradigms)} paradigms")

Enum.each(paradigms, fn p ->
  record = Map.drop(p, ["id"])
  NexBase.from(pg_conn, "paradigms") |> NexBase.insert(record) |> NexBase.run()
end)

IO.puts("Migrated #{length(paradigms)} paradigms")

# Migrate authors
IO.puts("\nMigrating authors...")
NexBase.query!(pg_conn, "DELETE FROM authors", [])

authors = get_data.(sqlite_conn, "authors")
IO.puts("Found #{length(authors)} authors")

Enum.each(authors, fn a ->
  record = Map.drop(a, ["id"])
  NexBase.from(pg_conn, "authors") |> NexBase.insert(record) |> NexBase.run()
end)

IO.puts("Migrated #{length(authors)} authors")

# Migrate papers
IO.puts("\nMigrating papers...")
NexBase.query!(pg_conn, "DELETE FROM papers", [])

papers = get_data.(sqlite_conn, "papers")
IO.puts("Found #{length(papers)} papers")

Enum.each(papers, fn p ->
  record = Map.drop(p, ["id"])
  NexBase.from(pg_conn, "papers") |> NexBase.insert(record) |> NexBase.run()
end)

IO.puts("Migrated #{length(papers)} papers")

# Migrate paper_authors
IO.puts("\nMigrating paper_authors...")
NexBase.query!(pg_conn, "DELETE FROM paper_authors", [])

paper_authors = get_data.(sqlite_conn, "paper_authors")
IO.puts("Found #{length(paper_authors)} paper_authors")

Enum.each(paper_authors, fn pa ->
  record = Map.drop(pa, ["id"])
  NexBase.from(pg_conn, "paper_authors") |> NexBase.insert(record) |> NexBase.run()
end)

IO.puts("Migrated #{length(paper_authors)} paper_authors")

IO.puts("\n✅ Migration complete!")
IO.puts("All data from SQLite has been migrated to PostgreSQL")
IO.puts("\nVerification:")

# Verify counts
{:ok, pg_papers} = pg_conn |> NexBase.from("papers") |> NexBase.run()
{:ok, pg_authors} = pg_conn |> NexBase.from("authors") |> NexBase.run()
{:ok, pg_paradigms} = pg_conn |> NexBase.from("paradigms") |> NexBase.run()

IO.puts("  Papers: #{length(pg_papers)} (SQLite had #{length(papers)})")
IO.puts("  Authors: #{length(pg_authors)} (SQLite had #{length(authors)})")
IO.puts("  Paradigms: #{length(pg_paradigms)} (SQLite had #{length(paradigms)})")

if length(pg_papers) == length(papers) and
   length(pg_authors) == length(authors) and
   length(pg_paradigms) == length(paradigms) do
  IO.puts("\n✅ All data verified successfully!")
else
  IO.puts("\n⚠️ Warning: Count mismatch detected!")
end
