# Extend projects table with GitHub metadata fields
Nex.Env.init()
NexBase.init(url: Nex.Env.get(:database_url), ssl: true, start: true)

NexBase.query!( """
ALTER TABLE projects ADD COLUMN IF NOT EXISTS full_name VARCHAR(500)
""", [])

NexBase.query!( """
ALTER TABLE projects ADD COLUMN IF NOT EXISTS avatar_url VARCHAR(500)
""", [])

NexBase.query!( """
ALTER TABLE projects ADD COLUMN IF NOT EXISTS open_issues INTEGER DEFAULT 0
""", [])

NexBase.query!( """
ALTER TABLE projects ADD COLUMN IF NOT EXISTS pushed_at TIMESTAMP
""", [])

NexBase.query!( """
ALTER TABLE projects ADD COLUMN IF NOT EXISTS license VARCHAR(100)
""", [])

# Add unique index on full_name for upsert
NexBase.query!( """
CREATE UNIQUE INDEX IF NOT EXISTS idx_projects_full_name ON projects(full_name)
""", [])

IO.puts("✅ Migration 002 completed — projects table extended!")
