# Connect to database
Nex.Env.init()
NexBase.init(url: Nex.Env.get(:database_url), start: true)

# Create projects table (includes fields from migrations 001, 002, 003)
NexBase.query!("""
CREATE TABLE IF NOT EXISTS projects (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  full_name TEXT,
  description TEXT,
  repo_url TEXT NOT NULL UNIQUE,
  homepage_url TEXT,
  avatar_url TEXT,
  stars INTEGER DEFAULT 0,
  open_issues INTEGER DEFAULT 0,
  pushed_at TEXT,
  license TEXT,
  last_commit_at TEXT,
  added_at TEXT DEFAULT CURRENT_TIMESTAMP,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
)
""", [])

# Create project_stats table
NexBase.query!("""
CREATE TABLE IF NOT EXISTS project_stats (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id INTEGER NOT NULL REFERENCES projects(id),
  stars INTEGER NOT NULL,
  recorded_at TEXT NOT NULL,
  UNIQUE(project_id, recorded_at)
)
""", [])

# Create tags table
NexBase.query!("""
CREATE TABLE IF NOT EXISTS tags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE
)
""", [])

# Create project_tags table
NexBase.query!("""
CREATE TABLE IF NOT EXISTS project_tags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id INTEGER NOT NULL REFERENCES projects(id),
  tag_id INTEGER NOT NULL REFERENCES tags(id),
  UNIQUE(project_id, tag_id)
)
""", [])

# Create indexes
NexBase.query!("CREATE INDEX IF NOT EXISTS idx_projects_stars ON projects(stars DESC)", [])
NexBase.query!("CREATE INDEX IF NOT EXISTS idx_projects_updated_at ON projects(updated_at DESC)", [])
NexBase.query!("CREATE INDEX IF NOT EXISTS idx_project_stats_project_recorded ON project_stats(project_id, recorded_at DESC)", [])
NexBase.query!("CREATE UNIQUE INDEX IF NOT EXISTS idx_projects_full_name ON projects(full_name)", [])

IO.puts("Migrations completed!")
