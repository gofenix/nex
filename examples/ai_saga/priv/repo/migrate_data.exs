_ = """
SQLite to PostgreSQL Data Migration
Usage: mix run priv/repo/migrate_data.exs
"""

Nex.Env.init()

# Read from SQLite
IO.puts("Reading from SQLite...")
System.put_env("DATABASE_URL", "sqlite:///#{File.cwd!()}/data/ai_saga.db")
Nex.Env.init()

{:ok, paradigms} = NexBase.from("aisaga_paradigms") |> NexBase.run()
{:ok, authors} = NexBase.from("aisaga_authors") |> NexBase.run()
{:ok, papers} = NexBase.from("aisaga_papers") |> NexBase.run()
{:ok, paper_authors} = NexBase.from("aisaga_paper_authors") |> NexBase.run()

IO.puts("SQLite data: #{length(paradigms)} paradigms, #{length(authors)} authors, #{length(papers)} papers, #{length(paper_authors)} links")

# Stop SQLite repo
:ok = GenServer.stop(NexBase.Repo.SQLite)

# Switch to PostgreSQL
IO.puts("\nSwitching to PostgreSQL...")
System.put_env("DATABASE_URL", "System.get_env("DATABASE_URL")")
Nex.Env.init()

# Get a PG connection and start repo
pg_conn = NexBase.init(url: System.get_env("DATABASE_URL"), start: true)
IO.puts("Connected to PostgreSQL")

# Insert paradigms
IO.puts("\nMigrating paradigms...")
NexBase.query!(pg_conn, "DELETE FROM aisaga_paradigms", [])
Enum.each(paradigms, fn p ->
  record = Map.drop(p, ["id"])
  NexBase.from(pg_conn, "aisaga_paradigms") |> NexBase.insert(record) |> NexBase.run()
end)
IO.puts("Migrated #{length(paradigms)} paradigms")

# Insert authors
IO.puts("\nMigrating authors...")
NexBase.query!(pg_conn, "DELETE FROM aisaga_authors", [])
Enum.each(authors, fn a ->
  record = Map.drop(a, ["id"])
  NexBase.from(pg_conn, "aisaga_authors") |> NexBase.insert(record) |> NexBase.run()
end)
IO.puts("Migrated #{length(authors)} authors")

# Insert papers
IO.puts("\nMigrating papers...")
NexBase.query!(pg_conn, "DELETE FROM aisaga_papers", [])
Enum.each(papers, fn p ->
  record = Map.drop(p, ["id"])
  NexBase.from(pg_conn, "aisaga_papers") |> NexBase.insert(record) |> NexBase.run()
end)
IO.puts("Migrated #{length(papers)} papers")

# Insert paper_authors
IO.puts("\nMigrating paper_authors...")
NexBase.query!(pg_conn, "DELETE FROM aisaga_paper_authors", [])
Enum.each(paper_authors, fn pa ->
  record = Map.drop(pa, ["id"])
  NexBase.from(pg_conn, "aisaga_paper_authors") |> NexBase.insert(record) |> NexBase.run()
end)
IO.puts("Migrated #{length(paper_authors)} paper_authors")

# Verify
IO.puts("\n✅ Migration complete!")
{:ok, pg_papers} = pg_conn |> NexBase.from("aisaga_papers") |> NexBase.run()
{:ok, pg_authors} = pg_conn |> NexBase.from("aisaga_authors") |> NexBase.run()
{:ok, pg_paradigms} = pg_conn |> NexBase.from("aisaga_paradigms") |> NexBase.run()

IO.puts("Verification:")
IO.puts("  Papers: #{length(pg_papers)} (SQLite had #{length(papers)})")
IO.puts("  Authors: #{length(pg_authors)} (SQLite had #{length(authors)})")
IO.puts("  Paradigms: #{length(pg_paradigms)} (SQLite had #{length(paradigms)})")
