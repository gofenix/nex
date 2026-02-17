# Connect to database
Nex.Env.init()
NexBase.init(url: Nex.Env.get(:database_url), start: true)

# Create projects table
NexBase.query!("""
CREATE TABLE IF NOT EXISTS projects (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  full_name TEXT,
  description TEXT,
  repo_url TEXT NOT NULL UNIQUE,
  homepage_url TEXT,
  avatar_url TEXT,
  stars INTEGER DEFAULT 0,
  open_issues INTEGER DEFAULT 0,
  pushed_at TIMESTAMP,
  license TEXT,
  last_commit_at TIMESTAMP,
  added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
""", [])

# Create project_stats table
NexBase.query!("""
CREATE TABLE IF NOT EXISTS project_stats (
  id SERIAL PRIMARY KEY,
  project_id INTEGER NOT NULL REFERENCES projects(id),
  stars INTEGER NOT NULL,
  recorded_at TIMESTAMP NOT NULL,
  UNIQUE(project_id, recorded_at)
)
""", [])

# Create tags table
NexBase.query!("""
CREATE TABLE IF NOT EXISTS tags (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE
)
""", [])

# Create project_tags table
NexBase.query!("""
CREATE TABLE IF NOT EXISTS project_tags (
  id SERIAL PRIMARY KEY,
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
