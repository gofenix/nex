# Connect to database
Nex.Env.init()
NexBase.init(url: Nex.Env.get(:database_url), ssl: true, start: true)

# Create projects table
NexBase.query!( """
CREATE TABLE IF NOT EXISTS projects (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  repo_url VARCHAR(500) NOT NULL UNIQUE,
  homepage_url VARCHAR(500),
  stars INTEGER DEFAULT 0,
  last_commit_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
""", [])

# Create project_stats table
NexBase.query!( """
CREATE TABLE IF NOT EXISTS project_stats (
  id SERIAL PRIMARY KEY,
  project_id INTEGER NOT NULL REFERENCES projects(id),
  stars INTEGER NOT NULL,
  recorded_at DATE NOT NULL,
  UNIQUE(project_id, recorded_at)
)
""", [])

# Create tags table
NexBase.query!( """
CREATE TABLE IF NOT EXISTS tags (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(100) NOT NULL UNIQUE
)
""", [])

# Create project_tags table
NexBase.query!( """
CREATE TABLE IF NOT EXISTS project_tags (
  id SERIAL PRIMARY KEY,
  project_id INTEGER NOT NULL REFERENCES projects(id),
  tag_id INTEGER NOT NULL REFERENCES tags(id),
  UNIQUE(project_id, tag_id)
)
""", [])

# Create indexes
NexBase.query!( """
CREATE INDEX IF NOT EXISTS idx_projects_stars ON projects(stars DESC)
""", [])

NexBase.query!( """
CREATE INDEX IF NOT EXISTS idx_projects_updated_at ON projects(updated_at DESC)
""", [])

NexBase.query!( """
CREATE INDEX IF NOT EXISTS idx_project_stats_project_recorded ON project_stats(project_id, recorded_at DESC)
""", [])

IO.puts("✅ Migrations completed!")
