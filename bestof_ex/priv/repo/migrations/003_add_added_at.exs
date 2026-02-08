# Add added_at column to track when a project was first imported
Nex.Env.init()
NexBase.init(url: Nex.Env.get(:database_url), ssl: true, start: true)

NexBase.query!("""
ALTER TABLE projects ADD COLUMN IF NOT EXISTS added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
""", [])

IO.puts("✅ Migration 003 completed — added_at column added!")
